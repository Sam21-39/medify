import 'dart:developer' as developer;

import 'package:medify/core/database/settings_store.dart';
import 'package:medify/core/error/failure.dart';
import 'package:medify/features/medicines/domain/entities/medicine.dart';
import 'package:medify/features/medicines/domain/repositories/medicine_repository.dart';
import 'package:medify/core/notifications/notification_service.dart';

/// Stock alert level. Alerts fire only when the level goes up.
enum RefillLevel { none, low, out }

RefillLevel refillLevel(Medicine m) => m.isOutOfStock
    ? RefillLevel.out
    : m.isLowStock
    ? RefillLevel.low
    : RefillLevel.none;

bool shouldAlert(RefillLevel previous, RefillLevel now) =>
    now.index > previous.index;

/// Service to manage medicine refill reminders and stock tracking
class RefillReminderService {
  final NotificationService _notificationService;
  final MedicineRepository _medicineRepository;
  final SettingsStore _settings;

  RefillReminderService(
    this._notificationService,
    this._medicineRepository,
    this._settings,
  );

  static String _alertKey(int medicineId) => 'refill_alert_$medicineId';

  /// Check all medicines and schedule refill reminders for low stock items
  Future<void> checkAndScheduleRefillReminders() async {
    try {
      developer.log(
        'Checking medicines for refill reminders',
        name: 'RefillReminderService',
      );

      final activeMedicines = (await _medicineRepository.getActiveMedicines())
          .unwrap();

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

      final key = _alertKey(medicine.id!);
      final previous =
          RefillLevel.values.asNameMap()[await _settings.getString(
            key,
            defaultValue: RefillLevel.none.name,
          )] ??
          RefillLevel.none;
      final now = refillLevel(medicine);

      if (shouldAlert(previous, now)) {
        if (now == RefillLevel.out) {
          await _showOutOfStockNotification(medicine);
        } else {
          await _scheduleRefillNotification(medicine, medicine.daysRemaining!);
        }
      }
      // Always store the level: a drop (after a refill) re-arms the alert.
      await _settings.setString(key, now.name);
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

  /// Re-check one medicine after a dose changed its stock.
  Future<void> checkMedicine(int medicineId) async {
    try {
      final medicine = (await _medicineRepository.getMedicineById(medicineId))
          .unwrap();
      if (medicine != null) await _checkMedicineRefillStatus(medicine);
    } catch (e) {
      developer.log(
        'Error checking medicine $medicineId: $e',
        name: 'RefillReminderService',
        error: e,
      );
    }
  }

  /// Set stock to [newQuantity] after a refill. Returns false on failure.
  Future<bool> refillMedicine(
    int medicineId, {
    required double newQuantity,
  }) async {
    try {
      (await _medicineRepository.refillStock(medicineId, newQuantity)).unwrap();
      await _settings.setString(_alertKey(medicineId), RefillLevel.none.name);
      developer.log(
        'Refilled medicine $medicineId: currentQuantity = $newQuantity',
        name: 'RefillReminderService',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error refilling medicine: $e',
        name: 'RefillReminderService',
        error: e,
      );
      return false;
    }
  }

  /// Get list of medicines that need refilling
  Future<List<Medicine>> getMedicinesNeedingRefill() async {
    try {
      final activeMedicines = (await _medicineRepository.getActiveMedicines())
          .unwrap();
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
