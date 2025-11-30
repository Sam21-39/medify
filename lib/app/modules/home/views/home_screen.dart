import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medify/core/theme/app_theme.dart';
import 'package:medify/app/modules/auth/controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import 'package:medify/app/routes/app_routes.dart';
import 'package:medify/core/utils/date_time_utils.dart';
import 'package:medify/app/modules/medications/controllers/medication_controller.dart';
import 'package:medify/app/data/models/medication_model.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medify',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Obx(
              () => Text(
                DateTimeUtils.formatDateFull(controller.selectedDate.value),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: controller.selectedDate.value,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                controller.selectDate(picked);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Get.find<AuthController>().logout();
              Get.offAllNamed(AppRoutes.login);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar Strip
          _buildCalendarStrip(context),

          // Main Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshData,
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final groupedMedications = controller.groupedMedications;
                final allMedications = controller.dailyMedications;

                if (allMedications.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  children: [
                    // Stats Card
                    _buildStatsCard(context),
                    const SizedBox(height: AppTheme.spacingL),

                    // Next Up Section
                    _buildNextUpSection(context),
                    const SizedBox(height: AppTheme.spacingL),

                    // Time Groups
                    ...TimeGroup.values.map((group) {
                      final medications = groupedMedications[group] ?? [];
                      if (medications.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(context, group),
                          const SizedBox(height: AppTheme.spacingS),
                          ...medications.map((med) => _buildMedicationCard(context, med, group)),
                          const SizedBox(height: AppTheme.spacingM),
                        ],
                      );
                    }),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.addMedication),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    final stats = controller.stats;
    final progress = stats['progress'] as double;
    final pending = stats['pending'] as int;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  pending == 0
                      ? 'All caught up!'
                      : '$pending medication${pending > 1 ? 's' : ''} left',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 6,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextUpSection(BuildContext context) {
    // Find the next upcoming medication
    final allMedications = controller.dailyMedications;
    final now = DateTime.now();

    // Flatten all scheduled times for today
    final List<Map<String, dynamic>> upcomingDoses = [];

    for (var med in allMedications) {
      for (var time in med.times) {
        final scheduledTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        if (scheduledTime.isAfter(now)) {
          upcomingDoses.add({'medication': med, 'time': scheduledTime});
        }
      }
    }

    // Sort by time
    upcomingDoses.sort((a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime));

    if (upcomingDoses.isEmpty) return const SizedBox.shrink();

    final nextDose = upcomingDoses.first;
    final med = nextDose['medication'] as MedicationModel;
    final time = nextDose['time'] as DateTime;
    final timeUntil = time.difference(now);

    String timeString;
    if (timeUntil.inHours > 0) {
      timeString = 'in ${timeUntil.inHours}h ${timeUntil.inMinutes % 60}m';
    } else {
      timeString = 'in ${timeUntil.inMinutes}m';
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next Up',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  timeString,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: med.colorTag != null
                      ? Color(int.parse(med.colorTag!, radix: 16)).withValues(alpha: 0.2)
                      : AppTheme.primaryColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medication,
                  color: med.colorTag != null
                      ? Color(int.parse(med.colorTag!, radix: 16))
                      : AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${med.dosage} ${med.unit} • ${DateTimeUtils.formatTime12Hour(time)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: AppTheme.successColor),
                onPressed: () {
                  Get.find<MedicationController>().markAsTaken(med.id, time);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, TimeGroup group) {
    String title;
    IconData icon;

    switch (group) {
      case TimeGroup.morning:
        title = 'Morning';
        icon = Icons.wb_sunny_outlined;
        break;
      case TimeGroup.afternoon:
        title = 'Afternoon';
        icon = Icons.wb_twilight;
        break;
      case TimeGroup.evening:
        title = 'Evening';
        icon = Icons.nights_stay_outlined;
        break;
      case TimeGroup.night:
        title = 'Night';
        icon = Icons.bedtime_outlined;
        break;
    }

    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: AppTheme.spacingXS),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationCard(BuildContext context, MedicationModel med, TimeGroup group) {
    // Find the specific time for this group
    final time = med.times.firstWhere(
      (t) => DateTimeUtils.getTimeGroup(t.hour) == group,
      orElse: () => med.times.first,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: InkWell(
        onTap: () => _showMedicationActions(context, med, time),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: med.colorTag != null
                      ? Color(int.parse(med.colorTag!, radix: 16)).withValues(alpha: 0.2)
                      : AppTheme.primaryColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medication,
                  color: med.colorTag != null
                      ? Color(int.parse(med.colorTag!, radix: 16))
                      : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          DateTimeUtils.formatTime12Hour(
                            DateTime(2024, 1, 1, time.hour, time.minute),
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${med.dosage} ${med.unit}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Quick Take Button
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: AppTheme.successColor),
                onPressed: () {
                  // Calculate scheduled time for today
                  final now = DateTime.now();
                  final scheduledTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    time.hour,
                    time.minute,
                  );
                  Get.find<MedicationController>().markAsTaken(med.id, scheduledTime);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMedicationActions(BuildContext context, MedicationModel med, MedicationTime time) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusL)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(med.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingM),
            ListTile(
              leading: const Icon(Icons.check_circle, color: AppTheme.successColor),
              title: const Text('Take Now'),
              onTap: () {
                Get.back();
                final now = DateTime.now();
                final scheduledTime = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  time.hour,
                  time.minute,
                );
                Get.find<MedicationController>().markAsTaken(med.id, scheduledTime);
              },
            ),
            ListTile(
              leading: const Icon(Icons.snooze, color: AppTheme.warningColor),
              title: const Text('Snooze'),
              onTap: () {
                Get.back();
                _showSnoozeOptions(context, med, time);
              },
            ),
            ListTile(
              leading: const Icon(Icons.skip_next, color: AppTheme.errorColor),
              title: const Text('Skip'),
              onTap: () {
                Get.back();
                final now = DateTime.now();
                final scheduledTime = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  time.hour,
                  time.minute,
                );
                Get.find<MedicationController>().skipMedication(
                  med.id,
                  scheduledTime,
                  'Skipped by user',
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Details'),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.medicationDetail, arguments: med.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSnoozeOptions(BuildContext context, MedicationModel med, MedicationTime time) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusL)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Snooze for...', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSnoozeButton(context, med, time, 10, '10m'),
                _buildSnoozeButton(context, med, time, 30, '30m'),
                _buildSnoozeButton(context, med, time, 60, '1h'),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
          ],
        ),
      ),
    );
  }

  Widget _buildSnoozeButton(
    BuildContext context,
    MedicationModel med,
    MedicationTime time,
    int minutes,
    String label,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textPrimary,
        side: const BorderSide(color: AppTheme.borderColor),
        elevation: 0,
      ),
      onPressed: () {
        Get.back();
        final now = DateTime.now();
        final scheduledTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        Get.find<MedicationController>().snoozeMedication(
          med.id,
          scheduledTime,
          Duration(minutes: minutes),
        );
      },
      child: Text(label),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      children: [
        _buildStatsCard(context),
        const SizedBox(height: 60),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.medication_outlined,
                size: 64,
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'No medications for this day',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingS),
              ElevatedButton(
                onPressed: () => Get.toNamed(AppRoutes.addMedication),
                child: const Text('Add Medication'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarStrip(BuildContext context) {
    // TODO: Implement a proper horizontal calendar strip
    // For now, just a placeholder or simple row
    return Container(
      height: 80,
      color: AppTheme.surfaceColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14, // 2 weeks
        itemBuilder: (context, index) {
          final date = DateTime.now().subtract(const Duration(days: 3)).add(Duration(days: index));
          return Obx(() {
            final isSelected =
                DateTimeUtils.isToday(date) &&
                    DateTimeUtils.isToday(controller.selectedDate.value) ||
                (date.day == controller.selectedDate.value.day &&
                    date.month == controller.selectedDate.value.month);

            return GestureDetector(
              onTap: () => controller.selectDate(date),
              child: Container(
                width: 60,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected ? null : Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateTimeUtils.formatDateShort(date).split(' ')[0], // Month
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      date.day.toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }
}
