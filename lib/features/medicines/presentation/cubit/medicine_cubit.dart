import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:medify/core/di/injection_container.dart';
import 'package:medify/core/error/failure.dart';
import 'package:medify/core/notifications/notification_service.dart';
// COMMENTED OUT FOR UPCOMING RELEASE
// import '../../../core/services/profile_service.dart';
import 'package:medify/features/schedule/data/sqflite/occurrence_sqflite_generator.dart';
import 'package:medify/features/schedule/presentation/cubit/medicine_log_cubit.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:medify/features/medicines/domain/entities/medicine.dart';
import 'package:medify/features/schedule/domain/entities/medicine_log.dart';
import 'package:medify/features/schedule/domain/repositories/medicine_log_repository.dart';
import 'package:medify/features/medicines/domain/repositories/medicine_repository.dart';
import 'package:medify/features/medicines/presentation/cubit/medicine_state.dart';

/// Cubit for managing medicine state
class MedicineCubit extends Cubit<MedicineState> {
  final MedicineRepository _medicineRepository;
  final NotificationService? _injectedNotifications;

  /// Medicine ids with a stop or pause/resume in flight; new taps are ignored.
  final _inFlight = <int>{};

  MedicineCubit(this._medicineRepository, {NotificationService? notifications})
    : _injectedNotifications = notifications,
      super(MedicineInitial());

  NotificationService get _notifications =>
      _injectedNotifications ?? getIt<NotificationService>();

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

  /// Stop a medicine (archived, with an optional preset reason).
  Future<void> stopMedicine(int id, {String? reason}) async {
    if (!_inFlight.add(id)) return;
    try {
      emit(MedicineLoading());

      // Cancel first: the cancel looks up occurrence ids that the stop deletes.
      // If the cancel fails, this throws before the DB is touched.
      await _cancelReminders(id);
      (await _medicineRepository.stopMedicine(id, reason: reason)).unwrap();
      await _refreshTodayLogs();

      emit(const MedicineOperationSuccess('Medicine stopped'));
      await loadMedicines();
    } catch (e) {
      await _restoreReminders();
      emit(MedicineError('Failed to stop medicine: ${e.toString()}'));
    } finally {
      _inFlight.remove(id);
    }
  }

  /// Pause or resume. Pausing removes future doses; resuming regenerates them.
  Future<void> toggleMedicineStatus(int id) async {
    if (!_inFlight.add(id)) return;
    try {
      final stored = (await _medicineRepository.getMedicineById(id)).unwrap();
      // Cancel first: the cancel looks up occurrence ids that the pause deletes.
      if (stored?.isActive ?? false) await _cancelReminders(id);

      final medicine = (await _medicineRepository.toggleMedicineStatus(id))
          .unwrap();
      await _refreshTodayLogs();

      // Resumed: regenerate occurrences and reminders
      if (medicine.isActive) {
        try {
          await _generateOccurrences();
          await _notifications.scheduleMedicineReminders(medicine);
        } catch (e) {
          // Silently handle occurrence and notification errors
        }
      }

      await loadMedicines();
    } catch (e) {
      await _restoreReminders();
      emit(MedicineError('Failed to toggle medicine status: ${e.toString()}'));
    } finally {
      _inFlight.remove(id);
    }
  }

  /// Propagates failure so the caller aborts before writing to the DB.
  Future<void> _cancelReminders(int id) =>
      _notifications.cancelMedicineReminders(id);

  /// Reschedules reminders for still-active medicines after a failed write.
  Future<void> _restoreReminders() async {
    try {
      await _notifications.rescheduleUpcoming();
    } catch (_) {
      // Restore is best effort; the original error is what the user sees.
    }
  }

  Future<void> _refreshTodayLogs() => getIt<MedicineLogCubit>().loadTodayLogs();

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
