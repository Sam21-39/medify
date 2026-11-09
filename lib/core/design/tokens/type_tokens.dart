import 'package:flutter/material.dart';

/// Nunito type roles — elderly-biased sizes.
abstract final class TypeTokens {
  static const String fontFamily = 'Nunito';

  static TextStyle _base(double size, FontWeight weight, Color color) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.35,
      );

  static TextStyle largeTitle(Color c) => _base(34, FontWeight.bold, c);
  static TextStyle title1(Color c) => _base(28, FontWeight.bold, c);
  static TextStyle title2(Color c) => _base(22, FontWeight.w600, c);
  static TextStyle title3(Color c) => _base(20, FontWeight.w600, c);
  static TextStyle body(Color c) => _base(17, FontWeight.w400, c);
  static TextStyle callout(Color c) => _base(16, FontWeight.w600, c);
  static TextStyle footnote(Color c) => _base(14, FontWeight.w400, c);
  static TextStyle caption(Color c) => _base(13, FontWeight.w400, c);
}
