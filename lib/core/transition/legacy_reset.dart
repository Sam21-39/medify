import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' show getDatabasesPath;

import 'package:medify/core/database/medify_database.dart';
import 'package:medify/core/platform/medify_paths.dart';
import 'package:medify/core/platform/medify_prefs_channel.dart';

/// Name of the 1.x ObjectBox store directory.
const legacyStoreDirName = 'medify-db';

/// File name of the 2.0 sqflite database.
const v2DatabaseFileName = 'medify_v2.db';

Future<void> _cancelAllReminders() =>
    FlutterLocalNotificationsPlugin().cancelAll();

/// Detects a 1.x install and resets it for 2.0. Every step is idempotent.
class LegacyReset {
  LegacyReset({
    required this.documentsDir,
    required this.v2DatabasePath,
    this.cancelReminders = _cancelAllReminders,
  });

  final String documentsDir;
  final String v2DatabasePath;
  final Future<void> Function() cancelReminders;

  /// Both 1.x layouts: the documents dir may be `filesDir` or
  /// `filesDir/app_flutter` on Android. Probed on device, not assumed.
  List<String> get legacyCandidates => [
    p.join(documentsDir, legacyStoreDirName),
    p.join(documentsDir, 'app_flutter', legacyStoreDirName),
  ];

  Future<List<String>> _existingLegacy() async {
    final found = <String>[];
    for (final path in legacyCandidates) {
      if (await FileSystemEntity.isDirectory(path)) found.add(path);
    }
    return found;
  }

  /// Existing user: a legacy store is present and the v2 database is absent.
  Future<bool> needsReset() async {
    if (await File(v2DatabasePath).exists()) return false;
    return (await _existingLegacy()).isNotEmpty;
  }

  /// Cancel reminders, clear legacy prefs, delete legacy store dirs, create v2.
  Future<void> run() async {
    await cancelReminders();
    await MedifyPrefsChannel.clearLegacyPrefs();
    for (final path in await _existingLegacy()) {
      await Directory(path).delete(recursive: true);
    }
    final db = await MedifyDatabase.open(path: v2DatabasePath);
    await db.close();
  }
}

/// [LegacyReset] wired to the device paths.
Future<LegacyReset> deviceLegacyReset() async {
  final documents = await MedifyPaths.documentsDirectory();
  final databases = await getDatabasesPath();
  return LegacyReset(
    documentsDir: documents,
    v2DatabasePath: p.join(databases, v2DatabaseFileName),
  );
}
