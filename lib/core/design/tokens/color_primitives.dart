import 'package:flutter/material.dart';

/// Raw palette — never use directly in widgets; go through semantic tokens.
abstract final class ColorPrimitives {
  // Brand teal / cyan
  static const Color teal400 = Color(0xFF22D3EE);
  static const Color teal500 = Color(0xFF14B8A6);
  static const Color teal600 = Color(0xFF0891B2);
  static const Color teal700 = Color(0xFF0E7490);

  // Health green (CTA / taken)
  static const Color green400 = Color(0xFF34D399);
  static const Color green500 = Color(0xFF10B981);
  static const Color green600 = Color(0xFF059669);

  // Status
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color slate400 = Color(0xFF94A3B8);

  // Light neutrals
  static const Color washLight = Color(0xFFECFEFF);
  static const Color groupedLight = Color(0xFFF0F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color labelLight = Color(0xFF164E63);
  static const Color labelSecondaryLight = Color(0xFF64748B);
  static const Color labelTertiaryLight = Color(0xFF94A3B8);
  static const Color separatorLight = Color(0xFFC5D4DC);
  static const Color tintSurfaceLight = Color(0xFFE0F2F5);

  // Dark neutrals (never pure black)
  static const Color groupedDark = Color(0xFF111827);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color surfaceElevatedDark = Color(0xFF2C2C2E);
  static const Color labelDark = Color(0xFFF8FAFC);
  static const Color labelSecondaryDark = Color(0xFFCBD5E1);
  static const Color labelTertiaryDark = Color(0xFF94A3B8);
  static const Color separatorDark = Color(0xFF3A3A3C);
  static const Color tintSurfaceDark = Color(0xFF1A2A32);
}
