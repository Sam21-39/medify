import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'schema.dart';

/// Opens the sqflite database. Tests pass [inMemoryDatabasePath].
class MedifyDatabase {
  MedifyDatabase._();

  static const _version = 1;

  static Future<Database> open({String? path}) async {
    final dbPath = path ?? p.join(await getDatabasesPath(), 'medify_v2.db');
    return openDatabase(
      dbPath,
      version: _version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        for (final statement in schemaStatements) {
          await db.execute(statement);
        }
      },
    );
  }
}
