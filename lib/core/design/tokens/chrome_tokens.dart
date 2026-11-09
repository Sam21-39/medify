/// Chrome-only tokens (glass on iOS, tint on Android).
class ChromeTokens {
  const ChromeTokens({
    required this.blurSigma,
    required this.glassOpacity,
    required this.tintStrength,
    required this.hairlineOpacity,
  });

  final double blurSigma;
  final double glassOpacity;
  final double tintStrength;
  final double hairlineOpacity;

  static const ChromeTokens glass = ChromeTokens(
    blurSigma: 18,
    glassOpacity: 0.62,
    tintStrength: 0,
    hairlineOpacity: 0.35,
  );

  /// Reduced-motion / a11y fallback on iOS — opaque bar, no blur.
  static const ChromeTokens glassFallback = ChromeTokens(
    blurSigma: 0,
    glassOpacity: 0.94,
    tintStrength: 0,
    hairlineOpacity: 0.25,
  );

  static const ChromeTokens tint = ChromeTokens(
    blurSigma: 0,
    glassOpacity: 1,
    tintStrength: 0.12,
    hairlineOpacity: 0.2,
  );
}
