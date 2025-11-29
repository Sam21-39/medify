import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:medify/app/data/models/medication_model.dart';
import 'package:medify/app/data/models/dose_log_model.dart';
import 'package:medify/app/data/providers/database_helper.dart';
import 'package:medify/app/services/firebase_service.dart';
import 'package:medify/app/services/notification_service.dart';
import 'package:medify/app/modules/auth/controllers/auth_controller.dart';

class MedicationController extends GetxController {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthController _authController = Get.find<AuthController>();
  final NotificationService _notificationService = Get.find<NotificationService>();

  final RxList<MedicationModel> medications = <MedicationModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadMedications();
  }

  Future<void> loadMedications() async {
    final userId = _authController.currentUser.value?.id;
    if (userId == null) return;

    isLoading.value = true;
    try {
      // Load from local DB
      final localMedications = await _databaseHelper.getAllMedications(userId);
      medications.assignAll(localMedications);

      // Sync with Firebase (in background)
      _syncMedications();
    } catch (e) {
      debugPrint('Error loading medications: $e');
      Get.snackbar('Error', 'Failed to load medications');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _syncMedications() async {
    // TODO: Implement full sync logic
    // For now, just listen to Firebase stream if online
    _firebaseService.getMedications().listen((remoteMedications) {
      // Simple strategy: Remote wins for now, or merge
      // Ideally we should compare timestamps
      if (remoteMedications.isNotEmpty) {
        medications.assignAll(remoteMedications);
        // Update local DB
        for (var med in remoteMedications) {
          _databaseHelper.insertMedication(med);
          // Reschedule notifications for synced medications
          _notificationService.scheduleMedicationReminders(med);
        }
      }
    });
  }

  Future<void> addMedication({
    required String name,
    required double dosage,
    required String unit,
    required MedicationFrequency frequency,
    required List<MedicationTime> times,
    String? instructions,
    int? quantity,
    int? refillThreshold,
    Color? color,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = _authController.currentUser.value?.id;
    if (userId == null) {
      Get.snackbar('Error', 'User not logged in');
      return;
    }

    isLoading.value = true;
    try {
      final now = DateTime.now();
      final newMedication = MedicationModel(
        id: const Uuid().v4(),
        userId: userId,
        name: name,
        dosage: dosage,
        unit: unit,
        frequency: frequency,
        times: times,
        instructions: instructions,
        quantity: quantity,
        refillThreshold: refillThreshold,
        colorTag: color?.toARGB32().toRadixString(16),
        startDate: startDate ?? now,
        endDate: endDate,
        status: MedicationStatus.active,
        createdAt: now,
        updatedAt: now,
        synced: false,
      );

      // Save locally
      await _databaseHelper.insertMedication(newMedication);
      medications.add(newMedication);
      medications.refresh();

      // Schedule Notifications
      await _notificationService.scheduleMedicationReminders(newMedication);

      // Save to Firebase
      try {
        await _firebaseService.saveMedication(newMedication.copyWith(synced: true));
        // Update local synced status
        await _databaseHelper.updateMedication(newMedication.copyWith(synced: true));
      } catch (e) {
        // Failed to sync, will be handled by sync service later
        debugPrint('Error syncing new medication: $e');
      }

      Get.back(); // Close add screen
      Get.snackbar('Success', 'Medication added successfully');
    } catch (e) {
      debugPrint('Error adding medication: $e');
      Get.snackbar('Error', 'Failed to add medication');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateMedication(MedicationModel medication) async {
    isLoading.value = true;
    try {
      final updatedMedication = medication.copyWith(updatedAt: DateTime.now(), synced: false);

      // Update locally
      await _databaseHelper.updateMedication(updatedMedication);

      final index = medications.indexWhere((m) => m.id == medication.id);
      if (index != -1) {
        medications[index] = updatedMedication;
        medications.refresh();
      }

      // Update Notifications
      await _notificationService.scheduleMedicationReminders(updatedMedication);

      // Update Firebase
      try {
        await _firebaseService.saveMedication(updatedMedication.copyWith(synced: true));
        await _databaseHelper.updateMedication(updatedMedication.copyWith(synced: true));
      } catch (e) {
        debugPrint('Error syncing update: $e');
      }

      Get.back();
      Get.snackbar('Success', 'Medication updated successfully');
    } catch (e) {
      debugPrint('Error updating medication: $e');
      Get.snackbar('Error', 'Failed to update medication');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteMedication(String id) async {
    try {
      // Delete locally
      await _databaseHelper.deleteMedication(id);
      medications.removeWhere((m) => m.id == id);

      // Cancel Notifications
      await _notificationService.cancelMedicationReminders(id);

      // Delete from Firebase
      try {
        await _firebaseService.deleteMedication(id);
      } catch (e) {
        debugPrint('Error deleting from Firebase: $e');
        // Add to sync queue for deletion
      }

      Get.back(); // Close detail screen if open
      Get.snackbar('Success', 'Medication deleted');
    } catch (e) {
      debugPrint('Error deleting medication: $e');
      Get.snackbar('Error', 'Failed to delete medication');
    }
  }

  Future<void> markAsTaken(String medicationId, DateTime scheduledTime) async {
    await _logDose(
      medicationId: medicationId,
      scheduledTime: scheduledTime,
      status: DoseStatus.taken,
      actualTime: DateTime.now(),
    );

    // Update inventory if applicable
    final med = medications.firstWhereOrNull((m) => m.id == medicationId);
    if (med != null && med.quantity != null) {
      final updatedMed = med.copyWith(quantity: med.quantity! - 1, synced: false);
      await updateMedication(updatedMed);
    }

    Get.snackbar('Success', 'Medication marked as taken');
  }

  Future<void> skipMedication(String medicationId, DateTime scheduledTime, String? reason) async {
    await _logDose(
      medicationId: medicationId,
      scheduledTime: scheduledTime,
      status: DoseStatus.skipped,
      reason: reason,
    );
    Get.snackbar('Skipped', 'Medication marked as skipped');
  }

  Future<void> snoozeMedication(
    String medicationId,
    DateTime scheduledTime,
    Duration duration,
  ) async {
    await _logDose(
      medicationId: medicationId,
      scheduledTime: scheduledTime,
      status: DoseStatus.snoozed,
    );

    // Schedule a one-off notification
    final med = medications.firstWhereOrNull((m) => m.id == medicationId);
    if (med != null) {
      final snoozeTime = DateTime.now().add(duration);
      // We use a unique ID for snooze notifications to avoid conflict with regular schedule
      // Or we can just use the regular ID logic but with a special flag
      // For simplicity, let's just use a random ID or hash
      final snoozeId = (med.id.hashCode ^ snoozeTime.hashCode).abs();

      await _notificationService.showNotification(
        id: snoozeId,
        title: 'Snoozed: ${med.name}',
        body: 'Time to take your ${med.dosage} ${med.unit} of ${med.name}',
        payload: med.id,
      );
    }

    Get.snackbar('Snoozed', 'Reminder set for ${duration.inMinutes} minutes');
  }

  Future<void> _logDose({
    required String medicationId,
    required DateTime scheduledTime,
    required DoseStatus status,
    DateTime? actualTime,
    String? reason,
    String? note,
  }) async {
    final med = medications.firstWhereOrNull((m) => m.id == medicationId);
    if (med == null) return;

    final doseLog = DoseLogModel(
      id: const Uuid().v4(),
      medicationId: medicationId,
      medicationName: med.name,
      scheduledTime: scheduledTime,
      actualTime: actualTime,
      status: status,
      reason: reason,
      note: note,
      createdAt: DateTime.now(),
      synced: false,
    );

    try {
      // Save locally
      await _databaseHelper.insertDoseLog(doseLog);

      // Sync to Firebase
      try {
        await _firebaseService.saveDoseLog(doseLog.copyWith(synced: true));
        await _databaseHelper.updateDoseLog(doseLog.copyWith(synced: true));
      } catch (e) {
        debugPrint('Error syncing dose log: $e');
      }
    } catch (e) {
      debugPrint('Error logging dose: $e');
      Get.snackbar('Error', 'Failed to log dose');
    }
  }
}
