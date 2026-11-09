import 'dart:developer' as developer;
import '../../domain/entities/medicine.dart';
import '../../domain/repositories/medicine_repository.dart';
import 'notification_service.dart';

/// Service to manage medicine refill reminders and stock tracking
class RefillReminderService {
  final NotificationService _notificationService;
  final MedicineRepository _medicineRepository;

  RefillReminderService(this._notificationService, this._medicineRepository);

  /// Check all medicines and schedule refill reminders for low stock items
  Future<void> checkAndScheduleRefillReminders() async {
    try {
      developer.log(
        'Checking medicines for refill reminders',
        name: 'RefillReminderService',
      );

      final activeMedicines = await _medicineRepository.getActiveMedicines();

      for (final medicine in activeMedicines) {
        await _checkMedicineRefillStatus(medicine);
      }

      developer.log(
        'Refill reminder check completed',
        name: 'RefillReminderService',
      );
    } catch (e) {
      developer.log(
        'Error checking refill reminders: $e',
        name: 'RefillReminderService',
        error: e,
      );
    }
  }

  /// Check individual medicine refill status and schedule notification if needed
  Future<void> _checkMedicineRefillStatus(Medicine medicine) async {
    try {
      // Skip if medicine doesn't have refill tracking enabled
      if (medicine.currentQuantity == null ||
          medicine.refillRemindDays == null) {
        return;
      }

      // Check if medicine is low on stock
      if (medicine.isLowStock) {
        final daysRemaining = medicine.daysRemaining;
        developer.log(
          'Low stock detected for ${medicine.name}: $daysRemaining days remaining',
          name: 'RefillReminderService',
        );

        // Schedule refill reminder notification
        await _scheduleRefillNotification(medicine, daysRemaining!);
      }

      // Check if medicine is out of stock
      if (medicine.isOutOfStock) {
        developer.log(
          'Out of stock: ${medicine.name}',
          name: 'RefillReminderService',
        );

        // Show immediate out of stock notification
        await _showOutOfStockNotification(medicine);
      }
    } catch (e) {
      developer.log(
        'Error checking refill status for ${medicine.name}: $e',
        name: 'RefillReminderService',
        error: e,
      );
    }
  }

  /// Schedule a refill reminder notification
  Future<void> _scheduleRefillNotification(
    Medicine medicine,
    int daysRemaining,
  ) async {
    try {
      final String message = daysRemaining == 0
          ? 'Your ${medicine.name} is running out today! Time to refill.'
          : daysRemaining == 1
          ? 'Only 1 day of ${medicine.name} left. Refill soon!'
          : 'Only $daysRemaining days of ${medicine.name} remaining. Consider refilling.';

      // Show immediate notification for refill reminder
      await _notificationService.showImmediateNotification(
        title: '🔔 Refill Reminder',
        body: message,
        payload: 'refill_${medicine.id}',
      );

      developer.log(
        'Scheduled refill notification for ${medicine.name}',
        name: 'RefillReminderService',
      );
    } catch (e) {
      developer.log(
        'Error scheduling refill notification: $e',
        name: 'RefillReminderService',
        error: e,
      );
    }
  }

  /// Show immediate out of stock notification
  Future<void> _showOutOfStockNotification(Medicine medicine) async {
    try {
      await _notificationService.showImmediateNotification(
        title: '⚠️ Medicine Out of Stock',
        body:
            '${medicine.name} is out of stock! Please refill immediately to continue your medication schedule.',
        payload: 'out_of_stock_${medicine.id}',
      );

      developer.log(
        'Showed out of stock notification for ${medicine.name}',
        name: 'RefillReminderService',
      );
    } catch (e) {
      developer.log(
        'Error showing out of stock notification: $e',
        name: 'RefillReminderService',
        error: e,
      );
    }
  }

