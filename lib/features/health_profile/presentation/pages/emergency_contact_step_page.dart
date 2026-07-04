import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/health_profile_cubit.dart';
import '../cubit/health_profile_state.dart';

class EmergencyContactStepPage extends StatefulWidget {
  const EmergencyContactStepPage({super.key, required this.uid});

  final String uid;

  @override
  State<EmergencyContactStepPage> createState() =>
      _EmergencyContactStepPageState();
}

class _EmergencyContactStepPageState extends State<EmergencyContactStepPage> {
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _doctorPhoneController = TextEditingController();

  @override
  void dispose() {
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _doctorNameController.dispose();
    _doctorPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HealthProfileCubit, HealthProfileState>(
      builder: (context, state) {
        final submitting = state is WizardSubmitting;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Emergency Contact',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emergencyNameController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emergencyPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Phone',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _doctorNameController,
                decoration: const InputDecoration(labelText: "Doctor's Name"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _doctorPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Doctor's Phone"),
              ),
              if (state is WizardError) ...[
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  TextButton(
                    onPressed: submitting
                        ? null
                        : () => context
                              .read<HealthProfileCubit>()
                              .backToConditions(),
                    child: const Text('Back'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () {
                            context.read<HealthProfileCubit>().submit(
                              widget.uid,
                              emergencyContactName:
                                  _emergencyNameController.text.trim().isEmpty
                                  ? null
                                  : _emergencyNameController.text.trim(),
                              emergencyContactPhone:
                                  _emergencyPhoneController.text.trim().isEmpty
                                  ? null
                                  : _emergencyPhoneController.text.trim(),
                              doctorName:
                                  _doctorNameController.text.trim().isEmpty
                                  ? null
                                  : _doctorNameController.text.trim(),
                              doctorPhone:
                                  _doctorPhoneController.text.trim().isEmpty
                                  ? null
                                  : _doctorPhoneController.text.trim(),
                            );
                          },
                    child: submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Profile'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
