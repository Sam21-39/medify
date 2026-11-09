import 'dart:developer' as developer;
import '../../domain/repositories/medicine_repository.dart';
import '../../domain/repositories/medicine_log_repository.dart';
import '../utils/log_generator.dart';
import 'preferences_service.dart';

/// Service to manage daily log generation for repeating reminders
class DailyLogService {
  final PreferencesService _preferencesService;
  final MedicineRepository _medicineRepository;
  final MedicineLogRepository _medicineLogRepository;

  DailyLogService(
    this._preferencesService,
    this._medicineRepository,
    this._medicineLogRepository,
  );

  /// Check if logs need to be generated for today and generate them if needed
  Future<void> generateDailyLogsIfNeeded() async {
    try {
      final today = _getTodayDateString();
      final lastGeneration = _getLastLogGenerationDate();

      developer.log(
        'Checking daily logs - Today: $today, Last: $lastGeneration',
        name: 'DailyLogService',
      );

      // If logs haven't been generated today, generate them
      if (lastGeneration != today) {
        await _generateLogsForToday();
        await _saveLastLogGenerationDate(today);
        developer.log(
          'Daily logs generated for $today',
          name: 'DailyLogService',
        );
      } else {
        developer.log(
          'Daily logs already generated for today',
          name: 'DailyLogService',
        );
      }
    } catch (e) {
      developer.log(
        'Error in generateDailyLogsIfNeeded: $e',
        name: 'DailyLogService',
        error: e,
      );
    }
  }

  /// Generate logs for all active medicines for today
  Future<void> _generateLogsForToday() async {
    try {
      // Get all active medicines
      final activeMedicines = await _medicineRepository.getActiveMedicines();

      if (activeMedicines.isEmpty) {
        developer.log(
          'No active medicines to generate logs for',
          name: 'DailyLogService',
        );
        return;
      }

      developer.log(
        'Generating logs for ${activeMedicines.length} active medicines',
        name: 'DailyLogService',
      );

      // Get existing logs for today to avoid duplicates
      final existingLogs = await _medicineLogRepository.getTodayLogs();
      final existingLogKeys = existingLogs.map((log) {
        final hour = log.scheduledTime.hour;
        final minute = log.scheduledTime.minute;
        return '${log.medicineId}_${hour}_$minute';
      }).toSet();

      int generatedCount = 0;

      // Generate logs for each medicine
      for (final medicine in activeMedicines) {
        final newLogs = LogGenerator.generateTodayLogs(medicine);

        // Only add logs that don't already exist
        for (final log in newLogs) {
          final hour = log.scheduledTime.hour;
          final minute = log.scheduledTime.minute;
          final logKey = '${log.medicineId}_${hour}_$minute';

          if (!existingLogKeys.contains(logKey)) {
            await _medicineLogRepository.addLog(log);
            generatedCount++;
          }
        }
      }

      developer.log(
        'Generated $generatedCount new logs for today',
        name: 'DailyLogService',
      );
    } catch (e) {
      developer.log(
        'Error generating logs for today: $e',
        name: 'DailyLogService',
        error: e,
      );
      rethrow;
    }
  }

  /// Get the last date logs were generated
  String? _getLastLogGenerationDate() {
    try {
      return _preferencesService.lastLogGenerationDate;
    } catch (e) {
      developer.log(
        'Error getting last log generation date: $e',
        name: 'DailyLogService',
        error: e,
      );
      return null;
    }
  }

  /// Save the current date as last log generation date
  Future<void> _saveLastLogGenerationDate(String date) async {
    try {
      await _preferencesService.setLastLogGenerationDate(date);
      developer.log(
        'Saved last generation date: $date',
        name: 'DailyLogService',
      );
    } catch (e) {
      developer.log(
        'Error saving last log generation date: $e',
        name: 'DailyLogService',
        error: e,
      );
    }
  }

  /// Get today's date as a string (YYYY-MM-DD)
  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Force regenerate logs for today (useful for testing or manual refresh)
  Future<void> forceRegenerateToday() async {
    try {
      developer.log(
        'Force regenerating logs for today',
        name: 'DailyLogService',
      );

      // Clear today's logs
      final todayLogs = await _medicineLogRepository.getTodayLogs();
      for (final log in todayLogs) {
        if (log.id != null) {
          await _medicineLogRepository.deleteLog(log.id!);
        }
      }

      // Generate fresh logs
      await _generateLogsForToday();
      await _saveLastLogGenerationDate(_getTodayDateString());

      developer.log('Force regeneration complete', name: 'DailyLogService');
    } catch (e) {
      developer.log(
        'Error in force regeneration: $e',
        name: 'DailyLogService',
        error: e,
      );
      rethrow;
    }
  }
}
