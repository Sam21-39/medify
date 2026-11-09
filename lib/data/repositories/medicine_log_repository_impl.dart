import 'dart:async';
import '../../domain/entities/medicine_log.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/statistics.dart';
import '../../domain/repositories/medicine_log_repository.dart';
import '../../domain/repositories/medicine_repository.dart';
import '../datasources/objectbox_service.dart';
import '../models/medicine_log_model.dart';
import '../../objectbox.g.dart';
import '../../core/di/injection_container.dart';

/// Implementation of MedicineLogRepository using ObjectBox
class MedicineLogRepositoryImpl implements MedicineLogRepository {
  final ObjectBoxService _objectBoxService;
  final _logStreamController = StreamController<List<MedicineLog>>.broadcast();

  MedicineLogRepositoryImpl(this._objectBoxService);

  @override
  Future<List<MedicineLog>> getAllLogs() async {
    final models = _objectBoxService.medicineLogBox.getAll();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<MedicineLog>> getLogsByMedicineId(int medicineId) async {
    final query = _objectBoxService.medicineLogBox
        .query(MedicineLogModel_.medicineId.equals(medicineId))
        .order(MedicineLogModel_.scheduledTime, flags: Order.descending)
        .build();
    final models = query.find();
    query.close();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<MedicineLog>> getTodayLogs() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final query = _objectBoxService.medicineLogBox
        .query(
          MedicineLogModel_.scheduledTime.betweenDate(startOfDay, endOfDay),
        )
        .order(MedicineLogModel_.scheduledTime)
        .build();
    final models = query.find();
    query.close();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<MedicineLog>> getLogsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final query = _objectBoxService.medicineLogBox
        .query(
          MedicineLogModel_.scheduledTime.betweenDate(startOfDay, endOfDay),
        )
        .order(MedicineLogModel_.scheduledTime)
        .build();
    final models = query.find();
    query.close();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<MedicineLog?> getLogById(int id) async {
    final model = _objectBoxService.medicineLogBox.get(id);
    return model?.toEntity();
  }

  @override
  Future<MedicineLog> addLog(MedicineLog log) async {
    final model = MedicineLogModel.fromEntity(log);
    final id = _objectBoxService.medicineLogBox.put(model);
    model.id = id;
    _notifyListeners();
    return model.toEntity();
  }

  @override
  Future<MedicineLog> updateLog(MedicineLog log) async {
    if (log.id == null) {
      throw Exception('Log ID cannot be null for update');
    }
    final model = MedicineLogModel.fromEntity(log);
    _objectBoxService.medicineLogBox.put(model);
    _notifyListeners();
    return model.toEntity();
  }

  @override
  Future<void> deleteLog(int id) async {
    _objectBoxService.medicineLogBox.remove(id);
    _notifyListeners();
  }

  @override
  Future<MedicineLog> markAsTaken(int id) async {
    final model = _objectBoxService.medicineLogBox.get(id);
    if (model == null) {
      throw Exception('Log not found');
    }
    model.status = MedicineLogStatus.taken.index;
    model.takenTime = DateTime.now();
    model.updatedAt = DateTime.now();
    _objectBoxService.medicineLogBox.put(model);
    _notifyListeners();
    return model.toEntity();
  }

  @override
  Future<MedicineLog> markAsSkipped(int id) async {
    final model = _objectBoxService.medicineLogBox.get(id);
    if (model == null) {
      throw Exception('Log not found');
    }
    model.status = MedicineLogStatus.skipped.index;
    model.updatedAt = DateTime.now();
    _objectBoxService.medicineLogBox.put(model);
    _notifyListeners();
    return model.toEntity();
  }

  @override
  Future<MedicineLog> markAsMissed(int id) async {
    final model = _objectBoxService.medicineLogBox.get(id);
    if (model == null) {
      throw Exception('Log not found');
    }
    model.status = MedicineLogStatus.missed.index;
    model.updatedAt = DateTime.now();
    _objectBoxService.medicineLogBox.put(model);
    _notifyListeners();
    return model.toEntity();
  }

  @override
  Future<MedicineLog> snoozeLog(int id, int minutes) async {
    final model = _objectBoxService.medicineLogBox.get(id);
    if (model == null) {
      throw Exception('Log not found');
    }
    model.status = MedicineLogStatus.snoozed.index;
    model.scheduledTime = model.scheduledTime.add(Duration(minutes: minutes));
    model.updatedAt = DateTime.now();
    _objectBoxService.medicineLogBox.put(model);
    _notifyListeners();
    return model.toEntity();
  }

  @override
  Future<List<MedicineLog>> getOverdueLogs() async {
    final now = DateTime.now();
    final query = _objectBoxService.medicineLogBox
        .query(
          MedicineLogModel_.scheduledTime.lessThan(now.millisecondsSinceEpoch),
        )
        .build();

    final models = query.find();
    query.close();

    // Filter out taken and skipped logs
    final overdueLogs = models
        .where(
          (model) =>
              model.status != MedicineLogStatus.taken.index &&
              model.status != MedicineLogStatus.skipped.index,
        )
        .map((model) => model.toEntity())
        .toList();

    return overdueLogs;
  }

  @override
  Future<List<MedicineLog>> getPendingLogs() async {
    final query = _objectBoxService.medicineLogBox
        .query(MedicineLogModel_.status.equals(MedicineLogStatus.pending.index))
        .order(MedicineLogModel_.scheduledTime)
        .build();
    final models = query.find();
    query.close();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Stream<List<MedicineLog>> watchTodayLogs() {
    // Initial data
    getTodayLogs().then((logs) {
      if (!_logStreamController.isClosed) {
        _logStreamController.add(logs);
      }
    });
    return _logStreamController.stream;
  }

  @override
  Stream<List<MedicineLog>> watchLogsByMedicineId(int medicineId) {
    return watchTodayLogs().map(
      (logs) => logs.where((log) => log.medicineId == medicineId).toList(),
    );
  }

  void _notifyListeners() {
    getTodayLogs().then((logs) {
      if (!_logStreamController.isClosed) {
        _logStreamController.add(logs);
      }
    });
  }

  void dispose() {
    _logStreamController.close();
  }

  // ==================== Statistics Implementation ====================

  @override
  Future<MedicineStatistics> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Default to all-time if no dates provided
    final logs = await _getLogsInRange(startDate, endDate);

    if (logs.isEmpty) {
      return MedicineStatistics.empty();
    }

    // Calculate basic counts
    final totalDoses = logs.length;
    final takenDoses = logs
        .where((log) => log.status == MedicineLogStatus.taken)
        .length;
    final missedDoses = logs
        .where((log) => log.status == MedicineLogStatus.missed)
        .length;
    final skippedDoses = logs
        .where((log) => log.status == MedicineLogStatus.skipped)
        .length;
    final pendingDoses = logs
        .where((log) => log.status == MedicineLogStatus.pending)
        .length;

    // Calculate adherence rate (taken / (taken + missed + skipped))
    final completed = takenDoses + missedDoses + skippedDoses;
    final adherenceRate = completed > 0 ? (takenDoses / completed) * 100 : 0.0;

    // Get streak data
    final currentStreak = await getCurrentStreak();
    final bestStreak = await getBestStreak();

    // Get medicine adherence rates
    final medicineAdherence = await getMedicineAdherenceRates(
      startDate: startDate,
      endDate: endDate,
    );

    // Get daily data
    final dailyCompletion = await getDailyCompletion(30);
    final dailyScheduled = await getDailyScheduled(30);

    // Generate weekly and monthly data for charts
    final weeklyData = await _generateDailyAdherenceData(7);
    final monthlyData = await _generateDailyAdherenceData(30);

    return MedicineStatistics(
      totalDoses: totalDoses,
      takenDoses: takenDoses,
      missedDoses: missedDoses,
      skippedDoses: skippedDoses,
      pendingDoses: pendingDoses,
      adherenceRate: adherenceRate,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      medicineAdherence: medicineAdherence,
      dailyCompletion: dailyCompletion,
      dailyScheduled: dailyScheduled,
      weeklyData: weeklyData,
      monthlyData: monthlyData,
    );
  }

  @override
  Future<MedicineStatistics> getStatisticsForDays(int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    return getStatistics(startDate: startDate, endDate: endDate);
  }

  @override
  Future<int> getCurrentStreak() async {
    final now = DateTime.now();
    int streak = 0;

    // Check each day going backwards from today
    for (int i = 0; i < 365; i++) {
      // Max 365 days
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final logs = await getLogsByDate(date);

      if (logs.isEmpty) {
        // No doses scheduled, continue
        continue;
      }

      final scheduled = logs.length;
      final taken = logs
          .where((log) => log.status == MedicineLogStatus.taken)
          .length;

      if (taken == scheduled && scheduled > 0) {
        // 100% adherence for this day
        streak++;
      } else if (i == 0) {
        // Today is incomplete, don't break streak yet
        continue;
      } else {
        // Streak is broken
        break;
      }
    }

    return streak;
  }

  @override
  Future<int> getBestStreak() async {
    // This should ideally be stored in preferences or a separate stats table
    // For now, we'll calculate it (can be optimized later)
    final allLogs = await getAllLogs();

    if (allLogs.isEmpty) return 0;

    // Group logs by date
    final Map<DateTime, List<MedicineLog>> logsByDate = {};
    for (final log in allLogs) {
      final date = DateTime(
        log.scheduledTime.year,
        log.scheduledTime.month,
        log.scheduledTime.day,
      );
      logsByDate.putIfAbsent(date, () => []).add(log);
    }

    // Find the longest streak
    int bestStreak = 0;
    int currentStreak = 0;

    final sortedDates = logsByDate.keys.toList()..sort();

    for (final date in sortedDates) {
      final logs = logsByDate[date]!;
      final scheduled = logs.length;
      final taken = logs
          .where((log) => log.status == MedicineLogStatus.taken)
          .length;

      if (taken == scheduled && scheduled > 0) {
        currentStreak++;
        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
    }

    return bestStreak;
  }

  @override
  Future<Map<DateTime, int>> getDailyCompletion(int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));

    final Map<DateTime, int> dailyCompletion = {};

    for (int i = 0; i < days; i++) {
      final date = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      ).add(Duration(days: i));

      final logs = await getLogsByDate(date);
      final taken = logs
          .where((log) => log.status == MedicineLogStatus.taken)
          .length;
      dailyCompletion[date] = taken;
    }

    return dailyCompletion;
  }

