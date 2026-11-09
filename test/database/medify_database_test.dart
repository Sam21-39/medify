import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/database/enums.dart';
import 'package:medify/core/database/medify_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<int> _profile(Database db, {String name = 'A'}) =>
    db.insert('profiles', {
      'name': name,
      'role': ProfileRole.patient.name,
      'color_value': 0,
      'created_at': 0,
      'updated_at': 0,
    });

Future<int> _medicine(Database db, {required int profileId}) =>
    db.insert('medicines', {
      'profile_id': profileId,
      'name': 'M',
      'medicine_type': MedicineType.tablet.name,
      'dose_amount': 1.0,
      'dose_unit': 'mg',
      'dose_label': '1 mg',
      'intake_timing': IntakeTiming.anytime.name,
      'state': MedicineState.active.name,
      'created_at': 0,
      'updated_at': 0,
    });

Future<int> _schedule(Database db, {required int medicineId}) => db.insert(
  'schedules',
  {'medicine_id': medicineId, 'time_of_day_seconds': 3600, 'start_date': 0},
);

Future<int> _occurrence(
  Database db, {
  required int profileId,
  required int medicineId,
  required int scheduleId,
  int scheduledAt = 0,
  String status = 'scheduled',
  int? takenAt,
}) => db.insert('occurrences', {
  'profile_id': profileId,
  'medicine_id': medicineId,
  'schedule_id': scheduleId,
  'scheduled_at_utc': scheduledAt,
  'local_date': '2026-01-01',
  'status': status,
  'taken_at_utc': takenAt,
  'actor_profile_id': profileId,
  'dose_snapshot_amount': 1.0,
  'dose_snapshot_unit': 'mg',
  'created_at': 0,
  'updated_at': 0,
});

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;

  setUp(() async {
    db = await MedifyDatabase.open(path: inMemoryDatabasePath);
  });

  tearDown(() async {
    await db.close();
  });

  test('foreign keys are enforced', () async {
    await expectLater(
      _medicine(db, profileId: 999),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('occurrence CHECK: taken status requires taken_at_utc', () async {
    final profileId = await _profile(db);
    final medicineId = await _medicine(db, profileId: profileId);
    final scheduleId = await _schedule(db, medicineId: medicineId);
    await expectLater(
      _occurrence(
        db,
        profileId: profileId,
        medicineId: medicineId,
        scheduleId: scheduleId,
        status: OccurrenceStatus.taken.name,
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('occurrence UNIQUE: schedule_id + scheduled_at_utc', () async {
    final profileId = await _profile(db);
    final medicineId = await _medicine(db, profileId: profileId);
    final scheduleId = await _schedule(db, medicineId: medicineId);
    await _occurrence(
      db,
      profileId: profileId,
      medicineId: medicineId,
      scheduleId: scheduleId,
      scheduledAt: 5,
    );
    await expectLater(
      _occurrence(
        db,
        profileId: profileId,
        medicineId: medicineId,
        scheduleId: scheduleId,
        scheduledAt: 5,
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('enum round trip stores Enum.name as text', () async {
    final profileId = await _profile(db);
    final id = await db.insert('medicines', {
      'profile_id': profileId,
      'name': 'Syrup',
      'medicine_type': MedicineType.syrup.name,
      'dose_amount': 5.0,
      'dose_unit': 'ml',
      'dose_label': '5 ml',
      'intake_timing': IntakeTiming.withFood.name,
      'state': MedicineState.active.name,
      'created_at': 0,
      'updated_at': 0,
    });
    final rows = await db.rawQuery(
      'SELECT medicine_type, typeof(medicine_type) AS t FROM medicines WHERE id = ?',
      [id],
    );
    expect(
      MedicineType.values.byName(rows.single['medicine_type'] as String),
      MedicineType.syrup,
    );
    expect(rows.single['t'], 'text');
    expect(rows.single['medicine_type'], 'syrup');
  });

  test('deleting a medicine cascades to its schedules', () async {
    final profileId = await _profile(db);
    final medicineId = await _medicine(db, profileId: profileId);
    await _schedule(db, medicineId: medicineId);
    await db.delete('medicines', where: 'id = ?', whereArgs: [medicineId]);
    expect(await db.query('schedules'), isEmpty);
  });

  test(
    'guard: occurrence profile must match medicine profile on insert',
    () async {
      final profileA = await _profile(db, name: 'A');
      final profileB = await _profile(db, name: 'B');
      final medicineId = await _medicine(db, profileId: profileA);
      final scheduleId = await _schedule(db, medicineId: medicineId);
      await expectLater(
        _occurrence(
          db,
          profileId: profileB,
          medicineId: medicineId,
          scheduleId: scheduleId,
        ),
        throwsA(isA<DatabaseException>()),
      );
    },
  );

  test(
    'guard: occurrence profile must match medicine profile on update',
    () async {
      final profileA = await _profile(db, name: 'A');
      final profileB = await _profile(db, name: 'B');
      final medicineId = await _medicine(db, profileId: profileA);
      final scheduleId = await _schedule(db, medicineId: medicineId);
      final occurrenceId = await _occurrence(
        db,
        profileId: profileA,
        medicineId: medicineId,
        scheduleId: scheduleId,
      );
      await expectLater(
        db.update(
          'occurrences',
          {'profile_id': profileB},
          where: 'id = ?',
          whereArgs: [occurrenceId],
        ),
        throwsA(isA<DatabaseException>()),
      );
    },
  );

  group('care_links', () {
    Future<void> link(Database db, int patientId, int caregiverId) =>
        db.insert('care_links', {
          'patient_profile_id': patientId,
          'caregiver_profile_id': caregiverId,
          'created_at_utc': 0,
        });

    test('foreign keys: both profiles must exist', () async {
      final patientId = await _profile(db, name: 'P');
      await expectLater(
        link(db, patientId, 999),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        link(db, 999, patientId),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('UNIQUE: duplicate pair rejected', () async {
      final patientId = await _profile(db, name: 'P');
      final caregiverId = await _profile(db, name: 'C');
      await link(db, patientId, caregiverId);
      await expectLater(
        link(db, patientId, caregiverId),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('CHECK: self-link rejected', () async {
      final profileId = await _profile(db);
      await expectLater(
        link(db, profileId, profileId),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  test('profiles has notes and is_default columns', () async {
    final columns = (await db.rawQuery('PRAGMA table_info(profiles)'))
        .map((row) => row['name'])
        .toSet();
    expect(columns, containsAll(['notes', 'is_default']));
  });

  test('guard: occurrence medicine must match schedule medicine', () async {
    final profileId = await _profile(db);
    final medicineA = await _medicine(db, profileId: profileId);
    final medicineB = await _medicine(db, profileId: profileId);
    final scheduleB = await _schedule(db, medicineId: medicineB);
    await expectLater(
      _occurrence(
        db,
        profileId: profileId,
        medicineId: medicineA,
        scheduleId: scheduleB,
      ),
      throwsA(isA<DatabaseException>()),
    );
  });
}
