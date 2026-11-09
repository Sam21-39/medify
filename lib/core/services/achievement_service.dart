import 'dart:developer' as developer;
import '../../domain/entities/achievement.dart';
import '../../domain/entities/medicine_log.dart';
import '../../domain/entities/statistics.dart';
import '../../domain/repositories/medicine_log_repository.dart';
import '../../data/datasources/objectbox_service.dart';
import '../../data/models/achievement_model.dart';
import '../../objectbox.g.dart'; // ObjectBox generated code
import 'notification_service.dart';
import 'preferences_service.dart';

/// Service for managing achievements and gamification
class AchievementService {
  final ObjectBoxService _objectBoxService;
  final MedicineLogRepository _medicineLogRepository;
  final NotificationService _notificationService;
  final PreferencesService _preferencesService;

  AchievementService(
    this._objectBoxService,
    this._medicineLogRepository,
    this._notificationService,
    this._preferencesService,
  );

  /// Get achievement box
  dynamic get _achievementBox =>
      _objectBoxService.store.box<AchievementModel>();

  /// Check and award achievements based on current statistics
  Future<List<Achievement>> checkAndAwardAchievements() async {
    try {
      developer.log(
        'Checking for new achievements',
        name: 'AchievementService',
      );

      final newlyUnlocked = <Achievement>[];

      // Get current statistics
      final stats = await _medicineLogRepository.getStatistics();
      final currentStreak = await _medicineLogRepository.getCurrentStreak();
      final allLogs = await _medicineLogRepository.getAllLogs();

      // Check all achievement types
      for (final type in AchievementType.values) {
        final achievement = await _checkAchievement(
          type,
          stats,
          currentStreak,
          allLogs,
        );
        if (achievement != null && achievement.isUnlocked) {
          // Check if already unlocked
          final existing = await getAchievement(type);
          if (existing == null || !existing.isUnlocked) {
            // New unlock!
            await _saveAchievement(achievement);
            newlyUnlocked.add(achievement);
            developer.log(
              'Achievement unlocked: ${type.title}',
              name: 'AchievementService',
            );
          }
        } else if (achievement != null) {
          // Update progress
          await _saveAchievement(achievement);
        }
      }

      // Show notifications for newly unlocked achievements
      for (final achievement in newlyUnlocked) {
        await _showAchievementNotification(achievement);
      }

      return newlyUnlocked;
    } catch (e) {
      developer.log(
        'Error checking achievements: $e',
        name: 'AchievementService',
        error: e,
      );
      return [];
    }
  }

