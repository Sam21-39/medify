import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Settings state
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// Settings loaded
class SettingsLoaded extends SettingsState {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final int snoozeDuration;

  const SettingsLoaded({
    required this.themeMode,
    required this.notificationsEnabled,
    required this.snoozeDuration,
  });

  @override
  List<Object?> get props => [themeMode, notificationsEnabled, snoozeDuration];

  SettingsLoaded copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    int? snoozeDuration,
  }) {
    return SettingsLoaded(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      snoozeDuration: snoozeDuration ?? this.snoozeDuration,
    );
  }
}

/// Settings updating
class SettingsUpdating extends SettingsState {
  const SettingsUpdating();
}

