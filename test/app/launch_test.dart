import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:medify/app/launch.dart';
import 'package:medify/core/database/medify_database.dart';
import 'package:medify/core/database/settings_store.dart';
import 'package:medify/core/di/injection_container.dart';
import 'package:medify/core/security/key_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;
  late Database db;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('launch_test');
    db = await MedifyDatabase.open(path: '${tempDir.path}/medify.db');
    getIt.registerSingleton<Database>(db);
    await SettingsStore(db).setString('marker', 'kept');
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
    tempDir.deleteSync(recursive: true);
  });

  test('a failed notification cancel leaves the DB untouched (N6-4)', () async {
    await expectLater(
      wipeAllDataAndRelaunch(
        cancelAll: () async => throw StateError('cancel failed'),
      ),
      throwsStateError,
    );

    expect(File('${tempDir.path}/medify.db').existsSync(), isTrue);
    expect(
      await SettingsStore(db).getString('marker', defaultValue: ''),
      'kept',
    );
  });

  group('wipeAllDataAndRelaunch seams', () {
    late List<String> calls;

    setUp(() {
      calls = [];
    });

    Future<void> recordDelete(String path) async {
      calls.add('delete');
      await File(path).delete();
    }

    test(
      'a delete failure still relaunches and keeps the delete error',
      () async {
        final error = StateError('delete failed');
        await expectLater(
          wipeAllDataAndRelaunch(
            cancelAll: () async => calls.add('cancel'),
            drain: () async => calls.add('drain'),
            deleteDb: (_) async => throw error,
            launch: () async => calls.add('launch'),
            onFailure: () => calls.add('failure'),
          ),
          throwsA(same(error)),
        );

        expect(calls, ['cancel', 'drain', 'cancel', 'launch']);
      },
    );

    test('a relaunch failure calls onFailure instead of throwing', () async {
      await wipeAllDataAndRelaunch(
        cancelAll: () async => calls.add('cancel'),
        drain: () async => calls.add('drain'),
        deleteDb: recordDelete,
        launch: () async => throw StateError('launch failed'),
        onFailure: () => calls.add('failure'),
      );

      expect(calls, ['cancel', 'delete', 'drain', 'cancel', 'failure']);
    });

    test('the key store is never touched by a wipe', () async {
      final keys = _FakeSecretStore();
      getIt.registerSingleton<SecretStore>(keys);

      await wipeAllDataAndRelaunch(
        cancelAll: () async {},
        drain: () async {},
        deleteDb: recordDelete,
        launch: () async {},
      );

      expect(keys.calls, isEmpty);
    });
  });
}

class _FakeSecretStore implements SecretStore {
  final List<String> calls = [];

  @override
  Future<String?> read(String key) async {
    calls.add('read:$key');
    return null;
  }

  @override
  Future<void> write(String key, String value) async {
    calls.add('write:$key');
  }
}
