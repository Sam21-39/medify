import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/database/medify_database.dart';
import 'package:medify/core/database/settings_store.dart';
import 'package:medify/core/preferences/preferences_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late SettingsStore store;

  setUp(() async {
    final db = await MedifyDatabase.open(path: inMemoryDatabasePath);
    store = SettingsStore(db);
  });

  test('defaults when nothing is stored', () async {
    final prefs = await PreferencesService.initialize(store);
    expect(prefs.isFirstLaunch, isTrue);
    expect(prefs.roleChosen, isFalse);
    expect(prefs.speakReminder, isTrue);
    expect(prefs.notificationsEnabled, isTrue);
    expect(prefs.snoozeDuration, 15);
    expect(prefs.actingPatientId, isNull);
    expect(prefs.themeMode, ThemeMode.system);
    expect(prefs.firstLaunchDate, isNull);
    expect(prefs.lastLogGenerationDate, isNull);
  });

  test('round trip per key type survives re-initialize', () async {
    final prefs = await PreferencesService.initialize(store);
    await prefs.setRoleChosen();
    await prefs.setSpeakReminder(false);
    await prefs.setNotificationsEnabled(false);
    await prefs.setSnoozeDuration(30);
    await prefs.setActingPatientId(7);
    await prefs.setThemeMode(ThemeMode.dark);
    await prefs.setLastLogGenerationDate('2026-11-10');
    await prefs.setFirstLaunchComplete();

    final reloaded = await PreferencesService.initialize(store);
    expect(reloaded.roleChosen, isTrue);
    expect(reloaded.speakReminder, isFalse);
    expect(reloaded.notificationsEnabled, isFalse);
    expect(reloaded.snoozeDuration, 30);
    expect(reloaded.actingPatientId, 7);
    expect(reloaded.themeMode, ThemeMode.dark);
    expect(reloaded.lastLogGenerationDate, '2026-11-10');
    expect(reloaded.isFirstLaunch, isFalse);
    expect(reloaded.firstLaunchDate, isNotNull);
  });

  test('cache reflects writes without re-initialize', () async {
    final prefs = await PreferencesService.initialize(store);
    await prefs.setSnoozeDuration(5);
    expect(prefs.snoozeDuration, 5);
    await prefs.setActingPatientId(3);
    expect(prefs.actingPatientId, 3);
    await prefs.setNotificationsEnabled(false);
    expect(prefs.notificationsEnabled, isFalse);
  });

  test('generic int and string keys round trip', () async {
    final prefs = await PreferencesService.initialize(store);
    await prefs.setInt('custom_int', 42);
    await prefs.setString('custom_text', 'hi');
    expect(await prefs.getInt('custom_int'), 42);
    expect(await prefs.getString('custom_text'), 'hi');
    expect(await prefs.getInt('missing'), isNull);
  });
}
