import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medify/core/theme/app_theme.dart';
import 'package:medify/core/utils/constants.dart';
import 'package:medify/core/utils/validators.dart';
import 'package:medify/app/data/models/medication_model.dart';
import '../controllers/medication_controller.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final MedicationController _controller = Get.find<MedicationController>();
  final PageController _pageController = PageController();
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  int _currentStep = 0;
  final int _totalSteps = 3;

  // Step 1: Basic Info
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  String _selectedUnit = 'mg';

  // Step 2: Schedule
  FrequencyType _frequencyType = FrequencyType.daily;
  int _interval = 1;
  final List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];

  // Step 3: Additional Info
  final _instructionsController = TextEditingController();
  final _quantityController = TextEditingController();
  final _refillThresholdController = TextEditingController(text: '5');
  Color _selectedColor = AppTheme.primaryColor;

  final List<Color> _colorOptions = [
    AppTheme.primaryColor,
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.teal,
    Colors.cyan,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.brown,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _quantityController.dispose();
    _refillThresholdController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_formKeyStep1.currentState!.validate()) return;
    } else if (_currentStep == 1) {
      if (_selectedTimes.isEmpty) {
        Get.snackbar('Error', 'Please add at least one time');
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else {
      _saveMedication();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  void _saveMedication() {
    if (!_formKeyStep3.currentState!.validate()) return;

    // Convert TimeOfDay to MedicationTime
    final times = _selectedTimes
        .map((t) => MedicationTime(hour: t.hour, minute: t.minute))
        .toList();

    // Create Frequency
    final frequency = MedicationFrequency(type: _frequencyType, intervalDays: _interval);

    _controller.addMedication(
      name: _nameController.text.trim(),
      dosage: double.parse(_dosageController.text),
      unit: _selectedUnit,
      frequency: frequency,
      times: times,
      instructions: _instructionsController.text.trim(),
      quantity: int.tryParse(_quantityController.text),
      refillThreshold: int.tryParse(_refillThresholdController.text),
      color: _selectedColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
      ),
      body: Column(
        children: [
          // Progress Indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: AppTheme.surfaceColor,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildStep1(), _buildStep2(), _buildStep3()],
            ),
          ),

          // Navigation Buttons
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  OutlinedButton(onPressed: _previousStep, child: const Text('Back'))
                else
                  const SizedBox.shrink(),

                ElevatedButton(
                  onPressed: _nextStep,
                  child: Text(_currentStep == _totalSteps - 1 ? 'Save' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Form(
        key: _formKeyStep1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basic Information', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppTheme.spacingM),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name',
                hintText: 'e.g., Aspirin',
                prefixIcon: Icon(Icons.medication),
              ),
              validator: Validators.validateMedicationName,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Dosage & Unit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _dosageController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Dosage', hintText: 'e.g., 500'),
                    validator: Validators.validateDosage,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: AppConstants.medicationUnits.map((unit) {
                      return DropdownMenuItem(value: unit, child: Text(unit));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedUnit = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Form(
        key: _formKeyStep2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Schedule', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppTheme.spacingM),

            // Frequency Type
            DropdownButtonFormField<FrequencyType>(
              value: _frequencyType,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                prefixIcon: Icon(Icons.repeat),
              ),
              items: FrequencyType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toString().split('.').last.capitalizeFirst!),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _frequencyType = value;
                  });
                }
              },
            ),
            if (_frequencyType == FrequencyType.customInterval) ...[
              const SizedBox(height: AppTheme.spacingM),
              TextFormField(
                initialValue: _interval.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Interval (Days)',
                  hintText: 'e.g., Every 2 days',
                  prefixIcon: Icon(Icons.timer),
                ),
                onChanged: (value) {
                  setState(() {
                    _interval = int.tryParse(value) ?? 1;
                  });
                },
                validator: (value) {
                  if (_frequencyType == FrequencyType.customInterval) {
                    final v = int.tryParse(value ?? '');
                    if (v == null || v < 1) {
                      return 'Enter a valid interval';
                    }
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: AppTheme.spacingL),

            // Times
            Text('Reminder Times', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingS),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedTimes.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(_selectedTimes[index].format(context)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _selectedTimes.removeAt(index);
                        });
                      },
                    ),
                    onTap: () => _selectTime(context, index),
                  ),
                );
              },
            ),

            TextButton.icon(
              onPressed: () => _selectTime(context, null),
              icon: const Icon(Icons.add),
              label: const Text('Add Time'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, int? index) async {
    final initialTime = index != null ? _selectedTimes[index] : TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initialTime);

    if (picked != null) {
      setState(() {
        if (index != null) {
          _selectedTimes[index] = picked;
        } else {
          _selectedTimes.add(picked);
          _selectedTimes.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
        }
      });
    }
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Form(
        key: _formKeyStep3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Additional Details', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppTheme.spacingM),

            // Instructions
            TextFormField(
              controller: _instructionsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Instructions (Optional)',
                hintText: 'e.g., Take with food',
                prefixIcon: Icon(Icons.description),
              ),
              validator: Validators.validateInstructions,
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Inventory
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Current Quantity',
                      hintText: 'e.g., 30',
                    ),
                    validator: Validators.validateQuantity,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: TextFormField(
                    controller: _refillThresholdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Refill Alert At',
                      hintText: 'e.g., 5',
                    ),
                    validator: Validators.validateQuantity,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Color Picker
            Text('Color Tag', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingS),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colorOptions.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: _selectedColor == color
                          ? Border.all(color: Colors.black, width: 2)
                          : null,
                      boxShadow: [
                        if (_selectedColor == color)
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: _selectedColor == color
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