  /// Update medicine quantity after taking a dose
  Future<void> decrementMedicineQuantity(int medicineId) async {
    try {
      final medicine = await _medicineRepository.getMedicineById(medicineId);
      if (medicine == null) {
        developer.log(
          'Medicine not found: $medicineId',
          name: 'RefillReminderService',
        );
        return;
      }

      // Only decrement if quantity tracking is enabled
      if (medicine.currentQuantity == null) {
        return;
      }

      // Decrement quantity by dosage amount (e.g., 2 tablets, 500 ml)
      final decrementAmount = medicine.dosageAmount;
      final newQuantity = medicine.currentQuantity! - decrementAmount;
      final updatedMedicine = medicine.copyWith(
        currentQuantity: newQuantity > 0 ? newQuantity : 0,
        updatedAt: DateTime.now(),
      );

      await _medicineRepository.updateMedicine(updatedMedicine);

      developer.log(
        'Decremented quantity for ${medicine.name}: ${medicine.currentQuantity} -> $newQuantity (decreased by $decrementAmount ${medicine.medicineType.unit})',
        name: 'RefillReminderService',
      );

      // Check if we need to send refill reminder after decrement
      await _checkMedicineRefillStatus(updatedMedicine);
    } catch (e) {
      developer.log(
        'Error decrementing medicine quantity: $e',
        name: 'RefillReminderService',
        error: e,
      );
    }
  }

  /// Refill medicine stock
  Future<void> refillMedicine(int medicineId, {double? newQuantity}) async {
    try {
      final medicine = await _medicineRepository.getMedicineById(medicineId);
      if (medicine == null) {
        developer.log(
          'Medicine not found: $medicineId',
          name: 'RefillReminderService',
        );
        return;
      }

      // Use provided quantity or reset to total quantity
      final refillAmount = newQuantity ?? medicine.totalQuantity ?? 0.0;

      final updatedMedicine = medicine.copyWith(
        currentQuantity: refillAmount,
        lastRefillDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _medicineRepository.updateMedicine(updatedMedicine);

      developer.log(
        'Refilled ${medicine.name}: currentQuantity = $refillAmount ${medicine.medicineType.unit}',
        name: 'RefillReminderService',
      );

      // Format quantity string for notification
      String quantityStr;
      if (refillAmount == refillAmount.toInt()) {
        quantityStr = '${refillAmount.toInt()} ${medicine.medicineType.unit}';
      } else {
        quantityStr = '$refillAmount ${medicine.medicineType.unit}';
      }

      // Show success notification
      await _notificationService.showImmediateNotification(
        title: '✅ Medicine Refilled',
        body:
            '${medicine.name} has been refilled successfully. Current stock: $quantityStr.',
        payload: 'refilled_${medicine.id}',
      );
    } catch (e) {
      developer.log(
        'Error refilling medicine: $e',
        name: 'RefillReminderService',
        error: e,
      );
    }
  }

  /// Get list of medicines that need refilling
  Future<List<Medicine>> getMedicinesNeedingRefill() async {
    try {
      final activeMedicines = await _medicineRepository.getActiveMedicines();
      return activeMedicines
          .where((medicine) => medicine.isLowStock || medicine.isOutOfStock)
          .toList();
    } catch (e) {
      developer.log(
        'Error getting medicines needing refill: $e',
        name: 'RefillReminderService',
        error: e,
      );
      return [];
    }
  }

  /// Calculate estimated refill date based on current usage
  DateTime? calculateEstimatedRefillDate(Medicine medicine) {
    final daysRemaining = medicine.daysRemaining;
    if (daysRemaining == null) return null;

    return DateTime.now().add(Duration(days: daysRemaining));
  }

  /// Get stock status description
  String getStockStatusDescription(Medicine medicine) {
    if (medicine.currentQuantity == null) {
      return 'Tracking disabled';
    }

    if (medicine.isOutOfStock) {
      return 'Out of stock';
    }

    // Format quantity string
    String quantityStr;
    if (medicine.currentQuantity == medicine.currentQuantity!.toInt()) {
      quantityStr =
          '${medicine.currentQuantity!.toInt()} ${medicine.medicineType.unit}';
    } else {
      quantityStr = '${medicine.currentQuantity} ${medicine.medicineType.unit}';
    }

    if (medicine.isLowStock) {
      final days = medicine.daysRemaining;
      return days == 1
          ? 'Low stock ($quantityStr, 1 day left)'
          : 'Low stock ($quantityStr, $days days left)';
    }

    final days = medicine.daysRemaining;
    if (days == null) return '$quantityStr left';

    return days == 1
        ? '$quantityStr (1 day left)'
        : '$quantityStr ($days days left)';
  }
}
