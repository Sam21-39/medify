import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medify/core/theme/app_theme.dart';
import '../controllers/medication_controller.dart';

import 'package:medify/app/routes/app_routes.dart';

class MedicationDetailScreen extends GetView<MedicationController> {
  const MedicationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String medicationId = Get.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit screen
              Get.toNamed(AppRoutes.editMedication, arguments: medicationId);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, medicationId),
          ),
        ],
      ),
      body: Obx(() {
        final medication = controller.medications.firstWhereOrNull((m) => m.id == medicationId);

        if (medication == null) {
          return const Center(child: Text('Medication not found'));
        }

        final color = medication.colorTag != null
            ? Color(int.parse(medication.colorTag!, radix: 16))
            : AppTheme.primaryColor;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.medication, size: 32, color: color),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medication.name,
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${medication.dosage} ${medication.unit}',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Schedule Section
              _buildSectionHeader(context, 'Schedule'),
              _buildInfoRow(
                context,
                Icons.repeat,
                'Frequency',
                medication.frequency.type.toString().split('.').last.capitalizeFirst!,
              ),
              _buildInfoRow(
                context,
                Icons.access_time,
                'Reminder Times',
                medication.times.map((t) => t.toTimeString()).join(', '),
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Instructions Section
              if (medication.instructions != null && medication.instructions!.isNotEmpty) ...[
                _buildSectionHeader(context, 'Instructions'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Text(
                    medication.instructions!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
              ],

              // Inventory Section
              _buildSectionHeader(context, 'Inventory'),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      'Current Quantity',
                      '${medication.quantity ?? 0}',
                      Icons.inventory_2,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      'Refill Alert',
                      'Below ${medication.refillThreshold ?? 0}',
                      Icons.notification_important,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXL),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Take next scheduled dose
                    // For simplicity, we assume the next dose is the next occurrence of any scheduled time
                    // In a real app, we'd find the closest future scheduled time
                    final now = DateTime.now();
                    // Just use current time as scheduled time for "Take Now" from details
                    controller.markAsTaken(medication.id, now);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Take Dose Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: AppTheme.spacingS),
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Medication?'),
        content: const Text(
          'Are you sure you want to delete this medication? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              controller.deleteMedication(id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
