import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeSpeech {
  static const _channel = MethodChannel('medify/speech');

  static Future<void> speak(String text) => _invoke('speak', {'text': text});

  static Future<void> stop() => _invoke('stop');

  static Future<void> _invoke(
    String method, [
    Map<String, Object?>? args,
  ]) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on PlatformException catch (e) {
      debugPrint('NativeSpeech.$method failed: ${e.code}');
    } on MissingPluginException catch (e) {
      debugPrint('NativeSpeech.$method missing plugin: $e');
    }
  }
}
