import 'package:flutter/material.dart';

/// Service for managing theme updates across the app
class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  /// Callback to update theme mode
  ValueChanged<ThemeMode>? _onThemeModeChanged;

  /// Register a callback for theme mode changes
  void registerThemeCallback(ValueChanged<ThemeMode> callback) {
    _onThemeModeChanged = callback;
  }

  /// Update theme mode
  void updateTheme(ThemeMode themeMode) {
    _onThemeModeChanged?.call(themeMode);
  }
}
