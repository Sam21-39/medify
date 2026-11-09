import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermissionService {
  /// Main method to handle the complete permission flow
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestNotificationPermission({
    required BuildContext context,
    bool showDialog = true,
    String dialogTitle = 'Enable Notifications',
    String dialogDescription =
        'Please allow notifications to receive timely medicine reminders and important alerts.',
    bool isRetry = false,
  }) async {
    // Check if already granted
    if (await _isPermissionGranted()) {
      return true;
    }
    if (!context.mounted) return false;
    // Show permission dialog if requested
    if (showDialog) {
      final userAgreed = await _showPermissionDialog(
        context: context,
        title: dialogTitle,
        description: dialogDescription,
        isRetry: isRetry,
      );

      if (!userAgreed) {
        return false;
      }
    }
    if (!context.mounted) return false;
    // Request system permission
    return await _requestSystemPermission(context, isRetry);
  }

  /// Check current permission status
  Future<bool> checkPermissionStatus() async {
    return await _isPermissionGranted();
  }

  /// Open app settings for manual permission enable
  Future<void> openSettings() async {
    await openAppSettings();
  }

  // Private methods
  Future<bool> _isPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // Future<bool> _isPermissionPermanentlyDenied() async {
  //   final status = await Permission.notification.status;
  //   return status.isPermanentlyDenied;
  // }

  Future<bool> _showPermissionDialog({
    required BuildContext context,
    required String title,
    required String description,
    required bool isRetry,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PermissionDialog(
        title: title,
        description: description,
        isRetry: isRetry,
        onDeny: () => Navigator.of(context).pop(false),
        onAllow: () => Navigator.of(context).pop(true),
      ),
    );

    return result ?? false;
  }

  Future<bool> _requestSystemPermission(BuildContext context, bool isRetry) async {
    final status = await Permission.notification.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      // Show settings guidance for permanently denied case
      if (!context.mounted) return false;
      await _showSettingsDialog(context);
      return false;
    }

    // For simple denial, show retry option if this wasn't already a retry
    if (!isRetry) {
      if (!context.mounted) return false;
      await _showRetryPrompt(context);
    }

    return false;
  }

  Future<void> _showSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Notification permission is permanently denied. '
          'Please enable it in your device settings to receive medicine reminders.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRetryPrompt(BuildContext context) async {
    // You can show a snackbar or quick dialog here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Permission denied. Medicine reminders will not work.'),
        action: SnackBarAction(
          label: 'RETRY',
          onPressed: () {
            // Retry the permission flow
            requestNotificationPermission(
              context: context,
              isRetry: true,
              dialogTitle: 'Reminders Required',
              dialogDescription:
                  'Medicine reminders are essential for your treatment. Please enable notifications.',
            );
          },
        ),
      ),
    );
  }
}

// Internal dialog widget
class _PermissionDialog extends StatelessWidget {
  final String title;
  final String description;
  final bool isRetry;
  final VoidCallback onAllow;
  final VoidCallback onDeny;

  const _PermissionDialog({
    required this.title,
    required this.description,
    required this.isRetry,
    required this.onAllow,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(
              Icons.notifications_active_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                // Deny button - only show in retry mode
                if (isRetry) ...[
                  Expanded(
                    child: OutlinedButton(onPressed: onDeny, child: const Text('Not Now')),
                  ),
                  const SizedBox(width: 12),
                ],

                // Allow button
                Expanded(
                  child: FilledButton(onPressed: onAllow, child: const Text('Allow')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
