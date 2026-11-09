import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app preferences and settings
class PreferencesService {
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyFirstLaunchDate = 'first_launch_date';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keySnoozeDuration = 'snooze_duration';
  static const String _keyLastLogGeneration = 'last_log_generation_date';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  /// Initialize preferences service
  static Future<PreferencesService> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  // First Launch
  bool get isFirstLaunch => _prefs.getBool(_keyFirstLaunch) ?? true;

  Future<bool> setFirstLaunchComplete() async {
    // Set first launch date if not already set
    if (firstLaunchDate == null) {
      await _prefs.setString(_keyFirstLaunchDate, DateTime.now().toIso8601String());
    }
    return await _prefs.setBool(_keyFirstLaunch, false);
  }

  // First Launch Date
  DateTime? get firstLaunchDate {
    final dateString = _prefs.getString(_keyFirstLaunchDate);
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Theme Mode
  ThemeMode get themeMode {
    final String? themeModeString = _prefs.getString(_keyThemeMode);
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<bool> setThemeMode(ThemeMode mode) async {
    String themeModeString;
    switch (mode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      case ThemeMode.system:
        themeModeString = 'system';
    }
    return await _prefs.setString(_keyThemeMode, themeModeString);
  }

  // Notifications
  bool get notificationsEnabled =>
      _prefs.getBool(_keyNotificationsEnabled) ?? true;

  Future<bool> setNotificationsEnabled(bool enabled) async {
    return await _prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  // Snooze Duration (in minutes)
  int get snoozeDuration => _prefs.getInt(_keySnoozeDuration) ?? 15;

  Future<bool> setSnoozeDuration(int minutes) async {
    return await _prefs.setInt(_keySnoozeDuration, minutes);
  }

  // Last Log Generation Date
  String? get lastLogGenerationDate => _prefs.getString(_keyLastLogGeneration);

  Future<bool> setLastLogGenerationDate(String date) async {
    return await _prefs.setString(_keyLastLogGeneration, date);
  }

  // Generic getters and setters
  Future<int?> getInt(String key) async {
    return _prefs.getInt(key);
  }

  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }

  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  /// Clear all preferences (for testing/reset)
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}
