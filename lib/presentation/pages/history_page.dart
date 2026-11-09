import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/di/injection_container.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/medicine_log.dart';
import '../blocs/history/history_cubit.dart';
import '../blocs/history/history_state.dart';
// COMMENTED OUT FOR UPCOMING RELEASE
// import '../widgets/profile_switcher.dart';

/// Medicine history page with calendar view
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<HistoryCubit>().loadHistory();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when page becomes visible (e.g., after adding medicine)
    if (ModalRoute.of(context)?.isCurrent == true) {
      getIt<HistoryCubit>().loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // COMMENTED OUT FOR UPCOMING RELEASE
        // leading: const Padding(
        //   padding: EdgeInsets.only(left: 8.0),
        //   child: ProfileSwitcher(),
        // ),
        title: const Text('History'),
        centerTitle: true,
        actions: [
          // Export button
          // IconButton(
          //   icon: const Icon(Icons.share),
          //   onPressed: () {
          //     getIt<HistoryCubit>().exportToCSV();
          //   },
          //   tooltip: 'Export to CSV',
          // ),

          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              getIt<HistoryCubit>().refresh();
            },
            tooltip: 'Refresh',
          ),
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: BlocConsumer<HistoryCubit, HistoryState>(
        listener: (context, state) {
          if (state is HistoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          if (state is HistoryExportSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('History exported successfully!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          if (state is HistoryExporting) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 16),
                    Text('Exporting...'),
                  ],
                ),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is HistoryLoading) {
            // Use shimmer loading for history
            return const ShimmerLoadingList(itemCount: 5, shimmerWidget: ShimmerMedicineLogCard());
          }

          if (state is HistoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: AppSizes.spacing16),
                  Text('Error loading history', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSizes.spacing8),
                  Text(
                    state.message,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.spacing24),
                  ElevatedButton.icon(
                    onPressed: () {
                      getIt<HistoryCubit>().refresh();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is HistoryLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                await getIt<HistoryCubit>().refresh();
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                children: [
                  // Calendar
                  _buildCalendar(context, state),
                  const SizedBox(height: AppSizes.spacing24),

                  // Selected date header
                  _buildDateHeader(context, state),
                  const SizedBox(height: AppSizes.spacing16),

                  // Active filter chips
                  if (state.filter.hasActiveFilters) _buildFilterChips(context, state),

                  // Logs list
                  if (state.logs.isEmpty)
                    EmptyState(
                      icon: Icons.history,
                      title: 'No Logs',
                      message: state.filter.hasActiveFilters
                          ? 'No logs match your filters'
                          : 'No medicines scheduled for this date',
                    )
                  else
                    ..._buildLogsList(context, state),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Build calendar widget
  Widget _buildCalendar(BuildContext context, HistoryLoaded state) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing8),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(state.selectedDate, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
            getIt<HistoryCubit>().selectDate(selectedDay);
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          ),
          headerStyle: HeaderStyle(
            formatButtonDecoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            titleTextStyle: theme.textTheme.titleLarge!,
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              return _buildDateMarker(date, state.calendarLogs);
            },
          ),
        ),
      ),
    );
  }

  /// Build date marker (colored dot)
  Widget? _buildDateMarker(DateTime date, Map<DateTime, List<MedicineLog>> calendarLogs) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final logs = calendarLogs[normalizedDate];

    if (logs == null || logs.isEmpty) return null;

    final total = logs.length;
    final taken = logs.where((log) => log.status == MedicineLogStatus.taken).length;
    final adherenceRate = (taken / total) * 100;

    Color color;
    if (adherenceRate == 100) {
      color = AppColors.success; // Green
    } else if (adherenceRate >= 50) {
      color = AppColors.warning; // Yellow
    } else {
      color = AppColors.error; // Red
    }

    return Positioned(
      bottom: 1,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  /// Build date header
  Widget _buildDateHeader(BuildContext context, HistoryLoaded state) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('EEEE, MMMM d, y').format(state.selectedDate);

    return Row(
      children: [
        Icon(Icons.calendar_today, color: theme.colorScheme.primary),
        const SizedBox(width: AppSizes.spacing8),
        Expanded(
          child: Text(
            dateStr,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (state.logs.isNotEmpty) ...[
          Text(
            '${state.logs.length} log${state.logs.length == 1 ? '' : 's'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  /// Build filter chips
  Widget _buildFilterChips(BuildContext context, HistoryLoaded state) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Active Filters:',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                getIt<HistoryCubit>().clearFilters();
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear All'),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacing8),
        Wrap(
          spacing: AppSizes.spacing8,
          runSpacing: AppSizes.spacing8,
          children: [
            if (state.filter.medicineId != null)
              _buildFilterChip(
                context,
                state.medicines.firstWhere((m) => m.id == state.filter.medicineId).name,
                Icons.medication,
              ),
            if (state.filter.status != null)
              _buildFilterChip(context, _getStatusString(state.filter.status!), Icons.info),
          ],
        ),
        const SizedBox(height: AppSizes.spacing16),
      ],
    );
  }

  /// Build individual filter chip
  Widget _buildFilterChip(BuildContext context, String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
    );
  }

  /// Build logs list
  List<Widget> _buildLogsList(BuildContext context, HistoryLoaded state) {
    return state.logs.map((log) {
      final medicine = state.medicines.firstWhere(
        (m) => m.id == log.medicineId,
        orElse: () => state.medicines.first,
      );

      return _buildLogCard(context, log, medicine);
    }).toList();
  }

  /// Build individual log card
  Widget _buildLogCard(BuildContext context, dynamic log, dynamic medicine) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(log.status);
    final statusIcon = _getStatusIcon(log.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSizes.spacing8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(medicine.name, style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${medicine.dosage} • ${DateTimeUtils.formatTime(log.scheduledTime)}'),
            if (log.takenTime != null) ...[
              const SizedBox(height: 2),
              Text(
                'Taken at ${DateTimeUtils.formatTime(log.takenTime!)}',
                style: TextStyle(color: AppColors.success, fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing8,
            vertical: AppSizes.spacing4,
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusXL),
          ),
          child: Text(
            _getStatusString(log.status),
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ),
    );
  }

  /// Show filter dialog
  void _showFilterDialog(BuildContext context) {
    final cubit = getIt<HistoryCubit>();
    final state = cubit.state;
    if (state is! HistoryLoaded) return;

    int? selectedMedicineId = state.filter.medicineId;
    MedicineLogStatus? selectedStatus = state.filter.status;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter History'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medicine filter
                const Text('Medicine:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  value: selectedMedicineId,
                  decoration: const InputDecoration(
                    hintText: 'All Medicines',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Medicines')),
                    ...state.medicines.map((medicine) {
                      return DropdownMenuItem(value: medicine.id, child: Text(medicine.name));
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedMedicineId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Status filter
                const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<MedicineLogStatus?>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    hintText: 'All Statuses',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Statuses')),
                    ...MedicineLogStatus.values.map((status) {
                      return DropdownMenuItem(value: status, child: Text(_getStatusString(status)));
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                cubit.applyFilter(
                  HistoryFilter(medicineId: selectedMedicineId, status: selectedStatus),
                );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  /// Get status color
  Color _getStatusColor(MedicineLogStatus status) {
    switch (status) {
      case MedicineLogStatus.taken:
        return AppColors.success;
      case MedicineLogStatus.pending:
        return AppColors.warning;
      case MedicineLogStatus.missed:
        return AppColors.error;
      case MedicineLogStatus.skipped:
        return AppColors.textDisabledLight;
      case MedicineLogStatus.snoozed:
        return AppColors.info;
    }
  }

  /// Get status icon
  IconData _getStatusIcon(MedicineLogStatus status) {
    switch (status) {
      case MedicineLogStatus.taken:
        return Icons.check_circle;
      case MedicineLogStatus.pending:
        return Icons.pending;
      case MedicineLogStatus.missed:
        return Icons.error;
      case MedicineLogStatus.skipped:
        return Icons.cancel;
      case MedicineLogStatus.snoozed:
        return Icons.snooze;
    }
  }

  /// Get status string
  String _getStatusString(MedicineLogStatus status) {
    switch (status) {
      case MedicineLogStatus.taken:
        return 'Taken';
      case MedicineLogStatus.pending:
        return 'Pending';
      case MedicineLogStatus.missed:
        return 'Missed';
      case MedicineLogStatus.skipped:
        return 'Skipped';
      case MedicineLogStatus.snoozed:
        return 'Snoozed';
    }
  }
}
