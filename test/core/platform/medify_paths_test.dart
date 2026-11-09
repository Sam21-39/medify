import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/platform/medify_paths.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('medify/paths');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('documentsDirectory returns the native path', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'documentsDirectory');
      return '/docs';
    });
    expect(await MedifyPaths.documentsDirectory(), '/docs');
  });

  test('temporaryDirectory returns the native path', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'temporaryDirectory');
      return '/tmp/medify';
    });
    expect(await MedifyPaths.temporaryDirectory(), '/tmp/medify');
  });

  test('native failure is rethrown as StateError', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'NO_DIRECTORY', message: 'missing');
    });
    await expectLater(
      MedifyPaths.temporaryDirectory(),
      throwsA(isA<StateError>()),
    );
  });
}
