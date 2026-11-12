import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sqflite/sqflite.dart';

import 'package:medify/app/my_app.dart';
import 'package:medify/core/di/injection_container.dart';
import 'package:medify/core/notifications/notification_service.dart';
import 'package:medify/features/schedule/data/services/daily_log_service.dart';

/// Shows the startup-error screen. Remembered from the last [launchApp] that
/// was given one, so a relaunch after "Delete all data" can use it too.
void Function()? _onLaunchFailure;

/// DI, then the real app. Also reschedules notifications for upcoming
/// occurrences and on every resume, so a new local day picks up day 8.
/// Safe to call again after a failed attempt: DI is reset first.
/// Also called after "Delete all data", which reopens a fresh database.
Future<void> launchApp({void Function()? onFailure}) async {
  if (onFailure != null) _onLaunchFailure = onFailure;
  await getIt.reset();
  try {
    await initializeDependencies();
    await _scheduleUpcoming();
  } catch (_) {
    // Release the handle this attempt opened so the retry can reopen it.
    if (getIt.isRegistered<Database>()) await getIt<Database>().close();
    rethrow;
  }
  _DayChangeObserver.addOnce();
  runApp(MyApp(key: myAppKey));
  unawaited(getIt<NotificationService>().handleLaunchDetails());
}

Future<void> _cancelAllNotifications() =>
    FlutterLocalNotificationsPlugin().cancelAll();

Future<void> _drainNotificationWork() =>
    getIt<NotificationService>().drainReschedules();

/// Cancels notifications, deletes the database file and relaunches, which
/// lands on onboarding. If the first [cancelAll] throws, nothing is touched.
/// After the delete, queued reschedules are drained and notifications are
/// cancelled again, so nothing queued before the wipe survives.
/// A delete failure is rethrown after the relaunch; a relaunch failure goes
/// to [onFailure] and never replaces the delete error.
/// The secure-storage key is kept on purpose: an empty DB with it is valid.
Future<void> wipeAllDataAndRelaunch({
  Future<void> Function() cancelAll = _cancelAllNotifications,
  Future<void> Function() drain = _drainNotificationWork,
  Future<void> Function(String path) deleteDb = deleteDatabase,
  Future<void> Function() launch = launchApp,
  void Function()? onFailure,
}) async {
  await cancelAll();
  final db = getIt<Database>();
  final path = db.path;
  await db.close();

  Object? deleteError;
  StackTrace? deleteStack;
  try {
    await deleteDb(path);
  } catch (error, stack) {
    deleteError = error;
    deleteStack = stack;
  }

  var relaunch = true;
  try {
    await drain();
    await cancelAll();
  } catch (error) {
    debugPrint('Post-wipe notification cancel failed: $error');
    relaunch = false;
  }

  // Unmount MyApp: its router is built once in initState.
  runApp(const SizedBox.shrink());
  await WidgetsBinding.instance.endOfFrame;
  if (relaunch) {
    try {
      await launch();
    } catch (error) {
      debugPrint('Relaunch after wipe failed: $error');
      relaunch = false;
    }
  }
  if (!relaunch) (onFailure ?? _onLaunchFailure)?.call();

  if (deleteError != null) {
    Error.throwWithStackTrace(deleteError, deleteStack!);
  }
}

Future<void> _scheduleUpcoming() =>
    getIt<NotificationService>().rescheduleUpcoming();

class _DayChangeObserver with WidgetsBindingObserver {
  static bool _added = false;

  /// A relaunch must not add a second observer.
  static void addOnce() {
    if (_added) return;
    _added = true;
    WidgetsBinding.instance.addObserver(_DayChangeObserver());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(() async {
      // Between getIt.reset and initializeDependencies these are not registered.
      if (!getIt.isRegistered<DailyLogService>() ||
          !getIt.isRegistered<NotificationService>()) {
        return;
      }
      try {
        await getIt<DailyLogService>().generateDailyLogsIfNeeded();
        await _scheduleUpcoming();
      } catch (error) {
        debugPrint('Day-change refresh failed: $error');
      }
    }());
  }
}
