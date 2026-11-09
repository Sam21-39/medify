import 'package:medify/features/achievements/data/sqflite/achievement_row_mapper.dart';
import 'package:medify/features/achievements/domain/entities/achievement.dart';
import 'package:sqflite/sqflite.dart';

/// Thrown by [AchievementSqfliteRepository.createAchievement] when the profile
/// already has a row for this type (UNIQUE (profile_id, type)).
class DuplicateAchievementException implements Exception {
  const DuplicateAchievementException(this.profileId, this.type);

  final int profileId;
  final AchievementType type;

  @override
  String toString() =>
      'DuplicateAchievementException: profile $profileId already has ${type.name}';
}

/// sqflite-backed achievement data access. Unlock and progress rules
/// (thresholds, streaks, time-of-day counts) stay in the legacy service and are
/// not in this repo.
class AchievementSqfliteRepository {
  AchievementSqfliteRepository(this._db);

  final Database _db;

  Future<Achievement?> getAchievement(int profileId, AchievementType type) =>
      _find(_db, profileId, type);

  /// Rows that exist for the profile. Types with no row are not included.
  Future<List<Achievement>> getAchievementsForProfile(int profileId) async {
    final rows = await _db.query(
      'achievements',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'id ASC',
    );
    return rows.map(AchievementRowMapper.fromRow).toList();
  }

  /// Inserts a locked row with progress 0. Throws [DuplicateAchievementException]
  /// when the (profile, type) row already exists.
  Future<Achievement> createAchievement(
    int profileId,
    AchievementType type,
  ) async {
    try {
      final id = await _db.insert(
        'achievements',
        AchievementRowMapper.toRow(
          profileId,
          Achievement(type: type, unlockedAt: DateTime.now()),
        ),
      );
      return (await _byId(_db, id))!;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw DuplicateAchievementException(profileId, type);
      }
      rethrow;
    }
  }

  /// Idempotent: an already-unlocked row is returned unchanged. A missing row
  /// is created unlocked.
  Future<Achievement> unlockAchievement(int profileId, AchievementType type) {
    return _db.transaction<Achievement>((txn) async {
      final existing = await _find(txn, profileId, type);
      if (existing != null) {
        if (existing.isUnlocked) return existing;
        await txn.update(
          'achievements',
          {'unlocked_at_utc': DateTime.now().toUtc().millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [existing.id],
        );
      } else {
        await txn.insert(
          'achievements',
          AchievementRowMapper.toRow(
            profileId,
            Achievement(
              type: type,
              unlockedAt: DateTime.now(),
              isUnlocked: true,
            ),
          ),
        );
      }
      return (await _find(txn, profileId, type))!;
    });
  }

  /// Progress only increases. A lower or equal value returns the row unchanged.
  Future<Achievement> updateProgress(
    int profileId,
    AchievementType type,
    int progress,
  ) {
    if (progress < 0) {
      throw ArgumentError.value(progress, 'progress', 'must be >= 0');
    }
    return _db.transaction<Achievement>((txn) async {
      final existing = await _find(txn, profileId, type);
      if (existing == null) {
        await txn.insert(
          'achievements',
          AchievementRowMapper.toRow(
            profileId,
            Achievement(
              type: type,
              unlockedAt: DateTime.now(),
              progress: progress,
            ),
          ),
        );
      } else if (progress > existing.progress) {
        await txn.update(
          'achievements',
          {'progress': progress},
          where: 'id = ?',
          whereArgs: [existing.id],
        );
      } else {
        return existing;
      }
      return (await _find(txn, profileId, type))!;
    });
  }

  static Future<Achievement?> _find(
    DatabaseExecutor db,
    int profileId,
    AchievementType type,
  ) async {
    final rows = await db.query(
      'achievements',
      where: 'profile_id = ? AND type = ?',
      whereArgs: [profileId, type.name],
      limit: 1,
    );
    return rows.isEmpty ? null : AchievementRowMapper.fromRow(rows.single);
  }

  static Future<Achievement?> _byId(DatabaseExecutor db, int id) async {
    final rows = await db.query(
      'achievements',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : AchievementRowMapper.fromRow(rows.single);
  }
}
