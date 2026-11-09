import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;

/// Device IANA time zone over the `medify/timezone` channel.
class MedifyTimezoneChannel {
  MedifyTimezoneChannel._();

  static const _channel = MethodChannel('medify/timezone');

  /// Sets `tz.local` to the device zone. Falls back to UTC on any failure.
  static Future<void> setLocalLocation() async {
    try {
      final name = await _channel.invokeMethod<String>('getLocalTimezone');
      tz.setLocalLocation(tz.getLocation(name ?? 'UTC'));
    } on Exception {
      tz.setLocalLocation(tz.UTC);
    }
  }
}
