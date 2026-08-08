/// The baseline flag set from Section 11 of the architecture doc. Every key
/// here must have a safe default — on fetch failure at startup, every
/// feature/ad flag defaults to off and sync stays on.
enum FeatureFlag {
  caregiverAlerts('feature_caregiver_alerts', false),
  appointments('feature_appointments', false),
  prescriptions('feature_prescriptions', false),
  ocrScanner('feature_ocr_scanner', false),
  healthTracking('feature_health_tracking', false),
  voiceCommands('feature_voice_commands', false),
  liveActivity('feature_live_activity', true),
  homeWidget('feature_home_widget', true),
  adsEnabled('ads_enabled', false),
  syncEnabled('sync_enabled', true);

  const FeatureFlag(this.remoteKey, this.safeDefault);

  final String remoteKey;
  final bool safeDefault;
}

/// Non-boolean config values from the same baseline set.
class RemoteConfigInts {
  static const encryptionKeyRotationDays = (
    key: 'encryption_key_rotation_days',
    safeDefault: 90,
  );
}
