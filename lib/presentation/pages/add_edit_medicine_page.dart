import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/di/injection_container.dart';
import '../../core/services/notification_service.dart';
// COMMENTED OUT FOR UPCOMING RELEASE
// import '../../core/services/profile_service.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../domain/entities/medicine.dart';
import '../blocs/medicine/medicine_cubit.dart';
import '../blocs/medicine/medicine_state.dart';

/// Page for adding or editing a medicine
class AddEditMedicinePage extends StatefulWidget {
  final Medicine? medicine; // null for add, non-null for edit

  const AddEditMedicinePage({super.key, this.medicine});

  @override
  State<AddEditMedicinePage> createState() => _AddEditMedicinePageState();
}

class _AddEditMedicinePageState extends State<AddEditMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageAmountController = TextEditingController();
  final _notesController = TextEditingController();
  final _totalQuantityController = TextEditingController();
  final _refillRemindDaysController = TextEditingController();

  // List to store selected reminder times (as seconds since midnight)
  final List<int> _reminderTimes = [];

  // Selected medicine type
  MedicineType _selectedMedicineType = MedicineType.tablet;

  // Selected intake timing
  MedicineIntakeTiming _selectedIntakeTiming = MedicineIntakeTiming.anytime;

  // Refill tracking toggle
  bool _enableRefillTracking = false;

  bool get _isEditMode => widget.medicine != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadMedicineData();
    }
  }

  void _loadMedicineData() {
    final medicine = widget.medicine!;
    _nameController.text = medicine.name;
    _selectedMedicineType = medicine.medicineType;
    _dosageAmountController.text = medicine.dosageAmount == medicine.dosageAmount.toInt()
        ? medicine.dosageAmount.toInt().toString()
        : medicine.dosageAmount.toString();
    _notesController.text = medicine.notes ?? '';
    _reminderTimes.addAll(medicine.reminderTimes);
    _selectedIntakeTiming = medicine.intakeTiming;

    // Load refill tracking data
    if (medicine.totalQuantity != null) {
      _enableRefillTracking = true;
      _totalQuantityController.text = medicine.totalQuantity == medicine.totalQuantity!.toInt()
          ? medicine.totalQuantity!.toInt().toString()
          : medicine.totalQuantity.toString();
      _refillRemindDaysController.text = (medicine.refillRemindDays ?? 7).toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageAmountController.dispose();
    _notesController.dispose();
    _totalQuantityController.dispose();
    _refillRemindDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode
              ? AppLocalizations.of(context)!.editMedicine
              : AppLocalizations.of(context)!.addMedicine,
        ),
        centerTitle: true,
      ),
      body: BlocListener<MedicineCubit, MedicineState>(
        listenWhen: (previous, current) {
          // Only listen to relevant state changes
          return (current is MedicineOperationSuccess || current is MedicineError) &&
              previous != current;
        },
        listener: (context, state) async {
          if (state is MedicineOperationSuccess) {
            // Schedule notifications for the medicine if it was successfully saved
            try {
              final notificationService = getIt<NotificationService>();

              // Check permission first
              final hasPermission = await notificationService.areNotificationsEnabled();
              if (!hasPermission) {
                final granted = await notificationService.requestPermissions();
                if (!granted && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification permission required for reminders'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            } catch (e) {
              // Silently handle permission errors
            }

            // Show success message
            if (context.mounted) {
              // Clear any existing snackbars first
              ScaffoldMessenger.of(context).clearSnackBars();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );

              // Wait a bit before navigating to ensure snackbar is visible
              await Future.delayed(const Duration(milliseconds: 500));

              // Navigate back with success result
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            }
          }

          if (state is MedicineError) {
            // Clear any existing snackbars
            if (context.mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
            }

            // Show error message
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            children: [
              // Instructions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: AppSizes.paddingM),
                      Expanded(
                        child: Text(
                          _isEditMode
                              ? 'Update your medicine details'
                              : 'Add a new medicine and set reminder times',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),

              // Medicine Name
              CustomTextField(
                label: AppLocalizations.of(context)!.medicineName,
                hint: 'e.g., Aspirin',
                controller: _nameController,
                validator: Validators.medicineName,
                prefixIcon: const Icon(Icons.medication),
                keyboardType: TextInputType.text,
                autofocus: !_isEditMode, // Auto-focus for new medicines
                maxLength: 50, // Standard max length
                textCapitalization: TextCapitalization.words,
                semanticLabel: 'Medicine name input field',
              ),
              const SizedBox(height: AppSizes.paddingM),

              // Medicine Type
              Text('Medicine Type', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSizes.paddingS),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                    vertical: AppSizes.paddingS,
                  ),
                  child: DropdownButtonFormField<MedicineType>(
                    initialValue: _selectedMedicineType,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        _getMedicineTypeIcon(_selectedMedicineType),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    items: MedicineType.values.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type.label));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMedicineType = value;
                          // Clear dosage amount when type changes
                          if (!_isEditMode) {
                            _dosageAmountController.clear();
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingM),

              // Dosage Amount
              CustomTextField(
                label: 'Dosage Amount',
                hint: _getDosageHint(),
                controller: _dosageAmountController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter dosage amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
                prefixIcon: const Icon(Icons.medical_information),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                suffixText: _selectedMedicineType.unit,
                semanticLabel: 'Dosage amount input field',
              ),
              const SizedBox(height: AppSizes.paddingM),

              // Intake Timing
              Text('When to take', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSizes.paddingS),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                    vertical: AppSizes.paddingS,
                  ),
                  child: DropdownButtonFormField<MedicineIntakeTiming>(
                    initialValue: _selectedIntakeTiming,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        _getIntakeTimingIcon(_selectedIntakeTiming),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    items: MedicineIntakeTiming.values.map((timing) {
                      return DropdownMenuItem(value: timing, child: Text(timing.label));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedIntakeTiming = value;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingM),

              // Notes (Optional)
              CustomTextField(
                label: '${AppLocalizations.of(context)!.notes} (Optional)',
                hint: 'e.g., Take with food',
                controller: _notesController,
                prefixIcon: const Icon(Icons.note),
                maxLines: 3,
                maxLength: 200, // Standard max length for notes
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                showValidationIndicator: false, // Optional field, no validation indicator
                semanticLabel: 'Additional notes input field, optional',
              ),
              const SizedBox(height: AppSizes.paddingL),

              // Refill Tracking Section
              // Row(
              //   children: [
              //     Expanded(
              //       child: Text(
              //         'Refill Tracking',
              //         style: Theme.of(context).textTheme.titleLarge,
              //       ),
              //     ),
              //     Switch(
              //       value: _enableRefillTracking,
              //       onChanged: (value) {
              //         setState(() {
              //           _enableRefillTracking = value;
              //           if (!value) {
              //             _totalQuantityController.clear();
              //             _refillRemindDaysController.clear();
              //           } else {
              //             // Set default values
              //             _refillRemindDaysController.text = '7';
              //           }
              //         });
              //       },
              //     ),
              //   ],
              // ),
              // const SizedBox(height: AppSizes.paddingS),
              // Text(
              //   'Track medicine stock and get refill reminders',
              //   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              //     color: Theme.of(
              //       context,
              //     ).colorScheme.onSurface.withValues(alpha: 0.7),
              //   ),
              // ),
              // if (_enableRefillTracking) ...[
              //   const SizedBox(height: AppSizes.paddingM),
              //   Card(
              //     child: Padding(
              //       padding: const EdgeInsets.all(AppSizes.paddingM),
              //       child: Column(
              //         children: [
              //           CustomTextField(
              //             label: 'Total Quantity',
              //             hint: _getQuantityHint(),
              //             controller: _totalQuantityController,
              //             prefixIcon: const Icon(Icons.inventory_2),
              //             keyboardType: const TextInputType.numberWithOptions(
              //               decimal: true,
              //             ),
              //             suffixText: _selectedMedicineType.unit,
              //             validator: (value) {
              //               if (_enableRefillTracking) {
              //                 if (value == null || value.isEmpty) {
              //                   return 'Please enter total quantity';
              //                 }
              //                 final quantity = double.tryParse(value);
              //                 if (quantity == null || quantity <= 0) {
              //                   return 'Please enter a valid quantity';
              //                 }
              //               }
              //               return null;
              //             },
              //             semanticLabel: 'Total medicine quantity',
              //           ),
              //           const SizedBox(height: AppSizes.paddingM),
              //           CustomTextField(
              //             label: 'Refill Reminder (days before)',
              //             hint: 'e.g., 7 days',
              //             controller: _refillRemindDaysController,
              //             prefixIcon: const Icon(Icons.notifications_active),
              //             keyboardType: TextInputType.number,
              //             validator: (value) {
              //               if (_enableRefillTracking) {
              //                 if (value == null || value.isEmpty) {
              //                   return 'Please enter refill reminder days';
              //                 }
              //                 final days = int.tryParse(value);
              //                 if (days == null || days < 1 || days > 90) {
              //                   return 'Enter between 1-90 days';
              //                 }
              //               }
              //               return null;
              //             },
              //             semanticLabel: 'Refill reminder days',
              //           ),
              //           const SizedBox(height: AppSizes.paddingS),
              //           Container(
              //             padding: const EdgeInsets.all(AppSizes.paddingM),
              //             decoration: BoxDecoration(
              //               color: Theme.of(
              //                 context,
              //               ).colorScheme.primary.withValues(alpha: 0.1),
              //               borderRadius: BorderRadius.circular(
              //                 AppSizes.radiusM,
              //               ),
              //             ),
              //             child: Row(
              //               children: [
              //                 Icon(
              //                   Icons.info_outline,
              //                   size: 20,
              //                   color: Theme.of(context).colorScheme.primary,
              //                 ),
              //                 const SizedBox(width: AppSizes.paddingS),
              //                 Expanded(
              //                   child: Text(
              //                     'You\'ll be notified when you have this many days of medicine left',
              //                     style: Theme.of(context).textTheme.bodySmall
              //                         ?.copyWith(
              //                           color: Theme.of(
              //                             context,
              //                           ).colorScheme.primary,
              //                         ),
              //                   ),
              //                 ),
              //               ],
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
              // ],
              // const SizedBox(height: AppSizes.paddingL),

              // Reminder Times Section
              Text('Reminder Times', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSizes.paddingS),
              Text(
                'Set times when you need to take this medicine',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSizes.paddingM),

              // Display reminder times
              if (_reminderTimes.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingL),
                    child: Column(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: AppSizes.iconXL,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: AppSizes.paddingS),
                        Text('No reminder times set', style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 4),
                        Text(
                          'Tap the button below to add',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: AppSizes.paddingS,
                  runSpacing: AppSizes.paddingS,
                  children: _reminderTimes.map((seconds) {
                    final time = DateTimeUtils.secondsToDateTime(seconds);
                    final timeString = DateTimeUtils.formatTime(time);
                    final timeOfDay = DateTimeUtils.getTimeOfDayString(time);

                    return Chip(
                      avatar: Icon(_getTimeOfDayIcon(timeOfDay), size: 18),
                      label: Text(timeString, style: const TextStyle(fontWeight: FontWeight.w600)),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _reminderTimes.remove(seconds);
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: AppSizes.paddingM),

              // Add reminder time button
              OutlinedButton.icon(
                onPressed: _addReminderTime,
                icon: const Icon(Icons.add_alarm),
                label: const Text('Add Reminder Time'),
              ),
              const SizedBox(height: AppSizes.paddingXL),

              // Save button
              BlocBuilder<MedicineCubit, MedicineState>(
                builder: (context, state) {
                  final isLoading = state is MedicineLoading;
                  return CustomButton(
                    text: _isEditMode ? 'Update Medicine' : 'Save Medicine',
                    icon: Icons.check,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _saveMedicine,
                  );
                },
              ),
              const SizedBox(height: AppSizes.paddingM),

              // Cancel button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show time picker and add selected time
  Future<void> _addReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Convert TimeOfDay to seconds since midnight
      final seconds = (picked.hour * 3600) + (picked.minute * 60);

      // Check if time already exists
      if (_reminderTimes.contains(seconds)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This time is already added'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Check if picked time has already passed today (for new medicines only)
      if (!_isEditMode) {
        final now = DateTime.now();
        final currentSeconds = (now.hour * 3600) + (now.minute * 60);

        if (seconds < currentSeconds) {
          // Time has passed, show confirmation dialog
          final shouldAdd = await _showPastTimeDialog(picked);
          if (!shouldAdd) return;
        }
      }

      setState(() {
        _reminderTimes.add(seconds);
        // Sort times chronologically
        _reminderTimes.sort();
      });
    }
  }

  /// Show dialog for past time confirmation
  Future<bool> _showPastTimeDialog(TimeOfDay time) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          icon: Icon(Icons.schedule, size: 48, color: theme.colorScheme.secondary),
          title: const Text('Time Already Passed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The time ${time.format(context)} has already passed today.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.paddingM),
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: AppSizes.paddingS),
                    Expanded(
                      child: Text(
                        'First reminder will be scheduled for tomorrow at ${time.format(context)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add Anyway'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Validate and save medicine
  Future<void> _saveMedicine() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if at least one reminder time is set
    if (_reminderTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorScheduleRequired),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Get active profile ID
    // COMMENTED OUT FOR UPCOMING RELEASE - profile support
    // final profileService = getIt<ProfileService>();
    // final activeProfileId = await profileService.getActiveProfileId();
    // if (activeProfileId == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('No active profile found. Please create a profile first.'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    //   return;
    // }
    const activeProfileId = 1; // Default profile ID for now

    // Parse dosage amount
    final dosageAmount = double.parse(_dosageAmountController.text.trim());

    // Parse refill tracking values
    double? totalQuantity;
    double? currentQuantity;
    int? refillRemindDays;
    DateTime? lastRefillDate;

    if (_enableRefillTracking) {
      totalQuantity = double.tryParse(_totalQuantityController.text.trim());
      currentQuantity = totalQuantity; // Initialize with total on creation
      refillRemindDays = int.tryParse(_refillRemindDaysController.text.trim());
      lastRefillDate = DateTime.now(); // Mark now as refill date

      // If editing, preserve current quantity from existing medicine
      if (_isEditMode && widget.medicine!.currentQuantity != null) {
        currentQuantity = widget.medicine!.currentQuantity;
        lastRefillDate = widget.medicine!.lastRefillDate;
      }
    }

    // Generate dosage string (e.g., "2 tablets", "500 ml")
    String dosageString;
    if (dosageAmount == dosageAmount.toInt()) {
      final intAmount = dosageAmount.toInt();
      dosageString =
          '$intAmount ${intAmount == 1 ? _selectedMedicineType.unit : "${_selectedMedicineType.unit}${_selectedMedicineType == MedicineType.syrup || _selectedMedicineType == MedicineType.injection ? "" : "s"}"}';
    } else {
      dosageString = '$dosageAmount ${_selectedMedicineType.unit}';
    }

    // Create medicine object
    final medicine = Medicine(
      id: _isEditMode ? widget.medicine!.id : null,
      profileId: _isEditMode ? widget.medicine!.profileId : activeProfileId,
      name: _nameController.text.trim(),
      medicineType: _selectedMedicineType,
      dosageAmount: dosageAmount,
      dosage: dosageString,
      reminderTimes: _reminderTimes,
      intakeTiming: _selectedIntakeTiming,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      totalQuantity: totalQuantity,
      currentQuantity: currentQuantity,
      refillRemindDays: refillRemindDays,
      lastRefillDate: lastRefillDate,
      isActive: _isEditMode ? widget.medicine!.isActive : true,
      createdAt: _isEditMode ? widget.medicine!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save using cubit
    if (_isEditMode) {
      getIt<MedicineCubit>().updateMedicine(medicine);
    } else {
      getIt<MedicineCubit>().addMedicine(medicine);
    }

    // Schedule notifications after saving
    // The medicine will get an ID after being saved
    // We'll schedule notifications after the state updates to MedicineOperationSuccess
    Navigator.of(context).pop(true);
  }

  /// Get icon based on time of day
  IconData _getTimeOfDayIcon(String timeOfDay) {
    switch (timeOfDay) {
      case 'Morning':
        return Icons.wb_sunny;
      case 'Afternoon':
        return Icons.wb_sunny_outlined;
      case 'Evening':
        return Icons.nights_stay;
      case 'Night':
        return Icons.bedtime;
      default:
        return Icons.access_time;
    }
  }

  /// Get icon for intake timing
  IconData _getIntakeTimingIcon(MedicineIntakeTiming timing) {
    switch (timing) {
      case MedicineIntakeTiming.beforeFood:
        return Icons.restaurant_menu;
      case MedicineIntakeTiming.afterFood:
        return Icons.dinner_dining;
      case MedicineIntakeTiming.withFood:
        return Icons.fastfood;
      case MedicineIntakeTiming.empty:
        return Icons.no_meals;
      case MedicineIntakeTiming.beforeSleep:
        return Icons.bedtime;
      case MedicineIntakeTiming.anytime:
        return Icons.schedule;
    }
  }

  /// Get icon for medicine type
  IconData _getMedicineTypeIcon(MedicineType type) {
    switch (type) {
      case MedicineType.tablet:
        return Icons.medication;
      case MedicineType.capsule:
        return Icons.medication_liquid;
      case MedicineType.syrup:
        return Icons.local_drink;
      case MedicineType.drops:
        return Icons.water_drop;
      case MedicineType.injection:
        return Icons.vaccines;
      case MedicineType.inhaler:
        return Icons.air;
      case MedicineType.ointment:
        return Icons.healing;
      case MedicineType.patch:
        return Icons.label;
      case MedicineType.other:
        return Icons.medical_services;
    }
  }

  /// Get dosage hint based on medicine type
  String _getDosageHint() {
    switch (_selectedMedicineType) {
      case MedicineType.tablet:
        return 'e.g., 1, 2, 0.5';
      case MedicineType.capsule:
        return 'e.g., 1, 2';
      case MedicineType.syrup:
        return 'e.g., 5, 10, 500';
      case MedicineType.drops:
        return 'e.g., 2, 3, 5';
      case MedicineType.injection:
        return 'e.g., 1, 2, 5';
      case MedicineType.inhaler:
        return 'e.g., 1, 2';
      case MedicineType.ointment:
        return 'e.g., 1, 2';
      case MedicineType.patch:
        return 'e.g., 1';
      case MedicineType.other:
        return 'e.g., 1';
    }
  }

  /// Get quantity hint for refill tracking based on medicine type
  // String _getQuantityHint() {
  //   switch (_selectedMedicineType) {
  //     case MedicineType.tablet:
  //     case MedicineType.capsule:
  //       return 'e.g., 30, 60 (total ${_selectedMedicineType.unit}s)';
  //     case MedicineType.syrup:
  //     case MedicineType.injection:
  //       return 'e.g., 100, 200 (total ${_selectedMedicineType.unit})';
  //     case MedicineType.drops:
  //       return 'e.g., 50, 100 (total ${_selectedMedicineType.unit})';
  //     case MedicineType.inhaler:
  //       return 'e.g., 120, 200 (total ${_selectedMedicineType.unit}s)';
  //     case MedicineType.ointment:
  //     case MedicineType.patch:
  //       return 'e.g., 1, 5 (total ${_selectedMedicineType.unit}s)';
  //     case MedicineType.other:
  //       return 'e.g., 30 (total ${_selectedMedicineType.unit}s)';
  //   }
  // }
}
