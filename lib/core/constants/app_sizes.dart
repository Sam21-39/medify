/// App size constants following Medify design specifications
class AppSizes {
  AppSizes._();

  // Spacing scale (4px base unit)
  static const double spacing4 = 4.0; // Micro spacing
  static const double spacing8 = 8.0; // Small spacing
  static const double spacing12 = 12.0; // Smaller medium spacing
  static const double spacing16 = 16.0; // Medium spacing
  static const double spacing20 = 20.0; // Larger medium spacing
  static const double spacing24 = 24.0; // Large spacing
  static const double spacing32 = 32.0; // Extra large spacing

  // Legacy padding names (mapped to spacing scale)
  static const double paddingXS = spacing4;
  static const double paddingS = spacing8;
  static const double paddingM = spacing16;
  static const double paddingL = spacing24;
  static const double paddingXL = spacing32;

  // Border radius (updated to spec)
  static const double radiusInput = 8.0; // Input fields
  static const double radiusButton = 12.0; // Buttons
  static const double radiusCard = 16.0; // Cards
  static const double radiusCircle = 999.0;

  // Legacy radius names
  static const double radiusS = radiusInput;
  static const double radiusM = radiusButton;
  static const double radiusL = radiusCard;
  static const double radiusXL = 24.0;

  // Icon sizes
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;
  static const double iconXXL = 64.0;
  static const double iconOnboarding = 72.0;

  // Button sizes (per spec: 56px height minimum)
  static const double buttonHeight = 56.0; // Primary button height
  static const double buttonHeightSmall = 44.0; // Minimum tap target
  static const double buttonHeightLarge = 64.0;
  static const double buttonMinWidth = 120.0;

  // Minimum tap target size for accessibility
  static const double minTapTarget = 44.0; // 44px × 44px minimum

  // Screen margins
  static const double screenMargin = 16.0; // 16px on all sides
  static const double contentPadding = 16.0; // Card internal padding
  static const double sectionSpacing = 24.0; // Between form sections

  // Card elevation
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;

  // App bar
  static const double appBarHeight = 56.0;

  // Bottom navigation bar
  static const double bottomNavHeight = 64.0;
}
