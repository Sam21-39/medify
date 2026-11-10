import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/database/medify_database.dart';
import 'package:medify/core/error/failure.dart';
import 'package:medify/core/security/field_cipher.dart';
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
    repo = SqfliteMedicineRepository(db, FieldCipher(List.filled(32, 7)));
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

  test('name and notes are stored encrypted; reads decrypt', () async {
    final added = (await repo.addMedicine(
      medicine().copyWith(notes: 'with food'),
    )).unwrap();
    final row = (await db.query(
      'medicines',
      where: 'id = ?',
      whereArgs: [added.id],
    )).single;
    expect(row['name'], startsWith('v1.'));
    expect(row['notes'], startsWith('v1.'));
    expect(row['dose_label'], '1 tablet');
    final read = (await repo.getMedicineById(added.id!)).unwrap()!;
    expect(read.name, 'Aspirin');
    expect(read.notes, 'with food');
  });

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
    final archived = (await repo.getAllMedicines()).unwrap().single;
    expect(archived.isActive, isFalse);
    expect((await repo.toggleMedicineStatus(id)).isLeft(), isTrue);
  });

  test('delete archives and keeps occurrence history', () async {
    final added = (await repo.addMedicine(medicine())).unwrap();
    final scheduleId = (await schedules(added.id!)).first['id']! as int;
    await db.insert('occurrences', {
      'profile_id': profileId,
      'medicine_id': added.id,
      'schedule_id': scheduleId,
      'scheduled_at_utc': 1000,
      'local_date': '2026-01-01',
      'actor_profile_id': profileId,
      'dose_snapshot_amount': 1.0,
      'dose_snapshot_unit': 'mg',
      'created_at': 0,
      'updated_at': 0,
    });

    await repo.deleteMedicine(added.id!);

    final state = (await db.query(
      'medicines',
      columns: ['state'],
      where: 'id = ?',
      whereArgs: [added.id],
    )).single['state'];
    expect(state, 'finished');
    expect(
      await db.query(
        'occurrences',
        where: 'medicine_id = ?',
        whereArgs: [added.id],
      ),
      hasLength(1),
    );
  });

  test('stale-entity update leaves stock unchanged', () async {
    final added = (await repo.addMedicine(
      medicine().copyWith(currentQuantity: 10),
    )).unwrap();
    // Stock decremented by a dose transition.
    await db.update(
      'medicines',
      {'current_quantity': 7},
      where: 'id = ?',
      whereArgs: [added.id],
    );

    // `added` still carries currentQuantity 10 (stale).
    await repo.updateMedicine(added.copyWith(name: 'Stale'));

    final row = (await db.query(
      'medicines',
      where: 'id = ?',
      whereArgs: [added.id],
    )).single;
    expect(row['current_quantity'], 7);
  });

  test('update keeps an archived medicine archived', () async {
    final added = (await repo.addMedicine(medicine())).unwrap();
    await repo.deleteMedicine(added.id!);
    await repo.updateMedicine(added.copyWith(isActive: true));
    final state = (await db.query(
      'medicines',
      columns: ['state'],
      where: 'id = ?',
      whereArgs: [added.id],
    )).single['state'];
    expect(state, 'finished');
  });

  test(
    'changing reminder times drops future pending occurrences only',
    () async {
      final added = (await repo.addMedicine(medicine(times: const [28800])))
          .unwrap();
      final oldSchedule = (await schedules(added.id!)).single['id']! as int;
      final future = DateTime.now()
          .add(const Duration(days: 1))
          .millisecondsSinceEpoch;
      Map<String, Object?> occurrence(int at, String status) => {
        'profile_id': profileId,
        'medicine_id': added.id,
        'schedule_id': oldSchedule,
        'scheduled_at_utc': at,
        'local_date': '2026-01-01',
        'actor_profile_id': profileId,
        'dose_snapshot_amount': 1.0,
        'dose_snapshot_unit': 'mg',
        'status': status,
        'taken_at_utc': status == 'taken' ? at : null,
        'created_at': 0,
        'updated_at': 0,
      };
      await db.insert('occurrences', occurrence(future, 'scheduled'));
      await db.insert('occurrences', occurrence(1000, 'taken'));

      await repo.updateMedicine(added.copyWith(reminderTimes: const [32400]));

      final remaining = await db.query('occurrences', columns: ['status']);
      expect(remaining.map((r) => r['status']), ['taken']);
    },
  );

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
