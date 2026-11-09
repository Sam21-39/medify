import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:medify/core/transition/legacy_reset.dart';
import 'package:medify/features/transition/presentation/reset_gate_cubit.dart';
import 'package:medify/features/transition/presentation/reset_gate_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const prefsChannel = MethodChannel('medify/prefs');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(prefsChannel, (call) async => null);
  });
  tearDown(() => messenger.setMockMethodCallHandler(prefsChannel, null));

  testWidgets('Not now changes no files and shows the declined state', (
    tester,
  ) async {
    final root = await tester.runAsync(
      () => Directory.systemTemp.createTemp('reset_gate_test'),
    );
    final store = Directory(p.join(root!.path, legacyStoreDirName));
    await tester.runAsync(() => store.create());

    final cubit = ResetGateCubit(
      reset: LegacyReset(
        documentsDir: root.path,
        v2DatabasePath: p.join(root.path, v2DatabaseFileName),
        cancelReminders: () async {},
      ),
      onComplete: () {},
    );
    await tester.pumpWidget(ResetGateApp(cubit: cubit));
    await tester.runAsync(cubit.start);
    await tester.pumpAndSettle();

    expect(find.textContaining('This cannot be undone.'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Reconsider'), findsOneWidget);
    expect(await tester.runAsync(store.exists), isTrue);
    expect(
      await tester.runAsync(
        () => File(p.join(root.path, v2DatabaseFileName)).exists(),
      ),
      isFalse,
    );
    await tester.runAsync(() => root.delete(recursive: true));
  });
}
