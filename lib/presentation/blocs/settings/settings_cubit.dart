import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/services/theme_service.dart';
import 'settings_state.dart';

/// Cubit for managing settings
class SettingsCubit extends Cubit<SettingsState> {
  final PreferencesService _preferencesService;
  final ThemeService _themeService = ThemeService();

  SettingsCubit(this._preferencesService) : super(const SettingsInitial()) {
    loadSettings();
  }

  /// Load current settings
  void loadSettings() {
    emit(
      SettingsLoaded(
        themeMode: _preferencesService.themeMode,
        notificationsEnabled: _preferencesService.notificationsEnabled,
        snoozeDuration: _preferencesService.snoozeDuration,
      ),
    );
  }

  /// Update theme mode
  Future<void> updateThemeMode(ThemeMode themeMode) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      // emit(const SettingsUpdating());

      await _preferencesService.setThemeMode(themeMode);

      // Notify the app to rebuild with new theme
      _themeService.updateTheme(themeMode);

      emit(currentState.copyWith(themeMode: themeMode));
    }
  }

  /// Update notifications enabled
  Future<void> updateNotificationsEnabled(bool enabled) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      // emit(const SettingsUpdating());

      await _preferencesService.setNotificationsEnabled(enabled);

      emit(currentState.copyWith(notificationsEnabled: enabled));
    }
  }

  /// Update snooze duration
  Future<void> updateSnoozeDuration(int minutes) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      // emit(const SettingsUpdating());

      await _preferencesService.setSnoozeDuration(minutes);

      emit(currentState.copyWith(snoozeDuration: minutes));
    }
  }

  /// Reset all settings to default
  Future<void> resetSettings() async {
    emit(const SettingsUpdating());

    await _preferencesService.setThemeMode(ThemeMode.system);
    await _preferencesService.setNotificationsEnabled(true);
    await _preferencesService.setSnoozeDuration(15);

    loadSettings();
  }
}
