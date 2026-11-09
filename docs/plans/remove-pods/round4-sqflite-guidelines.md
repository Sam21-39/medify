# Round 4: drop Drift, use sqflite; drop path_provider, use native paths channel

Owner instruction: if Drift is the problem, check sqflite and crypto, drop Drift completely.

Findings:
- sqflite_darwin 2.4.4+1 ships Package.swift (SPM supported).
- sqflite 2.4.5 / sqflite_common 2.5.14 / sqflite_android 2.4.5 are pure plugin code; no CocoaPods-only pieces.
- `crypto` (3.0.x) is hashing only (SHA, HMAC). Backup needs AES-256-GCM and PBKDF2, which `crypto` does not provide. Use `cryptography` (pure Dart, no native plugin). Add it in round 4 only if the backup slice needs it; do NOT add it now. Round 4 adds sqflite only.
- sqflite's `getDatabasesPath()` does not use path_provider. DB file location needs no channel.
- CSV export (history_cubit.dart) needs a temporary directory → `medify/paths` channel gets a `temporaryDirectory` method.
- ObjectBox (still in app until the Drift/sqflite repo slice + removal) needs documents directory → `medify/paths` `documentsDirectory` stays until ObjectBox is removed.

## Allowed write paths

- `pubspec.yaml`, `pubspec.lock`:
  - `flutter pub remove drift drift_flutter drift_dev path_provider` (drift_dev is dev dependency; `build_runner` stays if other code needs it — check `grep -rn "build_runner\|objectbox_generator" pubspec.yaml`; do NOT remove build_runner or objectbox_generator; ObjectBox still needs them)
  - `flutter pub add sqflite`
  - dev: `flutter pub add dev:sqflite_common_ffi`
  - Check sqflite pinned version is at least 14 days old on pub.dev. If newest is younger, use the previous stable.
- `lib/core/database/**` (rewrite): delete `app_database.dart` drift class, `tables/*.dart`, `drift_schemas/`. Keep `enums.dart` (Dart enums, lowerCamelCase values as already agreed). Add:
  - `lib/core/database/medify_database.dart`: opens sqflite database via `openDatabase(path, version: 1, onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'), onCreate: (db, v) => createSchema(db))`. Path: `join(await getDatabasesPath(), 'medify_v2.db')` (`path` package, already direct dependency). Export class `MedifyDatabase` with static `open({String? path})` for tests (test passes `inMemoryDatabasePath`).
  - `lib/core/database/schema.dart`: the SQL DDL as const strings, one `CREATE TABLE` per table, plus triggers. Translate exactly the constraints from the current Drift table files: NOT NULL, UNIQUE, CHECK, FK with ON DELETE CASCADE where it was declared, default values. Status/type/role/state columns are TEXT with `CHECK (col IN ('a','b',...))` using enum `.name` values. Booleans are INTEGER 0/1 with CHECK. Dates are INTEGER millisecond epoch, UTC for `*_utc`. Reference `enums.dart` values by name; do not hardcode a different spelling.
  - Triggers: keep the two guard triggers (`occurrences_guard_insert`, `occurrences_guard_update`) with the exact behavior the current `app_database.dart` documents (profile match with medicines.profile_id; medicine_id match with schedules.medicine_id). Read the current Drift file to copy the logic; do not invent new rules.
- `lib/core/database/tables/**`: delete.
- `lib/core/platform/medify_paths.dart` (new): MethodChannel `medify/paths`, methods `documentsDirectory` and `temporaryDirectory`, both return String. Errors → rethrow as `StateError`.
- `lib/core/database/objectbox_service.dart`: replace `getApplicationDocumentsDirectory()` with `MedifyPaths.documentsDirectory()`. Remove path_provider import.
- `lib/features/history/presentation/cubit/history_cubit.dart`: replace `getTemporaryDirectory()` with `MedifyPaths.temporaryDirectory()`. Remove path_provider import. Change nothing else.
- `ios/Runner/AppDelegate.swift`: extend the existing `medify/paths` channel (added in previous round, if present; if not present, add it) with `temporaryDirectory` → `NSTemporaryDirectory()` (trim trailing slash). Keep speech channel unchanged. Use registrar name `"MedifyPaths"`.
- `android/app/src/main/kotlin/com/sumit/medify/MainActivity.kt`: `temporaryDirectory` → `applicationContext.cacheDir.absolutePath`. Keep existing `documentsDirectory` and speech channel.
- `test/database/**`: delete the Drift tests. Add `test/database/medify_database_test.dart`: use `sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;` and `inMemoryDatabasePath`. Tests (same as before):
  - FK on: insert medicine with missing profile → throws.
  - CHECK: occurrence `status='taken'` with null `taken_at_utc` → throws.
  - UNIQUE: duplicate (schedule_id, scheduled_at_utc) → throws.
  - Enum round trip: insert `MedicineType.syrup.name`, read back equal; raw value is text `syrup`.
  - Cascade: delete medicine removes its schedules.
  - Guard: occurrence profile ≠ medicine profile → throws (insert and update).
  - Guard: occurrence medicine ≠ schedule medicine → throws.
- `test/core/platform/medify_paths_test.dart` (new): mock channel for both methods.

Do NOT touch: `ios/Podfile*`, `ios/Pods/`, `ios/Flutter/*.xcconfig`, `ios/Runner.xcodeproj/**`, `ios/Runner.xcworkspace/**`, `ios/.gitignore`, `android/app/build.gradle.kts`, `lib/core/voice/**`, `lib/features/**` except history_cubit.dart named above, `docs/**`. Do not commit.

## Steps

1. Baseline: `git status --short`, record. Record current `lib/core/database` and `test/database` listing.
2. `grep -rn "drift\|path_provider\|build_runner" pubspec.yaml lib test` — record every hit.
3. `flutter pub remove drift drift_flutter drift_dev path_provider`. Then `flutter pub add sqflite` and `flutter pub add dev:sqflite_common_ffi`. Confirm `grep -n "drift\|path_provider" pubspec.yaml` prints nothing.
4. Delete drift files (listed above). Write schema.dart, medify_database.dart, medify_paths.dart.
5. Update objectbox_service.dart and history_cubit.dart.
6. Native: AppDelegate.swift and MainActivity.kt as above.
7. Tests: delete old, add new.
8. Verify, stop on first failure:
   - `dart format --set-exit-if-changed lib/core/database lib/core/platform test/database test/core/platform lib/features/history/presentation/cubit/history_cubit.dart`
   - `flutter analyze lib test`
   - `flutter test test/database test/core/platform test/core/voice`
   - `flutter build ios --no-codesign --debug` — record pass/fail and whether the log has "Running pod install" (expected: still present, because pods removal is round 5).
   - `flutter build apk --debug` must pass.
   - `grep -rn "path_provider\|drift" lib test pubspec.yaml` must print nothing.
9. Report under 20 lines: files deleted/created/edited, pub result, pub add versions and their publish dates, grep result, test results, pod-install line, APK result.

## Stop and report if

- A Drift constraint has no straightforward SQL equivalent (report it, do not guess).
- `history_cubit.dart` needs a change beyond the temp dir call.
- Any verification step fails.
