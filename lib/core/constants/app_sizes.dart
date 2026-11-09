import 'package:medify/core/design/tokens/radius_tokens.dart';
import 'package:medify/core/design/tokens/space_tokens.dart';

/// Legacy size API — delegates to space/radius tokens.
class AppSizes {
  AppSizes._();

  static const double spacing4 = SpaceTokens.xxs;
  static const double spacing8 = SpaceTokens.xs;
  static const double spacing12 = SpaceTokens.sm;
  static const double spacing16 = SpaceTokens.md;
  static const double spacing20 = SpaceTokens.lg;
  static const double spacing24 = SpaceTokens.xl;
  static const double spacing32 = SpaceTokens.xxl;

  static const double paddingXS = spacing4;
  static const double paddingS = spacing8;
  static const double paddingM = spacing16;
  static const double paddingL = spacing24;
  static const double paddingXL = spacing32;

  static const double radiusInput = RadiusTokens.input;
  static const double radiusButton = RadiusTokens.button;
  static const double radiusCard = RadiusTokens.card;
  static const double radiusCircle = RadiusTokens.chip;

  static const double radiusS = radiusInput;
  static const double radiusM = radiusButton;
  static const double radiusL = radiusCard;
  static const double radiusXL = 24.0;

  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;
  static const double iconXXL = 64.0;
  static const double iconOnboarding = 72.0;

  static const double buttonHeight = SpaceTokens.buttonHeight;
  static const double buttonHeightSmall = SpaceTokens.buttonHeightSm;
  static const double buttonHeightLarge = 64.0;
  static const double buttonMinWidth = 120.0;

  static const double minTapTarget = SpaceTokens.minTap;

  static const double screenMargin = SpaceTokens.screenMargin;
  static const double contentPadding = SpaceTokens.md;
  static const double sectionSpacing = SpaceTokens.sectionGap;

  static const double elevationS = 1.0;
  static const double elevationM = 2.0;
  static const double elevationL = 4.0;

  static const double appBarHeight = SpaceTokens.appBarHeight;
  static const double bottomNavHeight = SpaceTokens.bottomNavHeight;
}
