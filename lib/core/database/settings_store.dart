import 'package:sqflite/sqflite.dart';

import 'enums.dart';

/// Typed key/value store over the `settings` table.
///
/// A read whose stored `value_type` differs from the requested type returns
/// the default. It does not throw.
class SettingsStore {
  SettingsStore(this._db);

  final Database _db;

  Future<bool> getBool(String key, {required bool defaultValue}) async {
    final raw = await _read(key, SettingType.bool);
    return raw == null ? defaultValue : raw == 'true';
  }

  Future<void> setBool(String key, bool value) =>
      _write(key, value ? 'true' : 'false', SettingType.bool);

  Future<int> getInt(String key, {required int defaultValue}) async {
    final raw = await _read(key, SettingType.int);
    return raw == null ? defaultValue : int.tryParse(raw) ?? defaultValue;
  }

  Future<void> setInt(String key, int value) =>
      _write(key, value.toString(), SettingType.int);

  Future<String> getString(String key, {required String defaultValue}) async =>
      await _read(key, SettingType.string) ?? defaultValue;

  Future<void> setString(String key, String value) =>
      _write(key, value, SettingType.string);

  Future<T> getEnum<T extends Enum>(
    String key,
    List<T> values, {
    required T defaultValue,
  }) async {
    final raw = await _read(key, SettingType.enumName);
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return defaultValue;
  }

  Future<void> setEnum<T extends Enum>(String key, T value) =>
      _write(key, value.name, SettingType.enumName);

  /// Returns the stored text only when `value_type` matches [type].
  Future<String?> _read(String key, SettingType type) async {
    final rows = await _db.query(
      'settings',
      columns: ['value', 'value_type'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    if (rows.first['value_type'] != type.name) return null;
    return rows.first['value']! as String;
  }

  Future<void> _write(String key, String value, SettingType type) async {
    await _db.rawInsert(
      'INSERT INTO settings (key, value, value_type) VALUES (?, ?, ?) '
      'ON CONFLICT(key) DO UPDATE SET '
      'value = excluded.value, value_type = excluded.value_type',
      [key, value, type.name],
    );
  }
}
