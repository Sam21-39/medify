import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/medicine_log.dart';

/// Card widget to display a medicine log (scheduled reminder)
class MedicineLogCard extends StatefulWidget {
  final Medicine medicine;
  final MedicineLog log;
  final VoidCallback? onTaken;
  final VoidCallback? onSkip;
  final Function(int minutes)? onSnooze;

  const MedicineLogCard({
    super.key,
    required this.medicine,
    required this.log,
    this.onTaken,
    this.onSkip,
    this.onSnooze,
  });

  @override
  State<MedicineLogCard> createState() => _MedicineLogCardState();
}

class _MedicineLogCardState extends State<MedicineLogCard> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(widget.log.status);
    final statusIcon = _getStatusIcon(widget.log.status);
    final isOverdue = widget.log.isOverdue;
    final isPending = widget.log.status == MedicineLogStatus.pending;

    return Stack(
      alignment: Alignment.center,
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
          elevation: isPending ? AppSizes.elevationM : AppSizes.elevationS,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with time and status
                Row(
                  children: [
                    // Time icon and scheduled time
                    Container(
                      padding: const EdgeInsets.all(AppSizes.paddingS),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            color: statusColor,
                            size: AppSizes.iconM,
                          ),
                          const SizedBox(width: AppSizes.paddingXS),
                          Text(
                            DateTimeUtils.formatTime(widget.log.scheduledTime),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingM),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingM,
                        vertical: AppSizes.paddingXS,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusText(widget.log.status),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingM),

                // Overdue indicator
                if (isOverdue && isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingS,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: Text(
                      'OVERDUE',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSizes.paddingS),
                // Medicine details
                Row(
                  children: [
                    Icon(
                      Icons.medication,
                      color: theme.colorScheme.primary,
                      size: AppSizes.iconL,
                    ),
                    const SizedBox(width: AppSizes.paddingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.medicine.name,
                            style: theme.textTheme.titleLarge,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.medicine.dosage,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Show taken time if taken
                if (widget.log.status == MedicineLogStatus.taken &&
                    widget.log.takenTime != null) ...[
                  const SizedBox(height: AppSizes.paddingS),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingS),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Taken at ${DateTimeUtils.formatTime(widget.log.takenTime!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Notes
                if (widget.medicine.notes != null &&
                    widget.medicine.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.paddingS),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.medicine.notes!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Action buttons for pending status
                if (isPending) ...[
                  const SizedBox(height: AppSizes.paddingM),
                  Row(
                    children: [
                      // Mark as Taken button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _confettiController.play(); // Trigger confetti
                            _showSuccessAnimation(context);
                            widget.onTaken?.call();
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Taken'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.paddingS,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingS),

                      // Snooze button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _showSnoozeOptions(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.paddingS,
                            ),
                          ),
                          child: const Icon(Icons.snooze, size: 18),
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingS),

                      // Skip button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            widget.onSkip?.call();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.paddingS,
                            ),
                          ),
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        // Confetti overlay
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -pi / 2, // Blast upwards
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            maxBlastForce: 20,
            minBlastForce: 10,
            gravity: 0.3,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
          ),
        ),
      ],
    );
  }

  /// Show snooze options bottom sheet
  void _showSnoozeOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Text(
                'Snooze for:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.snooze),
              title: const Text('15 minutes'),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                widget.onSnooze?.call(15);
              },
            ),
            ListTile(
              leading: const Icon(Icons.snooze),
              title: const Text('30 minutes'),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                widget.onSnooze?.call(30);
              },
            ),
            ListTile(
              leading: const Icon(Icons.snooze),
              title: const Text('1 hour'),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                widget.onSnooze?.call(60);
              },
            ),
            const SizedBox(height: AppSizes.paddingS),
          ],
        ),
      ),
    );
  }

  /// Show success animation
  void _showSuccessAnimation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (context) {
        // Auto-dismiss after 600ms
        Future.delayed(const Duration(milliseconds: 600), () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });

        return Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Get color based on status
  Color _getStatusColor(MedicineLogStatus status) {
    switch (status) {
      case MedicineLogStatus.taken:
        return AppColors.success;
      case MedicineLogStatus.pending:
        return AppColors.warning;
      case MedicineLogStatus.missed:
        return AppColors.error;
      case MedicineLogStatus.skipped:
        return AppColors.textDisabledLight;
      case MedicineLogStatus.snoozed:
        return AppColors.info;
    }
  }

  /// Get icon based on status
  IconData _getStatusIcon(MedicineLogStatus status) {
    switch (status) {
      case MedicineLogStatus.taken:
        return Icons.check_circle;
      case MedicineLogStatus.pending:
        return Icons.pending;
      case MedicineLogStatus.missed:
        return Icons.error;
      case MedicineLogStatus.skipped:
        return Icons.cancel;
      case MedicineLogStatus.snoozed:
        return Icons.snooze;
    }
  }

  /// Get text based on status
  String _getStatusText(MedicineLogStatus status) {
    switch (status) {
      case MedicineLogStatus.taken:
        return 'Taken';
      case MedicineLogStatus.pending:
        return 'Pending';
      case MedicineLogStatus.missed:
        return 'Missed';
      case MedicineLogStatus.skipped:
        return 'Skipped';
      case MedicineLogStatus.snoozed:
        return 'Snoozed';
    }
  }
}
