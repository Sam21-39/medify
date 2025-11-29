import 'package:get/get.dart';
import 'package:medify/app/modules/medications/controllers/medication_controller.dart';
import 'package:medify/app/data/models/medication_model.dart';

import 'package:medify/core/utils/date_time_utils.dart';

class HomeController extends GetxController {
  final MedicationController _medicationController = Get.put(MedicationController());

  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Refresh data when date changes
    ever(selectedDate, (_) => refreshData());
  }

  // Computed list of medications for the selected date
  List<MedicationModel> get dailyMedications {
    // TODO: Implement proper frequency checking based on selectedDate
    // For now, we assume all active medications are for every day
    // In a real app, we'd check:
    // 1. Start date <= selected date
    // 2. End date >= selected date (if exists)
    // 3. Frequency matches (daily, specific days, interval)

    return _medicationController.medications
        .where((m) => m.status == MedicationStatus.active)
        .toList();
  }

  // Group medications by time of day
  Map<TimeGroup, List<MedicationModel>> get groupedMedications {
    final medications = dailyMedications;
    final Map<TimeGroup, List<MedicationModel>> groups = {
      TimeGroup.morning: [],
      TimeGroup.afternoon: [],
      TimeGroup.evening: [],
      TimeGroup.night: [],
    };

    for (var med in medications) {
      for (var time in med.times) {
        final group = DateTimeUtils.getTimeGroup(time.hour);
        // Create a copy of medication for this specific time slot
        // This is important because one medication might appear in multiple time slots
        groups[group]?.add(med);
      }
    }

    // Sort each group by time
    groups.forEach((key, list) {
      list.sort((a, b) {
        // Find the time in this group for medication A
        final timeA = a.times.firstWhere(
          (t) => DateTimeUtils.getTimeGroup(t.hour) == key,
          orElse: () => a.times.first,
        );

        // Find the time in this group for medication B
        final timeB = b.times.firstWhere(
          (t) => DateTimeUtils.getTimeGroup(t.hour) == key,
          orElse: () => b.times.first,
        );

        int compareHour = timeA.hour.compareTo(timeB.hour);
        if (compareHour != 0) return compareHour;
        return timeA.minute.compareTo(timeB.minute);
      });
    });

    return groups;
  }

  // Quick Stats
  Map<String, dynamic> get stats {
    final total = dailyMedications.length; // This is a simplification. Should be total *doses*
    // TODO: Calculate actual taken/skipped based on DoseLogs
    const taken = 0;
    const skipped = 0;

    return {
      'total': total,
      'taken': taken,
      'skipped': skipped,
      'pending': total - taken - skipped,
      'progress': total == 0 ? 0.0 : taken / total,
    };
  }

  Future<void> refreshData() async {
    isLoading.value = true;
    await _medicationController.loadMedications();
    // TODO: Load dose logs for selected date
    await Future.delayed(const Duration(milliseconds: 500)); // UI smooth
    isLoading.value = false;
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
  }
}
