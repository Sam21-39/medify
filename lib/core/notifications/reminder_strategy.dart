/// Pluggable, additive scheduling strategies (Section 12) — new strategies
/// slot in without a rewrite of the core scheduler.
sealed class ReminderStrategy {
  const ReminderStrategy({required this.medicineId});

  final String medicineId;
}

/// Phase 1.
class ExactTimeStrategy extends ReminderStrategy {
  const ExactTimeStrategy({required super.medicineId, required this.times});

  final List<DateTime> times;
}

/// Phase 2.
class MealRelativeStrategy extends ReminderStrategy {
  const MealRelativeStrategy({
    required super.medicineId,
    required this.meal,
    required this.offset,
  });

  final String meal;
  final Duration offset;
}

/// Phase 2.
class IntervalStrategy extends ReminderStrategy {
  const IntervalStrategy({
    required super.medicineId,
    required this.interval,
    required this.startAt,
  });

  final Duration interval;
  final DateTime startAt;
}

/// Phase 2.
class WeekdayStrategy extends ReminderStrategy {
  const WeekdayStrategy({
    required super.medicineId,
    required this.weekdays,
    required this.time,
  });

  final Set<int> weekdays;
  final DateTime time;
}
