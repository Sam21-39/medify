import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:medify/core/design/medify_theme_extension.dart';
import 'package:medify/core/di/injection_container.dart';
import 'package:medify/core/preferences/preferences_service.dart';
import 'package:medify/core/ui/app_messenger.dart';
import 'package:medify/core/utils/date_time_utils.dart';
import 'package:medify/core/voice/reminder_voice.dart';
import 'package:medify/features/medicines/presentation/cubit/medicine_cubit.dart';
import 'package:medify/features/medicines/presentation/cubit/medicine_state.dart';
import 'package:medify/features/schedule/domain/entities/medicine_log.dart';
import 'package:medify/features/schedule/presentation/cubit/medicine_log_cubit.dart';
import 'package:medify/features/schedule/presentation/cubit/medicine_log_state.dart';

class AlarmPage extends StatefulWidget {
  const AlarmPage({
    super.key,
    required this.medicineId,
    required this.scheduledSeconds,
  });

  final int medicineId;
  final int scheduledSeconds;

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final time = DateFormat.jm().format(
        DateTimeUtils.secondsToDateTime(widget.scheduledSeconds),
      );
      final meds = context.read<MedicineCubit>().state;
      String? name;
      if (meds is MedicineLoaded) {
        for (final medicine in meds.medicines) {
          if (medicine.id == widget.medicineId) name = medicine.name;
        }
      }
      getIt<ReminderVoice>().speakDose(name: name ?? 'reminder', time: time);
    });
  }

  @override
  void dispose() {
    getIt<ReminderVoice>().stop();
    super.dispose();
  }

  MedicineLog? _log() {
    final state = context.read<MedicineLogCubit>().state;
    if (state is! MedicineLogLoaded) return null;
    final when = DateTimeUtils.secondsToDateTime(widget.scheduledSeconds);
    for (final log in state.logs) {
      if (log.medicineId == widget.medicineId &&
          log.scheduledTime.hour == when.hour &&
          log.scheduledTime.minute == when.minute) {
        return log;
      }
    }
    return null;
  }

  Future<void> _act(Future<void> Function(int id) action) async {
    final log = _log();
    await getIt<ReminderVoice>().stop();
    if (log?.id != null) await action(log!.id!);
    getIt<AppMessenger>().go('/today');
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.jm().format(
      DateTimeUtils.secondsToDateTime(widget.scheduledSeconds),
    );
    final minutes = getIt<PreferencesService>().snoozeDuration;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Medicine reminder', style: MedifyTokens.of(context).title1),
              const SizedBox(height: 8),
              Text(time, style: MedifyTokens.of(context).title2),
              const Spacer(),
              FilledButton(
                onPressed: () =>
                    _act(context.read<MedicineLogCubit>().markAsTaken),
                child: const Text('Taken'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _act(
                  (id) =>
                      context.read<MedicineLogCubit>().snoozeLog(id, minutes),
                ),
                child: const Text('Snooze'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    _act(context.read<MedicineLogCubit>().markAsSkipped),
                child: const Text('Skip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
