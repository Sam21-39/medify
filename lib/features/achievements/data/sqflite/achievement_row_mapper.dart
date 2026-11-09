import 'package:medify/features/achievements/domain/entities/achievement.dart';

/// Maps `achievements` rows to [Achievement]. One row per (profile, type).
///
/// `isUnlocked` is `unlocked_at_utc != null`. A locked row has no real unlock
/// time, so `unlockedAt` reads back as the epoch.
class AchievementRowMapper {
  AchievementRowMapper._();

  static Map<String, Object?> toRow(int profileId, Achievement a) => {
    'profile_id': profileId,
    'type': a.type.name,
    'progress': a.progress,
    'unlocked_at_utc': a.isUnlocked
        ? a.unlockedAt.toUtc().millisecondsSinceEpoch
        : null,
  };

  static Achievement fromRow(Map<String, Object?> row) {
    final typeName = row['type'] as String;
    final type = AchievementType.values
        .where((t) => t.name == typeName)
        .firstOrNull;
    if (type == null) {
      throw StateError('Unknown achievements.type value: $typeName');
    }
    final unlockedMs = row['unlocked_at_utc'] as int?;
    return Achievement(
      id: row['id'] as int,
      type: type,
      progress: row['progress'] as int,
      isUnlocked: unlockedMs != null,
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(
        unlockedMs ?? 0,
        isUtc: true,
      ),
    );
  }
}
