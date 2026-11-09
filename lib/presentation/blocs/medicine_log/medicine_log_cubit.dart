import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/medicine_log.dart';
import '../../../domain/repositories/medicine_log_repository.dart';
import '../../../core/services/refill_reminder_service.dart';
import '../../../core/services/achievement_service.dart';
import 'medicine_log_state.dart';

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

  /// Load today's logs
  Future<void> loadTodayLogs() async {
    try {
      emit(MedicineLogLoading());
      final logs = await _medicineLogRepository.getTodayLogs();
      emit(MedicineLogLoaded(logs));
    } catch (e) {
      emit(MedicineLogError('Failed to load logs: ${e.toString()}'));
    }
  }

  /// Load logs by medicine ID
  Future<void> loadLogsByMedicineId(int medicineId) async {
    try {
      emit(MedicineLogLoading());
      final logs = await _medicineLogRepository.getLogsByMedicineId(medicineId);
      emit(MedicineLogLoaded(logs));
    } catch (e) {
      emit(MedicineLogError('Failed to load logs: ${e.toString()}'));
    }
  }

  /// Load logs by date
  Future<void> loadLogsByDate(DateTime date) async {
    try {
      emit(MedicineLogLoading());
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
      // Get the log to find medicine ID
      final log = await _medicineLogRepository.getLogById(id);

      // Mark as taken
      await _medicineLogRepository.markAsTaken(id);

      // Decrement medicine quantity if refill service is available
      if (_refillReminderService != null && log != null) {
        await _refillReminderService.decrementMedicineQuantity(log.medicineId);
      }

      // Check for new achievements
      if (_achievementService != null) {
        await _achievementService.checkAndAwardAchievements();
      }

      emit(const MedicineLogOperationSuccess('Marked as taken'));
      await loadTodayLogs();
    } catch (e) {
      emit(MedicineLogError('Failed to mark as taken: ${e.toString()}'));
    }
  }

  /// Mark log as skipped
  Future<void> markAsSkipped(int id) async {
    try {
      await _medicineLogRepository.markAsSkipped(id);
      emit(const MedicineLogOperationSuccess('Marked as skipped'));
      await loadTodayLogs();
    } catch (e) {
      emit(MedicineLogError('Failed to mark as skipped: ${e.toString()}'));
    }
  }

  /// Snooze log
  Future<void> snoozeLog(int id, int minutes) async {
    try {
      await _medicineLogRepository.snoozeLog(id, minutes);
      emit(MedicineLogOperationSuccess('Snoozed for $minutes minutes'));
      await loadTodayLogs();
    } catch (e) {
      emit(MedicineLogError('Failed to snooze: ${e.toString()}'));
    }
  }

  /// Load overdue logs
  Future<void> loadOverdueLogs() async {
    try {
      emit(MedicineLogLoading());
      final logs = await _medicineLogRepository.getOverdueLogs();
      emit(MedicineLogLoaded(logs));
    } catch (e) {
      emit(MedicineLogError('Failed to load overdue logs: ${e.toString()}'));
    }
  }

  /// Load pending logs
  Future<void> loadPendingLogs() async {
    try {
      emit(MedicineLogLoading());
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