  /// Check individual achievement
  Future<Achievement?> _checkAchievement(
    AchievementType type,
    MedicineStatistics stats,
    int currentStreak,
    List<MedicineLog> allLogs,
  ) async {
    int progress = 0;
    bool isUnlocked = false;

    switch (type) {
      // Streak achievements
      case AchievementType.firstWeek:
      case AchievementType.twoWeeks:
      case AchievementType.oneMonth:
      case AchievementType.threeMonths:
      case AchievementType.sixMonths:
      case AchievementType.oneYear:
        progress = currentStreak;
        isUnlocked = currentStreak >= type.targetValue;
        break;

      // Perfect adherence
      case AchievementType.perfectWeek:
      case AchievementType.perfectMonth:
        final days = type == AchievementType.perfectWeek ? 7 : 30;
        final recentStats = await _medicineLogRepository.getStatisticsForDays(
          days,
        );
        progress = recentStats.adherenceRate == 100.0 ? days : 0;
        isUnlocked = progress >= type.targetValue;
        break;

      // Total doses
      case AchievementType.century:
      case AchievementType.fiveHundred:
      case AchievementType.thousand:
        progress = stats.takenDoses;
        isUnlocked = progress >= type.targetValue;
        break;

      // Early bird
      case AchievementType.earlyBird:
      case AchievementType.superEarly:
        progress = _countEarlyDoses(allLogs);
        isUnlocked = progress >= type.targetValue;
        break;

      // Never miss
      case AchievementType.neverMiss:
        final recentStats = await _medicineLogRepository.getStatisticsForDays(
          30,
        );
        progress = recentStats.missedDoses == 0 ? 30 : 0;
        isUnlocked = progress >= type.targetValue;
        break;

      // Organized (app usage duration)
      case AchievementType.organized:
        final firstLaunchDate = _preferencesService.firstLaunchDate;
        if (firstLaunchDate != null) {
          final daysSinceInstall = DateTime.now()
              .difference(firstLaunchDate)
              .inDays;
          progress = daysSinceInstall;
          isUnlocked = progress >= type.targetValue;
        }
        break;

      // First dose
      case AchievementType.firstDose:
        progress = allLogs
            .where((log) => log.status == MedicineLogStatus.taken)
            .length;
        isUnlocked = progress >= 1;
        break;

      // Weekend warrior
      case AchievementType.weekendWarrior:
        progress = await _countPerfectWeekends();
        isUnlocked = progress >= type.targetValue;
        break;

      // Time of day achievements
      case AchievementType.nightOwl:
      case AchievementType.morningPerson:
        progress = _countTimeOfDayDoses(allLogs, type);
        isUnlocked = progress >= type.targetValue;
        break;
    }

    return Achievement(
      type: type,
      unlockedAt: isUnlocked ? DateTime.now() : DateTime.now(),
      progress: progress,
      isUnlocked: isUnlocked,
    );
  }

  /// Count early doses (taken before scheduled time)
  int _countEarlyDoses(List<MedicineLog> logs) {
    return logs.where((log) {
      if (log.status != MedicineLogStatus.taken || log.takenTime == null) {
        return false;
      }
      return log.takenTime!.isBefore(log.scheduledTime);
    }).length;
  }

  /// Count perfect weekends in last 30 days
  Future<int> _countPerfectWeekends() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    int perfectWeekends = 0;

