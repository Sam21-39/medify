import 'package:equatable/equatable.dart';
import '../../../domain/entities/statistics.dart';

/// States for Statistics Cubit
abstract class StatisticsState extends Equatable {
  const StatisticsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class StatisticsInitial extends StatisticsState {
  const StatisticsInitial();
}

/// Loading state
class StatisticsLoading extends StatisticsState {
  const StatisticsLoading();
}

/// Statistics loaded successfully
class StatisticsLoaded extends StatisticsState {
  final MedicineStatistics statistics;
  final List<MedicineStatisticsDetail> medicineDetails;
  final StatisticsPeriod period;

  const StatisticsLoaded({
    required this.statistics,
    required this.medicineDetails,
    required this.period,
  });

  @override
  List<Object?> get props => [statistics, medicineDetails, period];

  StatisticsLoaded copyWith({
    MedicineStatistics? statistics,
    List<MedicineStatisticsDetail>? medicineDetails,
    StatisticsPeriod? period,
  }) {
    return StatisticsLoaded(
      statistics: statistics ?? this.statistics,
      medicineDetails: medicineDetails ?? this.medicineDetails,
      period: period ?? this.period,
    );
  }
}

/// Error state
class StatisticsError extends StatisticsState {
  final String message;

  const StatisticsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Time period for statistics
enum StatisticsPeriod {
  week(7, 'Week'),
  month(30, 'Month'),
  allTime(0, 'All Time');

  final int days;
  final String label;

  const StatisticsPeriod(this.days, this.label);
}
