import 'dart:convert';

import 'package:medify/core/security/field_cipher.dart';
import 'package:medify/features/medicines/domain/entities/medicine.dart';

/// Maps `medicines` rows and their active `schedules` rows to [Medicine].
///
/// Reminder times and weekdays live in `schedules` (one row per reminder time).
/// `weekdays_mask`: bit 0 = Monday ... bit 6 = Sunday. 127 = every day.
class MedicineRowMapper {
  MedicineRowMapper._();

  static const everyDayMask = 127;

  /// [id] is the medicines row id, used as AAD for the encrypted columns.
  static Future<Map<String, Object?>> toRow(
    Medicine m,
    FieldCipher cipher, {
    required int id,
  }) async => {
    'profile_id': m.profileId,
    'name': await cipher.seal(m.name, aad: aad('name', id)),
    'medicine_type': m.medicineType.name,
    'dose_amount': m.dosageAmount,
    'dose_unit': m.medicineType.unit,
    'dose_label': m.dosage,
    'intake_timing': m.intakeTiming.name,
    'notes': m.notes == null
        ? null
        : await cipher.seal(m.notes!, aad: aad('notes', id)),
    'photo_path': m.photoPath,
    'voice_note_path': m.voiceNotePath,
    'total_quantity': m.totalQuantity,
    'current_quantity': m.currentQuantity,
    'refill_remind_days': m.refillRemindDays,
    'last_refill_date': m.lastRefillDate?.millisecondsSinceEpoch,
    'state': m.isActive ? 'active' : 'paused',
    'created_at': m.createdAt.millisecondsSinceEpoch,
    'updated_at': m.updatedAt.millisecondsSinceEpoch,
  };

  /// One `schedules` row per reminder time. `start_date` is the creation date
  /// (local midnight, epoch ms). Other schedule columns use schema defaults.
  static List<Map<String, Object?>> toScheduleRows(Medicine m, int medicineId) {
    final createdAt = m.createdAt;
    final startDate = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    ).millisecondsSinceEpoch;
    final mask = weekdaysMask(m.daysOfWeek);
    final endDate = m.endDate?.millisecondsSinceEpoch;
    return [
      for (final seconds in m.reminderTimes)
        {
          'medicine_id': medicineId,
          'time_of_day_seconds': seconds,
          'weekdays_mask': mask,
          'start_date': startDate,
          'end_date': endDate,
          'is_active': 1,
        },
    ];
  }

  static Future<Medicine> fromRow(
    Map<String, Object?> row,
    List<Map<String, Object?>> activeSchedules,
    FieldCipher cipher,
  ) async {
    final times = <int>{
      for (final s in activeSchedules) s['time_of_day_seconds']! as int,
    }.toList()..sort();
    final first = activeSchedules.isEmpty ? null : activeSchedules.first;
    final state = _byName(
      _MedicineStateView.values,
      row['state'],
      'medicines.state',
    );
    return Medicine(
      id: row['id'] as int,
      profileId: row['profile_id'] as int,
      name: await cipher.open(
        row['name'] as String,
        aad: aad('name', row['id'] as int),
      ),
      medicineType: _byName(
        MedicineType.values,
        row['medicine_type'],
        'medicines.medicine_type',
      ),
      dosageAmount: (row['dose_amount'] as num).toDouble(),
      dosage: row['dose_label'] as String,
      reminderTimes: times,
      intakeTiming: _byName(
        MedicineIntakeTiming.values,
        row['intake_timing'],
        'medicines.intake_timing',
      ),
      // paused and finished both read back as inactive.
      isActive: state == _MedicineStateView.active,
      notes: row['notes'] == null
          ? null
          : await cipher.open(
              row['notes']! as String,
              aad: aad('notes', row['id'] as int),
            ),
      daysOfWeek: first == null
          ? const []
          : daysFromMask(first['weekdays_mask']! as int),
      endDate: first?['end_date'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(first!['end_date'] as int),
      photoPath: row['photo_path'] as String?,
      voiceNotePath: row['voice_note_path'] as String?,
      totalQuantity: (row['total_quantity'] as num?)?.toDouble(),
      currentQuantity: (row['current_quantity'] as num?)?.toDouble(),
      refillRemindDays: row['refill_remind_days'] as int?,
      lastRefillDate: row['last_refill_date'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row['last_refill_date'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }

  /// Empty [days] means every day.
  static int weekdaysMask(List<int> days) {
    if (days.isEmpty) return everyDayMask;
    var mask = 0;
    for (final day in days) {
      mask |= 1 << (day - 1);
    }
    return mask;
  }

  static List<int> daysFromMask(int mask) {
    if (mask == everyDayMask) return const [];
    return [
      for (var day = 1; day <= 7; day++)
        if (mask & (1 << (day - 1)) != 0) day,
    ];
  }

  /// AAD for an encrypted column: `medicines.<column>.<row id>`.
  static List<int> aad(String column, int id) =>
      utf8.encode('medicines.$column.$id');

  static T _byName<T extends Enum>(List<T> values, Object? raw, String column) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
    throw StateError('$column: unknown value $raw');
  }
}

/// Medicine state as stored in `medicines.state`. Only `active` and `paused`
/// are written by this repo; `finished` is read as inactive.
enum _MedicineStateView { active, paused, finished }
