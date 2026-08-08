import 'package:flutter/foundation.dart';

/// Catches anything that slips past the [Result]/[Failure] pattern —
/// registered once from `bootstrap.dart` via [FlutterError.onError] and
/// [PlatformDispatcher.instance.onError]. Never crashes or blocks the UI;
/// a caught error only ever surfaces as the calm, non-blocking banner
/// described in Section 10.2 of the architecture doc.
class AppErrorHandler {
  AppErrorHandler({this.onUnhandledError});

  /// Called with a user-safe message once an error has been logged. Wired
  /// up to whatever shows the non-blocking "something went wrong" banner.
  final void Function(String message)? onUnhandledError;

  void install() {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      _report(details.exception, details.stack);
      previousOnError?.call(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _report(error, stack);
      return true;
    };
  }

  void _report(Object error, StackTrace? stack) {
    // TODO(crashlytics): forward `error`/`stack` plus breadcrumbs (last
    // route, last action, auth/sync state) to Crashlytics once
    // firebase_crashlytics is initialized in bootstrap.dart.
    debugPrint('AppErrorHandler caught: $error');
    onUnhandledError?.call('Something went wrong — your data is safe locally.');
  }
}
