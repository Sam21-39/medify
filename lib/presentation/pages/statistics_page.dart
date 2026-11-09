import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/di/injection_container.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../domain/entities/statistics.dart';
import '../blocs/statistics/statistics_cubit.dart';
import '../blocs/statistics/statistics_state.dart';
// COMMENTED OUT FOR UPCOMING RELEASE
// import '../widgets/profile_switcher.dart';

/// Statistics and analytics page
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<StatisticsCubit>().loadStatistics();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent == true) {
      getIt<StatisticsCubit>().loadStatistics();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // COMMENTED OUT FOR UPCOMING RELEASE
        // leading: const Padding(
        //   padding: EdgeInsets.only(left: 8.0),
        //   child: ProfileSwitcher(),
        // ),
        title: const Text('Statistics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              getIt<StatisticsCubit>().refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocBuilder<StatisticsCubit, StatisticsState>(
        bloc: getIt<StatisticsCubit>(), // Explicitly use singleton instance
        builder: (context, state) {
          if (state is StatisticsLoading) {
            // Use shimmer loading for statistics
            return ListView(
              padding: const EdgeInsets.all(AppSizes.spacing16),
              children: const [
                ShimmerStatisticsCard(),
                SizedBox(height: AppSizes.spacing16),
                ShimmerStatisticsCard(),
                SizedBox(height: AppSizes.spacing16),
                ShimmerStatisticsCard(),
              ],
            );
          }

          if (state is StatisticsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: AppSizes.spacing16),
                  Text('Error loading statistics', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSizes.spacing8),
                  Text(
                    state.message,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.spacing24),
                  ElevatedButton.icon(
                    onPressed: () {
                      getIt<StatisticsCubit>().refresh();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is StatisticsLoaded) {
            if (!state.statistics.hasData) {
              return EmptyState(
                icon: Icons.bar_chart,
                title: 'No Statistics Yet',
                message:
                    'Start tracking your medicines to see your adherence statistics and progress!',
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                await getIt<StatisticsCubit>().refresh();
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                children: [
                  // Period Selector
                  _buildPeriodSelector(context, state.period),
                  const SizedBox(height: AppSizes.spacing16),

                  // Overview Cards
                  _buildOverviewCards(context, state.statistics),
                  const SizedBox(height: AppSizes.spacing24),

                  // Streak Card
                  _buildStreakCard(context, state.statistics),
                  const SizedBox(height: AppSizes.spacing24),

                  // Adherence Trend Chart
                  _buildAdherenceTrendCard(context, state),
                  const SizedBox(height: AppSizes.spacing24),

                  // Daily Completion Chart
                  _buildDailyCompletionCard(context, state),
                  const SizedBox(height: AppSizes.spacing24),

                  // Medicine Breakdown
                  if (state.medicineDetails.isNotEmpty) _buildMedicineBreakdownCard(context, state),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Build period selector chips
  Widget _buildPeriodSelector(BuildContext context, StatisticsPeriod current) {
    return Row(
      children: StatisticsPeriod.values.map((period) {
        final isSelected = period == current;
        return Padding(
          padding: const EdgeInsets.only(right: AppSizes.spacing8),
          child: ChoiceChip(
            label: Text(period.label),
            selected: isSelected,
            onSelected: (_) {
              getIt<StatisticsCubit>().changePeriod(period);
            },
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : null,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Build overview cards (taken, missed, adherence)
  Widget _buildOverviewCards(BuildContext context, MedicineStatistics stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Taken',
            '${stats.takenDoses}',
            Icons.check_circle,
            AppColors.success,
          ),
        ),
        const SizedBox(width: AppSizes.spacing12),
        Expanded(
          child: _buildStatCard(
            context,
            'Missed',
            '${stats.missedDoses}',
            Icons.cancel,
            AppColors.error,
          ),
        ),
        const SizedBox(width: AppSizes.spacing12),
        Expanded(
          child: _buildStatCard(
            context,
            'Adherence',
            '${stats.adherenceRate.toStringAsFixed(0)}%',
            Icons.trending_up,
            AppColors.primary,
          ),
        ),
      ],
    );
  }

  /// Build individual stat card
  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          children: [
            Icon(icon, color: color, size: AppSizes.iconL),
            const SizedBox(height: AppSizes.spacing8),
            Text(
              value,
              style: theme.textTheme.displaySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.spacing4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build streak card with badges
  Widget _buildStreakCard(BuildContext context, MedicineStatistics stats) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: AppColors.warning, size: AppSizes.iconL),
                const SizedBox(width: AppSizes.spacing8),
                Text(
                  'Streak',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStreakItem(
                  context,
                  'Current',
                  stats.currentStreak,
                  Icons.whatshot,
                  AppColors.warning,
                ),
                Container(
                  height: 60,
                  width: 1,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
                _buildStreakItem(
                  context,
                  'Best',
                  stats.bestStreak,
                  Icons.emoji_events,
                  AppColors.primary,
                ),
              ],
            ),
            if (stats.currentStreak > 0) ...[
              const SizedBox(height: AppSizes.spacing16),
              Container(
                padding: const EdgeInsets.all(AppSizes.spacing12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: Row(
                  children: [
                    Icon(Icons.celebration, color: AppColors.success, size: AppSizes.iconM),
                    const SizedBox(width: AppSizes.spacing8),
                    Expanded(
                      child: Text(
                        stats.currentStreak == 1
                            ? 'Keep it up! 1 day streak!'
                            : 'Amazing! ${stats.currentStreak} days streak! 🎉',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build streak item (current or best)
  Widget _buildStreakItem(
    BuildContext context,
    String label,
    int value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: AppSizes.iconXL),
        const SizedBox(height: AppSizes.spacing8),
        Text(
          '$value',
          style: theme.textTheme.displayMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value == 1 ? 'day' : 'days',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  /// Build adherence trend line chart
  Widget _buildAdherenceTrendCard(BuildContext context, StatisticsLoaded state) {
    final theme = Theme.of(context);
    final data = state.period == StatisticsPeriod.week
        ? state.statistics.weeklyData
        : state.statistics.monthlyData;

    if (data.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adherence Trend',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.spacing20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 10, //data.length > 7 ? data.length / 7 : 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < data.length) {
                            final date = data[value.toInt()].date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MM/dd').format(date),
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 25,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%', style: theme.textTheme.bodySmall);
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.adherenceRate);
                      }).toList(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          if (index % 5 != 0) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.transparent,
                              strokeWidth: 2,
                              strokeColor: Colors.transparent,
                            );
                          }
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: AppColors.primary,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = data[spot.x.toInt()].date;
                          return LineTooltipItem(
                            '${DateFormat('MMM dd').format(date)}\n${spot.y.toStringAsFixed(0)}%',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build daily completion bar chart
  Widget _buildDailyCompletionCard(BuildContext context, StatisticsLoaded state) {
    final theme = Theme.of(context);
    final data = state.period == StatisticsPeriod.week
        ? state.statistics.weeklyData
        : state.statistics.monthlyData.length > 14
        ? state.statistics.monthlyData.sublist(state.statistics.monthlyData.length - 14)
        : state.statistics.monthlyData;

    if (data.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Completion',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.spacing20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: data.map((d) => d.scheduled.toDouble()).reduce((a, b) => a > b ? a : b),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final date = data[group.x.toInt()].date;
                        final taken = data[group.x.toInt()].taken;
                        final scheduled = data[group.x.toInt()].scheduled;
                        return BarTooltipItem(
                          '${DateFormat('MMM dd').format(date)}\n$taken/$scheduled doses',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < data.length) {
                            final date = data[value.toInt()].date;
                            if (date.day % 5 == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('MM/dd').format(date),
                                  style: theme.textTheme.bodySmall,
                                ),
                              );
                            }
                            return const Text('');
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString(), style: theme.textTheme.bodySmall);
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  barGroups: data.asMap().entries.map((entry) {
                    final adherence = entry.value.adherenceRate;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.taken.toDouble(),
                          color: _getBarColor(adherence),
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spacing16),
            _buildLegend(context),
          ],
        ),
      ),
    );
  }

  /// Build medicine breakdown pie chart
  Widget _buildMedicineBreakdownCard(BuildContext context, StatisticsLoaded state) {
    final theme = Theme.of(context);
    final details = state.medicineDetails;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medicine Breakdown',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.spacing20),
            ...details.map((detail) => _buildMedicineListItem(context, detail)),
          ],
        ),
      ),
    );
  }

  /// Build medicine list item with progress bar
  Widget _buildMedicineListItem(BuildContext context, MedicineStatisticsDetail detail) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  detail.medicineName,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${detail.adherenceRate.toStringAsFixed(0)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Color(detail.colorValue),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
            child: LinearProgressIndicator(
              value: detail.adherenceRate / 100,
              minHeight: 8,
              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(Color(detail.colorValue)),
            ),
          ),
          const SizedBox(height: AppSizes.spacing4),
          Text(
            '${detail.takenDoses} of ${detail.totalDoses} doses taken',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Build legend for bar chart
  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(context, AppColors.success, '80-100%'),
        const SizedBox(width: AppSizes.spacing16),
        _buildLegendItem(context, AppColors.warning, '50-79%'),
        const SizedBox(width: AppSizes.spacing16),
        _buildLegendItem(context, AppColors.error, '0-49%'),
      ],
    );
  }

  /// Build legend item
  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: AppSizes.spacing4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  /// Get bar color based on adherence rate
  Color _getBarColor(double adherenceRate) {
    if (adherenceRate >= 80) return AppColors.success;
    if (adherenceRate >= 50) return AppColors.warning;
    return AppColors.error;
  }
}
