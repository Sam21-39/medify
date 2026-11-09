import 'package:flutter/services.dart';

/// Clears 1.x preferences data over the `medify/prefs` channel.
class MedifyPrefsChannel {
  MedifyPrefsChannel._();

  static const _channel = MethodChannel('medify/prefs');

  static Future<void> clearLegacyPrefs() async {
    try {
      await _channel.invokeMethod<void>('clearLegacyPrefs');
    } on PlatformException catch (e) {
      throw StateError('medify/prefs clearLegacyPrefs failed: ${e.message}');
    }
  }
}
