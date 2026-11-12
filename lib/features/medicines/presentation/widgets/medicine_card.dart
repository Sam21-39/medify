import 'package:flutter/material.dart';
import 'package:medify/core/constants/app_colors.dart';
import 'package:medify/core/constants/app_sizes.dart';
import 'package:medify/core/di/injection_container.dart';
import 'package:medify/core/ui/app_messenger.dart';
import 'package:medify/core/utils/date_time_utils.dart';
import 'package:medify/core/widgets/medify_icon.dart';
import 'package:medify/features/medicines/domain/entities/medicine.dart';
import 'package:medify/features/medicines/presentation/cubit/medicine_cubit.dart';
import 'package:medify/features/schedule/data/services/refill_reminder_service.dart';
import 'package:medify/gen/assets.gen.dart';
import 'package:medify/l10n/app_localizations.dart';

/// Asks for the quantity now in stock and saves it as a refill.
Future<void> showRefillDialog(BuildContext context, Medicine medicine) async {
  final l10n = AppLocalizations.of(context)!;
  final total = medicine.totalQuantity;
  final controller = TextEditingController(
    text: total == null
        ? ''
        : total == total.toInt()
        ? total.toInt().toString()
        : total.toString(),
  );
  String? error;
  final quantity = await showDialog<double>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(l10n.refillDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.refillQuantityLabel,
            suffixText: medicine.medicineType.unit,
            errorText: error,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value == null || value < 0) {
                setDialogState(() => error = l10n.refillInvalidQuantity);
                return;
              }
              Navigator.pop(dialogContext, value);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  if (quantity == null) return;

  final ok = await getIt<RefillReminderService>().refillMedicine(
    medicine.id!,
    newQuantity: quantity,
  );
  await getIt<MedicineCubit>().loadMedicines();
  getIt<AppMessenger>().show(
    ok ? l10n.refillSaved : l10n.refillFailed,
    error: !ok,
  );
}

/// Asks why the medicine is stopped (optional). Null when cancelled.
Future<({String? reason})?> showStopMedicineDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final reasons = {
    'course_finished': l10n.stopReasonCourseFinished,
    'doctor_stopped': l10n.stopReasonDoctorStopped,
    'side_effects': l10n.stopReasonSideEffects,
    'other': l10n.stopReasonOther,
  };
  return showDialog<({String? reason})>(
    context: context,
    builder: (dialogContext) {
      String? selected;
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.stopMedicineTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.stopMedicineBody),
              const SizedBox(height: AppSizes.paddingM),
              Text(l10n.stopReasonTitle),
              const SizedBox(height: AppSizes.paddingS),
              Wrap(
                spacing: AppSizes.paddingS,
                runSpacing: AppSizes.paddingS,
                children: [
                  for (final entry in reasons.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: selected == entry.key,
                      onSelected: (_) =>
                          setDialogState(() => selected = entry.key),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, (reason: selected)),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text(l10n.stopMedicineButton),
            ),
          ],
        ),
      );
    },
  );
}

/// Bundled icon for each medicine type.
extension MedicineTypeIcon on MedicineType {
  SvgGenImage get icon => switch (this) {
    MedicineType.tablet => Assets.icons.tablets,
    MedicineType.capsule => Assets.icons.capsule,
    MedicineType.syrup => Assets.icons.drop,
    MedicineType.drops => Assets.icons.drop,
    MedicineType.injection => Assets.icons.injection,
    MedicineType.inhaler => Assets.icons.otherMedicine,
    MedicineType.ointment => Assets.icons.ointment,
    MedicineType.patch => Assets.icons.pills,
    MedicineType.other => Assets.icons.otherMedicine,
  };
}

/// Card widget to display medicine information
class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback? onTap;
  final VoidCallback onToggleActive;
  final VoidCallback onStop;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.onTap,
    required this.onToggleActive,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.45)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
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
                    child: MedifyIcon(
                      medicine.medicineType.icon,
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
                          Row(
                            children: [
                              Expanded(child: _buildStockIndicator(context)),
                              TextButton(
                                onPressed: () =>
                                    showRefillDialog(context, medicine),
                                child: Text(
                                  AppLocalizations.of(context)!.refillButton,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Stopped label, or the pause / stop menu
                  if (medicine.isStopped)
                    Chip(
                      label: Text(AppLocalizations.of(context)!.stoppedLabel),
                      visualDensity: VisualDensity.compact,
                    )
                  else
                    PopupMenuButton<String>(
                      onSelected: (value) =>
                          value == 'stop' ? onStop() : onToggleActive(),
                      itemBuilder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return [
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(
                              medicine.isActive
                                  ? l10n.pauseMedicine
                                  : l10n.resumeMedicine,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'stop',
                            child: Text(l10n.stopMedicine),
                          ),
                        ];
                      },
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
                    MedifyIcon(
                      Assets.icons.time,
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
