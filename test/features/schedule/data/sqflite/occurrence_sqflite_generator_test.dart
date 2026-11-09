import 'package:medify/core/security/field_cipher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/database/medify_database.dart';
import 'package:medify/features/medicines/data/sqflite/medicine_sqflite_repository.dart';
import 'package:medify/features/medicines/domain/entities/medicine.dart';
import 'package:medify/features/schedule/data/sqflite/occurrence_sqflite_generator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tzdata.initializeTimeZones();
  });

  late Database db;
  late OccurrenceSqfliteGenerator generator;

  setUp(() async {
    db = await MedifyDatabase.open(path: inMemoryDatabasePath);
    generator = OccurrenceSqfliteGenerator(db);
    final profileId = await db.insert('profiles', {
      'name': 'A',
      'role': 'patient',
      'color_value': 0,
      'created_at': 0,
      'updated_at': 0,
    });
    // One reminder at 08:00, every day, start = local midnight of createdAt.
    await SqfliteMedicineRepository(
      db,
      FieldCipher(List.filled(32, 7)),
    ).addMedicine(
      Medicine(
        profileId: profileId,
        name: 'Aspirin',
        dosage: '2 tablets',
        dosageAmount: 2,
        reminderTimes: const [28800],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        currentQuantity: 10,
      ),
    );
  });

  tearDown(() => db.close());

  test('inserts one row per day and is idempotent on re-run', () async {
    final london = tz.getLocation('Europe/London');
    final window = (from: DateTime(2026, 3, 1), to: DateTime(2026, 3, 3));
    final now = DateTime.utc(2026, 3, 1);

    final first = await generator.generate(
      fromDate: window.from,
      toDate: window.to,
      location: london,
      nowUtc: now,
    );
    expect(first, 3);

    final second = await generator.generate(
      fromDate: window.from,
      toDate: window.to,
      location: london,
      nowUtc: now,
    );
    expect(second, 0);

    final rows = await db.query(
      'occurrences',
      columns: ['scheduled_at_utc', 'local_date', 'status'],
      orderBy: 'scheduled_at_utc',
    );
    expect(rows.length, 3);
    expect(rows.first['local_date'], '2026-03-01');
    expect(
      rows.first['scheduled_at_utc'],
      DateTime.utc(2026, 3, 1, 8).millisecondsSinceEpoch,
    );
    expect(rows.first['status'], 'scheduled');
  });
}
