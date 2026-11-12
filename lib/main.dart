import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:medify/app/launch.dart';
import 'package:medify/core/platform/medify_timezone_channel.dart';
import 'package:medify/core/transition/legacy_reset.dart';
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
      final cubit = ResetGateCubit(
        reset: reset,
        onComplete: () => launchApp(onFailure: _showStartupError),
      );
      runApp(ResetGateApp(cubit: cubit));
      unawaited(cubit.start());
      return;
    }
    await launchApp(onFailure: _showStartupError);
  } catch (error) {
    debugPrint('Startup failed: $error');
    _showStartupError();
  }
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
    await launchApp();
  } catch (error) {
    debugPrint('Startup retry failed: $error');
    _showStartupError();
  }
}
