# PRD: P2, sqflite repositories (additive, not wired)

## Problem and outcome

The v2 schema exists (`lib/core/database/schema.dart`, `medify_database.dart`). No repository reads or writes it. Feature work needs repos that do.

Outcome: sqflite-backed implementations of the existing domain repository interfaces, tested against an in-memory database. Not wired into DI. App behaviour unchanged (still ObjectBox).

## Scope

In:
- `SqfliteMedicineRepository` implements `MedicineRepository` (`lib/features/medicines/domain/repositories/medicine_repository.dart`).
- `SqfliteMedicineLogRepository` implements `MedicineLogRepository` (`lib/features/schedule/domain/repositories/medicine_log_repository.dart`).
- `SqfliteSettingsStore`: typed key/value over the `settings` table (replaces `PreferencesService` reads/writes, interface only; no caller changes).
- Mapping between domain entities and SQL rows.

Out:
- DI switch-over (ObjectBox stays registered).
- Reset gate (P3).
- Profiles, care links, achievements repos (P2b, separate slice).
- Stats/adherence queries beyond the methods the interface already declares, if they need a view not yet designed. Stub with `UnimplementedError` and list them in the report.

## Decisions fixed

- Schema is authoritative (`schema.dart`). Repos must not add columns.
- Dates: `*_utc` columns stored as epoch milliseconds UTC. Local-date snapshot is text `YYYY-MM-DD`.
- Enums by `.name`, never index.
- Dose actions (`markAsTaken`, `markAsSkipped`, `snoozeLog`) are single transactions. Stock decrement (`medicines.current_quantity`) happens once, inside the same transaction, only on `taken` transition from non-taken.
- `profile_id` on medicines and logs comes from the caller. No default profile logic here.
- Interface signatures unchanged. Where the existing interface returns `Either<Failure, T>`, use the existing `Failure` types.

## Acceptance checks

1. `SqfliteMedicineRepository` passes CRUD + toggle + watch tests (in-memory sqflite FFI).
2. `SqfliteMedicineLogRepository`: `markAsTaken` twice → stock decremented once; `markAsSkipped` after taken → returns `Failure` and leaves state unchanged; snooze stores `snoozed_until_utc`.
3. Duplicate (`schedule_id`, `scheduled_at_utc`) rejected by DB; repo surfaces `Failure`, does not crash.
4. Patient isolation: getters filter by `profile_id` when the interface passes one; cross-patient occurrence insert rejected by trigger (already tested in schema tests; re-assert via repo).
5. `SqfliteSettingsStore` round-trips bool, int, string, enum name; type mismatch on read returns the default.
6. DI file (`lib/core/di/injection_container.dart`) unchanged.
7. `flutter analyze` no new issues in touched files; `flutter test` green for new tests.

## Risks

- Interface methods returning `List<MedicineLog>` with joined medicine data may need a join the schema supports. Report any mismatch rather than changing the schema.
- Watch streams: sqflite has no reactive query. Use a simple broadcast `StreamController` refreshed after each write in the repo. Single-process only; document limit.
