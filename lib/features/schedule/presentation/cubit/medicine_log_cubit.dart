import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medify/core/di/injection_container.dart';
import 'package:medify/core/error/failure.dart';
import 'package:medify/core/notifications/notification_service.dart';

import 'package:medify/features/schedule/domain/entities/medicine_log.dart';
import 'package:medify/features/schedule/domain/repositories/medicine_log_repository.dart';
import 'package:medify/features/schedule/data/services/refill_reminder_service.dart';
import 'package:medify/features/achievements/data/services/achievement_service.dart';
import 'package:medify/features/schedule/presentation/cubit/medicine_log_state.dart';

/// Cubit for managing medicine log state
class MedicineLogCubit extends Cubit<MedicineLogState> {
  final MedicineLogRepository _medicineLogRepository;
  final RefillReminderService? _refillReminderService;
  final AchievementService? _achievementService;

  MedicineLogCubit(
    this._medicineLogRepository, [
    this._refillReminderService,
    this._achievementService,
  ]) : super(MedicineLogInitial());

  /// Soft refresh — skip Loading when already loaded (IndexedStack tab races).
  void _emitLoadingIfNeeded() {
    if (state is! MedicineLogLoaded) {
      emit(MedicineLogLoading());
    }
  }

  /// Load today's logs
  Future<void> loadTodayLogs() async {
    try {
      _emitLoadingIfNeeded();
      final logs = await _medicineLogRepository.getTodayLogs();
      emit(MedicineLogLoaded(logs));
    } catch (e) {
      emit(MedicineLogError('Failed to load logs: ${e.toString()}'));
    }
  }

  /// Load logs by medicine ID
  Future<void> loadLogsByMedicineId(int medicineId) async {
    try {
      _emitLoadingIfNeeded();
      final logs = await _medicineLogRepository.getLogsByMedicineId(medicineId);
      emit(MedicineLogLoaded(logs));
    } catch (e) {
      emit(MedicineLogError('Failed to load logs: ${e.toString()}'));
    }
  }

  /// Load logs by date
  Future<void> loadLogsByDate(DateTime date) async {
    try {
      _emitLoadingIfNeeded();
      final logs = await _medicineLogRepository.getLogsByDate(date);
      emit(MedicineLogLoaded(logs));
    } catch (e) {
      emit(MedicineLogError('Failed to load logs: ${e.toString()}'));
    }
  }

  /// Add a new log
  Future<void> addLog(MedicineLog log) async {
    try {
      await _medicineLogRepository.addLog(log);
      emit(const MedicineLogOperationSuccess('Log added successfully'));
      await loadTodayLogs();
    } catch (e) {
      emit(MedicineLogError('Failed to add log: ${e.toString()}'));
    }
  }

  /// Mark log as taken
  Future<void> markAsTaken(int id) async {
    try {
      // The repo lowers stock in the same transaction; the returned log gives the medicine ID.
      final log = (await _medicineLogRepository.markAsTaken(id)).unwrap();
      await getIt<NotificationService>().cancelOccurrence(id);

      await _refillReminderService?.checkMedicine(log.medicineId);

      // Check for new achievements
      if (_achievementService != null) {
        await _achievementService.checkAndAwardAchievements();
      }

      emit(MedicineLogOperationSuccess('Marked as taken', undoId: id));
      await loadTodayLogs();
    } catch (e) {
      emit(MedicineLogError('Failed to mark as taken: ${e.toString()}'));
    }
  }

  /// Mark log as skipped, with an optional preset reason key
  Future<void> markAsSkipped(int id, {String? reason}) async {
    try {
      (await _medicineLogRepository.markAsSkipped(id, reason: reason)).unwrap();
      await getIt<NotificationService>().cancelOccurrence(id);
      emit(MedicineLogOperationSuccess('Marked as skipped', undoId: id));
      await loadTodayLogs();
    } catch (e) {
      emit(MedicineLogError('Failed to mark as skipped: ${e.toString()}'));
    }
  }

  /// Snooze log
  Future<void> snoozeLog(int id, int minutes) async {
    try {
      await getIt<NotificationService>().snooze(id, minutes);
      emit(MedicineLogOperationSuccess('Snoozed for $minutes minutes'));
      await loadTodayLogs();
    } catch (e) {
      emit(MedicineLogError('Failed to snooze: ${e.toString()}'));
    }
  }

  /// Undo a Taken or Skipped back to scheduled, and reschedule its reminders
  Future<void> undo(int id) async {
    try {
      (await _medicineLogRepository.revertToScheduled(id)).unwrap();
      await getIt<NotificationService>().rescheduleUpcoming();
      await loadTodayLogs();
    } catch (e) {
      emit(MedicineLogError('Failed to undo: ${e.toString()}'));
    }
  }

  /// Load overdue logs
  Future<void> loadOverdueLogs() async {
    try {
      _emitLoadingIfNeeded();
      final logs = await _medicineLogRepository.getOverdueLogs();
      emit(MedicineLogLoaded(logs));
    } catch (e) {
      emit(MedicineLogError('Failed to load overdue logs: ${e.toString()}'));
    }
  }

  /// Load pending logs
  Future<void> loadPendingLogs() async {
    try {
      _emitLoadingIfNeeded();
      final logs = await _medicineLogRepository.getPendingLogs();
      emit(MedicineLogLoaded(logs));
    } catch (e) {
      emit(MedicineLogError('Failed to load pending logs: ${e.toString()}'));
    }
  }

  /// Watch today's logs stream
  void watchTodayLogs() {
    _medicineLogRepository.watchTodayLogs().listen(
      (logs) {
        emit(MedicineLogLoaded(logs));
      },
      onError: (error) {
        emit(MedicineLogError('Failed to watch logs: ${error.toString()}'));
      },
    );
  }
}
