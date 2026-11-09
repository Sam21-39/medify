import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:medify/app/my_app.dart';
import 'package:medify/core/di/injection_container.dart';
import 'package:medify/core/notifications/notification_service.dart';
import 'package:medify/core/platform/medify_timezone_channel.dart';
import 'package:medify/core/transition/legacy_reset.dart';
import 'package:medify/features/schedule/data/services/daily_log_service.dart';
import 'package:medify/features/transition/presentation/reset_gate_cubit.dart';
import 'package:medify/features/transition/presentation/reset_gate_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  await MedifyTimezoneChannel.setLocalLocation();

  // Existing 1.x users see the reset notice first. New installs skip it.
  final reset = await deviceLegacyReset();
  if (await reset.needsReset()) {
    final cubit = ResetGateCubit(reset: reset, onComplete: _launchApp);
    runApp(ResetGateApp(cubit: cubit));
    unawaited(cubit.start());
    return;
  }
  await _launchApp();
}

/// DI, then the real app. Also reschedules notifications for upcoming
/// occurrences and on every resume, so a new local day picks up day 8.
Future<void> _launchApp() async {
  await initializeDependencies();
  await _scheduleUpcoming();
  WidgetsBinding.instance.addObserver(_DayChangeObserver());
  runApp(MyApp(key: myAppKey));
}

Future<void> _scheduleUpcoming() =>
    getIt<NotificationService>().rescheduleUpcoming();

class _DayChangeObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(() async {
      await getIt<DailyLogService>().generateDailyLogsIfNeeded();
      await _scheduleUpcoming();
    }());
  }
}
