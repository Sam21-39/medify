import 'package:flutter/services.dart';

/// Transcript event from the native recognizer. [isFinal] is set once per session.
/// [errorCode] is set instead when the recognizer failed mid-session.
class SttEvent {
  const SttEvent({required this.text, required this.isFinal, this.errorCode});

  final String text;
  final bool isFinal;
  final String? errorCode;
}

/// On-device speech-to-text. Native side: iOS SFSpeechRecognizer, Android SpeechRecognizer.
abstract final class NativeSttChannel {
  static const _method = MethodChannel('medify/stt');
  static const _events = EventChannel('medify/stt/events');

  /// Throws [PlatformException] with code 'permission_denied', 'unavailable'
  /// or 'cancelled' (a stop or cancel arrived before the start completed).
  static Future<void> start() => _method.invokeMethod<void>('start');

  /// Ends capture; the final transcript then arrives on [events].
  static Future<void> stop() => _method.invokeMethod<void>('stop');

  /// Ends the session immediately. No final transcript is sent.
  static Future<void> cancel() => _method.invokeMethod<void>('cancel');

  /// [cancel] for teardown paths: a missing or failed native side is not an error.
  static Future<void> cancelQuietly() async {
    try {
      await cancel();
    } on PlatformException {
      // Native session already gone.
    } on MissingPluginException {
      // No native side (e.g. tests or unsupported platform).
    }
  }

  static Stream<SttEvent> get events =>
      _events.receiveBroadcastStream().map((event) {
        final map = event as Map<dynamic, dynamic>;
        final isError = map['type'] == 'error';
        return SttEvent(
          text: map['text'] as String? ?? '',
          isFinal: map['type'] == 'final',
          errorCode: isError ? map['code'] as String? ?? 'unavailable' : null,
        );
      });
}