    for (int i = 0; i < 30; i++) {
      final date = thirtyDaysAgo.add(Duration(days: i));
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        final logs = await _medicineLogRepository.getLogsByDate(date);
        if (logs.isNotEmpty) {
          final takenCount = logs
              .where((log) => log.status == MedicineLogStatus.taken)
              .length;
          if (takenCount == logs.length) {
            perfectWeekends++;
          }
        }
      }
    }

    return perfectWeekends;
  }

  /// Count time-of-day specific doses
  int _countTimeOfDayDoses(List<MedicineLog> logs, AchievementType type) {
    return logs.where((log) {
      if (log.status != MedicineLogStatus.taken) return false;

      final hour = log.scheduledTime.hour;

      if (type == AchievementType.morningPerson) {
        // Morning: 5 AM - 11 AM
        return hour >= 5 && hour < 12;
      } else if (type == AchievementType.nightOwl) {
        // Night: 8 PM - 11 PM
        return hour >= 20 && hour < 24;
      }

      return false;
    }).length;
  }

  /// Save achievement to database
  Future<void> _saveAchievement(Achievement achievement) async {
    try {
      final model = AchievementModel.fromEntity(achievement);

      // Check if achievement already exists
      final existing = _achievementBox
          .query(
            AchievementModel_.achievementType.equals(achievement.type.index),
          )
          .build()
          .findFirst();

      if (existing != null) {
        model.id = existing.id;
      }

      _achievementBox.put(model);

      developer.log(
        'Saved achievement: ${achievement.type.title} (progress: ${achievement.progress}/${achievement.type.targetValue})',
        name: 'AchievementService',
      );
    } catch (e) {
      developer.log(
        'Error saving achievement: $e',
        name: 'AchievementService',
        error: e,
      );
    }
  }

  /// Get specific achievement
  Future<Achievement?> getAchievement(AchievementType type) async {
    try {
      final model = _achievementBox
          .query(AchievementModel_.achievementType.equals(type.index))
          .build()
          .findFirst();

      return model?.toEntity();
    } catch (e) {
      developer.log(
        'Error getting achievement: $e',
        name: 'AchievementService',
        error: e,
      );
      return null;
    }
  }

  /// Get all achievements (unlocked and locked)
  Future<List<Achievement>> getAllAchievements() async {
    try {
      final allAchievements = <Achievement>[];

      for (final type in AchievementType.values) {
        final existing = await getAchievement(type);
        if (existing != null) {
          allAchievements.add(existing);
        } else {
          // Create locked achievement with 0 progress
          allAchievements.add(
            Achievement(
              type: type,
              unlockedAt: DateTime.now(),
              progress: 0,
              isUnlocked: false,
            ),
          );
        }
      }

      return allAchievements;
    } catch (e) {
      developer.log(
        'Error getting all achievements: $e',
        name: 'AchievementService',
        error: e,
      );
      return [];
    }
  }

  /// Get unlocked achievements only
  Future<List<Achievement>> getUnlockedAchievements() async {
    try {
      final allAchievements = await getAllAchievements();
      return allAchievements.where((a) => a.isUnlocked).toList();
    } catch (e) {
      developer.log(
        'Error getting unlocked achievements: $e',
        name: 'AchievementService',
        error: e,
      );
      return [];
    }
  }

  /// Get achievement statistics
  Future<AchievementStats> getAchievementStats() async {
    try {
      final allAchievements = await getAllAchievements();
      final unlocked = allAchievements.where((a) => a.isUnlocked).toList();

      // Count by rarity
      final common = unlocked
          .where((a) => a.type.rarity == AchievementRarity.common)
          .length;
      final uncommon = unlocked
          .where((a) => a.type.rarity == AchievementRarity.uncommon)
          .length;
      final rare = unlocked
          .where((a) => a.type.rarity == AchievementRarity.rare)
          .length;
      final epic = unlocked
          .where((a) => a.type.rarity == AchievementRarity.epic)
          .length;
      final legendary = unlocked
          .where((a) => a.type.rarity == AchievementRarity.legendary)
          .length;

      // Get most recent
      final recent = unlocked
        ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
      final recentUnlocked = recent.take(5).toList();

      return AchievementStats(
        totalAchievements: allAchievements.length,
        unlockedAchievements: unlocked.length,
        commonUnlocked: common,
        uncommonUnlocked: uncommon,
        rareUnlocked: rare,
        epicUnlocked: epic,
        legendaryUnlocked: legendary,
        lastUnlocked: unlocked.isNotEmpty ? unlocked.first.unlockedAt : null,
        recentUnlocked: recentUnlocked,
      );
    } catch (e) {
      developer.log(
        'Error getting achievement stats: $e',
        name: 'AchievementService',
        error: e,
      );
      return const AchievementStats(
        totalAchievements: 0,
        unlockedAchievements: 0,
      );
    }
  }

  /// Show achievement unlock notification
  Future<void> _showAchievementNotification(Achievement achievement) async {
    try {
      await _notificationService.showImmediateNotification(
        title: '🏆 Achievement Unlocked!',
        body:
            '${achievement.type.emoji} ${achievement.type.title}\n${achievement.type.description}',
        payload: 'achievement_${achievement.type.index}',
      );
    } catch (e) {
      developer.log(
        'Error showing achievement notification: $e',
        name: 'AchievementService',
        error: e,
      );
    }
  }

  /// Get achievements by category
  Future<Map<AchievementCategory, List<Achievement>>>
  getAchievementsByCategory() async {
    try {
      final allAchievements = await getAllAchievements();
      final grouped = <AchievementCategory, List<Achievement>>{};

      for (final category in AchievementCategory.values) {
        grouped[category] = allAchievements
            .where((a) => a.type.category == category)
            .toList();
      }

      return grouped;
    } catch (e) {
      developer.log(
        'Error grouping achievements: $e',
        name: 'AchievementService',
        error: e,
      );
      return {};
    }
  }
}
