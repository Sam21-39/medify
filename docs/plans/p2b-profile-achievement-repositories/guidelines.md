# Guidelines: P2b, sqflite profile, care-link, achievement repositories

Audience: `model-implementer`. Additive only. Not wired into DI. Same rules as P2 (`docs/plans/p2-sqflite-repositories/guidelines.md`), including its "Decisions" section.

## Read first

- `lib/core/database/schema.dart` (tables `profiles`, `achievements`; `settings` already covered)
- `lib/core/database/enums.dart` (`ProfileRole`, `AchievementType`)
- `lib/core/database/medify_database.dart`
- `lib/features/profiles/data/models/user_profile_model.dart` and `care_link_model.dart` (legacy fields; reference only)
- `lib/features/profiles/data/repositories/care_link_repository.dart` (legacy behaviour)
- `lib/features/profiles/domain/repositories/user_profile_repository.dart` and any entities under `lib/features/profiles/domain/entities/`
- `lib/features/achievements/data/models/achievement_model.dart`, `lib/features/achievements/data/services/achievement_service.dart` (type list and unlock rules)
- `lib/core/error/` (Failure types)

## Allowed write paths

- `lib/features/profiles/data/sqflite/profile_sqflite_repository.dart` (new)
- `lib/features/profiles/data/sqflite/profile_row_mapper.dart` (new)
- `lib/features/profiles/data/sqflite/care_link_sqflite_repository.dart` (new)
- `lib/features/achievements/data/sqflite/achievement_sqflite_repository.dart` (new)
- `lib/features/achievements/data/sqflite/achievement_row_mapper.dart` (new)
- `test/features/profiles/data/sqflite/**` (new)
- `test/features/achievements/data/sqflite/**` (new)

Do NOT touch: `lib/core/di/**`, `lib/core/database/schema.dart`, legacy `*_impl.dart`, legacy `*_service.dart`, `presentation/**`, `pubspec.yaml`, `ios/**`, `android/**`, `docs/**` (except report). Do not commit.

## Rules

- Schema frozen. No new columns.
- Enums by `.name`.
- Dates: epoch milliseconds (UTC for `*_utc` columns).
- Interface signatures unchanged. Either methods return `Left(Failure)`. Plain-value methods throw typed exceptions from a new `lib/features/profiles/data/sqflite/profile_exceptions.dart` (`InvalidProfileException`, `ProfileNotFoundException`).
- Profile role mapping: legacy `role` int -> `ProfileRole` by name via the enum; if the legacy value has no equivalent, stop and report.
- Deleting a profile: only if it has no medicines, occurrences or achievements; otherwise set `is_archived = 1` (soft delete). Report which path was taken for each caller.
- Care link: `patient_profile_id` and `caregiver_profile_id` must both exist and differ. Enforce in repo; schema has FKs only.
- Achievements: one row per (`profile_id`, `type`). `unlockAchievement` is idempotent: unlocking an already-unlocked type returns the existing row unchanged. `progress` only increases.

## Steps

1. Baseline: `git status --short`.
2. Mappers: `profile_row_mapper.dart`, `achievement_row_mapper.dart`.
3. `ProfileSqfliteRepository(Database db)` implementing the profile repository interface found under `lib/features/profiles/domain/repositories/`. Use transactions for writes that touch more than one row.
4. `CareLinkSqfliteRepository(Database db)`: match the legacy `CareLinkRepository` surface, add the validation rule above.
5. `AchievementSqfliteRepository(Database db)`: match the legacy `AchievementService` data needs (get, unlock, progress update, list per profile). If the service mixes logic that belongs in a domain rule, keep the repo to data access and report the logic found.
6. Tests in-memory sqflite FFI (`sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;`, `MedifyDatabase.open(path: inMemoryDatabasePath)`):
   - Profile: create, get, update, archive; delete blocked when medicines exist (archives instead).
   - Care link: self-link rejected; duplicate link rejected; both profiles must exist.
   - Achievement: unlock idempotent; progress never decreases; duplicate (profile, type) rejected by DB and surfaced as typed exception.
7. Verification, stop on first failure:
   - `dart format --set-exit-if-changed lib/features/profiles/data/sqflite lib/features/achievements/data/sqflite test/features/profiles test/features/achievements`
   - `flutter analyze lib test`
   - `flutter test test/features/profiles/data/sqflite test/features/achievements/data/sqflite test/features/medicines/data/sqflite test/features/schedule/data/sqflite test/core/database`
   - `git diff --stat -- lib/core/di lib/core/database/schema.dart` must be empty.
8. Report under 20 lines: files created, test results, legacy callers that needed a soft-delete decision, any logic found in services.

## Stop and report if

- A legacy role or achievement type has no enum equivalent.
- A repo needs a column not in `schema.dart`.
- Analyze errors appear outside allowed paths.
