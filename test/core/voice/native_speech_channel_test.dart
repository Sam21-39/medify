import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/voice/native_speech_channel.dart';

const _channel = MethodChannel('medify/speech');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    calls.clear();
  });

  void mock(Future<Object?> Function(MethodCall) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          return handler(call);
        });
  }

  test('speak sends text argument', () async {
    mock((_) async => null);
    await NativeSpeech.speak('Medicine A at 8am.');
    expect(calls.single.method, 'speak');
    expect(calls.single.arguments, {'text': 'Medicine A at 8am.'});
  });

  test('stop sends stop call', () async {
    mock((_) async => null);
    await NativeSpeech.stop();
    expect(calls.single.method, 'stop');
  });

  test('PlatformException is swallowed', () async {
    mock((_) async => throw PlatformException(code: 'TTS_UNAVAILABLE'));
    await expectLater(NativeSpeech.speak('x'), completes);
  });
}
