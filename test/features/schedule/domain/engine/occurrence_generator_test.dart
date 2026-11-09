import 'package:flutter_test/flutter_test.dart';
import 'package:medify/features/schedule/domain/engine/occurrence_generator.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late tz.Location utc;
  late tz.Location london;
  late tz.Location newYork;

  setUpAll(() {
    tzdata.initializeTimeZones();
    utc = tz.getLocation('UTC');
    london = tz.getLocation('Europe/London');
    newYork = tz.getLocation('America/New_York');
  });

  ScheduleRule rule({
    int timeOfDaySeconds = 8 * 3600,
    int weekdaysMask = 127,
    DateTime? startDate,
    DateTime? endDate,
    bool isActive = true,
  }) => ScheduleRule(
    scheduleId: 1,
    timeOfDaySeconds: timeOfDaySeconds,
    weekdaysMask: weekdaysMask,
    startDate: startDate ?? DateTime(2026, 1, 1),
    endDate: endDate,
    isActive: isActive,
  );

  List<GeneratedOccurrence> gen(
    ScheduleRule r, {
    DateTime? from,
    DateTime? to,
    tz.Location? location,
  }) => generateOccurrences(
    rule: r,
    fromDate: from ?? DateTime(2026, 3, 2),
    toDate: to ?? DateTime(2026, 3, 15),
    location: location ?? utc,
  );

  test('Monday-only mask over 14 days yields exactly the Mondays', () {
    final out = gen(rule(weekdaysMask: 1 << 0));
    expect(out.map((o) => o.localDate), ['2026-03-02', '2026-03-09']);
    for (final o in out) {
      expect(DateTime.parse(o.localDate).weekday, DateTime.monday);
    }
  });

  test('weekdays mask 0 is rejected with a typed error', () {
    expect(
      () => gen(rule(weekdaysMask: 0)),
      throwsA(isA<InvalidScheduleRuleException>()),
    );
  });

  test('start and end dates are inclusive', () {
    final out = gen(
      rule(startDate: DateTime(2026, 3, 3), endDate: DateTime(2026, 3, 5)),
      from: DateTime(2026, 3, 1),
      to: DateTime(2026, 3, 10),
    );
    expect(out.map((o) => o.localDate), [
      '2026-03-03',
      '2026-03-04',
      '2026-03-05',
    ]);
  });

  test('inactive schedule yields no occurrences', () {
    expect(gen(rule(isActive: false)), isEmpty);
  });

  test('midnight and 23:59 wall times map to the same local clock', () {
    final midnight = gen(
      rule(timeOfDaySeconds: 0),
      from: DateTime(2026, 3, 2),
      to: DateTime(2026, 3, 2),
      location: london,
    );
    expect(midnight.single.scheduledAtUtc, DateTime.utc(2026, 3, 2));

    final lastMinute = gen(
      rule(timeOfDaySeconds: 23 * 3600 + 59 * 60),
      from: DateTime(2026, 3, 2),
      to: DateTime(2026, 3, 2),
      location: london,
    );
    expect(lastMinute.single.scheduledAtUtc, DateTime.utc(2026, 3, 2, 23, 59));
  });

  test('spring-forward gap: 02:30 on 2026-03-08 New York -> 07:00 UTC', () {
    final out = gen(
      rule(timeOfDaySeconds: 2 * 3600 + 30 * 60),
      from: DateTime(2026, 3, 8),
      to: DateTime(2026, 3, 8),
      location: newYork,
    );
    expect(out.single.scheduledAtUtc, DateTime.utc(2026, 3, 8, 7));
  });

  test('fall-back overlap: 01:30 on 2026-11-01 New York -> first instant', () {
    final out = gen(
      rule(timeOfDaySeconds: 1 * 3600 + 30 * 60),
      from: DateTime(2026, 11, 1),
      to: DateTime(2026, 11, 1),
      location: newYork,
    );
    // 01:30 EDT (first occurrence) is 05:30 UTC; 01:30 EST would be 06:30 UTC.
    expect(out.single.scheduledAtUtc, DateTime.utc(2026, 11, 1, 5, 30));
  });

  test('same wall time in two zones gives different UTC instants', () {
    final lon = gen(
      rule(),
      from: DateTime(2026, 1, 15),
      to: DateTime(2026, 1, 15),
      location: london,
    ).single.scheduledAtUtc;
    final ny = gen(
      rule(),
      from: DateTime(2026, 1, 15),
      to: DateTime(2026, 1, 15),
      location: newYork,
    ).single.scheduledAtUtc;
    expect(lon, DateTime.utc(2026, 1, 15, 8));
    expect(ny, DateTime.utc(2026, 1, 15, 13));
  });
}
