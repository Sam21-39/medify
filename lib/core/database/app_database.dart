import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/health_profile/data/local/profile_table.dart';

part 'app_database.g.dart';

/// Shared local database. Each feature module owns its own tables and
/// composes them in here via `part` files (e.g. `medicine_table.dart`),
/// keeping module ownership real even though the DB is a single file.
@DriftDatabase(tables: [ProfileTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'medify.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
