import 'package:equatable/equatable.dart';

/// Enum for different achievement types
enum AchievementType {
  // Streak-based achievements
  firstWeek('First Week Strong', 'Complete 7 consecutive days', 7, '🔥'),
  twoWeeks('Two Week Warrior', 'Complete 14 consecutive days', 14, '💪'),
  oneMonth('Medicine Master', 'Complete 30 consecutive days', 30, '🏆'),
  threeMonths('Consistency King', 'Complete 90 consecutive days', 90, '👑'),
  sixMonths('Dedicated', 'Complete 180 consecutive days', 180, '💎'),
  oneYear('Legend', 'Complete 365 consecutive days', 365, '🌟'),

  // Perfect adherence achievements
  perfectWeek('Perfect Week', '7 days with 100% adherence', 7, '✨'),
  perfectMonth('Perfect Month', '30 days with 100% adherence', 30, '🎯'),
  
  // Usage milestones
  century('Century Club', 'Take 100 doses', 100, '💯'),
  fiveHundred('Half Thousand', 'Take 500 doses', 500, '🎖️'),
  thousand('Millennium', 'Take 1000 doses', 1000, '🏅'),

  // Early bird achievements
  earlyBird('Early Bird', 'Take medicine before scheduled time 10 times', 10, '🐦'),
  superEarly('Super Early', 'Take medicine before scheduled time 50 times', 50, '🦅'),

  // Consistency achievements
  neverMiss('Never Miss', 'Complete 30 days without missing a dose', 30, '🎪'),
  organized('Organized', 'Use app for 6 months', 180, '📋'),
  
  // Special achievements
  firstDose('Getting Started', 'Take your first dose', 1, '🎉'),
  weekendWarrior('Weekend Warrior', 'Don\'t miss any weekend doses for a month', 8, '🏖️'),
  nightOwl('Night Owl', 'Take 50 nighttime medicines', 50, '🦉'),
  morningPerson('Morning Person', 'Take 50 morning medicines', 50, '☀️');

  final String title;
  final String description;
  final int targetValue;
  final String emoji;

  const AchievementType(
    this.title,
    this.description,
    this.targetValue,
    this.emoji,
  );

  /// Get achievement category
  AchievementCategory get category {
    switch (this) {
      case AchievementType.firstWeek:
      case AchievementType.twoWeeks:
      case AchievementType.oneMonth:
      case AchievementType.threeMonths:
      case AchievementType.sixMonths:
      case AchievementType.oneYear:
        return AchievementCategory.streak;
      
      case AchievementType.perfectWeek:
      case AchievementType.perfectMonth:
      case AchievementType.neverMiss:
        return AchievementCategory.perfect;
      
      case AchievementType.century:
      case AchievementType.fiveHundred:
      case AchievementType.thousand:
        return AchievementCategory.milestone;
      
      case AchievementType.earlyBird:
      case AchievementType.superEarly:
      case AchievementType.nightOwl:
      case AchievementType.morningPerson:
        return AchievementCategory.timeOfDay;
      
      case AchievementType.firstDose:
      case AchievementType.organized:
      case AchievementType.weekendWarrior:
        return AchievementCategory.special;
    }
  }

  /// Get rarity level
  AchievementRarity get rarity {
    if (targetValue >= 365) return AchievementRarity.legendary;
    if (targetValue >= 180) return AchievementRarity.epic;
    if (targetValue >= 90) return AchievementRarity.rare;
    if (targetValue >= 30) return AchievementRarity.uncommon;
    return AchievementRarity.common;
  }
}

/// Achievement categories
enum AchievementCategory {
  streak('Streak Master', 'Consistency is key'),
  perfect('Perfectionist', 'Never miss a beat'),
  milestone('Milestone Maker', 'Big numbers'),
  timeOfDay('Time Master', 'Perfect timing'),
  special('Special', 'Unique achievements');

  final String title;
  final String subtitle;

  const AchievementCategory(this.title, this.subtitle);
}

/// Achievement rarity levels
enum AchievementRarity {
  common('Common', 0xFF9E9E9E),
  uncommon('Uncommon', 0xFF4CAF50),
  rare('Rare', 0xFF2196F3),
  epic('Epic', 0xFF9C27B0),
  legendary('Legendary', 0xFFFFD700);

  final String label;
  final int colorValue;

  const AchievementRarity(this.label, this.colorValue);
}

/// Achievement entity representing an unlocked achievement
class Achievement extends Equatable {
  final int? id;
  final AchievementType type;
  final DateTime unlockedAt;
  final int progress; // Current progress towards achievement
  final bool isUnlocked;

  const Achievement({
    this.id,
    required this.type,
    required this.unlockedAt,
    this.progress = 0,
    this.isUnlocked = false,
  });

  /// Create a copy with updated fields
  Achievement copyWith({
    int? id,
    AchievementType? type,
    DateTime? unlockedAt,
    int? progress,
    bool? isUnlocked,
  }) {
    return Achievement(
      id: id ?? this.id,
      type: type ?? this.type,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  /// Get progress percentage
  double get progressPercentage {
    if (isUnlocked) return 100.0;
    return (progress / type.targetValue * 100).clamp(0.0, 100.0);
  }

  /// Check if achievement is close to being unlocked (80%+)
  bool get isAlmostUnlocked {
    return !isUnlocked && progressPercentage >= 80.0;
  }

  @override
  List<Object?> get props => [
        id,
        type,
        unlockedAt,
        progress,
        isUnlocked,
      ];
}

/// User achievement statistics summary
class AchievementStats extends Equatable {
  final int totalAchievements;
  final int unlockedAchievements;
  final int commonUnlocked;
  final int uncommonUnlocked;
  final int rareUnlocked;
  final int epicUnlocked;
  final int legendaryUnlocked;
  final DateTime? lastUnlocked;
  final List<Achievement> recentUnlocked;

  const AchievementStats({
    required this.totalAchievements,
    required this.unlockedAchievements,
    this.commonUnlocked = 0,
    this.uncommonUnlocked = 0,
    this.rareUnlocked = 0,
    this.epicUnlocked = 0,
    this.legendaryUnlocked = 0,
    this.lastUnlocked,
    this.recentUnlocked = const [],
  });

  /// Get completion percentage
  double get completionPercentage {
    if (totalAchievements == 0) return 0.0;
    return (unlockedAchievements / totalAchievements * 100).clamp(0.0, 100.0);
  }

  @override
  List<Object?> get props => [
        totalAchievements,
        unlockedAchievements,
        commonUnlocked,
        uncommonUnlocked,
        rareUnlocked,
        epicUnlocked,
        legendaryUnlocked,
        lastUnlocked,
        recentUnlocked,
      ];
}

