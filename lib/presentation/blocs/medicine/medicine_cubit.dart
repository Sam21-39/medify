import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/notification_service.dart';
// COMMENTED OUT FOR UPCOMING RELEASE
// import '../../../core/services/profile_service.dart';
import '../../../core/utils/log_generator.dart';
import '../../../domain/entities/medicine.dart';
import '../../../domain/repositories/medicine_log_repository.dart';
import '../../../domain/repositories/medicine_repository.dart';
import 'medicine_state.dart';

/// Cubit for managing medicine state
class MedicineCubit extends Cubit<MedicineState> {
  final MedicineRepository _medicineRepository;

  MedicineCubit(this._medicineRepository) : super(MedicineInitial());

  /// Load all medicines
  Future<void> loadMedicines() async {
    try {
      emit(MedicineLoading());
      final medicines = await _medicineRepository.getAllMedicines();
      emit(MedicineLoaded(medicines));
    } catch (e) {
      emit(MedicineError('Failed to load medicines: ${e.toString()}'));
    }
  }

  /// Load active medicines only
  Future<void> loadActiveMedicines() async {
    try {
      emit(MedicineLoading());
      final medicines = await _medicineRepository.getActiveMedicines();
      emit(MedicineLoaded(medicines));
    } catch (e) {
      emit(MedicineError('Failed to load medicines: ${e.toString()}'));
    }
  }

  /// Add a new medicine
  Future<void> addMedicine(Medicine medicine) async {
    try {
      emit(MedicineLoading());
      final savedMedicine = await _medicineRepository.addMedicine(medicine);

      // Generate today's logs for the medicine
      try {
        final logRepository = getIt<MedicineLogRepository>();
        final logs = LogGenerator.generateTodayLogs(savedMedicine);
        for (final log in logs) {
          await logRepository.addLog(log);
        }
      } catch (e) {
        // Silently handle log generation errors
      }

      // Schedule notifications for the medicine
      // COMMENTED OUT FOR UPCOMING RELEASE - profile name support
      try {
        final notificationService = getIt<NotificationService>();
        // final profileService = getIt<ProfileService>();
        // final activeProfile = await profileService.getActiveProfile();
        await notificationService.scheduleMedicineReminders(
          savedMedicine,
          // profileName: activeProfile?.name,
        );
      } catch (e) {
        // Silently handle notification errors - don't fail the whole operation
        // In production, log to error tracking service
      }

      // Emit success state
      emit(const MedicineOperationSuccess('Medicine added successfully'));

      // Auto-reload medicines to update all listening pages
      await loadMedicines();
    } catch (e) {
      emit(MedicineError('Failed to add medicine: ${e.toString()}'));
    }
  }

  /// Update an existing medicine
  Future<void> updateMedicine(Medicine medicine) async {
    try {
      emit(MedicineLoading());

      // CRITICAL FIX: Get old medicine to check if reminder times changed
      final oldMedicine = await _medicineRepository.getMedicineById(
        medicine.id!,
      );

      // Update the medicine
      final updatedMedicine = await _medicineRepository.updateMedicine(
        medicine,
      );

      // Check if reminder times changed
      final timesChanged =
          oldMedicine != null &&
          !listEquals(oldMedicine.reminderTimes, updatedMedicine.reminderTimes);

      if (timesChanged) {
        // Delete today's logs for this medicine to prevent duplicates
        try {
          final logRepository = getIt<MedicineLogRepository>();
          final todayLogs = await logRepository.getTodayLogs();
          final medicineLogsToday = todayLogs
              .where((log) => log.medicineId == medicine.id!)
              .toList();

          for (final log in medicineLogsToday) {
            await logRepository.deleteLog(log.id!);
          }

          // Generate new logs for today with updated times
          final newLogs = LogGenerator.generateTodayLogs(updatedMedicine);
          for (final log in newLogs) {
            await logRepository.addLog(log);
          }
        } catch (e) {
          // Silently handle log regeneration errors
        }
      }

      // Reschedule notifications for the updated medicine
      // COMMENTED OUT FOR UPCOMING RELEASE - profile name support
      try {
        final notificationService = getIt<NotificationService>();
        // final profileService = getIt<ProfileService>();
        // final activeProfile = await profileService.getActiveProfile();
        await notificationService.scheduleMedicineReminders(
          updatedMedicine,
          // profileName: activeProfile?.name,
        );
      } catch (e) {
        // Silently handle notification errors
      }

      // Emit success state
      emit(const MedicineOperationSuccess('Medicine updated successfully'));

      // Auto-reload medicines to update all listening pages
      await loadMedicines();
    } catch (e) {
      emit(MedicineError('Failed to update medicine: ${e.toString()}'));
    }
  }

  /// Delete a medicine
  Future<void> deleteMedicine(int id) async {
    try {
      emit(MedicineLoading());

      // Cancel notifications for this medicine before deleting
      try {
        final notificationService = getIt<NotificationService>();
        await notificationService.cancelMedicineReminders(id);
      } catch (e) {
        // Silently handle notification errors
      }

      await _medicineRepository.deleteMedicine(id);
      emit(const MedicineOperationSuccess('Medicine deleted successfully'));
      // For delete, we can reload immediately since we're not navigating
      await loadMedicines();
    } catch (e) {
      emit(MedicineError('Failed to delete medicine: ${e.toString()}'));
    }
  }

  /// Toggle medicine active status
  Future<void> toggleMedicineStatus(int id) async {
    try {
      final medicine = await _medicineRepository.toggleMedicineStatus(id);

      // Update notifications based on active status
      // COMMENTED OUT FOR UPCOMING RELEASE - profile name support
      try {
        final notificationService = getIt<NotificationService>();
        if (medicine.isActive) {
          // Schedule notifications when activated
          // final profileService = getIt<ProfileService>();
          // final activeProfile = await profileService.getActiveProfile();
          await notificationService.scheduleMedicineReminders(
            medicine,
            // profileName: activeProfile?.name,
          );
        } else {
          // Cancel notifications when deactivated
          await notificationService.cancelMedicineReminders(id);
        }
      } catch (e) {
        // Silently handle notification errors
      }

      await loadMedicines();
    } catch (e) {
      emit(MedicineError('Failed to toggle medicine status: ${e.toString()}'));
    }
  }

  /// Watch medicines stream
  void watchMedicines() {
    _medicineRepository.watchAllMedicines().listen(
      (medicines) {
        emit(MedicineLoaded(medicines));
      },
      onError: (error) {
        emit(MedicineError('Failed to watch medicines: ${error.toString()}'));
      },
    );
  }
}
