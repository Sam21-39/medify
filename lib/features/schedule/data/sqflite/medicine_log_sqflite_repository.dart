import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:medify/core/error/failure.dart';
import 'package:medify/core/security/field_cipher.dart';
import 'package:medify/features/schedule/data/sqflite/medicine_log_exceptions.dart';
import 'package:medify/features/schedule/data/sqflite/medicine_log_row_mapper.dart';
import 'package:medify/features/schedule/domain/entities/medicine_log.dart';
import 'package:medify/features/schedule/domain/repositories/medicine_log_repository.dart';
import 'package:medify/features/statistics/domain/entities/statistics.dart';
import 'package:sqflite/sqflite.dart';

/// sqflite-backed [MedicineLogRepository] over the `occurrences` table.
///
/// Plain-value methods throw [OccurrenceConflictException] or
/// [InvalidTransitionException]. Methods returning `Either` return `Left`.
///
/// Watch streams are not reactive queries: they are re-queried after every
/// write in this repo. Single-process only; see `SqfliteMedicineRepository`.
///
/// Known limit: `actor_profile_id` is set at insert from the entity's
/// `profileId`. Transitions do not record who acted.
class SqfliteMedicineLogRepository implements MedicineLogRepository {
  SqfliteMedicineLogRepository(this._db, this._cipher);

  final Database _db;
  final FieldCipher _cipher;

  /// Message raised by the `occurrences_guard_insert` trigger in schema.dart.
  static const _guardMessage =
      'occurrence profile or schedule does not match medicine';

  late final _todayController = StreamController<List<MedicineLog>>.broadcast(
    onListen: _pushToday,
  );

  // ==================== CRUD ====================

  @override
  Future<List<MedicineLog>> getAllLogs() => _list();

  @override
  Future<List<MedicineLog>> getLogsByMedicineId(int medicineId) =>
      _list(where: 'medicine_id = ?', whereArgs: [medicineId]);

  @override
  Future<List<MedicineLog>> getTodayLogs() => getLogsByDate(DateTime.now());

  @override
  Future<List<MedicineLog>> getLogsByDate(DateTime date) => _list(
    where: 'local_date = ?',
    whereArgs: [MedicineLogRowMapper.localDate(date)],
  );

  @override
  Future<MedicineLog?> getLogById(int id) async {
    final rows = await _db.query(
      'occurrences',
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : MedicineLogRowMapper.fromRow(rows.first);
  }

  @override
  Future<MedicineLog> addLog(MedicineLog log) async {
    final medicine = await _db.query(
      'medicines',
      columns: ['dose_amount', 'dose_unit'],
      where: 'id = ?',
      whereArgs: [log.medicineId],
    );
    if (medicine.isEmpty) {
      throw StateError('medicine ${log.medicineId} not found');
    }
    final row = MedicineLogRowMapper.toInsertRow(
      log,
      doseAmount: (medicine.first['dose_amount']! as num).toDouble(),
      doseUnit: medicine.first['dose_unit']! as String,
    );
    final int id;
    try {
      id = await _db.insert('occurrences', row);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw OccurrenceConflictException(
          'occurrence already exists for schedule ${log.scheduleId} at '
          '${log.scheduledTime.toUtc().millisecondsSinceEpoch}',
        );
      }
      if (e.toString().contains(_guardMessage)) {
        throw InvalidOccurrenceException(_guardMessage);
      }
      rethrow;
    }
    _refresh();
    return (await getLogById(id))!;
  }

  @override
  Future<MedicineLog> updateLog(MedicineLog log) async {
    final id = log.id;
    if (id == null) throw StateError('Log ID cannot be null for update');
    final target = MedicineLogRowMapper.statusToDb(log.status);
    await _db.transaction((txn) async {
      final rows = await txn.query(
        'occurrences',
        columns: ['status'],
        where: 'id = ?',
        whereArgs: [id],
      );
      final current = rows.isEmpty ? null : rows.first['status'];
      if (target != current && target != 'scheduled') {
        throw InvalidTransitionException(
          'status change to $target is not allowed here; '
          'use markAsTaken, markAsSkipped or markAsMissed',
        );
      }
      await txn.update(
        'occurrences',
        MedicineLogRowMapper.statusColumns(log),
        where: 'id = ?',
        whereArgs: [id],
      );
    });
    _refresh();
    return (await getLogById(id))!;
  }

