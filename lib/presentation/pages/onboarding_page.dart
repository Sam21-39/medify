import 'package:flutter/material.dart';
import 'package:medify/core/services/permission_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/preferences_service.dart';
import '../../core/di/injection_container.dart';
import '../../gen/assets.gen.dart';
import '../../l10n/app_localizations.dart';
import 'main_navigation_page.dart';

/// Onboarding page with 3 screens
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _completeOnboarding() async {
    final prefsService = getIt<PreferencesService>();
    await prefsService.setFirstLaunchComplete();

    if (!mounted) return;

    // Navigate to main app
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => const MainNavigationPage()));
  }

  Future<void> _requestNotificationPermission() async {
    final notificationService = getIt<NotificationService>();

    final permissionService = getIt<AppPermissionService>();

    if (mounted) {
      final isNotificationEnabled = await permissionService.requestNotificationPermission(
        context: context,
      );
      // Move to next page or complete
      if (_currentPage < 2) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        if (isNotificationEnabled) {
          await notificationService.requestPermissions();
          await _completeOnboarding();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            // if (_currentPage < 2)
            //   Align(
            //     alignment: Alignment.topRight,
            //     child: TextButton(
            //       onPressed: _completeOnboarding,
            //       child: Text(
            //         'Skip',
            //         style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.primary),
            //       ),
            //     ),
            //   )
            // else
            //   const SizedBox(height: 48),

            // Page view
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _buildWelcomePage(theme),
                  _buildFeaturesPage(theme),
                  _buildPermissionsPage(theme),
                ],
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) => _buildPageIndicator(index == _currentPage)),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(AppSizes.spacing24),
              child: _currentPage == 2
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _requestNotificationPermission,
                        child: const Text('Enable Notifications'),
                      ),
                    )
                  : Row(
                      children: [
                        if (_currentPage > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: const Text('Back'),
                            ),
                          ),
                        if (_currentPage > 0) const SizedBox(width: AppSizes.spacing16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Text(
                              _currentPage == 0
                                  ? AppLocalizations.of(context)!.getStarted
                                  : AppLocalizations.of(context)!.next,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App Logo
          ClipOval(
            child: Container(
              width: AppSizes.iconOnboarding,
              height: AppSizes.iconOnboarding,
              padding: const EdgeInsets.all(AppSizes.spacing16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Assets.icons.medifyIcon.image(fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: AppSizes.spacing32),

          // Title
          Text(
            AppLocalizations.of(context)!.onboardingTitle1,
            style: theme.textTheme.displayLarge?.copyWith(color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spacing16),

          // Description
          Text(
            AppLocalizations.of(context)!.onboardingDesc1,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spacing32),

          // Tagline
          Text(
            AppLocalizations.of(context)!.appTagline,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          Text(
            AppLocalizations.of(context)!.onboardingTitle2,
            style: theme.textTheme.displayLarge?.copyWith(color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spacing16),

          // Description
          Text(
            AppLocalizations.of(context)!.onboardingDesc2,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spacing32),

          // Features list
          _buildFeatureItem(
            icon: Icons.notifications_active,
            title: 'Timely Reminders',
            description: 'Get notified at the right time for each medicine',
            theme: theme,
          ),
          const SizedBox(height: AppSizes.spacing24),

          _buildFeatureItem(
            icon: Icons.track_changes,
            title: 'Track Progress',
            description: 'See your daily progress and adherence',
            theme: theme,
          ),
          const SizedBox(height: AppSizes.spacing24),

          _buildFeatureItem(
            icon: Icons.check_circle,
            title: 'Easy to Use',
            description: 'Large text, simple interface, designed for everyone',
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large icon
          Container(
            width: AppSizes.iconOnboarding,
            height: AppSizes.iconOnboarding,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: AppSizes.spacing32),

          // Title
          Text(
            'Enable Notifications',
            style: theme.textTheme.displayLarge?.copyWith(color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spacing16),

          // Description
          Text(
            AppLocalizations.of(context)!.notificationPermissionDesc,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spacing32),

          // Why we need it
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: AppSizes.iconL),
                const SizedBox(width: AppSizes.spacing16),
                Expanded(
                  child: Text(
                    'Notifications are essential for medicine reminders. You can customize them later in settings.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusButton),
          ),
          child: Icon(icon, color: AppColors.primary, size: AppSizes.iconL),
        ),
        const SizedBox(width: AppSizes.spacing16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSizes.spacing4),
              Text(description, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
