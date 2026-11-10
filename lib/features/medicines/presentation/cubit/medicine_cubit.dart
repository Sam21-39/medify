import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:medify/core/di/injection_container.dart';
import 'package:medify/core/error/failure.dart';
import 'package:medify/core/notifications/notification_service.dart';
// COMMENTED OUT FOR UPCOMING RELEASE
// import '../../../core/services/profile_service.dart';
import 'package:medify/features/schedule/data/sqflite/occurrence_sqflite_generator.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:medify/features/medicines/domain/entities/medicine.dart';
import 'package:medify/features/schedule/domain/entities/medicine_log.dart';
import 'package:medify/features/schedule/domain/repositories/medicine_log_repository.dart';
import 'package:medify/features/medicines/domain/repositories/medicine_repository.dart';
import 'package:medify/features/medicines/presentation/cubit/medicine_state.dart';

/// Cubit for managing medicine state
class MedicineCubit extends Cubit<MedicineState> {
  final MedicineRepository _medicineRepository;

  MedicineCubit(this._medicineRepository) : super(MedicineInitial());

  /// Load all medicines
  Future<void> loadMedicines() async {
    try {
      // Soft refresh — avoid Loading flicker / cross-tab races when already loaded
      if (state is! MedicineLoaded) {
        emit(MedicineLoading());
      }
      final result = await _medicineRepository.getAllMedicines();
      result.fold((failure) {
        if (state is! MedicineLoaded) emit(MedicineError(failure.message));
      }, (medicines) => emit(MedicineLoaded(medicines)));
    } catch (e) {
      emit(MedicineError('Failed to load medicines: ${e.toString()}'));
    }
  }

  /// Load active medicines only
  Future<void> loadActiveMedicines() async {
    try {
      if (state is! MedicineLoaded) {
        emit(MedicineLoading());
      }
      final result = await _medicineRepository.getActiveMedicines();
      result.fold((failure) {
        if (state is! MedicineLoaded) emit(MedicineError(failure.message));
      }, (medicines) => emit(MedicineLoaded(medicines)));
    } catch (e) {
      emit(MedicineError('Failed to load medicines: ${e.toString()}'));
    }
  }

  /// Occurrences for today through +7 local days, from the schedules.
  Future<void> _generateOccurrences() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    await getIt<OccurrenceSqfliteGenerator>().generate(
      fromDate: from,
      toDate: DateTime(from.year, from.month, from.day + 7),
      location: tz.local,
      nowUtc: now.toUtc(),
    );
  }

  /// Add a new medicine
  Future<void> addMedicine(Medicine medicine) async {
    try {
      emit(MedicineLoading());
      final savedMedicine = (await _medicineRepository.addMedicine(medicine))
          .unwrap();

      // Generate today's logs for the medicine
      try {
        await _generateOccurrences();
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

      final updatedMedicine = (await _medicineRepository.updateMedicine(
        medicine,
      )).unwrap();

      // Replace pending future occurrences; taken/skipped history is kept
      try {
        final logRepository = getIt<MedicineLogRepository>();
        final now = DateTime.now();
        final logs = await logRepository.getLogsByMedicineId(medicine.id!);
        for (final log in logs) {
          if (log.status == MedicineLogStatus.pending &&
              log.scheduledTime.isAfter(now)) {
            await logRepository.deleteLog(log.id!);
          }
        }

        // Regenerate occurrences from the updated schedules
        await _generateOccurrences();
      } catch (e) {
        // Silently handle log regeneration errors
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

      (await _medicineRepository.deleteMedicine(id)).unwrap();

      // Cancel notifications only once the delete succeeded
      try {
        final notificationService = getIt<NotificationService>();
        await notificationService.cancelMedicineReminders(id);
      } catch (e) {
        // Silently handle notification errors
      }

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
      final medicine = (await _medicineRepository.toggleMedicineStatus(id))
          .unwrap();

      // Resumed: regenerate occurrences so upcoming doses exist again
      if (medicine.isActive) {
        try {
          await _generateOccurrences();
        } catch (e) {
          // Silently handle occurrence generation errors
        }
      }

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
