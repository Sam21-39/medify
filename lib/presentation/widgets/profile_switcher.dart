import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/di/injection_container.dart';
import '../../domain/entities/user_profile.dart';
import '../blocs/profile/profile_cubit.dart';
import '../blocs/profile/profile_state.dart';
import '../pages/profiles_page.dart';

/// Widget for quick profile switching with visual indicators
class ProfileSwitcher extends StatelessWidget {
  const ProfileSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    // Try to use existing cubit from context first (if available from main.dart)
    // Otherwise use getIt (which is now LazySingleton, so same instance everywhere)
    try {
      return BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          // Load profiles if not loaded yet
          if (state is ProfileInitial) {
            getIt<ProfileCubit>().loadActiveProfiles();
          }
          return const _ProfileSwitcherContent();
        },
      );
    } catch (e) {
      // If no cubit in context (shouldn't happen since main.dart provides it)
      // Fall back to getIt (LazySingleton ensures same instance)
      return BlocProvider.value(
        value: getIt<ProfileCubit>(),
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is ProfileInitial) {
              getIt<ProfileCubit>().loadActiveProfiles();
            }
            return const _ProfileSwitcherContent();
          },
        ),
      );
    }
  }
}

class _ProfileSwitcherContent extends StatelessWidget {
  const _ProfileSwitcherContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfilesLoaded) {
          return InkWell(
            onTap: () => _showProfileSwitcher(
              context,
              state.profiles,
              state.activeProfile,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingS,
                vertical: 4,
              ),
              child: _buildActiveProfileAvatar(state.activeProfile),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildActiveProfileAvatar(UserProfile? profile) {
    if (profile == null) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: const Center(child: Text('?', style: TextStyle(fontSize: 16))),
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: profile.color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: profile.color, width: 2),
      ),
      child: Center(
        child: Text(
          profile.avatarEmoji ?? '👤',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  void _showProfileSwitcher(
    BuildContext context,
    List<UserProfile> profiles,
    UserProfile? activeProfile,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Row(
                children: [
                  Text(
                    'Switch Profile',
                    style: Theme.of(sheetContext).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilesPage()),
                      );
                    },
                    tooltip: 'Manage Profiles',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Profile list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: profiles.length,
              itemBuilder: (sheetContext, index) {
                final profile = profiles[index];
                final isActive = profile.id == activeProfile?.id;

                return ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: profile.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: profile.color,
                        width: isActive ? 3 : 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        profile.avatarEmoji ?? '👤',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  title: Text(
                    profile.name,
                    style: TextStyle(
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: profile.relationship != null
                      ? Text(profile.relationship!)
                      : null,
                  trailing: isActive
                      ? Icon(Icons.check_circle, color: AppColors.success)
                      : null,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (!isActive && profile.id != null) {
                      // Use context cubit to ensure proper state updates
                      getIt<ProfileCubit>().switchProfile(profile.id!);
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Switched to ${profile.name}\'s profile',
                          ),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                );
              },
            ),

            const Divider(height: 1),

            // Add profile button
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(
                    sheetContext,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(sheetContext).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.add,
                  color: Theme.of(sheetContext).colorScheme.primary,
                ),
              ),
              title: const Text(
                'Add New Profile',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilesPage()),
                );
              },
            ),
            const SizedBox(height: AppSizes.paddingM),
          ],
        ),
      ),
    );
  }
}

/// Compact profile indicator for app bar
class ProfileIndicator extends StatelessWidget {
  final UserProfile? profile;

  const ProfileIndicator({super.key, this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      decoration: BoxDecoration(
        color: profile!.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: profile!.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            profile!.avatarEmoji ?? '👤',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            profile!.name,
            style: TextStyle(
              color: profile!.color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
