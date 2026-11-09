import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/database/medify_database.dart';
import 'package:medify/features/achievements/data/sqflite/achievement_sqflite_repository.dart';
import 'package:medify/features/achievements/domain/entities/achievement.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late AchievementSqfliteRepository repo;
  late int profileId;

  setUp(() async {
    db = await MedifyDatabase.open(path: inMemoryDatabasePath);
    repo = AchievementSqfliteRepository(db);
    profileId = await db.insert('profiles', {
      'name': 'Patient',
      'role': 'patient',
      'color_value': 0,
      'created_at': 0,
      'updated_at': 0,
    });
  });

  tearDown(() => db.close());

  test('unlock is idempotent and keeps the first unlock time', () async {
    final first = await repo.unlockAchievement(
      profileId,
      AchievementType.firstDose,
    );
    expect(first.isUnlocked, isTrue);
    final again = await repo.unlockAchievement(
      profileId,
      AchievementType.firstDose,
    );
    expect(again, first);
    expect(await repo.getAchievementsForProfile(profileId), [first]);
  });

  test('progress never decreases', () async {
    await repo.updateProgress(profileId, AchievementType.century, 40);
    final lower = await repo.updateProgress(
      profileId,
      AchievementType.century,
      10,
    );
    expect(lower.progress, 40);
    final higher = await repo.updateProgress(
      profileId,
      AchievementType.century,
      60,
    );
    expect(higher.progress, 60);
    expect(higher.isUnlocked, isFalse);
  });

  test(
    'duplicate (profile, type) rejected by DB and surfaced as typed exception',
    () async {
      await repo.createAchievement(profileId, AchievementType.oneMonth);
      await expectLater(
        repo.createAchievement(profileId, AchievementType.oneMonth),
        throwsA(isA<DuplicateAchievementException>()),
      );
      final rows = await db.query('achievements');
      expect(rows.length, 1);
    },
  );

  test('list returns only rows that exist for the profile', () async {
    await repo.unlockAchievement(profileId, AchievementType.firstDose);
    await repo.updateProgress(profileId, AchievementType.century, 5);
    final list = await repo.getAchievementsForProfile(profileId);
    expect(list.map((a) => a.type), [
      AchievementType.firstDose,
      AchievementType.century,
    ]);
  });
}
