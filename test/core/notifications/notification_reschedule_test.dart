import 'package:dartz/dartz.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:medify/core/database/medify_database.dart';
import 'package:medify/core/error/failure.dart';
import 'package:medify/core/notifications/notification_service.dart';
import 'package:medify/features/medicines/domain/entities/medicine.dart';
import 'package:medify/features/medicines/domain/repositories/medicine_repository.dart';
import 'package:medify/features/schedule/domain/entities/medicine_log.dart';
import 'package:medify/features/schedule/domain/repositories/medicine_log_repository.dart';

final _now = DateTime.now();

final _medicine = Medicine(
  id: 1,
  profileId: 1,
  name: 'Test',
  dosage: '1 tablet',
  reminderTimes: const [28800],
  createdAt: _now,
  updatedAt: _now,
);

// Occurrence 1 is pending in the future, so its reminder is rescheduled.
final _pendingLog = MedicineLog(
  id: 1,
  profileId: 1,
  medicineId: 1,
  scheduledTime: _now.add(const Duration(days: 1)),
  status: MedicineLogStatus.pending,
  createdAt: _now,
  updatedAt: _now,
);

class _Medicines implements MedicineRepository {
  @override
  Future<Either<Failure, List<Medicine>>> getActiveMedicines() async =>
      Right([_medicine]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _Logs implements MedicineLogRepository {
  @override
  Future<List<MedicineLog>> getLogsByMedicineId(int medicineId) async => [
    _pendingLog,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  setUp(() async {
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    final db = await MedifyDatabase.open(path: inMemoryDatabasePath);
    GetIt.instance.registerSingleton<Database>(db);
    GetIt.instance.registerSingleton<MedicineRepository>(_Medicines());
    GetIt.instance.registerSingleton<MedicineLogRepository>(_Logs());
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
    await GetIt.instance.get<Database>().close();
    await GetIt.instance.reset();
  });

  List<int> cancelledIds() => [
    for (final c in calls)
      if (c.method == 'cancel') (c.arguments as Map)['id'] as int,
  ];

  test(
    'resume cancels only pending main and prior ids, keeps snooze',
    () async {
      await NotificationService().rescheduleUpcoming();

      expect(calls.map((c) => c.method), isNot(contains('cancelAll')));
      expect(cancelledIds(), containsAll([4, 5]));
      expect(cancelledIds(), isNot(contains(6)), reason: 'live snooze id');
    },
  );
}
