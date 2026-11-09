import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../domain/entities/medicine.dart';
import '../../../domain/entities/medicine_log.dart';
import '../../../domain/repositories/medicine_log_repository.dart';
import '../../../domain/repositories/medicine_repository.dart';
import 'history_state.dart';

/// Cubit for managing medicine history state
class HistoryCubit extends Cubit<HistoryState> {
  final MedicineLogRepository _medicineLogRepository;
  final MedicineRepository _medicineRepository;

  HistoryCubit(this._medicineLogRepository, this._medicineRepository)
    : super(const HistoryInitial());

  /// Load history for initial date (today)
  Future<void> loadHistory([DateTime? date]) async {
    try {
      emit(const HistoryLoading());

      final selectedDate = date ?? DateTime.now();
      final medicines = await _medicineRepository.getAllMedicines();

      // Load calendar data (30 days before and after selected date)
      final startDate = selectedDate.subtract(const Duration(days: 30));
      final endDate = selectedDate.add(const Duration(days: 30));
      final calendarLogs = await _loadCalendarLogs(startDate, endDate);

      // Load logs for selected date
      final logs = await _medicineLogRepository.getLogsByDate(selectedDate);

      emit(
        HistoryLoaded(
          selectedDate: selectedDate,
          logs: logs,
          calendarLogs: calendarLogs,
          medicines: medicines,
          filter: HistoryFilter.empty(),
        ),
      );
    } catch (e) {
      emit(HistoryError('Failed to load history: ${e.toString()}'));
    }
  }

  /// Change selected date
  Future<void> selectDate(DateTime date) async {
    if (state is! HistoryLoaded) return;

    try {
      final currentState = state as HistoryLoaded;
      emit(const HistoryLoading());

      // Load logs for new date
      final logs = await _medicineLogRepository.getLogsByDate(date);

      // Apply current filter
      final filteredLogs = _applyFilter(logs, currentState.filter);

      emit(currentState.copyWith(selectedDate: date, logs: filteredLogs));
    } catch (e) {
      emit(HistoryError('Failed to load date: ${e.toString()}'));
    }
  }

  /// Apply filter
  Future<void> applyFilter(HistoryFilter filter) async {
    if (state is! HistoryLoaded) return;

    try {
      final currentState = state as HistoryLoaded;
      emit(const HistoryLoading());

      // Load logs for selected date
      final logs = await _medicineLogRepository.getLogsByDate(
        currentState.selectedDate,
      );

      // Apply filter
      final filteredLogs = _applyFilter(logs, filter);

      emit(currentState.copyWith(logs: filteredLogs, filter: filter));
    } catch (e) {
      emit(HistoryError('Failed to apply filter: ${e.toString()}'));
    }
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    await applyFilter(HistoryFilter.empty());
  }

  /// Refresh current view
  Future<void> refresh() async {
    if (state is HistoryLoaded) {
      await loadHistory((state as HistoryLoaded).selectedDate);
    } else {
      await loadHistory();
    }
  }

  /// Export logs to CSV
  Future<void> exportToCSV() async {
    if (state is! HistoryLoaded) return;

    try {
      emit(const HistoryExporting());

      final currentState = state as HistoryLoaded;

      // Get all logs in date range if filter is applied, otherwise get selected date
      final logs = currentState.filter.hasActiveFilters
          ? await _getFilteredLogs(currentState.filter)
          : currentState.logs;

      if (logs.isEmpty) {
        emit(const HistoryError('No logs to export'));
        emit(currentState); // Return to previous state
        return;
      }

      // Create CSV content
      final csvData = _generateCSVData(logs, currentState.medicines);

      // Save to file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/medicine_history_$timestamp.csv';
      final file = File(filePath);
      await file.writeAsString(csvData);

      // Share file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Medicine History',
        text: 'My medicine tracking history',
      );

      emit(HistoryExportSuccess(filePath));
      emit(currentState); // Return to previous state
    } catch (e) {
      emit(HistoryError('Failed to export: ${e.toString()}'));
      if (state is HistoryLoaded) {
        emit(state as HistoryLoaded); // Return to previous state
      }
    }
  }

  // ==================== Helper Methods ====================

  /// Load calendar logs for date range
  Future<Map<DateTime, List<MedicineLog>>> _loadCalendarLogs(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final Map<DateTime, List<MedicineLog>> calendarLogs = {};

    // Load all logs in range
    for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
      final date = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      ).add(Duration(days: i));

      final logs = await _medicineLogRepository.getLogsByDate(date);
      if (logs.isNotEmpty) {
        calendarLogs[date] = logs;
      }
    }

    return calendarLogs;
  }

  /// Apply filter to logs
  List<MedicineLog> _applyFilter(List<MedicineLog> logs, HistoryFilter filter) {
    var filtered = logs;

    // Filter by medicine
    if (filter.medicineId != null) {
      filtered = filtered
          .where((log) => log.medicineId == filter.medicineId)
          .toList();
    }

    // Filter by status
    if (filter.status != null) {
      filtered = filtered.where((log) => log.status == filter.status).toList();
    }

    return filtered;
  }

  /// Get filtered logs from repository
  Future<List<MedicineLog>> _getFilteredLogs(HistoryFilter filter) async {
    final startDate =
        filter.startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final endDate = filter.endDate ?? DateTime.now();

    final allLogs = <MedicineLog>[];

    for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
      final date = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      ).add(Duration(days: i));

      final logs = await _medicineLogRepository.getLogsByDate(date);
      allLogs.addAll(logs);
    }

    return _applyFilter(allLogs, filter);
  }

  /// Generate CSV data
  String _generateCSVData(List<MedicineLog> logs, List<Medicine> medicines) {
    // CSV headers
    final headers = [
      'Date',
      'Time',
      'Medicine',
      'Dosage',
      'Status',
      'Taken Time',
      'Notes',
    ];

    // CSV rows
    final rows = logs.map((log) {
      Medicine? medicine;
      try {
        medicine = medicines.firstWhere((m) => m.id == log.medicineId);
      } catch (e) {
        medicine = null;
      }

      return [
        _formatDate(log.scheduledTime),
        _formatTime(log.scheduledTime),
        medicine?.name ?? 'Unknown',
        medicine?.dosage ?? '',
        _getStatusString(log.status),
        log.takenTime != null ? _formatTime(log.takenTime!) : '',
        medicine?.notes ?? '',
      ];
    }).toList();

    // Combine headers and rows
    final csvData = [headers, ...rows];

    // Convert to CSV string
    return const ListToCsvConverter().convert(csvData);
  }

  /// Format date for CSV
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format time for CSV
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Get status string
  String _getStatusString(dynamic status) {
    switch (status.toString().split('.').last) {
      case 'taken':
        return 'Taken';
      case 'missed':
        return 'Missed';
      case 'skipped':
        return 'Skipped';
      case 'pending':
        return 'Pending';
      case 'snoozed':
        return 'Snoozed';
      default:
        return 'Unknown';
    }
  }
}
