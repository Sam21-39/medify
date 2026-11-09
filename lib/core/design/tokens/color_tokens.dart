import 'package:flutter/material.dart';

import 'package:medify/core/design/tokens/color_primitives.dart';

/// Semantic colors for light or dark.
class ColorTokens {
  const ColorTokens({
    required this.brand,
    required this.onBrand,
    required this.brandSoft,
    required this.bgGrouped,
    required this.bgSurface,
    required this.labelPrimary,
    required this.labelSecondary,
    required this.labelTertiary,
    required this.separator,
    required this.statusTaken,
    required this.statusMissed,
    required this.statusUpcoming,
    required this.statusSkipped,
    required this.danger,
    required this.chromeGlassFill,
    required this.chromeTintSurface,
    required this.chromeHairline,
  });

  final Color brand;
  final Color onBrand;
  final Color brandSoft;
  final Color bgGrouped;
  final Color bgSurface;
  final Color labelPrimary;
  final Color labelSecondary;
  final Color labelTertiary;
  final Color separator;
  final Color statusTaken;
  final Color statusMissed;
  final Color statusUpcoming;
  final Color statusSkipped;
  final Color danger;
  final Color chromeGlassFill;
  final Color chromeTintSurface;
  final Color chromeHairline;

  static const ColorTokens light = ColorTokens(
    brand: ColorPrimitives.teal600,
    onBrand: Colors.white,
    brandSoft: ColorPrimitives.teal400,
    bgGrouped: ColorPrimitives.groupedLight,
    bgSurface: ColorPrimitives.surfaceLight,
    labelPrimary: ColorPrimitives.labelLight,
    labelSecondary: ColorPrimitives.labelSecondaryLight,
    labelTertiary: ColorPrimitives.labelTertiaryLight,
    separator: ColorPrimitives.separatorLight,
    statusTaken: ColorPrimitives.green600,
    statusMissed: ColorPrimitives.red600,
    statusUpcoming: ColorPrimitives.amber500,
    statusSkipped: ColorPrimitives.slate400,
    danger: ColorPrimitives.red600,
    chromeGlassFill: Color(0x9EFFFFFF), // ~62% white
    chromeTintSurface: ColorPrimitives.tintSurfaceLight,
    chromeHairline: Color(0x59FFFFFF),
  );

  static const ColorTokens dark = ColorTokens(
    brand: ColorPrimitives.teal400,
    onBrand: Color(0xFF0F172A),
    brandSoft: ColorPrimitives.teal500,
    bgGrouped: ColorPrimitives.groupedDark,
    bgSurface: ColorPrimitives.surfaceDark,
    labelPrimary: ColorPrimitives.labelDark,
    labelSecondary: ColorPrimitives.labelSecondaryDark,
    labelTertiary: ColorPrimitives.labelTertiaryDark,
    separator: ColorPrimitives.separatorDark,
    statusTaken: ColorPrimitives.green400,
    statusMissed: Color(0xFFF87171),
    statusUpcoming: Color(0xFFFBBF24),
    statusSkipped: ColorPrimitives.slate400,
    danger: Color(0xFFF87171),
    chromeGlassFill: Color(0x9E1C1C1E),
    chromeTintSurface: ColorPrimitives.tintSurfaceDark,
    chromeHairline: Color(0x59FFFFFF),
  );
}
