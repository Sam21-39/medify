import 'package:flutter/services.dart';

/// Native directory lookups over the `medify/paths` channel.
class MedifyPaths {
  MedifyPaths._();

  static const _channel = MethodChannel('medify/paths');

  static Future<String> documentsDirectory() => _invoke('documentsDirectory');

  static Future<String> temporaryDirectory() => _invoke('temporaryDirectory');

  static Future<String> _invoke(String method) async {
    try {
      final path = await _channel.invokeMethod<String>(method);
      if (path == null) {
        throw StateError('medify/paths $method returned null');
      }
      return path;
    } on PlatformException catch (e) {
      throw StateError('medify/paths $method failed: ${e.message}');
    }
  }
}
