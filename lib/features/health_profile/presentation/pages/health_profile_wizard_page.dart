import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../cubit/health_profile_cubit.dart';
import '../cubit/health_profile_state.dart';
import '../cubit/profile_gate_cubit.dart';
import 'basic_info_step_page.dart';
import 'conditions_step_page.dart';
import 'emergency_contact_step_page.dart';

/// Hosts the 3-step wizard behind a single BlocProvider, switching the
/// visible step based on HealthProfileCubit's current state.
class HealthProfileWizardPage extends StatelessWidget {
  const HealthProfileWizardPage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<HealthProfileCubit>(),
      child: BlocListener<HealthProfileCubit, HealthProfileState>(
        listener: (context, state) {
          if (state is WizardComplete) {
            getIt<ProfileGateCubit>().markComplete();
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Health Profile')),
          body: SafeArea(
            child: Column(
              children: [
                const _WizardProgressBar(),
                Expanded(
                  child: BlocBuilder<HealthProfileCubit, HealthProfileState>(
                    builder: (context, state) {
                      return switch (state) {
                        WizardStep1Basic() => const BasicInfoStepPage(),
                        WizardStep2Conditions() => const ConditionsStepPage(),
                        WizardStep3Emergency() ||
                        WizardSubmitting() ||
                        WizardError() => EmergencyContactStepPage(uid: uid),
                        WizardComplete() => const SizedBox.shrink(),
                      };
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WizardProgressBar extends StatelessWidget {
  const _WizardProgressBar();

  int _stepIndex(HealthProfileState state) => switch (state) {
    WizardStep1Basic() => 0,
    WizardStep2Conditions() => 1,
    WizardStep3Emergency() || WizardSubmitting() || WizardError() => 2,
    WizardComplete() => 2,
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HealthProfileCubit, HealthProfileState>(
      builder: (context, state) {
        final step = _stepIndex(state);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= step
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
