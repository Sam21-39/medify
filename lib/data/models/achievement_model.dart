import 'package:objectbox/objectbox.dart';
import '../../domain/entities/achievement.dart';

/// ObjectBox model for Achievement entity
@Entity()
class AchievementModel {
  @Id()
  int id;

  int achievementType; // Store as int (enum index)
  
  @Property(type: PropertyType.date)
  DateTime unlockedAt;
  
  int progress;
  bool isUnlocked;

  AchievementModel({
    this.id = 0,
    required this.achievementType,
    required this.unlockedAt,
    this.progress = 0,
    this.isUnlocked = false,
  });

  /// Convert Achievement entity to AchievementModel
  factory AchievementModel.fromEntity(Achievement achievement) {
    return AchievementModel(
      id: achievement.id ?? 0,
      achievementType: achievement.type.index,
      unlockedAt: achievement.unlockedAt,
      progress: achievement.progress,
      isUnlocked: achievement.isUnlocked,
    );
  }

  /// Convert AchievementModel to Achievement entity
  Achievement toEntity() {
    return Achievement(
      id: id == 0 ? null : id,
      type: AchievementType.values[achievementType],
      unlockedAt: unlockedAt,
      progress: progress,
      isUnlocked: isUnlocked,
    );
  }
}

