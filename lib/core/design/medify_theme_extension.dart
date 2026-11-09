import 'package:flutter/material.dart';

import 'package:medify/core/design/tokens/chrome_tokens.dart';
import 'package:medify/core/design/tokens/color_tokens.dart';
import 'package:medify/core/design/tokens/radius_tokens.dart';
import 'package:medify/core/design/tokens/space_tokens.dart';
import 'package:medify/core/design/tokens/type_tokens.dart';

/// Semantic design tokens on [ThemeData.extensions].
class MedifyTokens extends ThemeExtension<MedifyTokens> {
  const MedifyTokens({required this.colors, required this.chrome});

  final ColorTokens colors;
  final ChromeTokens chrome;

  static MedifyTokens of(BuildContext context) {
    final tokens = Theme.of(context).extension<MedifyTokens>();
    assert(tokens != null, 'MedifyTokens missing from ThemeData.extensions');
    return tokens!;
  }

  static const MedifyTokens light = MedifyTokens(
    colors: ColorTokens.light,
    chrome: ChromeTokens
        .tint, // Android default; iOS glass via adaptive_platform_ui
  );

  static const MedifyTokens dark = MedifyTokens(
    colors: ColorTokens.dark,
    chrome: ChromeTokens.tint,
  );

  // Convenience getters
  Color get brand => colors.brand;
  Color get onBrand => colors.onBrand;
  Color get bgGrouped => colors.bgGrouped;
  Color get bgSurface => colors.bgSurface;
  Color get labelPrimary => colors.labelPrimary;
  Color get labelSecondary => colors.labelSecondary;
  Color get statusTaken => colors.statusTaken;
  Color get statusMissed => colors.statusMissed;
  Color get statusUpcoming => colors.statusUpcoming;
  Color get statusSkipped => colors.statusSkipped;
  Color get danger => colors.danger;
  Color get separator => colors.separator;
  Color get tintSurface => colors.chromeTintSurface;

  double get radiusCard => RadiusTokens.card;
  double get radiusButton => RadiusTokens.button;
  double get spaceMd => SpaceTokens.md;
  double get minTap => SpaceTokens.minTap;
  double get buttonHeight => SpaceTokens.buttonHeight;

  TextStyle get title1 => TypeTokens.title1(labelPrimary);
  TextStyle get title2 => TypeTokens.title2(labelPrimary);
  TextStyle get title3 => TypeTokens.title3(labelPrimary);
  TextStyle get body => TypeTokens.body(labelPrimary);
  TextStyle get callout => TypeTokens.callout(labelPrimary);
  TextStyle get footnote => TypeTokens.footnote(labelSecondary);

  @override
  MedifyTokens copyWith({ColorTokens? colors, ChromeTokens? chrome}) {
    return MedifyTokens(
      colors: colors ?? this.colors,
      chrome: chrome ?? this.chrome,
    );
  }

  @override
  MedifyTokens lerp(ThemeExtension<MedifyTokens>? other, double t) {
    if (other is! MedifyTokens) return this;
    return t < 0.5 ? this : other;
  }
}
