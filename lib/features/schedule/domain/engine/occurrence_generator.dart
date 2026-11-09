import 'package:timezone/timezone.dart' as tz;

/// Pure occurrence generation. Never reads "now"; the caller passes the window.
///
/// Weekdays mask: bit 0 = Monday ... bit 6 = Sunday. 127 = every day.
/// `startDate`/`endDate`/`fromDate`/`toDate` are calendar dates (only y/m/d used).

class InvalidScheduleRuleException implements Exception {
  const InvalidScheduleRuleException(this.message);
  final String message;

  @override
  String toString() => 'InvalidScheduleRuleException: $message';
}

class ScheduleRule {
  const ScheduleRule({
    required this.scheduleId,
    required this.timeOfDaySeconds,
    required this.weekdaysMask,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  final int scheduleId;
  final int timeOfDaySeconds;
  final int weekdaysMask;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
}

class GeneratedOccurrence {
  const GeneratedOccurrence({
    required this.scheduleId,
    required this.scheduledAtUtc,
    required this.localDate,
  });

  final int scheduleId;
  final DateTime scheduledAtUtc;

  /// `YYYY-MM-DD` of the local date the occurrence belongs to.
  final String localDate;
}

/// Occurrences for [rule] on each local date in [fromDate]..[toDate] (inclusive).
List<GeneratedOccurrence> generateOccurrences({
  required ScheduleRule rule,
  required DateTime fromDate,
  required DateTime toDate,
  required tz.Location location,
}) {
  final mask = rule.weekdaysMask;
  if (mask < 1 || mask > 127) {
    throw InvalidScheduleRuleException('weekdays mask $mask must be 1..127');
  }
  if (rule.timeOfDaySeconds < 0 || rule.timeOfDaySeconds > 86399) {
    throw InvalidScheduleRuleException(
      'time of day ${rule.timeOfDaySeconds}s out of range',
    );
  }
  if (!rule.isActive) return const [];

  final start = _dateOnly(rule.startDate);
  final end = rule.endDate == null ? null : _dateOnly(rule.endDate!);
  final last = _dateOnly(toDate);
  final out = <GeneratedOccurrence>[];
  for (
    var day = _dateOnly(fromDate);
    !day.isAfter(last);
    day = day.add(const Duration(days: 1))
  ) {
    if (day.isBefore(start)) continue;
    if (end != null && day.isAfter(end)) continue;
    if (mask & (1 << (day.weekday - 1)) == 0) continue;
    final wall = day.add(Duration(seconds: rule.timeOfDaySeconds));
    out.add(
      GeneratedOccurrence(
        scheduleId: rule.scheduleId,
        scheduledAtUtc: _wallClockToUtc(wall, location),
        localDate: _formatDate(day),
      ),
    );
  }
  return out;
}

/// Local wall clock (fields of [wall], which is a UTC DateTime used only as a
/// naive container) to a UTC instant in [location].
///
/// DST rules:
/// - Gap (wall time skipped by a forward shift): returns the transition
///   instant, i.e. the first valid local time after the gap (02:30 -> 03:00).
/// - Overlap (wall time repeated by a backward shift): returns the earlier
///   instant (the first occurrence).
DateTime _wallClockToUtc(DateTime wall, tz.Location location) {
  const day = Duration.millisecondsPerDay;
  final naive = wall.millisecondsSinceEpoch;
  int offsetAt(int utcMs) => location.timeZone(utcMs).offset.inMilliseconds;

  final candidates = <int>{
    for (final o in {offsetAt(naive - day), offsetAt(naive + day)})
      if (offsetAt(naive - o) == o) naive - o,
  }.toList()..sort();
  if (candidates.isNotEmpty) {
    return DateTime.fromMillisecondsSinceEpoch(candidates.first, isUtc: true);
  }

  // Gap: binary search for the first instant that already has the post-gap offset.
  final after = offsetAt(naive + day);
  var lo = naive - day;
  var hi = naive + day;
  while (hi - lo > 1) {
    final mid = lo + (hi - lo) ~/ 2;
    if (offsetAt(mid) == after) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  return DateTime.fromMillisecondsSinceEpoch(hi, isUtc: true);
}

DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

String _formatDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
