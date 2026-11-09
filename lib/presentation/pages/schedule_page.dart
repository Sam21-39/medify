import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/di/injection_container.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/medicine_log.dart';
import '../blocs/medicine/medicine_cubit.dart';
import '../blocs/medicine/medicine_state.dart';
import '../blocs/medicine_log/medicine_log_cubit.dart';
import '../blocs/medicine_log/medicine_log_state.dart';
import '../widgets/medicine_log_card.dart';
// COMMENTED OUT FOR UPCOMING RELEASE
// import '../widgets/profile_switcher.dart';
import 'settings_page.dart';

/// Page to display today's medicine schedule
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Medicine> _medicines = [];
  List<MedicineLog> _logs = [];
  final DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when page becomes visible (e.g., after adding medicine)
    if (ModalRoute.of(context)?.isCurrent == true) {
      _loadData();
    }
  }

  void _loadData() {
    getIt<MedicineCubit>().loadActiveMedicines();
    if (_isToday()) {
      getIt<MedicineLogCubit>().loadTodayLogs();
    } else {
      getIt<MedicineLogCubit>().loadLogsByDate(_selectedDate);
    }
  }

  bool _isToday() {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String _getTitle() {
    if (_isToday()) {
      return 'Today';
    }
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    if (_selectedDate.year == yesterday.year &&
        _selectedDate.month == yesterday.month &&
        _selectedDate.day == yesterday.day) {
      return 'Yesterday';
    }
    if (_selectedDate.year == tomorrow.year &&
        _selectedDate.month == tomorrow.month &&
        _selectedDate.day == tomorrow.day) {
      return 'Tomorrow';
    }
    // Format: "Mon, Jan 15"
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[_selectedDate.weekday - 1]}, ${months[_selectedDate.month - 1]} ${_selectedDate.day}';
  }

  // Future<void> _selectDate() async {
  //   final DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate: _selectedDate,
  //     firstDate: DateTime(2020),
  //     lastDate: DateTime.now().add(const Duration(days: 365)),
  //     helpText: 'Select Date',
  //     cancelText: 'Cancel',
  //     confirmText: 'OK',
  //   );

  //   if (picked != null && picked != _selectedDate) {
  //     setState(() {
  //       _selectedDate = picked;
  //     });
  //     _loadData();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        // COMMENTED OUT FOR UPCOMING RELEASE
        // leading: const Padding(
        //   padding: EdgeInsets.only(left: 8.0),
        //   child: ProfileSwitcher(),
        // ),
        title: Text(_getTitle()),
        centerTitle: true,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.calendar_today),
          //   onPressed: _selectDate,
          //   tooltip: 'Select date',
          // ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData, tooltip: 'Refresh'),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<MedicineLogCubit, MedicineLogState>(
            listenWhen: (previous, current) {
              // Only listen when this page is visible (prevent duplicate toasts)
              return current is MedicineLogOperationSuccess && previous != current;
            },
            listener: (context, state) {
              if (state is MedicineLogOperationSuccess) {
                // Clear any existing snackbars first
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
                _loadData();
              }
            },
          ),
        ],
        child: RefreshIndicator(
          onRefresh: () async {
            _loadData();
          },
          child: BlocBuilder<MedicineCubit, MedicineState>(
            bloc: getIt<MedicineCubit>(), // Explicitly use singleton instance
            builder: (context, medicineState) {
              if (medicineState is MedicineLoaded) {
                _medicines = medicineState.medicines;
              }

              return BlocBuilder<MedicineLogCubit, MedicineLogState>(
                bloc: getIt<MedicineLogCubit>(), // Explicitly use singleton instance
                builder: (context, logState) {
                  if (logState is MedicineLogLoading || medicineState is MedicineLoading) {
                    // Use shimmer loading instead of circular progress
                    return const ShimmerLoadingList(
                      itemCount: 5,
                      shimmerWidget: ShimmerMedicineLogCard(),
                    );
                  }

                  if (logState is MedicineLogLoaded) {
                    _logs = logState.logs;

                    if (_logs.isEmpty) {
                      return EmptyState(
                        icon: Icons.calendar_today,
                        title: AppLocalizations.of(context)!.noReminders,
                        message: AppLocalizations.of(context)!.allCaughtUp,
                      );
                    }

                    // Calculate stats
                    final takenCount = _logs
                        .where((log) => log.status == MedicineLogStatus.taken)
                        .length;
                    final totalCount = _logs.length;
                    final adherencePercent = totalCount > 0
                        ? (takenCount / totalCount * 100).round()
                        : 0;

                    // Group logs by time of day
                    final groupedLogs = DateTimeUtils.groupByTimeOfDay(
                      _logs,
                      (log) => log.scheduledTime,
                    );

                    // Sort periods in chronological order
                    final sortedPeriods = [
                      TimeOfDayPeriod.morning,
                      TimeOfDayPeriod.afternoon,
                      TimeOfDayPeriod.evening,
                      TimeOfDayPeriod.night,
                    ];

                    return ListView(
                      padding: const EdgeInsets.all(AppSizes.paddingM),
                      children: [
                        // Progress Card
                        _buildProgressCard(context, takenCount, totalCount, adherencePercent),
                        const SizedBox(height: AppSizes.paddingL),

                        // Time-based sections
                        ...sortedPeriods.expand((period) {
                          final logsForPeriod = groupedLogs[period] ?? [];
                          if (logsForPeriod.isEmpty) return <Widget>[];

                          return [
                            _buildTimeBasedSection(context, period, logsForPeriod),
                            const SizedBox(height: AppSizes.paddingM),
                          ];
                        }),
                      ],
                    );
                  }

                  return EmptyState(
                    icon: Icons.calendar_today,
                    title: AppLocalizations.of(context)!.noReminders,
                    message: 'Add some medicines to see your schedule',
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /// Build progress card
  Widget _buildProgressCard(BuildContext context, int taken, int total, int percent) {
    final theme = Theme.of(context);
    final progress = total > 0 ? taken / total : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: theme.colorScheme.primary, size: AppSizes.iconL),
                const SizedBox(width: AppSizes.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Today's Progress", style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        '$taken of $total medicines taken',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                    vertical: AppSizes.paddingS,
                  ),
                  decoration: BoxDecoration(
                    color: _getProgressColor(percent).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                  ),
                  child: Text(
                    '$percent%',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: _getProgressColor(percent),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingM),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(percent)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build time-based section with expansion tile
  Widget _buildTimeBasedSection(
    BuildContext context,
    TimeOfDayPeriod period,
    List<MedicineLog> logs,
  ) {
    final theme = Theme.of(context);

    // Count statuses
    final pending = logs.where((log) => log.status == MedicineLogStatus.pending).length;
    final taken = logs.where((log) => log.status == MedicineLogStatus.taken).length;
    final overdue = logs
        .where((log) => log.isOverdue && log.status == MedicineLogStatus.pending)
        .length;

    return Card(
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: pending > 0 || overdue > 0, // Expand if has pending/overdue
          title: Row(
            children: [
              Text(period.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: AppSizes.paddingS),
              Text(
                period.label,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: AppSizes.paddingS),
              Text(
                period.timeRange,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${logs.length} medicine${logs.length == 1 ? '' : 's'}'
              '${taken > 0 ? ' • $taken taken' : ''}'
              '${pending > 0 ? ' • $pending pending' : ''}'
              '${overdue > 0 ? ' • $overdue overdue' : ''}',
              style: theme.textTheme.bodySmall,
            ),
          ),
          children: logs.map((log) {
            final medicine = _getMedicineForLog(log);
            if (medicine == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingM,
                vertical: AppSizes.paddingS,
              ),
              child: MedicineLogCard(
                medicine: medicine,
                log: log,
                onTaken: () => _markAsTaken(log.id!),
                onSkip: () => _markAsSkipped(log.id!),
                onSnooze: (minutes) => _snoozeLog(log.id!, minutes),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Get medicine for a log
  Medicine? _getMedicineForLog(MedicineLog log) {
    try {
      return _medicines.firstWhere((m) => m.id == log.medicineId);
    } catch (e) {
      return null;
    }
  }

  /// Get progress color based on percentage
  Color _getProgressColor(int percent) {
    if (percent >= 80) return AppColors.success;
    if (percent >= 50) return AppColors.warning;
    return AppColors.error;
  }

  /// Mark log as taken
  void _markAsTaken(int logId) {
    getIt<MedicineLogCubit>().markAsTaken(logId);
  }

  /// Mark log as skipped
  void _markAsSkipped(int logId) {
    getIt<MedicineLogCubit>().markAsSkipped(logId);
  }

  /// Snooze log
  void _snoozeLog(int logId, int minutes) {
    getIt<MedicineLogCubit>().snoozeLog(logId, minutes);
  }
}
