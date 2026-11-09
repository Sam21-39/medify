import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/medicine.dart';

/// Card widget to display medicine information
class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback? onTap;
  final VoidCallback? onToggleActive;
  final VoidCallback? onDelete;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.onTap,
    this.onToggleActive,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and status toggle
              Row(
                children: [
                  // Medicine icon
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingS),
                    decoration: BoxDecoration(
                      color: medicine.isActive
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.textDisabledLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: Icon(
                      Icons.medication,
                      color: medicine.isActive
                          ? AppColors.primary
                          : AppColors.textDisabledLight,
                      size: AppSizes.iconL,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingM),

                  // Medicine name and dosage
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            decoration: medicine.isActive
                                ? null
                                : TextDecoration.lineThrough,
                            color: medicine.isActive
                                ? null
                                : AppColors.textDisabledLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          medicine.dosage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: medicine.isActive
                                ? theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  )
                                : AppColors.textDisabledLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _getIntakeTimingIcon(medicine.intakeTiming),
                              size: 14,
                              color: medicine.isActive
                                  ? AppColors.primary
                                  : AppColors.textDisabledLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              medicine.intakeTiming.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: medicine.isActive
                                    ? AppColors.primary
                                    : AppColors.textDisabledLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        // Stock level indicator
                        if (medicine.currentQuantity != null) ...[
                          const SizedBox(height: 4),
                          _buildStockIndicator(context),
                        ],
                      ],
                    ),
                  ),

                  // Active/Inactive toggle
                  if (onToggleActive != null)
                    IconButton(
                      icon: Icon(
                        medicine.isActive ? Icons.toggle_on : Icons.toggle_off,
                        size: AppSizes.iconL,
                      ),
                      color: medicine.isActive
                          ? AppColors.success
                          : AppColors.textDisabledLight,
                      onPressed: onToggleActive,
                      tooltip: medicine.isActive ? 'Deactivate' : 'Activate',
                    ),
                ],
              ),

              // Reminder times section
              if (medicine.reminderTimes.isNotEmpty) ...[
                const SizedBox(height: AppSizes.paddingM),
                const Divider(height: 1),
                const SizedBox(height: AppSizes.paddingM),

                // Reminder times label
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: AppSizes.iconS,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: AppSizes.paddingXS),
                    Text(
                      'Reminder Times',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingS),

                // Reminder time chips (with overflow protection)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: AppSizes.paddingS,
                      runSpacing: AppSizes.paddingS,
                      children: medicine.reminderTimes.map((seconds) {
                        final time = DateTimeUtils.secondsToDateTime(seconds);
                        final timeString = DateTimeUtils.formatTime(time);
                        final timeOfDay = DateTimeUtils.getTimeOfDayString(
                          time,
                        );

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingM,
                            vertical: AppSizes.paddingS,
                          ),
                          decoration: BoxDecoration(
                            color: medicine.isActive
                                ? AppColors.primaryLight.withValues(alpha: 0.15)
                                : AppColors.textDisabledLight.withValues(
                                    alpha: 0.1,
                                  ),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusXL,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getTimeOfDayIcon(timeOfDay),
                                size: 14,
                                color: medicine.isActive
                                    ? AppColors.primaryDark
                                    : AppColors.textDisabledLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeString,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: medicine.isActive
                                      ? AppColors.primaryDark
                                      : AppColors.textDisabledLight,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],

              // Notes section
              if (medicine.notes != null && medicine.notes!.isNotEmpty) ...[
                const SizedBox(height: AppSizes.paddingM),
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingS),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        size: AppSizes.iconS,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingS),
                      Expanded(
                        child: Text(
                          medicine.notes!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Get icon based on time of day
  IconData _getTimeOfDayIcon(String timeOfDay) {
    switch (timeOfDay) {
      case 'Morning':
        return Icons.wb_sunny;
      case 'Afternoon':
        return Icons.wb_sunny_outlined;
      case 'Evening':
        return Icons.nights_stay;
      case 'Night':
        return Icons.bedtime;
      default:
        return Icons.access_time;
    }
  }

  /// Get icon for intake timing
  IconData _getIntakeTimingIcon(MedicineIntakeTiming timing) {
    switch (timing) {
      case MedicineIntakeTiming.beforeFood:
        return Icons.restaurant_menu;
      case MedicineIntakeTiming.afterFood:
        return Icons.dinner_dining;
      case MedicineIntakeTiming.withFood:
        return Icons.fastfood;
      case MedicineIntakeTiming.empty:
        return Icons.no_meals;
      case MedicineIntakeTiming.beforeSleep:
        return Icons.bedtime;
      case MedicineIntakeTiming.anytime:
        return Icons.schedule;
    }
  }

  /// Build stock level indicator
  Widget _buildStockIndicator(BuildContext context) {
    final theme = Theme.of(context);

    // Determine stock status
    Color stockColor;
    IconData stockIcon;
    String stockText;

    if (medicine.isOutOfStock) {
      stockColor = AppColors.error;
      stockIcon = Icons.error_outline;
      stockText = 'Out of stock';
    } else if (medicine.isLowStock) {
      stockColor = AppColors.warning;
      stockIcon = Icons.warning_amber;
      final days = medicine.daysRemaining;
      stockText = days == 1 ? 'Low stock (1 day)' : 'Low stock ($days days)';
    } else {
      stockColor = AppColors.success;
      stockIcon = Icons.check_circle_outline;
      final days = medicine.daysRemaining;
      stockText = days == null
          ? '${medicine.currentQuantity} doses'
          : days == 1
          ? '${medicine.currentQuantity} doses (1 day)'
          : '${medicine.currentQuantity} doses ($days days)';
    }

    return Row(
      children: [
        Icon(
          stockIcon,
          size: 14,
          color: medicine.isActive ? stockColor : AppColors.textDisabledLight,
        ),
        const SizedBox(width: 4),
        Text(
          stockText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: medicine.isActive ? stockColor : AppColors.textDisabledLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
