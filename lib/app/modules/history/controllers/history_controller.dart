import 'package:get/get.dart';
import 'package:medify/app/data/models/dose_log_model.dart';
import 'package:medify/app/data/providers/database_helper.dart';

class HistoryController extends GetxController {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  final RxList<DoseLogModel> logs = <DoseLogModel>[].obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadLogsForDate(selectedDate.value);
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    loadLogsForDate(date);
  }

  Future<void> loadLogsForDate(DateTime date) async {
    isLoading.value = true;
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final fetchedLogs = await _databaseHelper.getDoseLogsForDateRange(start, end);
      logs.assignAll(fetchedLogs);
    } catch (e) {
      print('Error loading logs: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
