import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

import '../error/failure.dart';
import '../error/result.dart';
import 'notification_scheduler.dart';
import 'reminder_strategy.dart';

@LazySingleton(as: NotificationScheduler)
class FlutterLocalNotificationScheduler implements NotificationScheduler {
  FlutterLocalNotificationScheduler()
    : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  @override
  Future<Result<void, NotificationSchedulingFailure>> schedule(
    ReminderStrategy strategy,
  ) async {
    try {
      switch (strategy) {
        case ExactTimeStrategy():
          // TODO(notifications): zonedSchedule per `strategy.times`, using
          // `timezone` package initialization from bootstrap.dart.
          break;
        case MealRelativeStrategy():
        case IntervalStrategy():
        case WeekdayStrategy():
          // TODO(notifications): Phase 2 strategies.
          break;
      }
      return const Success(null);
    } catch (e) {
      return Error(
        NotificationSchedulingFailure(technicalMessage: e.toString()),
      );
    }
  }

  @override
  Future<Result<void, NotificationSchedulingFailure>> cancel(
    String medicineId,
  ) async {
    try {
      await _plugin.cancel(id: medicineId.hashCode);
      return const Success(null);
    } catch (e) {
      return Error(
        NotificationSchedulingFailure(technicalMessage: e.toString()),
      );
    }
  }
}
