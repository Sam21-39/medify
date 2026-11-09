import 'dart:developer' as developer;

import 'package:medify/core/preferences/preferences_service.dart';
import 'package:medify/features/schedule/data/sqflite/occurrence_sqflite_generator.dart';
import 'package:timezone/timezone.dart' as tz;

/// Generates occurrences for the next [_windowDays] local days.
class DailyLogService {
  DailyLogService(this._preferencesService, this._occurrenceGenerator);

  static const _windowDays = 7;

  final PreferencesService _preferencesService;
  final OccurrenceSqfliteGenerator _occurrenceGenerator;

  /// Runs at startup and on resume. Generates once per local day. The
  /// generator is idempotent, so a retry after a failure is safe.
  Future<void> generateDailyLogsIfNeeded() async {
    try {
      final today = _getTodayDateString();
      if (_getLastLogGenerationDate() == today) return;

      final now = DateTime.now();
      final from = DateTime(now.year, now.month, now.day);
      final to = DateTime(from.year, from.month, from.day + _windowDays);
      final inserted = await _occurrenceGenerator.generate(
        fromDate: from,
        toDate: to,
        location: tz.local,
        nowUtc: now.toUtc(),
      );
      await _saveLastLogGenerationDate(today);
      developer.log(
        'Generated $inserted occurrences for $today + $_windowDays days',
        name: 'DailyLogService',
      );
    } catch (e) {
      developer.log(
        'Error in generateDailyLogsIfNeeded: $e',
        name: 'DailyLogService',
        error: e,
      );
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
}
