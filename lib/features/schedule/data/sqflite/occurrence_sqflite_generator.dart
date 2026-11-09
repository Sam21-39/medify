import 'package:medify/features/schedule/domain/engine/occurrence_generator.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/timezone.dart' as tz;

/// Writes generated occurrences for every schedule in [fromDate]..[toDate].
/// Idempotent: `INSERT OR IGNORE` on UNIQUE(schedule_id, scheduled_at_utc).
class OccurrenceSqfliteGenerator {
  OccurrenceSqfliteGenerator(this._db);

  final Database _db;

  /// Returns the number of rows inserted (existing rows are skipped).
  Future<int> generate({
    required DateTime fromDate,
    required DateTime toDate,
    required tz.Location location,
    required DateTime nowUtc,
  }) async {
    final rows = await _db.rawQuery('''
      SELECT s.id AS schedule_id, s.time_of_day_seconds, s.weekdays_mask,
             s.start_date, s.end_date, s.is_active,
             m.id AS medicine_id, m.profile_id, m.dose_amount, m.dose_unit
      FROM schedules s
      JOIN medicines m ON m.id = s.medicine_id
      WHERE m.state = 'active'
    ''');
    final nowMs = nowUtc.toUtc().millisecondsSinceEpoch;
    var inserted = 0;
    await _db.transaction((txn) async {
      for (final row in rows) {
        final endDate = row['end_date'] as int?;
        final occurrences = generateOccurrences(
          rule: ScheduleRule(
            scheduleId: row['schedule_id']! as int,
            timeOfDaySeconds: row['time_of_day_seconds']! as int,
            weekdaysMask: row['weekdays_mask']! as int,
            startDate: DateTime.fromMillisecondsSinceEpoch(
              row['start_date']! as int,
            ),
            endDate: endDate == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(endDate),
            isActive: row['is_active'] == 1,
          ),
          fromDate: fromDate,
          toDate: toDate,
          location: location,
        );
        for (final o in occurrences) {
          await txn.rawInsert(
            '''
            INSERT OR IGNORE INTO occurrences (
              profile_id, medicine_id, schedule_id, scheduled_at_utc, local_date,
              actor_profile_id, dose_snapshot_amount, dose_snapshot_unit,
              created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            [
              row['profile_id'],
              row['medicine_id'],
              o.scheduleId,
              o.scheduledAtUtc.millisecondsSinceEpoch,
              o.localDate,
              row['profile_id'],
              (row['dose_amount']! as num).toDouble(),
              row['dose_unit'],
              nowMs,
              nowMs,
            ],
          );
          inserted +=
              Sqflite.firstIntValue(await txn.rawQuery('SELECT changes()')) ??
              0;
        }
      }
    });
    return inserted;
  }
}
