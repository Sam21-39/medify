import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/database/medify_database.dart';
import 'package:medify/core/database/settings_store.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'after the wipe the file is gone and reopening gives an empty schema',
    () async {
      final dir = Directory.systemTemp.createTempSync('db_wipe_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}/medify_v2.db';

      final db = await MedifyDatabase.open(path: path);
      await SettingsStore(db).setString('marker', 'before wipe');
      await db.close();

      // The wipe step: delete the file that the closed handle pointed at.
      await deleteDatabase(path);
      expect(File(path).existsSync(), isFalse);

      final fresh = await MedifyDatabase.open(path: path);
      try {
        expect(
          Sqflite.firstIntValue(
            await fresh.rawQuery('SELECT COUNT(*) FROM settings'),
          ),
          0,
        );
        expect(
          Sqflite.firstIntValue(
            await fresh.rawQuery('SELECT COUNT(*) FROM medicines'),
          ),
          0,
        );
      } finally {
        await fresh.close();
      }
    },
  );
}
