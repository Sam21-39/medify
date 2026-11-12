import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/database/medify_database.dart';
import 'package:medify/core/database/settings_store.dart';
import 'package:medify/core/error/failure.dart';
import 'package:medify/core/notifications/notification_service.dart';
import 'package:medify/core/security/field_cipher.dart';
import 'package:medify/features/medicines/data/sqflite/medicine_sqflite_repository.dart';
import 'package:medify/features/medicines/domain/entities/medicine.dart';
import 'package:medify/features/schedule/data/services/refill_reminder_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Medicine medicine({
  double? quantity,
  double dose = 1,
  List<int> times = const [28800],
}) => Medicine(
  profileId: 1,
  name: 'Aspirin',
  dosage: '1 tablet',
  dosageAmount: dose,
  reminderTimes: times,
  currentQuantity: quantity,
  refillRemindDays: 7,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('alert rule', () {
    test('alerts once per level crossing', () {
      expect(shouldAlert(RefillLevel.none, RefillLevel.low), isTrue);
      expect(shouldAlert(RefillLevel.low, RefillLevel.low), isFalse);
      expect(shouldAlert(RefillLevel.low, RefillLevel.out), isTrue);
      expect(shouldAlert(RefillLevel.out, RefillLevel.out), isFalse);
    });

    test('a refill drops the level to none, so low alerts again', () {
      // Out, refilled (stored as none), then low again.
      expect(shouldAlert(RefillLevel.out, RefillLevel.none), isFalse);
      expect(shouldAlert(RefillLevel.none, RefillLevel.low), isTrue);
    });

    test('level follows stock', () {
      expect(refillLevel(medicine(quantity: 0)), RefillLevel.out);
      expect(refillLevel(medicine(quantity: 3)), RefillLevel.low);
      expect(refillLevel(medicine(quantity: 30)), RefillLevel.none);
    });
  });

  test('days remaining counts dose amount per dose', () {
    // 10 units, 2 units per dose, 2 doses a day: 4 a day, so 2 days.
    final m = medicine(quantity: 10, dose: 2, times: const [28800, 72000]);
    expect(m.daysRemaining, 2);
  });

  group('cold start', () {
    late Database db;
    late SqfliteMedicineRepository repo;
    final channel = const MethodChannel(
      'dexterous.com/flutter/local_notifications',
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    late List<MethodCall> calls;

    setUp(() async {
      FlutterLocalNotificationsPlatform.instance =
          AndroidFlutterLocalNotificationsPlugin();
      calls = [];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
      db = await MedifyDatabase.open(path: inMemoryDatabasePath);
      repo = SqfliteMedicineRepository(db, FieldCipher(List.filled(32, 7)));
      await db.insert('profiles', {
        'name': 'Patient',
        'role': 'patient',
        'color_value': 0,
        'created_at': 0,
        'updated_at': 0,
      });
    });

    tearDown(() async {
      messenger.setMockMethodCallHandler(channel, null);
      await db.close();
    });

    test('two launches while stock is low give one notification', () async {
      await repo.addMedicine(medicine(quantity: 3));
      final service = RefillReminderService(
        NotificationService(),
        repo,
        SettingsStore(db),
      );

      await service.checkAndScheduleRefillReminders();
      await service.checkAndScheduleRefillReminders();

      expect(calls.where((c) => c.method == 'show'), hasLength(1));
    });

    test('low, refill, low again gives two notifications', () async {
      final added = (await repo.addMedicine(medicine(quantity: 3))).unwrap();
      final service = RefillReminderService(
        NotificationService(),
        repo,
        SettingsStore(db),
      );

      await service.checkAndScheduleRefillReminders();
      await service.refillMedicine(added.id!, newQuantity: 3);
      await service.checkAndScheduleRefillReminders();

      expect(calls.where((c) => c.method == 'show'), hasLength(2));
    });
  });
}
