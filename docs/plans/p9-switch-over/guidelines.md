# Guidelines: P9 switch-over

Audience: `model-implementer`. Read `docs/plans/p9-switch-over/prd.md` first. Run in the order below; stop at the first failure. Do not start a step until the previous one passes.

Do not commit. Report each step's result in under 25 lines total at the end.

## Step A: inventory (read only)

- `grep -rln "objectbox\|ObjectBox" lib test`
- `grep -rln "shared_preferences\|PreferencesService" lib test`
- `grep -rn "MedicineRepositoryImpl\|MedicineLogRepositoryImpl\|CareLinkRepository\|ProfileService\|AchievementService" lib test`
- Record the list in your report.

## Step B: DI and repos

Files: `lib/core/di/injection_container.dart`, `lib/core/database/medify_database.dart` (if a getter for the open DB is needed).

- Open `MedifyDatabase` once in DI; register `Database`, `FieldCipher` (from `lib/core/security/`), `DatabaseKeyStore`.
- Register sqflite repos: `SqfliteMedicineRepository`, `SqfliteMedicineLogRepository`, `SqfliteProfileRepository`, `SqfliteCareLinkRepository`, `SqfliteAchievementRepository`, `SettingsStore`.
- Interfaces stay as `MedicineRepository`, `MedicineLogRepository`, etc. Replace the registration target only.
- Legacy repo registrations removed.
- Verify: `flutter analyze lib/core/di` clean.

## Step C: PreferencesService over SettingsStore

File: `lib/core/preferences/preferences_service.dart`.

- Same public API (sync getters, async setters).
- `PreferencesService.initialize(SettingsStore store)` loads all known keys into an in-memory map.
- Setters write to the map and to the store.
- Keys: keep the legacy key names (`first_launch`, `theme_mode`, `notifications_enabled`, `snooze_duration`, `last_log_generation_date`, `role_chosen`, `speak_reminder`, `acting_patient_id`, `active_profile_id`).
- Remove `import 'package:shared_preferences/...'`.
- Test: round trip per key type; cache reflects writes.

## Step D: services off ObjectBox

Files: `lib/features/profiles/data/services/profile_service.dart`, `lib/features/profiles/data/repositories/care_link_repository.dart`, `lib/features/achievements/data/services/achievement_service.dart`, `lib/features/schedule/data/services/daily_log_service.dart`, `lib/features/schedule/data/services/log_generator.dart`.

- Replace direct ObjectBox box calls with the sqflite repo methods (P2b/P2 repos).
- Keep the logic. Only swap storage calls.
- `DailyLogService` uses `occurrence_sqflite_generator` (P4). Filter medicines with state != `active`.
- Legacy `CareLinkRepository` replaced by the sqflite care-link repo; keep the same class name only if callers need it; otherwise update callers.
- Verify: `flutter analyze lib` no errors from these files.

## Step E: notifications

File: `lib/core/notifications/notification_service.dart`.

- Payload: `NotificationPayload.encode(installationId, occurrenceId)` from `lib/features/schedule/domain/engine/notification_payload.dart`.
- Tap handlers (foreground and background): `decode` → on `Valid` load the occurrence through the log repo and proceed; on Missing/Malformed/Mismatch log and ignore.
- Installation ID: read from `installation_metadata` (create on first run if absent).
- Scheduling uses `occurrence_sqflite_generator` output.
- Keep existing notification IDs only if still unique; otherwise derive from occurrence id.

## Step F: main.dart and reset

File: `lib/main.dart`.

- Order: `WidgetsFlutterBinding.ensureInitialized()` → detect legacy store (P3 detector) → if existing user and not yet reset: run app with P3 reset notice only; on Continue, run reset then `initializeDependencies()` then the real app → else `initializeDependencies()` then the real app.
- Reset notice uses P3 screen code unchanged.

## Step G: remove ObjectBox and shared_preferences

- Delete: `lib/core/database/objectbox_service.dart` (keep only the constant and path logic used by the P3 detector; move to `lib/core/transition/legacy_store.dart` if needed), `lib/objectbox.g.dart`, all `*_model.dart` under `lib/features/**/data/models/` that are ObjectBox entities, legacy `*_impl.dart` repos, and their now-unused imports.
- Confirm no ObjectBox annotation remains: `grep -rn "@Entity\|@Id()\|objectbox" lib`.
- `pubspec.yaml`: `flutter pub remove objectbox objectbox_flutter_libs objectbox_generator shared_preferences`. Keep `build_runner` only if `injectable_generator` or `flutter_gen_runner` still needs it; report which.
- `flutter pub get`; `dart run build_runner build --delete-conflicting-outputs` only if build_runner remains.

## Step H: verification (stop on first failure)

1. `dart format --set-exit-if-changed lib test`
2. `flutter analyze` — zero errors.
3. `flutter test` — all pass.
4. `grep -rn "objectbox\|ObjectBox\|shared_preferences" lib test pubspec.yaml` — only the legacy-name constant allowed.
5. `flutter build ios --no-codesign --debug` — pass; log has no "pod install".
6. `flutter build apk --debug` — pass.

## Step I: simulator run

- `xcrun simctl boot CBEC0565-8CEB-42F5-84E9-01466DF90CE5` (if not booted).
- `flutter run -d CBEC0565-8CEB-42F5-84E9-01466DF90CE5` in background; wait for "Flutter run key commands" or app launch.
- Take a screenshot: `xcrun simctl io CBEC0565-8CEB-42F5-84E9-01466DF90CE5 screenshot <scratchpad>/launch.png`.
- Report the screenshot path and the first screen shown.
- Do NOT delete data in the simulator without asking (the reset path must be exercised by the app, not by shell deletes).

## Stop and report if

- Any step fails. Do not force past it.
- A legacy caller cannot be migrated without changing a public API used by presentation code (list callers; stop).
- The simulator is unavailable or the app fails to launch (include the shortest error line).
