import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:medify/core/error/failure.dart';
import 'package:medify/core/security/field_cipher.dart';
import 'package:medify/features/medicines/data/sqflite/medicine_row_mapper.dart';
import 'package:medify/features/medicines/domain/entities/medicine.dart';
import 'package:medify/features/medicines/domain/repositories/medicine_repository.dart';
import 'package:sqflite/sqflite.dart';

/// sqflite-backed [MedicineRepository].
///
/// Watch streams are not reactive queries: each watch stream is re-queried
/// after every write in this repo. Single-process only; writes from another
/// isolate or another [Database] instance do not refresh the streams.
class SqfliteMedicineRepository implements MedicineRepository {
  SqfliteMedicineRepository(this._db, this._cipher);

  final Database _db;
  final FieldCipher _cipher;

  late final _allController = StreamController<List<Medicine>>.broadcast(
    onListen: _pushAll,
  );
  late final _activeController = StreamController<List<Medicine>>.broadcast(
    onListen: _pushActive,
  );

  @override
  Future<Either<Failure, List<Medicine>>> getAllMedicines() =>
      _read(() => _load(_db));

  @override
  Future<Either<Failure, List<Medicine>>> getActiveMedicines() =>
      _read(() => _load(_db, activeOnly: true));

  @override
  Future<Either<Failure, Medicine?>> getMedicineById(int id) =>
      _read(() => _byId(_db, id));

  @override
  Future<Either<Failure, Medicine>> addMedicine(Medicine medicine) {
    return _write<Medicine>(() async {
      final saved = await _db.transaction<Medicine>((txn) async {
        // Encrypted columns need the row id as AAD, so insert, then re-seal.
        final id = await txn.insert(
          'medicines',
          await MedicineRowMapper.toRow(medicine, _cipher, id: 0),
        );
        await txn.update(
          'medicines',
          await MedicineRowMapper.toRow(medicine, _cipher, id: id),
          where: 'id = ?',
          whereArgs: [id],
        );
        for (final row in MedicineRowMapper.toScheduleRows(medicine, id)) {
          await txn.insert('schedules', row);
        }
        return (await _byId(txn, id))!;
      });
      _refresh();
      return Right(saved);
    });
  }

  @override
  Future<Either<Failure, Medicine>> updateMedicine(Medicine medicine) {
    final id = medicine.id;
    if (id == null) {
      return Future.value(
        const Left(Failure('Medicine ID cannot be null for update')),
      );
    }
    return _write<Medicine>(() async {
      final result = await _db.transaction<Either<Failure, Medicine>>((
        txn,
      ) async {
        final stored = await txn.query(
          'medicines',
          columns: ['state'],
          where: 'id = ?',
          whereArgs: [id],
        );
        if (stored.isEmpty) return const Left(Failure('Medicine not found'));
        final row = await MedicineRowMapper.toRow(medicine, _cipher, id: id);
        // Stock moves only through dose transitions, never from an entity.
        row.remove('current_quantity');
        // Archived (finished) is sticky here; nothing in this repo reactivates.
        if (stored.single['state'] == 'finished') row['state'] = 'finished';
        await txn.update('medicines', row, where: 'id = ?', whereArgs: [id]);
        await _syncSchedules(txn, medicine, id);
        return Right((await _byId(txn, id))!);
      });
      _refresh();
      return result;
    });
  }

