import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:medify/core/theme/app_theme.dart';
import 'package:medify/features/transition/presentation/reset_gate_cubit.dart';

/// Minimal themed app for the 2.0 reset notice. No BLoC, DI, or notifications.
class ResetGateApp extends StatelessWidget {
  const ResetGateApp({super.key, required this.cubit});

  final ResetGateCubit cubit;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: ResetGateScreen(cubit: cubit),
    );
  }
}

class ResetGateScreen extends StatelessWidget {
  const ResetGateScreen({super.key, required this.cubit});

  final ResetGateCubit cubit;

  @override
  Widget build(BuildContext context) {
    final showExit = defaultTargetPlatform == TargetPlatform.android;
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<ResetGateState>(
          valueListenable: cubit.state,
          builder: (context, state, _) {
            final body = switch (state) {
              ResetGateChecking() || ResetGateRunning() => const Center(
                child: CircularProgressIndicator(),
              ),
              ResetGateNotice() => _Message(
                text:
                    'Medify 2.0 is here. We have changed the database, so your '
                    'existing data will be reset. Thank you for your patience.\n\n'
                    'This cannot be undone.',
                actions: [
                  _Action(
                    label: 'Continue',
                    filled: true,
                    onPressed: cubit.continueReset,
                  ),
                  _Action(label: 'Not now', onPressed: cubit.notNow),
                  if (showExit) _exit,
                ],
              ),
              ResetGateDeclined() => _Message(
                text:
                    'Your data is unchanged. Medify will ask again the next '
                    'time you open it.',
                actions: [
                  _Action(
                    label: 'Reconsider',
                    filled: true,
                    onPressed: cubit.reconsider,
                  ),
                  if (showExit) _exit,
                ],
              ),
              ResetGateFailed(:final retry) => _Message(
                text: 'The reset did not finish. Tap Retry to try again.',
                actions: [
                  _Action(label: 'Retry', filled: true, onPressed: retry),
                ],
              ),
            };
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(child: body),
            );
          },
        ),
      ),
    );
  }

  static const _exit = _Action(label: 'Exit', onPressed: SystemNavigator.pop);
}

class _Action {
  const _Action({
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.actions});

  final String text;
  final List<_Action> actions;

  @override
  Widget build(BuildContext context) {
    const buttonStyleSize = Size.fromHeight(48);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Text(text, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        for (final action in actions) ...[
          action.filled
              ? FilledButton(
                  style: FilledButton.styleFrom(minimumSize: buttonStyleSize),
                  onPressed: action.onPressed,
                  child: Text(action.label),
                )
              : OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: buttonStyleSize),
                  onPressed: action.onPressed,
                  child: Text(action.label),
                ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
