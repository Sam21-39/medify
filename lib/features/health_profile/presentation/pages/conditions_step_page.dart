import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/health_profile_cubit.dart';

class ConditionsStepPage extends StatefulWidget {
  const ConditionsStepPage({super.key});

  @override
  State<ConditionsStepPage> createState() => _ConditionsStepPageState();
}

class _ConditionsStepPageState extends State<ConditionsStepPage> {
  final _allergyController = TextEditingController();
  final _conditionController = TextEditingController();
  final List<String> _allergies = [];
  final List<String> _chronicConditions = [];

  @override
  void dispose() {
    _allergyController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  void _addChip(TextEditingController controller, List<String> target) {
    final value = controller.text.trim();
    if (value.isEmpty) return;
    setState(() {
      target.add(value);
      controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Conditions & Allergies',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const Text('Allergies'),
          Wrap(
            spacing: 8,
            children: _allergies
                .map(
                  (a) => Chip(
                    label: Text(a),
                    onDeleted: () => setState(() => _allergies.remove(a)),
                  ),
                )
                .toList(),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _allergyController,
                  decoration: const InputDecoration(hintText: 'Add allergy'),
                  onSubmitted: (_) => _addChip(_allergyController, _allergies),
                ),
              ),
              IconButton(
                onPressed: () => _addChip(_allergyController, _allergies),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Current Conditions'),
          Wrap(
            spacing: 8,
            children: _chronicConditions
                .map(
                  (c) => Chip(
                    label: Text(c),
                    onDeleted: () =>
                        setState(() => _chronicConditions.remove(c)),
                  ),
                )
                .toList(),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _conditionController,
                  decoration: const InputDecoration(hintText: 'Add condition'),
                  onSubmitted: (_) =>
                      _addChip(_conditionController, _chronicConditions),
                ),
              ),
              IconButton(
                onPressed: () =>
                    _addChip(_conditionController, _chronicConditions),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              TextButton(
                onPressed: () =>
                    context.read<HealthProfileCubit>().backToBasicInfo(),
                child: const Text('Back'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  final cubit = context.read<HealthProfileCubit>();
                  cubit.updateConditions(
                    allergies: _allergies,
                    chronicConditions: _chronicConditions,
                  );
                  cubit.goToEmergencyStep();
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
