import 'package:flutter/material.dart';

/// App color constants following Medify design specifications
class AppColors {
  AppColors._();

  // Primary - Teal shades (Material Design 3 Teal)
  static const Color primary = Color(0xFF14B8A6); // Teal 500
  static const Color primaryLight = Color(0xFF2DD4BF); // Teal 400
  static const Color primaryDark = Color(0xFF0D9488); // Teal 600

  // Secondary - Using success color for compatibility
  static const Color secondary = Color(0xFF10B981); // Green
  static const Color secondaryLight = Color(0xFF34D399); // Light green
  static const Color secondaryDark = Color(0xFF059669); // Dark green

  // Semantic colors
  static const Color success = Color(0xFF10B981); // Green for taken
  static const Color warning = Color(0xFFF59E0B); // Amber for upcoming
  static const Color error = Color(0xFFEF4444); // Red for missed
  static const Color info = Color(0xFF3B82F6); // Blue for info

  // Background colors - Light mode
  static const Color backgroundLight = Color(0xFFFAFAFA); // Neutral 50
  static const Color surfaceLight = Color(0xFFFFFFFF); // White
  static const Color cardLight = Color(0xFFFFFFFF); // White

  // Background colors - Dark mode
  static const Color backgroundDark = Color(0xFF111827); // Gray 900
  static const Color surfaceDark = Color(0xFF1F2937); // Gray 800
  static const Color cardDark = Color(0xFF1F2937); // Gray 800

  // Text colors - Light mode
  static const Color textPrimaryLight = Color(0xFF1F2937); // Gray 800
  static const Color textSecondaryLight = Color(0xFF6B7280); // Gray 500
  static const Color textDisabledLight = Color(0xFF9CA3AF); // Gray 400

  // Text colors - Dark mode
  static const Color textPrimaryDark = Color(0xFFF9FAFB); // Gray 50
  static const Color textSecondaryDark = Color(0xFFD1D5DB); // Gray 300
  static const Color textDisabledDark = Color(0xFF6B7280); // Gray 500

  // Border colors
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF424242);

  // Shadow colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x40000000);
}
