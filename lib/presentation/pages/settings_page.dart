import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medify/core/services/system_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/di/injection_container.dart';
// import '../../core/services/notification_service.dart';
import '../../gen/assets.gen.dart';
import '../../l10n/app_localizations.dart';
import '../blocs/settings/settings_cubit.dart';
import '../blocs/settings/settings_state.dart';
import 'achievements_page.dart';
// COMMENTED OUT FOR UPCOMING RELEASE
// import 'profiles_page.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        bloc: getIt<SettingsCubit>(),
        builder: (context, state) {
          if (state is SettingsLoaded) {
            return ListView(
              padding: const EdgeInsets.all(AppSizes.spacing16),
              children: [
                // App Section
                _buildSectionHeader('App', theme),
                _buildThemeSetting(context, state, theme),

                // const SizedBox(height: AppSizes.spacing8),
                // _buildLanguageSetting(context, theme), // Commented out for now
                const SizedBox(height: AppSizes.spacing24),

                // Notifications Section
                _buildSectionHeader('Notifications', theme),
                // _buildNotificationsSetting(context, state, theme),
                const SizedBox(height: AppSizes.spacing8),
                _buildSnoozeDurationSetting(context, state, theme),

                const SizedBox(height: AppSizes.spacing24),

                // About Section
                _buildSectionHeader('About', theme),
                // COMMENTED OUT FOR UPCOMING RELEASE
                // _buildProfilesCard(context, theme),
                // const SizedBox(height: AppSizes.spacing8),
                _buildAchievementsCard(context, theme),
                const SizedBox(height: AppSizes.spacing8),
                // _buildHistoryCard(context, theme),
                // const SizedBox(height: AppSizes.spacing8),
                _buildAboutCard(context, theme),
                const SizedBox(height: AppSizes.spacing8),
                _buildVersionCard(theme),

                const SizedBox(height: AppSizes.spacing24),

                // Reset Button
                Center(
                  child: TextButton.icon(
                    onPressed: () => _showResetDialog(context),
                    icon: const Icon(Icons.restore, color: AppColors.error),
                    label: const Text(
                      'Reset All Settings',
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
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSizes.spacing8, bottom: AppSizes.spacing8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildThemeSetting(BuildContext context, SettingsLoaded state, ThemeData theme) {
    String getThemeLabel(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.light:
          return 'Light';
        case ThemeMode.dark:
          return 'Dark';
        case ThemeMode.system:
          return 'System';
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
        title: Text('Theme', style: theme.textTheme.titleMedium),
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
          final currentState = modalState is SettingsLoaded ? modalState : state;
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
                    'Select Theme',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: AppSizes.spacing8),
                _buildThemeOption(
                  modalContext,
                  currentState,
                  ThemeMode.light,
                  'Light',
                  'Bright and clean',
                  Icons.light_mode,
                ),
                _buildThemeOption(
                  modalContext,
                  currentState,
                  ThemeMode.dark,
                  'Dark',
                  'Easy on the eyes',
                  Icons.dark_mode,
                ),
                _buildThemeOption(
                  modalContext,
                  currentState,
                  ThemeMode.system,
                  'System',
                  'Follow device settings',
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
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey[600], size: 28),
            const SizedBox(width: AppSizes.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
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
              ? AppColors.primary.withOpacity(0.1)
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

  Widget _buildSnoozeDurationSetting(BuildContext context, SettingsLoaded state, ThemeData theme) {
    String getSnoozeDurationLabel(int duration) {
      if (duration == 15) return '15 minutes';
      if (duration == 30) return '30 minutes';
      if (duration == 60) return '1 hour';
      return '$duration minutes';
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.snooze, color: AppColors.primary),
        title: Text('Snooze Duration', style: theme.textTheme.titleMedium),
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
          final currentState = modalState is SettingsLoaded ? modalState : state;
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
                    'Select Snooze Duration',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: AppSizes.spacing8),
                _buildSnoozeDurationOption(
                  modalContext,
                  currentState,
                  15,
                  '15 minutes',
                  'Quick reminder',
                ),
                _buildSnoozeDurationOption(
                  modalContext,
                  currentState,
                  30,
                  '30 minutes',
                  'Standard delay',
                ),
                _buildSnoozeDurationOption(
                  modalContext,
                  currentState,
                  60,
                  '1 hour',
                  'Longer break',
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
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(Icons.timer, color: isSelected ? AppColors.primary : Colors.grey[600], size: 28),
            const SizedBox(width: AppSizes.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
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
        title: Text('Achievements', style: theme.textTheme.titleMedium),
        subtitle: Text('View your unlocked badges and progress', style: theme.textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const AchievementsPage()));
        },
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
        subtitle: Text(AppLocalizations.of(context)!.appTagline, style: theme.textTheme.bodySmall),
        onTap: () => _showAboutDialog(context),
      ),
    );
  }

  Widget _buildVersionCard(ThemeData theme) {
    final systemService = getIt<SystemService>();
    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Assets.icons.medifyIcon.image(width: 32, height: 32),
        ),
        title: Text('Version', style: theme.textTheme.titleMedium),
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
        Text(AppLocalizations.of(context)!.appTagline, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        Text(AppLocalizations.of(context)!.aboutDialogDesc),
        const SizedBox(height: 16),
        Text(AppLocalizations.of(context)!.copyrightNotice),
      ],
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              getIt<SettingsCubit>().resetSettings();
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Settings reset to default')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
