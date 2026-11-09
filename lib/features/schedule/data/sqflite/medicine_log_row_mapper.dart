import 'package:medify/features/schedule/domain/entities/medicine_log.dart';

/// Maps `occurrences` rows to [MedicineLog].
///
/// Status: `pending` and `snoozed` are stored as `scheduled`. `snoozed` is
/// `scheduled` with `snoozed_until_utc` set.
class MedicineLogRowMapper {
  MedicineLogRowMapper._();

  /// Full row for insert. Dose snapshot comes from the medicine at insert time.
  static Map<String, Object?> toInsertRow(
    MedicineLog log, {
    required double doseAmount,
    required String doseUnit,
  }) {
    final scheduleId = log.scheduleId;
    if (scheduleId == null) {
      throw StateError('occurrences insert: scheduleId is required');
    }
    return {
      'profile_id': log.profileId,
      'medicine_id': log.medicineId,
      'schedule_id': scheduleId,
      'scheduled_at_utc': log.scheduledTime.toUtc().millisecondsSinceEpoch,
      'local_date': localDate(log.scheduledTime),
      'actor_profile_id': log.profileId,
      'dose_snapshot_amount': doseAmount,
      'dose_snapshot_unit': doseUnit,
      'created_at': log.createdAt.toUtc().millisecondsSinceEpoch,
      'updated_at': log.updatedAt.toUtc().millisecondsSinceEpoch,
      ...statusColumns(log),
    };
  }

  /// Columns a status change may update.
  static Map<String, Object?> statusColumns(MedicineLog log) => {
    'status': statusToDb(log.status),
    'taken_at_utc': log.takenTime?.toUtc().millisecondsSinceEpoch,
    'snoozed_until_utc': log.status == MedicineLogStatus.snoozed
        ? log.snoozedUntil?.toUtc().millisecondsSinceEpoch
        : null,
    'updated_at': log.updatedAt.toUtc().millisecondsSinceEpoch,
  };

  static String statusToDb(MedicineLogStatus status) => switch (status) {
    MedicineLogStatus.pending || MedicineLogStatus.snoozed => 'scheduled',
    MedicineLogStatus.taken => 'taken',
    MedicineLogStatus.skipped => 'skipped',
    MedicineLogStatus.missed => 'missed',
  };

  static MedicineLog fromRow(Map<String, Object?> row) {
    final raw = row['status'];
    final snoozedUntil = row['snoozed_until_utc'] as int?;
    final status = switch (raw) {
      'scheduled' =>
        snoozedUntil == null
            ? MedicineLogStatus.pending
            : MedicineLogStatus.snoozed,
      'taken' => MedicineLogStatus.taken,
      'skipped' => MedicineLogStatus.skipped,
      'missed' => MedicineLogStatus.missed,
      _ => throw StateError('occurrences.status: unknown value $raw'),
    };
    final takenAt = row['taken_at_utc'] as int?;
    return MedicineLog(
      id: row['id'] as int,
      profileId: row['profile_id'] as int,
      medicineId: row['medicine_id'] as int,
      scheduleId: row['schedule_id'] as int,
      scheduledTime: _fromMs(row['scheduled_at_utc'] as int),
      takenTime: takenAt == null ? null : _fromMs(takenAt),
      status: status,
      snoozedUntil: snoozedUntil == null ? null : _fromMs(snoozedUntil),
      actorProfileId: row['actor_profile_id'] as int,
      createdAt: _fromMs(row['created_at'] as int),
      updatedAt: _fromMs(row['updated_at'] as int),
    );
  }

  /// Local calendar date as `YYYY-MM-DD`.
  static String localDate(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime _fromMs(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
}
