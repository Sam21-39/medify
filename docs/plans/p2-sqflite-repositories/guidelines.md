# Guidelines: P2 sqflite repositories

Audience: `model-implementer`. Follow literally. Stop and report on conflict.

## Read first

- `docs/plans/p2-sqflite-repositories/prd.md`
- `lib/core/database/schema.dart`, `lib/core/database/medify_database.dart`, `lib/core/database/enums.dart`
- `lib/features/medicines/domain/repositories/medicine_repository.dart`
- `lib/features/medicines/data/repositories/medicine_repository_impl.dart` (legacy; read for behaviour, do not copy ObjectBox calls)
- `lib/features/schedule/domain/repositories/medicine_log_repository.dart`
- `lib/features/schedule/data/repositories/medicine_log_repository_impl.dart` (legacy behaviour reference)
- `lib/features/medicines/domain/entities/` and `lib/features/schedule/domain/entities/` (domain types)
- `lib/core/error/` (Failure types)

## Allowed write paths

- `lib/features/medicines/data/sqflite/medicine_sqflite_repository.dart` (new)
- `lib/features/medicines/data/sqflite/medicine_row_mapper.dart` (new)
- `lib/features/schedule/data/sqflite/medicine_log_sqflite_repository.dart` (new)
- `lib/features/schedule/data/sqflite/medicine_log_row_mapper.dart` (new)
- `lib/core/database/settings_store.dart` (new)
- `test/features/medicines/data/sqflite/**` (new)
- `test/features/schedule/data/sqflite/**` (new)
- `test/core/database/settings_store_test.dart` (new)

Do NOT touch: `lib/core/di/**`, `lib/core/database/schema.dart` (schema frozen), `lib/core/database/medify_database.dart` (unless a helper is strictly needed; report it), any legacy `*_impl.dart`, `lib/features/**/presentation/**`, `pubspec.yaml`, `ios/**`, `android/**`, `docs/**` (except report). Do not commit.

## Steps

1. Baseline: `git status --short`. Record.
2. Mapper first: `medicine_row_mapper.dart` converts row Map ↔ domain `Medicine`. Enum conversion via `.name` and `Enum.values.byName`. Dates via `millisecondsSinceEpoch`. Unknown enum value in a row → throw `StateError` with table/column name.
3. `SqfliteMedicineRepository(Database db)`:
   - Every method uses `db.transaction` for writes that touch more than one row.
   - Implement every method in `MedicineRepository`.
   - `watch*` methods: a `StreamController<List<Medicine>>.broadcast()` per method; after each write, re-query and push. Document single-process limit in a comment.
   - Map sqflite exceptions on write to `Left(Failure)` where the interface returns Either. Use the existing Failure type found in `lib/core/error/`.
4. `medicine_log_row_mapper.dart` and `SqfliteMedicineLogRepository(Database db)`:
   - `markAsTaken(id)`: in one transaction: read row; if status already `taken` → return Right(row unchanged) (idempotent, no second decrement); if status `skipped` → Left(Failure) with message "already skipped"; else set status `taken`, `taken_at_utc = now UTC`, decrement `medicines.current_quantity` by `dose_snapshot_amount` if not null, clamp at 0 (CHECK forbids negative — report if clamp is needed). Both updates in one transaction.
   - `markAsSkipped(id)`: from `scheduled` or `missed` only; set `status='skipped'`, `skip_reason` from notes if the interface provides it, else null. Respect the CHECK (taken requires taken_at_utc; skipped must not set taken_at_utc).
   - `markAsMissed(id)`: from `scheduled` only; no-op Right if already `missed`.
   - `snoozeLog(id, minutes)`: from `scheduled` only; set `snoozed_until_utc = now + minutes`.
   - Insert of a log whose (schedule_id, scheduled_at_utc) exists → Left(Failure). Do not overwrite.
   - Read methods: order by `scheduled_at_utc` ascending unless the interface implies otherwise.
   - Stats methods (`getStatistics`, `getStatisticsForDays`, `getCurrentStreak`, `getBestStreak`, `getDailyCompletion`, `getDailyScheduled`, `getMedicineAdherenceRates`, `getMedicineStatisticsDetails`): implement only if a straightforward SQL query fits; otherwise throw `UnimplementedError('stats: P2c')` and list them in the report. Do NOT add schema views.