  @override
  Future<void> deleteLog(int id) async {
    await _db.delete('occurrences', where: 'id = ?', whereArgs: [id]);
    _refresh();
  }

  // ==================== Transitions ====================

  @override
  Future<Either<Failure, MedicineLog>> markAsTaken(int id) => _eitherWrite(
    () => _transition(id, (txn, row) async {
      final status = row['status'];
      if (status == 'taken') return Right(MedicineLogRowMapper.fromRow(row));
      if (status == 'skipped') {
        return const Left(Failure('already skipped'));
      }
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await txn.update(
        'occurrences',
        {'status': 'taken', 'taken_at_utc': now, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );
      // CHECK forbids negative stock; MAX(0, ...) clamps. NULL stock stays NULL.
      await txn.rawUpdate(
        'UPDATE medicines SET current_quantity = MAX(0, current_quantity - ?) '
        'WHERE id = ?',
        [row['dose_snapshot_amount'], row['medicine_id']],
      );
      return Right(await _reread(txn, id));
    }),
  );

  @override
  Future<Either<Failure, MedicineLog>> markAsSkipped(int id) => _eitherWrite(
    () => _transition(id, (txn, row) async {
      final status = row['status'];
      if (status == 'skipped') return Right(MedicineLogRowMapper.fromRow(row));
      if (status != 'scheduled' && status != 'missed') {
        return Left(Failure('cannot skip: status is $status'));
      }
      await txn.update(
        'occurrences',
        {
          'status': 'skipped',
          'skip_reason': null,
          'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return Right(await _reread(txn, id));
    }),
  );

  @override
  Future<MedicineLog> markAsMissed(int id) async {
    final result = await _transition(id, (txn, row) async {
      final status = row['status'];
      if (status == 'missed') return Right(MedicineLogRowMapper.fromRow(row));
      if (status != 'scheduled') {
        return Left(Failure('cannot mark missed: status is $status'));
      }
      await txn.update(
        'occurrences',
        {
          'status': 'missed',
          'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return Right(await _reread(txn, id));
    });
    return result.fold(
      (f) => throw InvalidTransitionException(f.message),
      (l) => l,
    );
  }

  @override
  Future<Either<Failure, MedicineLog>> snoozeLog(int id, int minutes) =>
      _eitherWrite(
        () => _transition(id, (txn, row) async {
          final status = row['status'];
          if (status != 'scheduled') {
            return Left(Failure('cannot snooze: status is $status'));
          }
          final until = DateTime.now().add(Duration(minutes: minutes));
          await txn.update(
            'occurrences',
            {
              'snoozed_until_utc': until.toUtc().millisecondsSinceEpoch,
              'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: [id],
          );
          return Right(await _reread(txn, id));
        }),
      );

  // ==================== Queries ====================

  @override
  Future<List<MedicineLog>> getOverdueLogs() => _list(
    where: "scheduled_at_utc < ? AND status NOT IN ('taken', 'skipped')",
    whereArgs: [DateTime.now().toUtc().millisecondsSinceEpoch],
  );

  @override
  Future<List<MedicineLog>> getPendingLogs() =>
      _list(where: "status = 'scheduled' AND snoozed_until_utc IS NULL");

  @override
  Stream<List<MedicineLog>> watchTodayLogs() => _todayController.stream;

  @override
  Stream<List<MedicineLog>> watchLogsByMedicineId(int medicineId) {
    return watchTodayLogs().map(
      (logs) => logs.where((log) => log.medicineId == medicineId).toList(),
    );
  }

  // ==================== Statistics ====================
  // Computed in Dart over loaded rows, same rules as the legacy repo.

  @override
  Future<MedicineStatistics> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final logs = await _logsInRange(startDate, endDate);
    if (logs.isEmpty) return MedicineStatistics.empty();

    final takenDoses = _count(logs, MedicineLogStatus.taken);
    final missedDoses = _count(logs, MedicineLogStatus.missed);
    final skippedDoses = _count(logs, MedicineLogStatus.skipped);
    final pendingDoses = _count(logs, MedicineLogStatus.pending);
    final completed = takenDoses + missedDoses + skippedDoses;

    return MedicineStatistics(
      totalDoses: logs.length,
      takenDoses: takenDoses,
      missedDoses: missedDoses,
      skippedDoses: skippedDoses,
      pendingDoses: pendingDoses,
      adherenceRate: completed > 0 ? (takenDoses / completed) * 100 : 0.0,
      currentStreak: await getCurrentStreak(),
      bestStreak: await getBestStreak(),
      medicineAdherence: await getMedicineAdherenceRates(
        startDate: startDate,
        endDate: endDate,
      ),
      dailyCompletion: await getDailyCompletion(30),
      dailyScheduled: await getDailyScheduled(30),
      weeklyData: await _dailyAdherence(7),
      monthlyData: await _dailyAdherence(30),
    );
  }

  @override
  Future<MedicineStatistics> getStatisticsForDays(int days) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    return getStatistics(startDate: startDate, endDate: endDate);
  }

  @override
  Future<int> getCurrentStreak() async {
    final now = DateTime.now();
    var streak = 0;
    for (var i = 0; i < 365; i++) {
      final logs = await getLogsByDate(
        DateTime(now.year, now.month, now.day - i),
      );
      if (logs.isEmpty) continue;
      final taken = _count(logs, MedicineLogStatus.taken);
      if (taken == logs.length) {
        streak++;
      } else if (i == 0) {
        // Today is incomplete, don't break streak yet.
        continue;
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Future<int> getBestStreak() async {
    final byDate = <DateTime, List<MedicineLog>>{};
    for (final log in await getAllLogs()) {
      final t = log.scheduledTime;
      byDate.putIfAbsent(DateTime(t.year, t.month, t.day), () => []).add(log);
    }
    var best = 0;
    var current = 0;
    for (final date in byDate.keys.toList()..sort()) {
      final logs = byDate[date]!;
      if (_count(logs, MedicineLogStatus.taken) == logs.length) {
        current++;
        if (current > best) best = current;
      } else {
        current = 0;
      }
    }
    return best;
  }

  @override
  Future<Map<DateTime, int>> getDailyCompletion(int days) async {
    final result = <DateTime, int>{};
    for (final date in _lastDays(days)) {
      final logs = await getLogsByDate(date);
      result[date] = _count(logs, MedicineLogStatus.taken);
    }
    return result;
  }

  @override
  Future<Map<DateTime, int>> getDailyScheduled(int days) async {
    final result = <DateTime, int>{};
    for (final date in _lastDays(days)) {
      result[date] = (await getLogsByDate(date)).length;
    }
    return result;
  }

  @override
  Future<Map<int, double>> getMedicineAdherenceRates({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final rates = <int, double>{};
    for (final entry in _groupByMedicine(
      await _logsInRange(startDate, endDate),
    ).entries) {
      rates[entry.key] = _adherence(entry.value);
    }
    return rates;
  }

  @override
  Future<List<MedicineStatisticsDetail>> getMedicineStatisticsDetails({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final names = <int, String>{
      for (final row in await _db.query('medicines', columns: ['id', 'name']))
        row['id']! as int: await _cipher.open(row['name']! as String),
    };
    const colors = [
      0xFF14B8A6,
      0xFF10B981,
      0xFFF59E0B,
      0xEF4444,
      0x3B82F6,
      0x8B5CF6,
    ];
    final details = <MedicineStatisticsDetail>[];
    var colorIndex = 0;
    for (final entry in _groupByMedicine(
      await _logsInRange(startDate, endDate),
    ).entries) {
      final name = names[entry.key];
      if (name == null) continue;
      final logs = entry.value;
      details.add(
        MedicineStatisticsDetail(
          medicineId: entry.key,
          medicineName: name,
          totalDoses: logs.length,
          takenDoses: _count(logs, MedicineLogStatus.taken),
          adherenceRate: _adherence(logs),
          colorValue: colors[colorIndex % colors.length],
        ),
      );
      colorIndex++;
    }
    return details;
  }

  // ==================== Helpers ====================

  Future<List<MedicineLog>> _list({
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final rows = await _db.query(
      'occurrences',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'scheduled_at_utc',
    );
    return rows.map(MedicineLogRowMapper.fromRow).toList();
  }

  Future<MedicineLog> _reread(DatabaseExecutor db, int id) async {
    final rows = await db.query(
      'occurrences',
      where: 'id = ?',
      whereArgs: [id],
    );
    return MedicineLogRowMapper.fromRow(rows.first);
  }

  /// Runs [step] in one transaction. A `Left` from [step] commits nothing.
  Future<Either<Failure, MedicineLog>> _transition(
    int id,
    Future<Either<Failure, MedicineLog>> Function(
      Transaction txn,
      Map<String, Object?> row,
    )
    step,
  ) async {
    final result = await _db.transaction<Either<Failure, MedicineLog>>((
      txn,
    ) async {
      final rows = await txn.query(
        'occurrences',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows.isEmpty) return const Left(Failure('Log not found'));
      return step(txn, rows.first);
    });
    _refresh();
    return result;
  }

  Future<Either<Failure, MedicineLog>> _eitherWrite(
    Future<Either<Failure, MedicineLog>> Function() body,
  ) async {
    try {
      return await body();
    } on DatabaseException catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  void _pushToday() {
    getTodayLogs().then(
      (logs) {
        if (!_todayController.isClosed) _todayController.add(logs);
      },
      onError: (Object error) {
        if (!_todayController.isClosed) _todayController.addError(error);
      },
    );
  }

  void _refresh() => _pushToday();

  Future<List<MedicineLog>> _logsInRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return getAllLogs();
    final from = start ?? DateTime(2000);
    final to = end ?? DateTime.now();
    return _list(
      where: 'scheduled_at_utc BETWEEN ? AND ?',
      whereArgs: [
        from.toUtc().millisecondsSinceEpoch,
        to.toUtc().millisecondsSinceEpoch,
      ],
    );
  }

  Future<List<DailyAdherence>> _dailyAdherence(int days) async {
    final result = <DailyAdherence>[];
    for (final date in _lastDays(days)) {
      final logs = await getLogsByDate(date);
      final taken = _count(logs, MedicineLogStatus.taken);
      result.add(
        DailyAdherence(
          date: date,
          scheduled: logs.length,
          taken: taken,
          adherenceRate: logs.isEmpty ? 0.0 : (taken / logs.length) * 100,
        ),
      );
    }
    return result;
  }

  /// Local midnights for the last [days] days, oldest first, ending today.
  List<DateTime> _lastDays(int days) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - (days - 1));
    return [
      for (var i = 0; i < days; i++)
        DateTime(start.year, start.month, start.day + i),
    ];
  }

  Map<int, List<MedicineLog>> _groupByMedicine(List<MedicineLog> logs) {
    final grouped = <int, List<MedicineLog>>{};
    for (final log in logs) {
      grouped.putIfAbsent(log.medicineId, () => []).add(log);
    }
    return grouped;
  }

  /// taken / (taken + missed + skipped), as a percentage.
  double _adherence(List<MedicineLog> logs) {
    final taken = _count(logs, MedicineLogStatus.taken);
    final completed =
        taken +
        _count(logs, MedicineLogStatus.missed) +
        _count(logs, MedicineLogStatus.skipped);
    return completed > 0 ? (taken / completed) * 100 : 0.0;
  }

  int _count(List<MedicineLog> logs, MedicineLogStatus status) =>
      logs.where((log) => log.status == status).length;
}
