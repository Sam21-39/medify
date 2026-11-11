import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medify/core/system/system_service.dart';

import 'package:medify/core/constants/app_colors.dart';
import 'package:medify/core/constants/app_sizes.dart';
import 'package:medify/core/design/adaptive.dart';
import 'package:medify/core/di/injection_container.dart';
import 'package:medify/core/ui/app_messenger.dart';
import 'package:medify/core/widgets/medify_icon.dart';
// import 'package:medify/core/notifications/notification_service.dart';
import 'package:medify/gen/assets.gen.dart';
import 'package:medify/l10n/app_localizations.dart';
import 'package:medify/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:medify/features/settings/presentation/cubit/settings_state.dart';

// COMMENTED OUT FOR UPCOMING RELEASE
// import 'package:medify/features/profiles/presentation/pages/profiles_page.dart';

/// Settings page for app preferences
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SettingsView();
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: AppLocalizations.of(context)!.settingsTitle,
        useNativeToolbar: false,
      ),
      body: MedifyAdaptive.body(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          bloc: getIt<SettingsCubit>(),
          builder: (context, state) {
            if (state is SettingsLoaded) {
              return ListView(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                children: [
                  // App Section
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.appSection,
                    theme,
                  ),
                  _buildThemeSetting(context, state, theme),

                  // const SizedBox(height: AppSizes.spacing8),
                  // _buildLanguageSetting(context, theme), // Commented out for now
                  const SizedBox(height: AppSizes.spacing24),

                  // Notifications Section
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.notificationsSection,
                    theme,
                  ),
                  // _buildNotificationsSetting(context, state, theme),
                  const SizedBox(height: AppSizes.spacing8),
                  _buildSnoozeDurationSetting(context, state, theme),
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.speakReminder),
                    subtitle: Text(
                      AppLocalizations.of(context)!.speakReminderDesc,
                    ),
                    trailing: AdaptiveSwitch(
                      value: state.speakReminder,
                      onChanged: (value) =>
                          getIt<SettingsCubit>().updateSpeakReminder(value),
                    ),
                  ),

                  const SizedBox(height: AppSizes.spacing24),

                  // About Section
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.aboutSection,
                    theme,
                  ),
                  // COMMENTED OUT FOR UPCOMING RELEASE
                  // _buildProfilesCard(context, theme),
                  // const SizedBox(height: AppSizes.spacing8),
                  _buildAchievementsCard(context, theme),
                  const SizedBox(height: AppSizes.spacing8),
                  // _buildHistoryCard(context, theme),
                  // const SizedBox(height: AppSizes.spacing8),
                  _buildAboutCard(context, theme),
                  const SizedBox(height: AppSizes.spacing8),
                  _buildVersionCard(context, theme),

                  const SizedBox(height: AppSizes.spacing24),

                  // Reset Button
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _showResetDialog(context),
                      icon: MedifyIcon(
                        Assets.icons.refresh,
                        color: AppColors.error,
                      ),
                      label: Text(
                        AppLocalizations.of(context)!.resetAllSettings,
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSizes.spacing8,
        bottom: AppSizes.spacing8,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildThemeSetting(
    BuildContext context,
    SettingsLoaded state,
    ThemeData theme,
  ) {
    String getThemeLabel(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.light:
          return AppLocalizations.of(context)!.themeLight;
        case ThemeMode.dark:
          return AppLocalizations.of(context)!.themeDark;
        case ThemeMode.system:
          return AppLocalizations.of(context)!.themeSystem;
      }
    }

    IconData getThemeIcon(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.light:
          return Icons.light_mode;
        case ThemeMode.dark:
          return Icons.dark_mode;
        case ThemeMode.system:
          return Icons.settings_brightness;
      }
    }

    return Card(
      child: ListTile(
        leading: Icon(getThemeIcon(state.themeMode), color: AppColors.primary),
        title: Text(
          AppLocalizations.of(context)!.theme,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          getThemeLabel(state.themeMode),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: () => _showThemeDialog(context, state),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, SettingsLoaded state) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => BlocBuilder<SettingsCubit, SettingsState>(
        bloc: getIt<SettingsCubit>(),
        builder: (context, modalState) {
          final currentState = modalState is SettingsLoaded
              ? modalState
              : state;
          return Padding(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSizes.spacing16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing8,
                    vertical: AppSizes.spacing8,
                  ),
                  child: Text(
                    AppLocalizations.of(modalContext)!.selectTheme,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.spacing8),
                _buildThemeOption(
                  modalContext,
                  currentState,
                  ThemeMode.light,
                  AppLocalizations.of(modalContext)!.themeLight,
                  AppLocalizations.of(modalContext)!.themeLightDesc,
                  Icons.light_mode,
                ),
                _buildThemeOption(
                  modalContext,
                  currentState,
                  ThemeMode.dark,
                  AppLocalizations.of(modalContext)!.themeDark,
                  AppLocalizations.of(modalContext)!.themeDarkDesc,
                  Icons.dark_mode,
                ),
                _buildThemeOption(
                  modalContext,
                  currentState,
                  ThemeMode.system,
                  AppLocalizations.of(modalContext)!.themeSystem,
                  AppLocalizations.of(modalContext)!.themeSystemDesc,
                  Icons.settings_brightness,
                ),
                const SizedBox(height: AppSizes.spacing16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    SettingsLoaded state,
    ThemeMode mode,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = state.themeMode == mode;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        getIt<SettingsCubit>().updateThemeMode(mode);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spacing12),
        margin: const EdgeInsets.only(bottom: AppSizes.spacing8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(width: AppSizes.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  // Commented out for now - Language switcher removed
  /* Widget _buildLanguageSetting(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context);

    String getCurrentLanguageLabel() {
      switch (currentLocale.languageCode) {
        case 'en':
          return '🇬🇧 ${l10n.english}';
        case 'hi':
          return '🇮🇳 ${l10n.hindi}';
        case 'bn':
          return '🇧🇩 ${l10n.bengali}';
        default:
          return l10n.english;
      }
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.language, color: AppColors.primary),
        title: Text(l10n.language, style: theme.textTheme.titleMedium),
        subtitle: Text(
          getCurrentLanguageLabel(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: () => _showLanguageDialog(context),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSizes.spacing16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing8,
                vertical: AppSizes.spacing8,
              ),
              child: Text(
                l10n.selectLanguage,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spacing8),
            _buildLanguageOption(
              context,
              currentLocale,
              'en',
              l10n.english,
              '🇬🇧',
            ),
            _buildLanguageOption(
              context,
              currentLocale,
              'hi',
              l10n.hindi,
              '🇮🇳',
            ),
            _buildLanguageOption(
              context,
              currentLocale,
              'bn',
              l10n.bengali,
              '🇧🇩',
            ),
            const SizedBox(height: AppSizes.spacing16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    Locale currentLocale,
    String languageCode,
    String title,
    String flag,
  ) {
    final isSelected = currentLocale.languageCode == languageCode;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        myAppKey.currentState?.setLocale(Locale(languageCode));
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spacing12),
        margin: const EdgeInsets.only(bottom: AppSizes.spacing8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: AppSizes.spacing16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : null,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  } */

  // Widget _buildNotificationsSetting(BuildContext context, SettingsLoaded state, ThemeData theme) {
  //   return Card(
  //     child: SwitchListTile(
  //       value: state.notificationsEnabled,
  //       onChanged: (value) async {
  //         if (state.notificationsEnabled == false) {
  //           final notificationService = getIt<NotificationService>();
  //           final isEnabled = await notificationService.requestPermissions();
  //           if (isEnabled) {
  //             getIt<SettingsCubit>().updateNotificationsEnabled(value);
  //           } else {}
  //         }
  //         getIt<SettingsCubit>().updateNotificationsEnabled(value);
  //       },
  //       title: Text('Enable Notifications', style: theme.textTheme.titleMedium),
  //       subtitle: Text('Receive reminders for your medicines', style: theme.textTheme.bodySmall),
  //       secondary: const Icon(Icons.notifications_active, color: AppColors.primary),
  //     ),
  //   );
  // }

  Widget _buildSnoozeDurationSetting(
    BuildContext context,
    SettingsLoaded state,
    ThemeData theme,
  ) {
    String getSnoozeDurationLabel(int duration) {
      final l10n = AppLocalizations.of(context)!;
      if (duration == 60) return l10n.snoozeOneHour;
      return l10n.snoozeMinutes(duration);
    }

    return Card(
      child: ListTile(
        leading: MedifyIcon(Assets.icons.snooze, color: AppColors.primary),
        title: Text(
          AppLocalizations.of(context)!.snoozeDuration,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          getSnoozeDurationLabel(state.snoozeDuration),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: () => _showSnoozeDurationDialog(context, state),
      ),
    );
  }

  void _showSnoozeDurationDialog(BuildContext context, SettingsLoaded state) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => BlocBuilder<SettingsCubit, SettingsState>(
        bloc: getIt<SettingsCubit>(),
        builder: (context, modalState) {
          final currentState = modalState is SettingsLoaded
              ? modalState
              : state;
          return Padding(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSizes.spacing16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing8,
                    vertical: AppSizes.spacing8,
                  ),
                  child: Text(
                    AppLocalizations.of(modalContext)!.selectSnoozeDuration,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.spacing8),
                _buildSnoozeDurationOption(
                  modalContext,
                  currentState,
                  15,
                  AppLocalizations.of(modalContext)!.snoozeMinutes(15),
                  AppLocalizations.of(modalContext)!.snoozeQuick,
                ),
                _buildSnoozeDurationOption(
                  modalContext,
                  currentState,
                  30,
                  AppLocalizations.of(modalContext)!.snoozeMinutes(30),
                  AppLocalizations.of(modalContext)!.snoozeStandard,
                ),
                _buildSnoozeDurationOption(
                  modalContext,
                  currentState,
                  60,
                  AppLocalizations.of(modalContext)!.snoozeOneHour,
                  AppLocalizations.of(modalContext)!.snoozeLong,
                ),
                const SizedBox(height: AppSizes.spacing16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSnoozeDurationOption(
    BuildContext context,
    SettingsLoaded state,
    int duration,
    String title,
    String subtitle,
  ) {
    final isSelected = state.snoozeDuration == duration;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        getIt<SettingsCubit>().updateSnoozeDuration(duration);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spacing12),
        margin: const EdgeInsets.only(bottom: AppSizes.spacing8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            MedifyIcon(
              Assets.icons.time,
              color: isSelected ? AppColors.primary : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(width: AppSizes.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  // COMMENTED OUT FOR UPCOMING RELEASE
  // Widget _buildProfilesCard(BuildContext context, ThemeData theme) {
  //   return Card(
  //     child: ListTile(
  //       leading: const Icon(Icons.people, color: AppColors.primary),
  //       title: Text('Family Profiles', style: theme.textTheme.titleMedium),
  //       subtitle: Text(
  //         'Manage profiles for family members',
  //         style: theme.textTheme.bodySmall,
  //       ),
  //       trailing: const Icon(Icons.chevron_right),
  //       onTap: () {
  //         Navigator.of(context).push(
  //           MaterialPageRoute(builder: (context) => const ProfilesPage()),
  //         );
  //       },
  //     ),
  //   );
  // }

  Widget _buildAchievementsCard(BuildContext context, ThemeData theme) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.emoji_events, color: AppColors.warning),
        title: Text(
          AppLocalizations.of(context)!.achievements,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          AppLocalizations.of(context)!.achievementsDesc,
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => getIt<AppMessenger>().push('/achievements'),
      ),
    );
  }

  // Widget _buildHistoryCard(BuildContext context, ThemeData theme) {
  //   return Card(
  //     child: ListTile(
  //       leading: const Icon(Icons.history, color: AppColors.primary),
  //       title: Text('Medicine History', style: theme.textTheme.titleMedium),
  //       subtitle: Text(
  //         'View past logs and export data',
  //         style: theme.textTheme.bodySmall,
  //       ),
  //       trailing: const Icon(Icons.chevron_right),
  //       onTap: () {
  //         Navigator.of(
  //           context,
  //         ).push(MaterialPageRoute(builder: (context) => const HistoryPage()));
  //       },
  //     ),
  //   );
  // }

  Widget _buildAboutCard(BuildContext context, ThemeData theme) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline, color: AppColors.info),
        title: Text(
          'About ${AppLocalizations.of(context)!.appName}',
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          AppLocalizations.of(context)!.appTagline,
          style: theme.textTheme.bodySmall,
        ),
        onTap: () => _showAboutDialog(context),
      ),
    );
  }

  Widget _buildVersionCard(BuildContext context, ThemeData theme) {
    final systemService = getIt<SystemService>();
    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Assets.icons.medifyIcon.image(width: 32, height: 32),
        ),
        title: Text(
          AppLocalizations.of(context)!.version,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: FutureBuilder(
          future: systemService.getVersionCode(),
          builder: (context, app) {
            return Text('${app.data}', style: theme.textTheme.bodySmall);
          },
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) async {
    final appVersion = await getIt<SystemService>().getVersionCode();
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: AppLocalizations.of(context)!.appName,
      applicationVersion: appVersion,
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Assets.icons.medifyIcon.image(width: 64, height: 64),
      ),
      children: [
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.appTagline,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        Text(AppLocalizations.of(context)!.aboutDialogDesc),
        const SizedBox(height: 16),
        Text(AppLocalizations.of(context)!.copyrightNotice),
      ],
    );
  }

  void _showResetDialog(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: AppLocalizations.of(context)!.resetSettings,
      message: AppLocalizations.of(context)!.resetSettingsConfirm,
      actions: [
        AlertAction(
          title: AppLocalizations.of(context)!.cancel,
          style: AlertActionStyle.cancel,
          onPressed: () {},
        ),
        AlertAction(
          title: AppLocalizations.of(context)!.reset,
          style: AlertActionStyle.destructive,
          onPressed: () {
            getIt<SettingsCubit>().resetSettings();
            getIt<AppMessenger>().show(
              AppLocalizations.of(context)!.settingsResetDone,
            );
          },
        ),
      ],
    );
  }
}
