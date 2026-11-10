import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/database/medify_database.dart';
import 'package:medify/core/security/field_cipher.dart';
import 'package:medify/features/profiles/data/sqflite/profile_exceptions.dart';
import 'package:medify/features/profiles/data/sqflite/profile_sqflite_repository.dart';
import 'package:medify/features/profiles/domain/entities/user_profile.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late ProfileSqfliteRepository repo;

  setUp(() async {
    db = await MedifyDatabase.open(path: inMemoryDatabasePath);
    repo = ProfileSqfliteRepository(db, FieldCipher(List.filled(32, 7)));
  });

  tearDown(() => db.close());

  UserProfile profile({String name = 'Ann', int role = 0}) => UserProfile(
    name: name,
    colorValue: 0xFF14B8A6,
    role: role,
    relationship: 'Mom',
    notes: 'allergy: none',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  test('create, get, update', () async {
    final created = await repo.createProfile(profile());
    expect(created.id, isNotNull);
    expect(await repo.getProfileById(created.id!), created);

    final renamed = created.copyWith(name: 'Anna');
    expect((await repo.updateProfile(renamed)).name, 'Anna');
    expect(await repo.getProfileById(created.id!), isNot(created));
  });

  test('role round-trips through ProfileRole names', () async {
    final caregiver = await repo.createProfile(profile(role: 1));
    final row = await db.query(
      'profiles',
      where: 'id = ?',
      whereArgs: [caregiver.id],
    );
    expect(row.single['role'], 'caregiver');
    expect((await repo.getProfileById(caregiver.id!))!.role, 1);
  });

  test('unknown role int is rejected', () async {
    await expectLater(
      repo.createProfile(profile(role: 5)),
      throwsA(isA<InvalidProfileException>()),
    );
  });

  test('update without id and unknown id are typed exceptions', () async {
    await expectLater(
      repo.updateProfile(profile()),
      throwsA(isA<InvalidProfileException>()),
    );
    final ghost = profile().copyWith(id: 999);
    await expectLater(
      repo.updateProfile(ghost),
      throwsA(isA<ProfileNotFoundException>()),
    );
  });

  test('archive hides the profile from active list', () async {
    final created = await repo.createProfile(profile());
    await repo.updateProfile(created.copyWith(isActive: false));
    expect(await repo.getActiveProfiles(), isEmpty);
    expect((await repo.getProfileById(created.id!))!.isActive, isFalse);
  });

  test('delete hard-deletes an unreferenced profile', () async {
    final created = await repo.createProfile(profile());
    await repo.deleteProfile(created.id!);
    expect(await repo.getProfileById(created.id!), isNull);
  });

  test(
    'archiving the active profile clears it; archived cannot be set',
    () async {
      final created = await repo.createProfile(profile());
      await repo.setActiveProfile(created.id!);
      await db.insert('medicines', {
        'profile_id': created.id,
        'name': 'M',
        'medicine_type': 'tablet',
        'dose_amount': 1.0,
        'dose_unit': 'mg',
        'dose_label': '1 mg',
        'intake_timing': 'anytime',
        'state': 'active',
        'created_at': 0,
        'updated_at': 0,
      });
      await repo.deleteProfile(created.id!);
      expect(await repo.getActiveProfile(), isNull);
      await expectLater(
        repo.setActiveProfile(created.id!),
        throwsA(isA<InvalidProfileException>()),
      );
    },
  );

  test('delete archives a profile that has medicines', () async {
    final created = await repo.createProfile(profile());
    await db.insert('medicines', {
      'profile_id': created.id,
      'name': 'M',
      'medicine_type': 'tablet',
      'dose_amount': 1.0,
      'dose_unit': 'mg',
      'dose_label': '1 mg',
      'intake_timing': 'anytime',
      'state': 'active',
      'created_at': 0,
      'updated_at': 0,
    });
    await repo.deleteProfile(created.id!);
    final after = (await repo.getProfileById(created.id!))!;
    expect(after.isActive, isFalse);
  });

  test('active profile is stored and read back; unknown id rejected', () async {
    final created = await repo.createProfile(profile());
    expect(await repo.getActiveProfile(), isNull);
    await repo.setActiveProfile(created.id!);
    expect(await repo.getActiveProfile(), created);
    await expectLater(
      repo.setActiveProfile(999),
      throwsA(isA<ProfileNotFoundException>()),
    );
  });

  test('name and notes are stored as v1 values, other columns plain', () async {
    final created = await repo.createProfile(profile(name: 'Ann'));
    final row = (await db.query(
      'profiles',
      where: 'id = ?',
      whereArgs: [created.id],
    )).single;
    expect(row['name'], startsWith('v1.'));
    expect(row['name'], isNot('Ann'));
    expect(row['notes'], startsWith('v1.'));
    expect(row['relation'], 'Mom');
    expect(row['role'], 'patient');
    expect((await repo.getProfileById(created.id!))!.name, 'Ann');
  });

  test('search, count and name-exists ignore archived profiles', () async {
    final ann = await repo.createProfile(profile(name: 'Ann'));
    await repo.createProfile(profile(name: 'Bob'));
    expect(await repo.searchProfiles('An'), [ann]);
    expect(await repo.getProfileCount(), 2);
    expect(await repo.isProfileNameExists('Ann'), isTrue);
    expect(await repo.isProfileNameExists('Ann', excludeId: ann.id), isFalse);
    await repo.updateProfile(ann.copyWith(isActive: false));
    expect(await repo.getProfileCount(), 1);
    expect(await repo.isProfileNameExists('Ann'), isFalse);
  });
}
