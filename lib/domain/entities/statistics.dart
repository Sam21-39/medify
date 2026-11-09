import 'package:equatable/equatable.dart';

/// Entity representing medicine adherence statistics
class MedicineStatistics extends Equatable {
  /// Total number of scheduled doses in the period
  final int totalDoses;

  /// Number of doses marked as taken
  final int takenDoses;

  /// Number of doses marked as missed
  final int missedDoses;

  /// Number of doses marked as skipped
  final int skippedDoses;

  /// Number of pending doses (not yet due)
  final int pendingDoses;

  /// Overall adherence rate as a percentage (0-100)
  final double adherenceRate;

  /// Current consecutive streak of days with 100% adherence
  final int currentStreak;

  /// Best streak ever achieved
  final int bestStreak;

  /// Per-medicine adherence rates (medicineId -> adherence %)
  final Map<int, double> medicineAdherence;

  /// Daily completion counts (date -> number of doses taken)
  final Map<DateTime, int> dailyCompletion;

  /// Daily scheduled counts (date -> number of doses scheduled)
  final Map<DateTime, int> dailyScheduled;

  /// Weekly adherence data (for charts)
  final List<DailyAdherence> weeklyData;

  /// Monthly adherence data (for charts)
  final List<DailyAdherence> monthlyData;

  const MedicineStatistics({
    required this.totalDoses,
    required this.takenDoses,
    required this.missedDoses,
    required this.skippedDoses,
    required this.pendingDoses,
    required this.adherenceRate,
    required this.currentStreak,
    required this.bestStreak,
    required this.medicineAdherence,
    required this.dailyCompletion,
    required this.dailyScheduled,
    required this.weeklyData,
    required this.monthlyData,
  });

  /// Create empty statistics (for initial state)
  factory MedicineStatistics.empty() {
    return MedicineStatistics(
      totalDoses: 0,
      takenDoses: 0,
      missedDoses: 0,
      skippedDoses: 0,
      pendingDoses: 0,
      adherenceRate: 0.0,
      currentStreak: 0,
      bestStreak: 0,
      medicineAdherence: {},
      dailyCompletion: {},
      dailyScheduled: {},
      weeklyData: [],
      monthlyData: [],
    );
  }

  /// Check if there's enough data to display statistics
  bool get hasData => totalDoses > 0;

  /// Get completion rate (taken / (taken + missed + skipped))
  double get completionRate {
    final completed = takenDoses + missedDoses + skippedDoses;
    if (completed == 0) return 0.0;
    return (takenDoses / completed) * 100;
  }

  /// Get success rate (taken / total)
  double get successRate {
    if (totalDoses == 0) return 0.0;
    return (takenDoses / totalDoses) * 100;
  }

  @override
  List<Object?> get props => [
    totalDoses,
    takenDoses,
    missedDoses,
    skippedDoses,
    pendingDoses,
    adherenceRate,
    currentStreak,
    bestStreak,
    medicineAdherence,
    dailyCompletion,
    dailyScheduled,
    weeklyData,
    monthlyData,
  ];

  MedicineStatistics copyWith({
    int? totalDoses,
    int? takenDoses,
    int? missedDoses,
    int? skippedDoses,
    int? pendingDoses,
    double? adherenceRate,
    int? currentStreak,
    int? bestStreak,
    Map<int, double>? medicineAdherence,
    Map<DateTime, int>? dailyCompletion,
    Map<DateTime, int>? dailyScheduled,
    List<DailyAdherence>? weeklyData,
    List<DailyAdherence>? monthlyData,
  }) {
    return MedicineStatistics(
      totalDoses: totalDoses ?? this.totalDoses,
      takenDoses: takenDoses ?? this.takenDoses,
      missedDoses: missedDoses ?? this.missedDoses,
      skippedDoses: skippedDoses ?? this.skippedDoses,
      pendingDoses: pendingDoses ?? this.pendingDoses,
      adherenceRate: adherenceRate ?? this.adherenceRate,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      medicineAdherence: medicineAdherence ?? this.medicineAdherence,
      dailyCompletion: dailyCompletion ?? this.dailyCompletion,
      dailyScheduled: dailyScheduled ?? this.dailyScheduled,
      weeklyData: weeklyData ?? this.weeklyData,
      monthlyData: monthlyData ?? this.monthlyData,
    );
  }
}

/// Daily adherence data point for charts
class DailyAdherence extends Equatable {
  /// The date
  final DateTime date;

  /// Number of doses scheduled
  final int scheduled;

  /// Number of doses taken
  final int taken;

  /// Adherence percentage for this day
  final double adherenceRate;

  const DailyAdherence({
    required this.date,
    required this.scheduled,
    required this.taken,
    required this.adherenceRate,
  });

  /// Create empty data point
  factory DailyAdherence.empty(DateTime date) {
    return DailyAdherence(
      date: date,
      scheduled: 0,
      taken: 0,
      adherenceRate: 0.0,
    );
  }

  @override
  List<Object?> get props => [date, scheduled, taken, adherenceRate];
}

/// Medicine-specific statistics
class MedicineStatisticsDetail extends Equatable {
  /// Medicine ID
  final int medicineId;

  /// Medicine name
  final String medicineName;

  /// Total scheduled doses
  final int totalDoses;

  /// Doses taken
  final int takenDoses;

  /// Adherence rate
  final double adherenceRate;

  /// Color for chart display
  final int colorValue;

  const MedicineStatisticsDetail({
    required this.medicineId,
    required this.medicineName,
    required this.totalDoses,
    required this.takenDoses,
    required this.adherenceRate,
    required this.colorValue,
  });

  @override
  List<Object?> get props => [
    medicineId,
    medicineName,
    totalDoses,
    takenDoses,
    adherenceRate,
    colorValue,
  ];
}
