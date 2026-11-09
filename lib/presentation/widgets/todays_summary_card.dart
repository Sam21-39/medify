import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/medicine_log.dart';

/// Card displaying today's medicine schedule summary
class TodaysSummaryCard extends StatelessWidget {
  final List<MedicineLog> todaysLogs;
  final VoidCallback? onTap;

  const TodaysSummaryCard({super.key, required this.todaysLogs, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Calculate progress
    final totalDoses = todaysLogs.length;
    final takenDoses = todaysLogs
        .where((log) => log.status == MedicineLogStatus.taken)
        .length;
    final progress = totalDoses > 0
        ? (takenDoses / totalDoses * 100).round()
        : 0;

    // Find next upcoming dose
    final now = DateTime.now();
    final upcomingLogs =
        todaysLogs
            .where(
              (log) =>
                  log.status == MedicineLogStatus.pending &&
                  log.scheduledTime.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    final nextDose = upcomingLogs.isNotEmpty ? upcomingLogs.first : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(AppSizes.spacing16),
        padding: const EdgeInsets.all(AppSizes.spacing24),
        decoration: BoxDecoration(
          // Gradient background (Teal 500 for light, Teal 400 for dark)
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.primaryLight, AppColors.primary]
                : [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: "Today's Schedule"
            Row(
              children: [
                Icon(
                  Icons.today_outlined,
                  color: Colors.white,
                  size: AppSizes.iconL,
                ),
                const SizedBox(width: AppSizes.spacing8),
                Text(
                  "Today's Schedule",
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing16),

            // Next dose time
            if (nextDose != null) ...[
              Text(
                'Next dose:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: AppSizes.spacing4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.white,
                    size: AppSizes.iconM,
                  ),
                  const SizedBox(width: AppSizes.spacing8),
                  Expanded(
                    child: Text(
                      DateTimeUtils.formatTime(nextDose.scheduledTime),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Icon(
                    progress == 100 ? Icons.check_circle : Icons.info_outline,
                    color: Colors.white,
                    size: AppSizes.iconL,
                  ),
                  const SizedBox(width: AppSizes.spacing8),
                  Expanded(
                    child: Text(
                      progress == 100
                          ? 'All doses taken today! 🎉'
                          : 'No upcoming doses',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSizes.spacing16),

            // Progress: "2 of 3 doses taken"
            Row(
              children: [
                Icon(
                  Icons.medication,
                  color: Colors.white,
                  size: AppSizes.iconM,
                ),
                const SizedBox(width: AppSizes.spacing8),
                Expanded(
                  child: Text(
                    totalDoses > 0
                        ? '$takenDoses of $totalDoses doses taken ($progress%)'
                        : 'No doses scheduled today',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Progress bar
            if (totalDoses > 0) ...[
              const SizedBox(height: AppSizes.spacing8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusInput),
                child: LinearProgressIndicator(
                  value: totalDoses > 0 ? takenDoses / totalDoses : 0,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
