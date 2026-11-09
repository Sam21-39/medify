import 'package:equatable/equatable.dart';
import '../../../domain/entities/medicine.dart';
import '../../../domain/entities/medicine_log.dart';

/// States for History Cubit
abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

/// Loading state
class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

/// History loaded successfully
class HistoryLoaded extends HistoryState {
  final DateTime selectedDate;
  final List<MedicineLog> logs;
  final Map<DateTime, List<MedicineLog>> calendarLogs; // For date markers
  final List<Medicine> medicines; // For filter dropdown
  final HistoryFilter filter;

  const HistoryLoaded({
    required this.selectedDate,
    required this.logs,
    required this.calendarLogs,
    required this.medicines,
    required this.filter,
  });

  @override
  List<Object?> get props => [
        selectedDate,
        logs,
        calendarLogs,
        medicines,
        filter,
      ];

  HistoryLoaded copyWith({
    DateTime? selectedDate,
    List<MedicineLog>? logs,
    Map<DateTime, List<MedicineLog>>? calendarLogs,
    List<Medicine>? medicines,
    HistoryFilter? filter,
  }) {
    return HistoryLoaded(
      selectedDate: selectedDate ?? this.selectedDate,
      logs: logs ?? this.logs,
      calendarLogs: calendarLogs ?? this.calendarLogs,
      medicines: medicines ?? this.medicines,
      filter: filter ?? this.filter,
    );
  }
}

/// Error state
class HistoryError extends HistoryState {
  final String message;

  const HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Exporting data
class HistoryExporting extends HistoryState {
  const HistoryExporting();
}

/// Export success
class HistoryExportSuccess extends HistoryState {
  final String filePath;

  const HistoryExportSuccess(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

/// Filter configuration for history
class HistoryFilter extends Equatable {
  final int? medicineId; // null = all medicines
  final MedicineLogStatus? status; // null = all statuses
  final DateTime? startDate;
  final DateTime? endDate;

  const HistoryFilter({
    this.medicineId,
    this.status,
    this.startDate,
    this.endDate,
  });

  /// Create empty filter (no filters applied)
  factory HistoryFilter.empty() {
    return const HistoryFilter();
  }

  /// Check if any filters are active
  bool get hasActiveFilters =>
      medicineId != null ||
      status != null ||
      startDate != null ||
      endDate != null;

  @override
  List<Object?> get props => [medicineId, status, startDate, endDate];

  HistoryFilter copyWith({
    int? medicineId,
    MedicineLogStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    bool clearMedicineId = false,
    bool clearStatus = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return HistoryFilter(
      medicineId: clearMedicineId ? null : (medicineId ?? this.medicineId),
      status: clearStatus ? null : (status ?? this.status),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }
}