5. `settings_store.dart`: `SettingsStore(Database db)` with `getBool/setBool`, `getInt/setInt`, `getString/setString`, `getEnum<T extends Enum>(key, values, default)`, `setEnum`. Writes use `INSERT ... ON CONFLICT(key) DO UPDATE`. `value_type` column must match the call; on mismatch read returns default and does not throw.
6. Tests (in-memory sqflite FFI; each test opens a fresh `MedifyDatabase.open(path: inMemoryDatabasePath)`; call `sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;` in `setUpAll`):
   - Medicine: add/get/update/delete/toggle; cascade delete removes schedules.
   - Log: taken twice → stock decremented once; skipped after taken → Left; snooze stores snoozed_until_utc; duplicate occurrence insert → Left, no crash; cross-patient occurrence → Left.
   - Settings: bool, int, string, enum round trip; type-mismatch read → default.
7. Verification, stop on first failure:
   - `dart format --set-exit-if-changed lib/features/medicines/data/sqflite lib/features/schedule/data/sqflite lib/core/database test/features test/core/database`
   - `flutter analyze lib test`
   - `flutter test test/features/medicines/data/sqflite test/features/schedule/data/sqflite test/core/database test/database`
   - `git diff --stat -- lib/core/di lib/core/database/schema.dart` must be empty.
   - `grep -rn "objectbox\|shared_preferences" lib/features/*/data/sqflite lib/core/database/settings_store.dart` must print nothing.
8. Report under 25 lines: files created, test results, which stats methods are stubbed, any schema mismatch found (do not change schema), any helper added to medify_database.dart.

## Stop and report if

- A repo method needs a column that does not exist in `schema.dart`.
- Failure type for a Left return is unclear.
- `flutter analyze` shows errors in files outside allowed paths.

## Decisions made after stop report (binding)

1. Return contract: keep existing interface signatures. Methods returning `Either` return `Left(Failure)` on conflict or invalid transition. Methods returning plain values (`addLog`, `markAsMissed`, `updateLog`, `deleteLog`) throw typed exceptions defined in `lib/features/schedule/data/sqflite/medicine_log_exceptions.dart`: `OccurrenceConflictException` (duplicate key) and `InvalidTransitionException`.
2. scheduleId: add nullable `int? scheduleId` to the domain `MedicineLog` entity (file found via `grep -rn "class MedicineLog" lib/features/schedule/domain`). Nullable so legacy code still compiles; the sqflite insert throws `StateError` if it is null. Do not change legacy `medicine_log_model.dart` mapping beyond what compiles.
3. Actor: `actor_profile_id` is set once at insert from the entity's `profileId`. Transition methods do not take an actor. Report this as a known limit: the actor who takes a dose is not recorded separately yet.
4. Status mapping: `pending` -> `scheduled`; `snoozed` -> `scheduled` with `snoozed_until_utc` set; `taken`/`skipped`/`missed` one-to-one. Read back: `scheduled` with null `snoozed_until_utc` -> `pending`; `scheduled` with `snoozed_until_utc` -> `snoozed`.
5. Medicine reminder times and weekdays live in `schedules`. `start_date` = the medicine's `createdAt` date. `weekdays_mask`: bit 0 = Monday ... bit 6 = Sunday; `daysOfWeek` values 1-7 (ISO, Monday=1) map to bit (value-1). Empty `daysOfWeek` means all days (127).
6. Medicine update that changes reminder times: set existing schedules `is_active = 0` (do not delete, occurrences reference them), insert new schedules. Do not delete schedule rows that have occurrences.
7. `deleteMedicine`: in one transaction, delete occurrences for the medicine, then schedules, then the medicine (same order as legacy: logs first).
8. `isActive` true -> `state='active'`; false -> `state='paused'`. Read back: `paused` and `finished` -> isActive false. Do not write `finished` from this repo.
9. Stub nothing that the interface requires without a clear SQL query. Stats stubs allowed only as listed in the PRD.
