import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/database/medify_database.dart';
import 'package:medify/features/profiles/data/sqflite/care_link_sqflite_repository.dart';
import 'package:medify/features/profiles/data/sqflite/profile_exceptions.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late CareLinkSqfliteRepository repo;
  late int patientId;
  late int caregiverId;

  setUp(() async {
    db = await MedifyDatabase.open(path: inMemoryDatabasePath);
    repo = CareLinkSqfliteRepository(db);
    Future<int> profile(String name) => db.insert('profiles', {
      'name': name,
      'role': 'patient',
      'color_value': 0,
      'created_at': 0,
      'updated_at': 0,
    });
    patientId = await profile('Patient');
    caregiverId = await profile('Caregiver');
  });

  tearDown(() => db.close());

  test('link then canActFor; self is always allowed', () async {
    expect(
      await repo.canActFor(caregiverId: caregiverId, patientId: patientId),
      isFalse,
    );
    await repo.link(caregiverId: caregiverId, patientId: patientId);
    expect(
      await repo.canActFor(caregiverId: caregiverId, patientId: patientId),
      isTrue,
    );
    expect(
      await repo.canActFor(caregiverId: patientId, patientId: patientId),
      isTrue,
    );
  });

  test('self-link rejected', () async {
    await expectLater(
      repo.link(caregiverId: patientId, patientId: patientId),
      throwsA(isA<InvalidProfileException>()),
    );
  });

  test('duplicate link rejected', () async {
    await repo.link(caregiverId: caregiverId, patientId: patientId);
    await expectLater(
      repo.link(caregiverId: caregiverId, patientId: patientId),
      throwsA(isA<InvalidProfileException>()),
    );
  });

  test('both profiles must exist', () async {
    await expectLater(
      repo.link(caregiverId: caregiverId, patientId: 999),
      throwsA(isA<ProfileNotFoundException>()),
    );
    await expectLater(
      repo.link(caregiverId: 999, patientId: patientId),
      throwsA(isA<ProfileNotFoundException>()),
    );
  });
}
