import 'package:flutter/material.dart';

/// Design tokens derived from the Medify Figma file
/// (figma.com/design/RAJjYynBT0faYvEWtfWsJr).
abstract final class AppColors {
  static const primary = Color(0xFF0B5D5D);
  static const primaryDark = Color(0xFF083F3F);
  static const primaryLight = Color(0xFF3D8A8A);

  static const backgroundLight = Color(0xFFF3F6FA);
  static const backgroundDark = Color(0xFF0B1F1F);

  static const surfaceLight = Colors.white;
  static const surfaceDark = Color(0xFF13302F);

  static const statusTaken = Color(0xFF1B8A5A);
  static const statusSnoozed = Color(0xFFE0A030);
  static const statusMissed = Color(0xFFD0453B);
  static const statusSkipped = Color(0xFF9AA5A5);
}
