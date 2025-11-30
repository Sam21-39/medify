import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medify/core/theme/app_theme.dart';
import 'package:medify/core/utils/date_time_utils.dart';
import '../controllers/history_controller.dart';
import 'package:medify/app/data/models/dose_log_model.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HistoryController controller = Get.put(HistoryController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: controller.selectedDate.value,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                controller.selectDate(picked);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            color: AppTheme.surfaceColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => controller.selectDate(
                    controller.selectedDate.value.subtract(const Duration(days: 1)),
                  ),
                ),
                Obx(
                  () => Text(
                    DateTimeUtils.formatDateFull(controller.selectedDate.value),
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    if (DateTimeUtils.isToday(controller.selectedDate.value)) return;
                    controller.selectDate(
                      controller.selectedDate.value.add(const Duration(days: 1)),
                    );
                  },
                ),
              ],
            ),
          ),

          // Logs List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.logs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No history for this date',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                itemCount: controller.logs.length,
                itemBuilder: (context, index) {
                  final log = controller.logs[index];
                  return _buildLogCard(context, log);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, DoseLogModel log) {
    Color statusColor;
    IconData statusIcon;

    switch (log.status) {
      case DoseStatus.taken:
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case DoseStatus.skipped:
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.cancel;
        break;
      case DoseStatus.snoozed:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.snooze;
        break;
      case DoseStatus.pending:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(log.medicationName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scheduled: ${DateTimeUtils.formatTime12Hour(log.scheduledTime)}'),
            if (log.actualTime != null)
              Text('Taken: ${DateTimeUtils.formatTime12Hour(log.actualTime!)}'),
            if (log.reason != null)
              Text('Reason: ${log.reason}', style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
