import 'package:injectable/injectable.dart';

import 'feature_flags.dart';

/// Typed accessor over Firebase Remote Config. `initialize()` must complete
/// (with a timeout, falling back to safe defaults) before `main.dart` runs
/// the app shell — see `bootstrap.dart`.
///
/// Firebase Remote Config wiring is stubbed until `firebase_options.dart`
/// exists (see bootstrap TODO); until then every flag simply serves its
/// safe default, which is the correct fail-safe behavior anyway.
@lazySingleton
class RemoteConfigService {
  final Map<String, bool> _boolOverrides = {};
  final Map<String, int> _intOverrides = {};

  Future<void> initialize() async {
    // TODO(remote-config): fetchAndActivate() via firebase_remote_config
    // once Firebase is configured; populate _boolOverrides/_intOverrides
    // from the fetched values, falling back to defaults on timeout/failure.
  }

  bool isEnabled(FeatureFlag flag) =>
      _boolOverrides[flag.remoteKey] ?? flag.safeDefault;

  int encryptionKeyRotationDays() =>
      _intOverrides[RemoteConfigInts.encryptionKeyRotationDays.key] ??
      RemoteConfigInts.encryptionKeyRotationDays.safeDefault;
}