  @override
  Future<Map<DateTime, int>> getDailyScheduled(int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));

    final Map<DateTime, int> dailyScheduled = {};

    for (int i = 0; i < days; i++) {
      final date = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      ).add(Duration(days: i));

      final logs = await getLogsByDate(date);
      dailyScheduled[date] = logs.length;
    }

    return dailyScheduled;
  }

  @override
  Future<Map<int, double>> getMedicineAdherenceRates({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final logs = await _getLogsInRange(startDate, endDate);

    // Group by medicine ID
    final Map<int, List<MedicineLog>> logsByMedicine = {};
    for (final log in logs) {
      logsByMedicine.putIfAbsent(log.medicineId, () => []).add(log);
    }

    // Calculate adherence rate for each medicine
    final Map<int, double> adherenceRates = {};
    for (final entry in logsByMedicine.entries) {
      final medicineId = entry.key;
      final medicineLogs = entry.value;

      final taken = medicineLogs
          .where((log) => log.status == MedicineLogStatus.taken)
          .length;
      final completed = medicineLogs
          .where(
            (log) =>
                log.status == MedicineLogStatus.taken ||
                log.status == MedicineLogStatus.missed ||
                log.status == MedicineLogStatus.skipped,
          )
          .length;

      adherenceRates[medicineId] = completed > 0
          ? (taken / completed) * 100
          : 0.0;
    }

    return adherenceRates;
  }

  @override
  Future<List<MedicineStatisticsDetail>> getMedicineStatisticsDetails({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final logs = await _getLogsInRange(startDate, endDate);

    // Group by medicine ID
    final Map<int, List<MedicineLog>> logsByMedicine = {};
    for (final log in logs) {
      logsByMedicine.putIfAbsent(log.medicineId, () => []).add(log);
    }

    // Get medicine repository to fetch medicine details
    final medicineRepo = getIt<MedicineRepository>();
    final medicines = await medicineRepo.getAllMedicines();

    // Create medicine map for quick lookup
    final Map<int, Medicine> medicineMap = {
      for (final medicine in medicines) medicine.id!: medicine,
    };

    // Build statistics details
    final List<MedicineStatisticsDetail> details = [];
    int colorIndex = 0;
    final colors = [
      0xFF14B8A6,
      0xFF10B981,
      0xFFF59E0B,
      0xEF4444,
      0x3B82F6,
      0x8B5CF6,
    ];

    for (final entry in logsByMedicine.entries) {
      final medicineId = entry.key;
      final medicineLogs = entry.value;
      final medicine = medicineMap[medicineId];

      if (medicine == null) continue;

      final totalDoses = medicineLogs.length;
      final takenDoses = medicineLogs
          .where((log) => log.status == MedicineLogStatus.taken)
          .length;
      final completed = medicineLogs
          .where(
            (log) =>
                log.status == MedicineLogStatus.taken ||
                log.status == MedicineLogStatus.missed ||
                log.status == MedicineLogStatus.skipped,
          )
          .length;

      final adherenceRate = completed > 0
          ? (takenDoses / completed) * 100
          : 0.0;

      details.add(
        MedicineStatisticsDetail(
          medicineId: medicineId,
          medicineName: medicine.name,
          totalDoses: totalDoses,
          takenDoses: takenDoses,
          adherenceRate: adherenceRate,
          colorValue: colors[colorIndex % colors.length],
        ),
      );

      colorIndex++;
    }

    return details;
  }

  // ==================== Helper Methods ====================

  /// Get logs within a date range
  Future<List<MedicineLog>> _getLogsInRange(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    if (startDate == null && endDate == null) {
      return getAllLogs();
    }

    final start = startDate ?? DateTime(2000);
    final end = endDate ?? DateTime.now();

    final query = _objectBoxService.medicineLogBox
        .query(MedicineLogModel_.scheduledTime.betweenDate(start, end))
        .build();
    final models = query.find();
    query.close();

    return models.map((model) => model.toEntity()).toList();
  }

  /// Generate daily adherence data for charts
  Future<List<DailyAdherence>> _generateDailyAdherenceData(int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));

    final List<DailyAdherence> data = [];

    for (int i = 0; i < days; i++) {
      final date = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      ).add(Duration(days: i));

      final logs = await getLogsByDate(date);
      final scheduled = logs.length;
      final taken = logs
          .where((log) => log.status == MedicineLogStatus.taken)
          .length;
      final adherenceRate = scheduled > 0 ? (taken / scheduled) * 100 : 0.0;

      data.add(
        DailyAdherence(
          date: date,
          scheduled: scheduled,
          taken: taken,
          adherenceRate: adherenceRate,
        ),
      );
    }

    return data;
  }
}
