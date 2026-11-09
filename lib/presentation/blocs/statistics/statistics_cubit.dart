import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/medicine_log_repository.dart';
import 'statistics_state.dart';

/// Cubit for managing statistics state
class StatisticsCubit extends Cubit<StatisticsState> {
  final MedicineLogRepository _medicineLogRepository;

  StatisticsCubit(this._medicineLogRepository)
    : super(const StatisticsInitial());

  /// Load statistics for a specific period
  Future<void> loadStatistics([
    StatisticsPeriod period = StatisticsPeriod.month,
  ]) async {
    try {
      emit(const StatisticsLoading());

      final statistics = period == StatisticsPeriod.allTime
          ? await _medicineLogRepository.getStatistics()
          : await _medicineLogRepository.getStatisticsForDays(period.days);

      final medicineDetails = period == StatisticsPeriod.allTime
          ? await _medicineLogRepository.getMedicineStatisticsDetails()
          : await _medicineLogRepository.getMedicineStatisticsDetails(
              startDate: DateTime.now().subtract(Duration(days: period.days)),
              endDate: DateTime.now(),
            );

      emit(
        StatisticsLoaded(
          statistics: statistics,
          medicineDetails: medicineDetails,
          period: period,
        ),
      );
    } catch (e) {
      emit(StatisticsError('Failed to load statistics: ${e.toString()}'));
    }
  }

  /// Switch time period
  Future<void> changePeriod(StatisticsPeriod period) async {
    await loadStatistics(period);
  }

  /// Refresh current statistics
  Future<void> refresh() async {
    if (state is StatisticsLoaded) {
      final currentPeriod = (state as StatisticsLoaded).period;
      await loadStatistics(currentPeriod);
    } else {
      await loadStatistics();
    }
  }
}
