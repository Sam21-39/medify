import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/database/medify_database.dart';
import 'package:medify/core/error/failure.dart';
import 'package:medify/features/medicines/data/sqflite/medicine_sqflite_repository.dart';
import 'package:medify/features/medicines/domain/entities/medicine.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late SqfliteMedicineRepository repo;
  late int profileId;

  setUp(() async {
    db = await MedifyDatabase.open(path: inMemoryDatabasePath);
    repo = SqfliteMedicineRepository(db);
    profileId = await db.insert('profiles', {
      'name': 'Patient',
      'role': 'patient',
      'color_value': 0,
      'created_at': 0,
      'updated_at': 0,
    });
  });

  tearDown(() => db.close());

  Medicine medicine({List<int> times = const [28800, 72000]}) => Medicine(
    profileId: profileId,
    name: 'Aspirin',
    dosage: '1 tablet',
    reminderTimes: times,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  Future<List<Map<String, Object?>>> schedules(int medicineId) =>
      db.query('schedules', where: 'medicine_id = ?', whereArgs: [medicineId]);

  test('add, get, update, toggle, delete', () async {
    final added = (await repo.addMedicine(medicine())).unwrap();
    final id = added.id!;
    expect(added.reminderTimes, [28800, 72000]);
    expect((await repo.getMedicineById(id)).unwrap(), added);

    final renamed = added.copyWith(name: 'Ibuprofen');
    expect((await repo.updateMedicine(renamed)).unwrap().name, 'Ibuprofen');
    // Name-only change keeps the same schedule rows.
    expect((await schedules(id)).length, 2);

    final toggled = (await repo.toggleMedicineStatus(id)).unwrap();
    expect(toggled.isActive, isFalse);
    expect((await repo.getActiveMedicines()).unwrap(), isEmpty);
    expect((await repo.toggleMedicineStatus(id)).unwrap().isActive, isTrue);

    expect((await repo.deleteMedicine(id)).isRight(), isTrue);
    expect((await repo.getAllMedicines()).unwrap(), isEmpty);
    expect(await schedules(id), isEmpty);
  });

  test(
    'changing reminder times deactivates old schedules, keeps rows',
    () async {
      final added = (await repo.addMedicine(medicine())).unwrap();
      await repo.updateMedicine(added.copyWith(reminderTimes: [3600]));

      final rows = await schedules(added.id!);
      expect(rows.where((r) => r['is_active'] == 0).length, 2);
      final updated = (await repo.getMedicineById(added.id!)).unwrap()!;
      expect(updated.reminderTimes, [3600]);
    },
  );

  test('update with null id and toggle of missing id return Left', () async {
    expect(
      (await repo.updateMedicine(medicine())).fold((f) => f, (_) => null),
      isA<Failure>(),
    );
    expect(
      (await repo.toggleMedicineStatus(9999)).fold((f) => f, (_) => null),
      isA<Failure>(),
    );
  });

  test('watchAllMedicines emits on subscribe and after writes', () async {
    final emitted = <List<Medicine>>[];
    final sub = repo.watchAllMedicines().listen(emitted.add);
    await pumpEventQueue();
    expect(emitted.last, isEmpty);

    await repo.addMedicine(medicine());
    await pumpEventQueue();
    expect(emitted.last.length, 1);
    await sub.cancel();
  });
}
