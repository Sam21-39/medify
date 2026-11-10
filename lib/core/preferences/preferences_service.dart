import 'package:flutter/material.dart';
import 'package:medify/core/database/settings_store.dart';

/// Service for managing app preferences and settings.
///
/// Backed by [SettingsStore]. Known keys are loaded into an in-memory cache at
/// [initialize], so the getters stay synchronous. Setters update the cache and
/// the store.
class PreferencesService {
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyFirstLaunchDate = 'first_launch_date';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keySnoozeDuration = 'snooze_duration';
  static const String _keyLastLogGeneration = 'last_log_generation_date';
  static const String _keyRoleChosen = 'role_chosen';
  static const String _keySpeakReminder = 'speak_reminder';
  static const String _keyActingPatient = 'acting_patient_id';
  static const String _keyActiveProfileId = 'active_profile_id';

  final SettingsStore _store;
  final Map<String, Object> _cache;

  PreferencesService._(this._store, this._cache);

  /// Loads all known keys. Missing keys take the getter defaults. Ids and
  /// dates use 0 and '' as "unset".
  static Future<PreferencesService> initialize(SettingsStore store) async {
    final cache = <String, Object>{
      _keyFirstLaunch: await store.getBool(_keyFirstLaunch, defaultValue: true),
      _keyRoleChosen: await store.getBool(_keyRoleChosen, defaultValue: false),
      _keySpeakReminder: await store.getBool(
        _keySpeakReminder,
        defaultValue: true,
      ),
      _keyNotificationsEnabled: await store.getBool(
        _keyNotificationsEnabled,
        defaultValue: true,
      ),
      _keySnoozeDuration: await store.getInt(
        _keySnoozeDuration,
        defaultValue: 15,
      ),
      _keyActingPatient: await store.getInt(_keyActingPatient, defaultValue: 0),
      _keyActiveProfileId: await store.getInt(
        _keyActiveProfileId,
        defaultValue: 0,
      ),
      _keyFirstLaunchDate: await store.getString(
        _keyFirstLaunchDate,
        defaultValue: '',
      ),
      _keyThemeMode: await store.getString(
        _keyThemeMode,
        defaultValue: 'system',
      ),
      _keyLastLogGeneration: await store.getString(
        _keyLastLogGeneration,
        defaultValue: '',
      ),
    };
    return PreferencesService._(store, cache);
  }

  Future<bool> _setBool(String key, bool value) async {
    await _store.setBool(key, value);
    _cache[key] = value;
    return true;
  }

  Future<bool> _setInt(String key, int value) async {
    await _store.setInt(key, value);
    _cache[key] = value;
    return true;
  }

  Future<bool> _setString(String key, String value) async {
    await _store.setString(key, value);
    _cache[key] = value;
    return true;
  }

  // First Launch
  bool get isFirstLaunch => _cache[_keyFirstLaunch] as bool;

  bool get roleChosen => _cache[_keyRoleChosen] as bool;

  Future<void> setRoleChosen() => _setBool(_keyRoleChosen, true);

  bool get speakReminder => _cache[_keySpeakReminder] as bool;

  Future<void> setSpeakReminder(bool value) =>
      _setBool(_keySpeakReminder, value);

  int? get actingPatientId {
    final id = _cache[_keyActingPatient] as int;
    return id == 0 ? null : id;
  }

  Future<void> setActingPatientId(int id) => _setInt(_keyActingPatient, id);

  Future<bool> setFirstLaunchComplete() async {
    // Set first launch date if not already set
    if (firstLaunchDate == null) {
      await _setString(_keyFirstLaunchDate, DateTime.now().toIso8601String());
    }
    return _setBool(_keyFirstLaunch, false);
  }

  // First Launch Date
  DateTime? get firstLaunchDate {
    final dateString = _cache[_keyFirstLaunchDate] as String;
    if (dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Theme Mode
  ThemeMode get themeMode {
    switch (_cache[_keyThemeMode] as String) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<bool> setThemeMode(ThemeMode mode) {
    final String themeModeString;
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
    return _setString(_keyThemeMode, themeModeString);
  }

  // Notifications
  bool get notificationsEnabled => _cache[_keyNotificationsEnabled] as bool;

  Future<bool> setNotificationsEnabled(bool enabled) =>
      _setBool(_keyNotificationsEnabled, enabled);

  // Snooze Duration (in minutes)
  int get snoozeDuration => _cache[_keySnoozeDuration] as int;

  Future<bool> setSnoozeDuration(int minutes) =>
      _setInt(_keySnoozeDuration, minutes);

  // Last Log Generation Date
  String? get lastLogGenerationDate {
    final date = _cache[_keyLastLogGeneration] as String;
    return date.isEmpty ? null : date;
  }

  Future<bool> setLastLogGenerationDate(String date) =>
      _setString(_keyLastLogGeneration, date);

  // Generic getters and setters. Keys outside the known set are read from the
  // store on a cache miss.
  Future<int?> getInt(String key) async {
    final cached = _cache[key];
    final value = cached is int
        ? cached
        : await _store.getInt(key, defaultValue: 0);
    return value == 0 ? null : value;
  }

  Future<bool> setInt(String key, int value) => _setInt(key, value);

  Future<String?> getString(String key) async {
    final cached = _cache[key];
    final value = cached is String
        ? cached
        : await _store.getString(key, defaultValue: '');
    return value.isEmpty ? null : value;
  }

  Future<bool> setString(String key, String value) => _setString(key, value);
}
