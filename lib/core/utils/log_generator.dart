import '../../domain/entities/medicine.dart';
import '../../domain/entities/medicine_log.dart';
import 'date_time_utils.dart';

/// Utility class to generate medicine logs
class LogGenerator {
  LogGenerator._();

  /// Generate today's logs for a medicine
  static List<MedicineLog> generateTodayLogs(Medicine medicine) {
    final logs = <MedicineLog>[];
    final now = DateTime.now();

    for (final seconds in medicine.reminderTimes) {
      final scheduledTime = DateTimeUtils.secondsToDateTime(seconds);

      logs.add(
        MedicineLog(
          profileId: medicine.profileId,
          medicineId: medicine.id!,
          scheduledTime: scheduledTime,
          status: MedicineLogStatus.pending,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    return logs;
  }

  /// Generate logs for a specific date
  static List<MedicineLog> generateLogsForDate(
    Medicine medicine,
    DateTime date,
  ) {
    final logs = <MedicineLog>[];
    final startOfDay = DateTimeUtils.getStartOfDay(date);

    for (final seconds in medicine.reminderTimes) {
      final time = Duration(seconds: seconds);
      final scheduledTime = startOfDay.add(time);

      logs.add(
        MedicineLog(
          profileId: medicine.profileId,
          medicineId: medicine.id!,
          scheduledTime: scheduledTime,
          status: MedicineLogStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    return logs;
  }

  /// Generate logs for a date range
  static List<MedicineLog> generateLogsForRange(
    Medicine medicine,
    DateTime startDate,
    DateTime endDate,
  ) {
    final logs = <MedicineLog>[];
    var currentDate = DateTimeUtils.getStartOfDay(startDate);
    final end = DateTimeUtils.getStartOfDay(endDate);

    while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
      logs.addAll(generateLogsForDate(medicine, currentDate));
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return logs;
  }
}
