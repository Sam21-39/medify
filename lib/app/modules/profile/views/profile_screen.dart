import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medify/core/theme/app_theme.dart';
import 'package:medify/app/modules/auth/controllers/auth_controller.dart';
import 'package:medify/app/routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          children: [
            // User Header
            Obx(() {
              final user = authController.currentUser.value;
              return Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 40, color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    user?.name ?? 'Guest',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              );
            }),
            const SizedBox(height: AppTheme.spacingXL),

            // Menu Items
            _buildProfileItem(
              context,
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () {
                // TODO: Navigate to edit profile
              },
            ),
            _buildProfileItem(
              context,
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {
                // TODO: Navigate to notification settings
              },
            ),
            _buildProfileItem(
              context,
              icon: Icons.lock_outline,
              title: 'Privacy & Security',
              onTap: () {
                // TODO: Navigate to privacy settings
              },
            ),
            _buildProfileItem(
              context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                // TODO: Navigate to help
              },
            ),
            const Divider(height: AppTheme.spacingXL),
            _buildProfileItem(
              context,
              icon: Icons.logout,
              title: 'Log Out',
              textColor: AppTheme.errorColor,
              onTap: () {
                Get.defaultDialog(
                  title: 'Log Out',
                  middleText: 'Are you sure you want to log out?',
                  textConfirm: 'Log Out',
                  textCancel: 'Cancel',
                  confirmTextColor: Colors.white,
                  onConfirm: () {
                    Get.back();
                    authController.logout();
                    Get.offAllNamed(AppRoutes.login);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppTheme.textPrimary),
      title: Text(
        title,
        style: TextStyle(color: textColor ?? AppTheme.textPrimary, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
    );
  }
}
