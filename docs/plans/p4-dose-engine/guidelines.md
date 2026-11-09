# Guidelines: P4 dose engine (pure logic, not wired)

Audience: `model-implementer`. Additive. Not wired into DI or notifications yet (switch-over is P9). Repos from P2 already exist; reuse them, do not change their behaviour.

## Read first

- `docs/architecture/medify-2-0-0-release-plan.md` (section "Architecture and Interfaces", data model, test plan: schedule/notification bullets)
- `docs/adr/0001-reset-legacy-objectbox-storage.md` (section "Related decisions" only as needed)
- `lib/core/database/schema.dart` (`schedules`, `occurrences`)
- `lib/features/schedule/data/services/log_generator.dart`, `daily_log_service.dart` (legacy generation rules; reference only)
- `lib/features/schedule/data/sqflite/medicine_log_sqflite_repository.dart` (existing transitions)
- `lib/core/notifications/notification_service.dart` lines around payload creation (~line 350 and ~650) and tap handlers (~166, ~229), reference only

## Allowed write paths

- `lib/features/schedule/domain/engine/**` (new): pure Dart, no Flutter, no sqflite.
  - `occurrence_generator.dart`: given a schedule (time_of_day_seconds, weekdays mask, start_date, end_date, is_active) and a local date range and a timezone location, produce UTC `scheduled_at_utc` instants and `local_date` strings. Use `package:timezone` (already a dependency) for local wall-clock → UTC.
  - `notification_payload.dart`: encode/decode `{"installationId": String, "occurrenceId": int}`. Decode returns a sealed result: `Valid`, `Missing`, `Malformed`, `Mismatch`. Mismatch = installationId differs from the given local installation id.
- `lib/features/schedule/data/sqflite/occurrence_sqflite_generator.dart` (new): writes generated occurrences via `INSERT OR IGNORE` keyed by UNIQUE(schedule_id, scheduled_at_utc). Returns count inserted. Idempotent.
- `test/features/schedule/domain/engine/**` (new)
- `test/features/schedule/data/sqflite/occurrence_sqflite_generator_test.dart` (new)

Do NOT touch: `lib/main.dart`, `lib/core/di/**`, `lib/core/notifications/**`, `lib/core/database/schema.dart`, legacy `*_impl.dart`, `lib/features/**/presentation/**`, `pubspec.yaml`, `ios/**`, `android/**`, `docs/**` (except report). Do not commit.

## Rules

- Weekdays mask: bit 0 = Monday … bit 6 = Sunday (matches P2 decision). Mask 127 = every day. Mask 0 is invalid (reject).
- A schedule occurs on a local date d if weekday(d) bit set AND start_date <= d AND (end_date null OR d <= end_date). Ignore inactive schedules (`is_active = 0`).
- Time: `time_of_day_seconds` in local wall clock. DST: if the local time does not exist (spring-forward gap), shift forward to the first valid instant; if it occurs twice (fall-back), use the first. Document the rule in a comment.
- `local_date` stored as `YYYY-MM-DD` of the local date the occurrence belongs to.
- Generation window is caller-supplied. Generator never reads "now" itself (inject a clock or pass dates).
- Notification payload: installationId must be non-empty; occurrenceId positive int. Anything else → `Malformed`.

## Steps

1. Baseline `git status --short`.
2. `occurrence_generator.dart` and unit tests.
3. `notification_payload.dart` and unit tests.
4. `occurrence_sqflite_generator.dart` and tests (in-memory sqflite FFI: `sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;` and `MedifyDatabase.open(path: inMemoryDatabasePath)`).
5. Tests required:
   - Weekdays: Mon-only mask over a 14-day range → exactly the Mondays.
   - Mask 0 → rejected with a typed error.
   - Start/end date boundaries inclusive.
   - Inactive schedule → no occurrences.
   - Midnight schedule (00:00) and 23:59 schedule.
   - DST spring-forward gap time: returns the shifted instant; fall-back: first instant.
   - Timezone: same wall time in two zones gives different UTC instants.
   - Re-running generation for the same window inserts 0 new rows (idempotent).
   - Payload: valid; missing field; malformed JSON; wrong installationId → Mismatch; zero occurrenceId → Malformed.
6. Verification, stop on first failure:
   - `dart format --set-exit-if-changed lib/features/schedule/domain/engine lib/features/schedule/data/sqflite test/features/schedule/domain/engine test/features/schedule/data/sqflite`
   - `flutter analyze lib test`
   - `flutter test test/features/schedule`
   - `git diff --stat -- lib/main.dart lib/core/di lib/core/notifications lib/core/database` must be empty.

## Report (under 20 lines)

Files, test results, DST rule as implemented, any legacy rule that did not map (for example, legacy repeat-daily reminders ignoring weekdays).

## Stop and report if

- Timezone DB init is needed at app start (report; do not add init code outside allowed paths).
- A required behaviour is not expressible with the existing schema.
