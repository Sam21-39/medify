import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../encryption/database_key_provisioner.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Drift is the source of truth for all reads — Firestore is sync/backup
/// only, never read directly by UI (Section 1.2). The underlying SQLite
/// file is opened through `package:sqlite3`'s sqlite3mc build (see the
/// `hooks.user_defines.sqlite3.source: sqlite3mc` entry in pubspec.yaml),
/// which replaces the now-deprecated `sqlcipher_flutter_libs` package.
@DriftDatabase(
  tables: [
    Profiles,
    Medicines,
    DoseLogs,
    Appointments,
    Prescriptions,
    HealthMetrics,
    Achievements,
    SyncQueue,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  /// Opens (or creates) the encrypted on-disk database, provisioning the
  /// SQLCipher-equivalent key via [DatabaseKeyProvisioner] on first launch.
  static Future<AppDatabase> open(DatabaseKeyProvisioner keyProvisioner) async {
    final key = await keyProvisioner.resolveKey();
    final executor = NativeDatabase.createInBackground(
      await _resolveDbFile(),
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = '$key';");
      },
    );
    return AppDatabase(executor);
  }

  static Future<File> _resolveDbFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'medify.sqlite'));
  }
}