  @override
  Future<Either<Failure, void>> deleteMedicine(int id) {
    // Archive, not delete: occurrences keep the history. Hard purge is later.
    return _write<void>(() async {
      await _db.update(
        'medicines',
        {
          'state': 'finished',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      _refresh();
      return const Right(null);
    });
  }

  @override
  Future<Either<Failure, Medicine>> toggleMedicineStatus(int id) {
    return _write<Medicine>(() async {
      final result = await _db.transaction<Either<Failure, Medicine>>((
        txn,
      ) async {
        final stored = await txn.query(
          'medicines',
          columns: ['state'],
          where: 'id = ?',
          whereArgs: [id],
        );
        if (stored.isEmpty) return const Left(Failure('Medicine not found'));
        if (stored.single['state'] == 'finished') {
          return const Left(Failure('Medicine is archived'));
        }
        final current = (await _byId(txn, id))!;
        await txn.update(
          'medicines',
          {
            'state': current.isActive ? 'paused' : 'active',
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        return Right((await _byId(txn, id))!);
      });
      _refresh();
      return result;
    });
  }

  @override
  Stream<List<Medicine>> watchAllMedicines() => _allController.stream;

  @override
  Stream<List<Medicine>> watchActiveMedicines() => _activeController.stream;

  /// Replaces active schedules only when the reminder set changes. Old rows are
  /// deactivated, not deleted, because occurrences reference them.
  Future<void> _syncSchedules(
    Transaction txn,
    Medicine medicine,
    int id,
  ) async {
    final desired = MedicineRowMapper.toScheduleRows(medicine, id);
    final current = await txn.query(
      'schedules',
      where: 'medicine_id = ? AND is_active = 1',
      whereArgs: [id],
    );
    String key(Map<String, Object?> row) =>
        '${row['time_of_day_seconds']}|${row['weekdays_mask']}|${row['end_date']}';
    final currentKeys = current.map(key).toList()..sort();
    final desiredKeys = desired.map(key).toList()..sort();
    if (currentKeys.join(',') == desiredKeys.join(',')) return;

    // Future pending occurrences of the replaced schedules are dropped; taken
    // and past rows stay.
    await txn.delete(
      'occurrences',
      where:
          "schedule_id IN (${List.filled(current.length, '?').join(',')}) "
          "AND status = 'scheduled' AND scheduled_at_utc > ?",
      whereArgs: [
        ...current.map((row) => row['id']),
        DateTime.now().toUtc().millisecondsSinceEpoch,
      ],
    );
    await txn.update(
      'schedules',
      {'is_active': 0},
      where: 'medicine_id = ? AND is_active = 1',
      whereArgs: [id],
    );
    for (final row in desired) {
      await txn.insert('schedules', row);
    }
  }

  Future<List<Medicine>> _load(
    DatabaseExecutor db, {
    bool activeOnly = false,
  }) async {
    final rows = await db.query(
      'medicines',
      where: activeOnly ? "state = 'active'" : null,
      orderBy: 'id',
    );
    return [for (final row in rows) await _fromRow(db, row)];
  }

  Future<Medicine?> _byId(DatabaseExecutor db, int id) async {
    final rows = await db.query('medicines', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : _fromRow(db, rows.first);
  }

  Future<Medicine> _fromRow(
    DatabaseExecutor db,
    Map<String, Object?> row,
  ) async {
    final schedules = await db.query(
      'schedules',
      where: 'medicine_id = ? AND is_active = 1',
      whereArgs: [row['id']],
      orderBy: 'time_of_day_seconds',
    );
    return MedicineRowMapper.fromRow(row, schedules, _cipher);
  }

  void _pushAll() => _emit(_allController, () => _load(_db));

  void _pushActive() =>
      _emit(_activeController, () => _load(_db, activeOnly: true));

  void _refresh() {
    _pushAll();
    _pushActive();
  }

  void _emit(
    StreamController<List<Medicine>> controller,
    Future<List<Medicine>> Function() load,
  ) {
    load().then(
      (value) {
        if (!controller.isClosed) controller.add(value);
      },
      onError: (Object error) {
        if (!controller.isClosed) controller.addError(error);
      },
    );
  }

  Future<Either<Failure, T>> _read<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } on DatabaseException catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, T>> _write<T>(
    Future<Either<Failure, T>> Function() body,
  ) async {
    try {
      return await body();
    } on DatabaseException catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
