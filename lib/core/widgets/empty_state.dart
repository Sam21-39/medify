import 'package:flutter/material.dart';

import 'package:medify/core/constants/app_sizes.dart';
import 'package:medify/core/widgets/medify_icon.dart';
import 'package:medify/gen/assets.gen.dart';

/// Empty state widget for displaying when no data is available
class EmptyState extends StatelessWidget {
  final IconData? icon;
  final SvgGenImage? svg;
  final String title;
  final String? message;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon,
    this.svg,
    required this.title,
    this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (svg != null)
              MedifyIcon(
                svg!,
                size: AppSizes.iconXL * 2,
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: 0.5),
              )
            else
              Icon(
                icon,
                size: AppSizes.iconXL * 2,
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: 0.5),
              ),
            const SizedBox(height: AppSizes.paddingL),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSizes.paddingM),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppSizes.paddingXL),
              ElevatedButton(onPressed: onAction, child: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}
