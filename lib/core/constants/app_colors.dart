import 'package:flutter/material.dart';

import 'package:medify/core/design/tokens/color_primitives.dart';
import 'package:medify/core/design/tokens/color_tokens.dart';

/// Legacy color API — delegates to design tokens.
class AppColors {
  AppColors._();

  static const Color primary = ColorPrimitives.teal600;
  static const Color primaryLight = ColorPrimitives.teal400;
  static const Color primaryDark = ColorPrimitives.teal700;

  static const Color secondary = ColorPrimitives.green600;
  static const Color secondaryLight = ColorPrimitives.green400;
  static const Color secondaryDark = ColorPrimitives.green600;

  static const Color success = ColorPrimitives.green600;
  static const Color warning = ColorPrimitives.amber500;
  static const Color error = ColorPrimitives.red600;
  static const Color info = ColorPrimitives.blue500;

  static const Color backgroundLight = ColorPrimitives.groupedLight;
  static const Color surfaceLight = ColorPrimitives.surfaceLight;
  static const Color cardLight = ColorPrimitives.surfaceLight;

  static const Color backgroundDark = ColorPrimitives.groupedDark;
  static const Color surfaceDark = ColorPrimitives.surfaceDark;
  static const Color cardDark = ColorPrimitives.surfaceDark;

  static const Color textPrimaryLight = ColorPrimitives.labelLight;
  static const Color textSecondaryLight = ColorPrimitives.labelSecondaryLight;
  static const Color textDisabledLight = ColorPrimitives.labelTertiaryLight;

  static const Color textPrimaryDark = ColorPrimitives.labelDark;
  static const Color textSecondaryDark = ColorPrimitives.labelSecondaryDark;
  static const Color textDisabledDark = ColorPrimitives.labelTertiaryDark;

  static const Color borderLight = ColorPrimitives.separatorLight;
  static const Color borderDark = ColorPrimitives.separatorDark;

  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x40000000);

  static ColorTokens semantic(Brightness brightness) =>
      brightness == Brightness.dark ? ColorTokens.dark : ColorTokens.light;
}
