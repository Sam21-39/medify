import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medify/core/theme/app_theme.dart';
import 'package:medify/app/data/models/medication_model.dart';
import '../controllers/medication_controller.dart';
import 'package:medify/app/routes/app_routes.dart';

class AllMedicationsScreen extends StatefulWidget {
  const AllMedicationsScreen({super.key});

  @override
  State<AllMedicationsScreen> createState() => _AllMedicationsScreenState();
}

class _AllMedicationsScreenState extends State<AllMedicationsScreen> {
  final MedicationController controller = Get.find<MedicationController>();
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final Rx<MedicationStatus?> statusFilter = Rx<MedicationStatus?>(null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medications'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterBottomSheet),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search medications...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    searchQuery.value = '';
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
              ),
              onChanged: (value) => searchQuery.value = value,
            ),
          ),

          // Filter Chips (Active/Paused/Completed) if filter applied
          Obx(() {
            if (statusFilter.value == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
              child: Row(
                children: [
                  InputChip(
                    label: Text(statusFilter.value.toString().split('.').last.capitalizeFirst!),
                    onDeleted: () => statusFilter.value = null,
                    selected: true,
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ],
              ),
            );
          }),

          // Medication List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              var filteredList = controller.medications.toList();

              // Apply Search
              if (searchQuery.value.isNotEmpty) {
                filteredList = filteredList
                    .where(
                      (med) => med.name.toLowerCase().contains(searchQuery.value.toLowerCase()),
                    )
                    .toList();
              }

              // Apply Filter
              if (statusFilter.value != null) {
                filteredList = filteredList
                    .where((med) => med.status == statusFilter.value)
                    .toList();
              }

              if (filteredList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No medications found',
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
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final med = filteredList[index];
                  return _buildMedicationCard(context, med);
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.addMedication),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMedicationCard(BuildContext context, MedicationModel med) {
    final color = med.colorTag != null
        ? Color(int.parse(med.colorTag!, radix: 16))
        : AppTheme.primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: Icon(Icons.medication, color: color),
        ),
        title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${med.dosage} ${med.unit} • ${med.frequency.type.name.capitalizeFirst}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.toNamed(AppRoutes.medicationDetail, arguments: med.id),
      ),
    );
  }

  void _showFilterBottomSheet() {
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
            Text('Filter by Status', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingM),
            Wrap(
              spacing: 8,
              children: MedicationStatus.values.map((status) {
                return FilterChip(
                  label: Text(status.name.capitalizeFirst!),
                  selected: statusFilter.value == status,
                  onSelected: (selected) {
                    statusFilter.value = selected ? status : null;
                    Get.back();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spacingM),
          ],
        ),
      ),
    );
  }
}
