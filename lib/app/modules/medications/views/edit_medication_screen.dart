import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medify/core/theme/app_theme.dart';
import 'package:medify/core/utils/constants.dart';
import 'package:medify/core/utils/validators.dart';
import 'package:medify/app/data/models/medication_model.dart';
import '../controllers/medication_controller.dart';

class EditMedicationScreen extends StatefulWidget {
  const EditMedicationScreen({super.key});

  @override
  State<EditMedicationScreen> createState() => _EditMedicationScreenState();
}

class _EditMedicationScreenState extends State<EditMedicationScreen> {
  final MedicationController _controller = Get.find<MedicationController>();
  final _formKey = GlobalKey<FormState>();
  late MedicationModel _medication;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _instructionsController;
  late TextEditingController _quantityController;
  late TextEditingController _refillThresholdController;

  // State
  late String _selectedUnit;
  late FrequencyType _frequencyType;
  late int _interval;
  late List<TimeOfDay> _selectedTimes;
  late Color _selectedColor;

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
  void initState() {
    super.initState();
    final String medicationId = Get.arguments as String;
    final med = _controller.medications.firstWhereOrNull((m) => m.id == medicationId);

    if (med == null) {
      Get.back();
      Get.snackbar('Error', 'Medication not found');
      return;
    }

    _medication = med;

    _nameController = TextEditingController(text: med.name);
    _dosageController = TextEditingController(text: med.dosage.toString());
    _instructionsController = TextEditingController(text: med.instructions);
    _quantityController = TextEditingController(text: med.quantity?.toString());
    _refillThresholdController = TextEditingController(text: med.refillThreshold?.toString());

    _selectedUnit = med.unit;
    _frequencyType = med.frequency.type;
    _interval = med.frequency.intervalDays ?? 1;
    _selectedTimes = med.times.map((t) => TimeOfDay(hour: t.hour, minute: t.minute)).toList();
    _selectedColor = med.colorTag != null
        ? Color(int.parse(med.colorTag!, radix: 16))
        : AppTheme.primaryColor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _quantityController.dispose();
    _refillThresholdController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTimes.isEmpty) {
      Get.snackbar('Error', 'Please add at least one time');
      return;
    }

    final times = _selectedTimes
        .map((t) => MedicationTime(hour: t.hour, minute: t.minute))
        .toList();

    final frequency = MedicationFrequency(type: _frequencyType, intervalDays: _interval);

    final updatedMedication = _medication.copyWith(
      name: _nameController.text.trim(),
      dosage: double.parse(_dosageController.text),
      unit: _selectedUnit,
      frequency: frequency,
      times: times,
      instructions: _instructionsController.text.trim(),
      quantity: int.tryParse(_quantityController.text),
      refillThreshold: int.tryParse(_refillThresholdController.text),
      colorTag: _selectedColor.toARGB32().toRadixString(16),
    );

    _controller.updateMedication(updatedMedication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Medication'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context, 'Basic Information'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: Validators.validateMedicationName,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _dosageController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Dosage'),
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
              const SizedBox(height: AppTheme.spacingL),

              _buildSectionHeader(context, 'Schedule'),
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
              const SizedBox(height: AppTheme.spacingM),

              Text('Reminder Times', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppTheme.spacingS),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._selectedTimes.map(
                    (time) => Chip(
                      label: Text(time.format(context)),
                      onDeleted: () {
                        setState(() {
                          _selectedTimes.remove(time);
                        });
                      },
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                    onPressed: () => _selectTime(context),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingL),

              _buildSectionHeader(context, 'Additional Details'),
              TextFormField(
                controller: _instructionsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  prefixIcon: Icon(Icons.description),
                ),
                validator: Validators.validateInstructions,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      validator: Validators.validateQuantity,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: TextFormField(
                      controller: _refillThresholdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Refill Alert'),
                      validator: Validators.validateQuantity,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingL),

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
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());

    if (picked != null) {
      setState(() {
        _selectedTimes.add(picked);
        _selectedTimes.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
      });
    }
  }
}
