import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:medify/core/transition/legacy_reset.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const prefsChannel = MethodChannel('medify/prefs');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory root;
  late int prefsCalls;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('legacy_reset_test');
    prefsCalls = 0;
    messenger.setMockMethodCallHandler(prefsChannel, (call) async {
      expect(call.method, 'clearLegacyPrefs');
      prefsCalls++;
      return null;
    });
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(prefsChannel, null);
    await root.delete(recursive: true);
  });

  LegacyReset reset({Future<void> Function()? cancel}) => LegacyReset(
    documentsDir: root.path,
    v2DatabasePath: p.join(root.path, v2DatabaseFileName),
    cancelReminders: cancel ?? () async {},
  );

  Future<Directory> legacyStore() async {
    final dir = Directory(p.join(root.path, legacyStoreDirName));
    await dir.create();
    await File(p.join(dir.path, 'data.mdb')).writeAsString('x');
    return dir;
  }

  test(
    'existing user: legacy store present and v2 absent needs reset',
    () async {
      await legacyStore();
      expect(await reset().needsReset(), isTrue);
    },
  );

  test('fresh install: no legacy store does not need reset', () async {
    expect(await reset().needsReset(), isFalse);
  });

  test('v2 present means no reset even with a legacy store', () async {
    await legacyStore();
    await File(p.join(root.path, v2DatabaseFileName)).writeAsString('v2');
    expect(await reset().needsReset(), isFalse);
  });

  test('detects the app_flutter legacy layout too', () async {
    await Directory(p.join(root.path, 'app_flutter', legacyStoreDirName))
        .create(recursive: true);
    expect(await reset().needsReset(), isTrue);
  });

  test('Not now path: detection alone changes no files', () async {
    final store = await legacyStore();
    await reset().needsReset();
    expect(await store.exists(), isTrue);
    expect(await File(p.join(root.path, v2DatabaseFileName)).exists(), isFalse);
    expect(prefsCalls, 0);
  });

  test(
    'run clears prefs, cancels reminders, deletes legacy, creates v2',
    () async {
      final store = await legacyStore();
      var cancelled = 0;
      final r = reset(cancel: () async => cancelled++);

      await r.run();

      expect(cancelled, 1);
      expect(prefsCalls, 1);
      expect(await store.exists(), isFalse);
      expect(
        await File(p.join(root.path, v2DatabaseFileName)).exists(),
        isTrue,
      );
      expect(await r.needsReset(), isFalse);
    },
  );

  test('run is idempotent when repeated', () async {
    await legacyStore();
    final r = reset();
    await r.run();
    await r.run();
    expect(prefsCalls, 2);
    expect(await r.needsReset(), isFalse);
  });

  test('failed run can be retried and completes', () async {
    final store = await legacyStore();
    var attempts = 0;
    final r = reset(
      cancel: () async {
        attempts++;
        if (attempts == 1) throw StateError('boom');
      },
    );

    await expectLater(r.run(), throwsA(isA<StateError>()));
    expect(
      await store.exists(),
      isTrue,
      reason: 'nothing deleted before failure',
    );

    await r.run();
    expect(await store.exists(), isFalse);
    expect(await r.needsReset(), isFalse);
  });

  test('native prefs failure surfaces as StateError', () async {
    messenger.setMockMethodCallHandler(prefsChannel, (call) async {
      throw PlatformException(code: 'PREFS_CLEAR_FAILED', message: 'no');
    });
    await legacyStore();
    await expectLater(reset().run(), throwsA(isA<StateError>()));
  });
}
