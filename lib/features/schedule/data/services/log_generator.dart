import 'package:medify/features/medicines/domain/entities/medicine.dart';
import 'package:medify/features/schedule/domain/entities/medicine_log.dart';
import 'package:medify/core/utils/date_time_utils.dart';

/// Utility class to generate medicine logs
class LogGenerator {
  LogGenerator._();

  /// Generate today's logs for a medicine
  static bool scheduledOn(Medicine medicine, DateTime date) {
    if (medicine.endDate != null &&
        DateTimeUtils.getStartOfDay(date)
            .isAfter(DateTimeUtils.getStartOfDay(medicine.endDate!))) {
      return false;
    }
    if (medicine.daysOfWeek.isEmpty) return true;
    return medicine.daysOfWeek.contains(date.weekday);
  }

  static List<MedicineLog> generateTodayLogs(Medicine medicine) {
    final now = DateTime.now();
    if (!scheduledOn(medicine, now)) return [];
    final logs = <MedicineLog>[];

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
    if (!scheduledOn(medicine, date)) return [];
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
