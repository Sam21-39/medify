import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
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
  try {
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
  } catch (error) {
    debugPrint('Startup failed: $error');
    _showStartupError();
  }
}

/// DI, then the real app. Also reschedules notifications for upcoming
/// occurrences and on every resume, so a new local day picks up day 8.
/// Safe to call again after a failed attempt: DI is reset first.
Future<void> _launchApp() async {
  await getIt.reset();
  try {
    await initializeDependencies();
    await _scheduleUpcoming();
  } catch (_) {
    // Release the handle this attempt opened so the retry can reopen it.
    if (getIt.isRegistered<Database>()) await getIt<Database>().close();
    rethrow;
  }
  WidgetsBinding.instance.addObserver(_DayChangeObserver());
  runApp(MyApp(key: myAppKey));
}

/// Minimal screen for a failed launch. Plain text, no BLoC, no DI.
void _showStartupError() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Medify could not start. Tap Retry to try again.'),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _retryLaunch,
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _retryLaunch() async {
  try {
    await _launchApp();
  } catch (error) {
    debugPrint('Startup retry failed: $error');
    _showStartupError();
  }
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
