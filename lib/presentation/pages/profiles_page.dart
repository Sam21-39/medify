import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/di/injection_container.dart';
import '../../domain/entities/user_profile.dart';
import '../blocs/profile/profile_cubit.dart';
import '../blocs/profile/profile_state.dart';
import 'add_edit_profile_page.dart';

/// Page to display and manage all user profiles
class ProfilesPage extends StatefulWidget {
  const ProfilesPage({super.key});

  @override
  State<ProfilesPage> createState() => _ProfilesPageState();
}

class _ProfilesPageState extends State<ProfilesPage> {
  late final ProfileCubit _profileCubit;

  @override
  void initState() {
    super.initState();
    _profileCubit = getIt<ProfileCubit>();
    _profileCubit.loadProfiles();
  }

  @override
  void dispose() {
    // Don't dispose the cubit as it's managed by GetIt
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // CRITICAL: Must provide cubit to children via BlocProvider.value
    // Otherwise BlocConsumer in _ProfilesPageContent won't have access to it
    return BlocProvider.value(
      value: _profileCubit,
      child: _ProfilesPageContent(
        onRefresh: () => _profileCubit.loadProfiles(),
      ),
    );
  }
}

class _ProfilesPageContent extends StatelessWidget {
  final VoidCallback onRefresh;

  const _ProfilesPageContent({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Profiles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddProfile(context),
            tooltip: 'Add Profile',
          ),
        ],
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is ProfileOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfilesLoaded) {
            if (state.profiles.isEmpty) {
              return _buildEmptyState(context);
            }

            return _buildProfilesList(
              context,
              state.profiles,
              state.activeProfile,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 100,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSizes.paddingL),
            Text(
              'No Profiles Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSizes.paddingM),
            Text(
              'Create profiles for family members to track their medications separately',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSizes.paddingXL),
            FilledButton.icon(
              onPressed: () => _navigateToAddProfile(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilesList(
    BuildContext context,
    List<UserProfile> profiles,
    UserProfile? activeProfile,
  ) {
    return Column(
      children: [
        // Summary card
        _buildSummaryCard(context, profiles, activeProfile),

        // Profiles list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final isActive = profile.id == activeProfile?.id;
              return _buildProfileCard(context, profile, isActive);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    List<UserProfile> profiles,
    UserProfile? activeProfile,
  ) {
    final activeCount = profiles.where((p) => p.isActive).length;

    return Container(
      margin: const EdgeInsets.all(AppSizes.paddingM),
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.group,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: AppSizes.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Family Profiles',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$activeCount active ${activeCount == 1 ? "profile" : "profiles"}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (activeProfile != null) ...[
            const SizedBox(height: AppSizes.paddingM),
            const Divider(),
            const SizedBox(height: AppSizes.paddingM),
            Row(
              children: [
                Text(
                  activeProfile.avatarEmoji ?? '👤',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: AppSizes.paddingM),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Currently Active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      activeProfile.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    UserProfile profile,
    bool isActive,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
      elevation: isActive ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        side: isActive
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showProfileOptions(context, profile, isActive),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: profile.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: profile.color, width: 2),
                ),
                child: Center(
                  child: Text(
                    profile.avatarEmoji ?? '👤',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.paddingL),

              // Profile info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            profile.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (profile.relationship != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.relationship!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: profile.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (profile.age != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${profile.age} years old',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileOptions(
    BuildContext context,
    UserProfile profile,
    bool isActive,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.switch_account),
              title: const Text('Switch to this profile'),
              enabled: !isActive,
              onTap: () {
                Navigator.pop(sheetContext);
                if (!isActive && profile.id != null) {
                  getIt<ProfileCubit>().switchProfile(profile.id!);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit profile'),
              onTap: () {
                Navigator.pop(sheetContext);
                _navigateToEditProfile(context, profile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text(
                'Delete profile',
                style: TextStyle(color: AppColors.error),
              ),
              enabled: !profile.isDefaultProfile,
              onTap: () {
                Navigator.pop(sheetContext);
                if (!profile.isDefaultProfile) {
                  _confirmDeleteProfile(context, profile);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteProfile(BuildContext context, UserProfile profile) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text(
          'Are you sure you want to delete ${profile.name}\'s profile? This will also delete all associated medicines and logs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (profile.id != null) {
                getIt<ProfileCubit>().deleteProfile(profile.id!);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddProfile(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditProfilePage()),
    );
    // Reload profiles after returning
    onRefresh();
  }

  void _navigateToEditProfile(BuildContext context, UserProfile profile) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditProfilePage(profile: profile)),
    );
    // Reload profiles after returning
    onRefresh();
  }
}
