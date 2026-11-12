import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/database/medify_database.dart';
import 'package:medify/core/error/failure.dart';
import 'package:medify/core/security/field_cipher.dart';
import 'package:medify/features/medicines/data/sqflite/medicine_sqflite_repository.dart';
import 'package:medify/features/medicines/domain/entities/medicine.dart';
import 'package:medify/features/schedule/data/sqflite/medicine_log_exceptions.dart';
import 'package:medify/features/schedule/data/sqflite/medicine_log_sqflite_repository.dart';
import 'package:medify/features/schedule/domain/entities/medicine_log.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late SqfliteMedicineLogRepository logs;
  late int profileId;
  late int otherProfileId;
  late int medicineId;
  late int scheduleId;

  setUp(() async {
    db = await MedifyDatabase.open(path: inMemoryDatabasePath);
    final cipher = FieldCipher(List.filled(32, 7));
    logs = SqfliteMedicineLogRepository(db, cipher);
    final profiles = SqfliteMedicineRepository(db, cipher);
    Future<int> profile(String name) => db.insert('profiles', {
      'name': name,
      'role': 'patient',
      'color_value': 0,
      'created_at': 0,
      'updated_at': 0,
    });
    profileId = await profile('A');
    otherProfileId = await profile('B');
    medicineId = (await profiles.addMedicine(
      Medicine(
        profileId: profileId,
        name: 'Aspirin',
        dosage: '2 tablets',
        dosageAmount: 2,
        reminderTimes: const [28800],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        currentQuantity: 10,
      ),
    )).unwrap().id!;
    final rows = await db.query(
      'schedules',
      where: 'medicine_id = ?',
      whereArgs: [medicineId],
    );
    scheduleId = rows.single['id']! as int;
  });

  tearDown(() => db.close());

  MedicineLog log({
    bool noSchedule = false,
    DateTime? at,
    int? profile,
    MedicineLogStatus status = MedicineLogStatus.pending,
  }) => MedicineLog(
    profileId: profile ?? profileId,
    medicineId: medicineId,
    scheduleId: noSchedule ? null : scheduleId,
    scheduledTime: at ?? DateTime(2026, 3, 1, 8),
    status: status,
    createdAt: DateTime(2026, 3, 1),
    updatedAt: DateTime(2026, 3, 1),
  );

  Future<num?> stock() async {
    final rows = await db.query(
      'medicines',
      columns: ['current_quantity'],
      where: 'id = ?',
      whereArgs: [medicineId],
    );
    return rows.single['current_quantity'] as num?;
  }

  test('markAsTaken twice decrements stock once', () async {
    final added = await logs.addLog(log());
    final first = (await logs.markAsTaken(added.id!)).unwrap();
    final second = (await logs.markAsTaken(added.id!)).unwrap();

    expect(first.status, MedicineLogStatus.taken);
    expect(second, first);
    expect(await stock(), 8);
  });

  test('stock clamps at zero', () async {
    // Stock 10, dose 2: five doses reach 0, the sixth must clamp, not go negative.
    for (var hour = 8; hour < 14; hour++) {
      final added = await logs.addLog(log(at: DateTime(2026, 3, 1, hour)));
      await logs.markAsTaken(added.id!);
    }
    expect(await stock(), 0);
  });

  test('skip and missed leave stock unchanged', () async {
    final skipped = await logs.addLog(log());
    await logs.markAsSkipped(skipped.id!);
    final missed = await logs.addLog(log(at: DateTime(2026, 3, 1, 9)));
    await logs.markAsMissed(missed.id!);

    expect(await stock(), 10);
  });

  test('markAsSkipped after taken returns Left and leaves state', () async {
    final added = await logs.addLog(log());
    await logs.markAsTaken(added.id!);
    final result = await logs.markAsSkipped(added.id!);

    expect(result.fold((f) => f, (_) => null), isA<Failure>());
    expect((await logs.getLogById(added.id!))!.status, MedicineLogStatus.taken);
  });

  test('snooze stores snoozed_until_utc and reads back as snoozed', () async {
    final added = await logs.addLog(log());
    final snoozed = (await logs.snoozeLog(added.id!, 15)).unwrap();

    expect(snoozed.status, MedicineLogStatus.snoozed);
    final rows = await db.query(
      'occurrences',
      where: 'id = ?',
      whereArgs: [added.id],
    );
    expect(rows.single['snoozed_until_utc'], isNotNull);
  });

  test('markAsMissed on scheduled, then again is a no-op', () async {
    final added = await logs.addLog(log());
    expect(
      (await logs.markAsMissed(added.id!)).status,
      MedicineLogStatus.missed,
    );
    expect(
      (await logs.markAsMissed(added.id!)).status,
      MedicineLogStatus.missed,
    );
  });

  test('duplicate occurrence throws OccurrenceConflictException', () async {
    await logs.addLog(log());
    expect(
      () => logs.addLog(log()),
      throwsA(isA<OccurrenceConflictException>()),
    );
  });

  test('cross-patient occurrence is rejected by the trigger', () async {
    expect(
      () => logs.addLog(log(profile: otherProfileId)),
      throwsA(isA<InvalidOccurrenceException>()),
    );
  });

  test('updateLog to taken throws and leaves stock unchanged', () async {
    final added = await logs.addLog(log());
    expect(
      () => logs.updateLog(added.copyWith(status: MedicineLogStatus.taken)),
      throwsA(isA<InvalidTransitionException>()),
    );
    expect(await stock(), 10);
    expect(
      (await logs.getLogById(added.id!))!.status,
      MedicineLogStatus.pending,
    );
  });

  test('updateLog away from taken throws and keeps taken', () async {
    final added = await logs.addLog(log());
    await logs.markAsTaken(added.id!);
    await expectLater(
      logs.updateLog(added.copyWith(status: MedicineLogStatus.pending)),
      throwsA(isA<InvalidTransitionException>()),
    );
    expect((await logs.getLogById(added.id!))!.status, MedicineLogStatus.taken);
  });

  test('updateLog with missing id throws InvalidTransitionException', () async {
    await expectLater(
      logs.updateLog(log().copyWith(id: 999999)),
      throwsA(isA<InvalidTransitionException>()),
    );
  });

  test('statistics colours are opaque ARGB', () async {
    await logs.addLog(log());
    final details = await logs.getMedicineStatisticsDetails();
    expect(details.single.colorValue >>> 24, 0xFF);
  });

  test('addLog without scheduleId throws StateError', () async {
    expect(() => logs.addLog(log(noSchedule: true)), throwsStateError);
  });

  test('undo taken restores stock once; a second undo does nothing', () async {
    final added = await logs.addLog(log());
    await logs.markAsTaken(added.id!);
    expect(await stock(), 8);

    // The dose is in the past, so undo returns it to missed, not pending.
    final first = (await logs.revertToScheduled(added.id!)).unwrap();
    expect(first.status, MedicineLogStatus.missed);
    expect(await stock(), 10);

    final second = await logs.revertToScheduled(added.id!);
    expect(second.isLeft(), isTrue);
    expect(await stock(), 10);
  });

  test(
    'undo skipped on a past dose returns to missed and clears the reason',
    () async {
      final added = await logs.addLog(log());
      await logs.markAsSkipped(added.id!, reason: 'felt_unwell');

      final reverted = (await logs.revertToScheduled(added.id!)).unwrap();

      expect(reverted.status, MedicineLogStatus.missed);
      expect(reverted.skipReason, isNull);
      expect(await stock(), 10);
    },
  );

  test('undo of missed returns Left and leaves the row unchanged', () async {
    final added = await logs.addLog(log());
    await logs.markAsMissed(added.id!);
    final before = (await logs.getLogById(added.id!))!;

    final result = await logs.revertToScheduled(added.id!);

    expect(result.isLeft(), isTrue);
    expect((await logs.getLogById(added.id!))!, before);
  });

  test('undo taken with null stock leaves stock null', () async {
    await db.update(
      'medicines',
      {'current_quantity': null},
      where: 'id = ?',
      whereArgs: [medicineId],
    );
    final added = await logs.addLog(log());
    await logs.markAsTaken(added.id!);
    expect(await stock(), isNull);

    await logs.revertToScheduled(added.id!);

    expect(await stock(), isNull);
  });

  test('undo of snoozed clears snoozed_until_utc', () async {
    final added = await logs.addLog(
      log(at: DateTime.now().add(const Duration(days: 1))),
    );
    await logs.snoozeLog(added.id!, 30);
    expect((await logs.getLogById(added.id!))!.snoozedUntil, isNotNull);

    final reverted = (await logs.revertToScheduled(added.id!)).unwrap();

    expect(reverted.snoozedUntil, isNull);
    expect(reverted.status, MedicineLogStatus.pending);
  });

  test('markAsSkipped stores the reason and reads it back', () async {
    final added = await logs.addLog(log());
    await logs.markAsSkipped(added.id!, reason: 'x');

    final read = (await logs.getLogById(added.id!))!;
    expect(read.status, MedicineLogStatus.skipped);
    expect(read.skipReason, 'x');
  });
}
