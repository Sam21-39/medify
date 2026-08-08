import 'package:flutter/material.dart';

/// Light/dark ColorScheme, TextTheme, and motion tokens (Section 3). Kept
/// minimal for the initial scaffold — expand as visual design lands.
class AppTheme {
  const AppTheme._();

  static const _seedColor = Colors.teal;

  static ThemeData light() => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
    useMaterial3: true,
  );

  static ThemeData dark() => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
}

/// Shared spring/motion curves, referenced by feature-level animations
/// instead of ad-hoc `Curves.*` picks scattered per screen.
class AppMotion {
  const AppMotion._();

  static const standard = Curves.easeInOutCubic;
  static const emphasized = Curves.easeOutCubic;
  static const standardDuration = Duration(milliseconds: 250);
}
