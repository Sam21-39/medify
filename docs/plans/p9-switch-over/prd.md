# PRD: P9 switch-over to SQLite, remove ObjectBox, run on iOS simulator

## Goal

App runs on sqflite (v2 schema) end to end. ObjectBox and shared_preferences removed. Reset notice shown to existing users only. Verified by build and launch on the iOS simulator (iPhone 17 Pro Max, CBEC0565-8CEB-42F5-84E9-01466DF90CE5).

## Done before this slice

- P2: sqflite repos (medicine, dose log, settings, profile, care link, achievement). Not wired.
- P3: reset gate (simplified, ADR 0001 amendment). Built in parallel; wired here.
- P4: occurrence generator, notification payload. Not wired.
- P8a: field-level encryption (AES-GCM, key in flutter_secure_storage). Built in parallel; wired here.

## Scope

1. Wire sqflite repos into `lib/core/di/injection_container.dart`, replacing ObjectBox repos.
2. `PreferencesService` keeps its public API but is backed by `SettingsStore` with an in-memory cache loaded at init (sync getters preserved). Callers unchanged.
3. Services off ObjectBox: `ProfileService`, `CareLinkRepository`, `AchievementService`. Repos only; logic in these services stays where it is unless it touches ObjectBox.
4. `DailyLogService` / `log_generator` use `occurrence_sqflite_generator` (P4). Filter out stopped medicines (state != active).
5. Notifications: payload now `{installationId, occurrenceId}`; tap handlers reject Missing/Malformed/Mismatch (P4 `notification_payload.dart`). Installation ID stored in `installation_metadata`.
6. `lib/main.dart`: legacy detection → reset notice (P3 screen) if needed → DI init → app. New installs skip the notice.
7. Remove ObjectBox: `objectbox_service.dart` (except the legacy-directory probe constant needed by P3 reset), `objectbox.g.dart`, legacy `*_model.dart` files, legacy `*_impl.dart` repos, `objectbox`, `objectbox_flutter_libs`, `objectbox_generator` from pubspec. Keep `build_runner` only if another generator needs it (check `injectable_generator`, `flutter_gen_runner`).
8. Remove `shared_preferences` from pubspec once `PreferencesService` no longer imports it (P3 legacy-prefs clear uses the native channel, not the package).
9. Remove stale generated files and references. `flutter pub get` clean. `flutter analyze` no errors.
10. Build and launch on iOS simulator. Screenshot the first screen.

## Out of scope

- P5 full Family UI and profile switcher (wiring only; UI as-is).
- P6 UI redesign.
- P7 capture, OCR (deferred).
- P8b backup/restore and reports.

## Acceptance

1. `flutter analyze` — zero errors.
2. `flutter test` — all tests pass.
3. `grep -rn "objectbox\|ObjectBox\|shared_preferences" lib test pubspec.yaml` — no hits, except the legacy-directory name constant in the reset code.
4. `flutter build ios --no-codesign --debug` passes; log has no "pod install".
5. `flutter build apk --debug` passes.
6. Simulator: app launches fresh (no legacy store) to onboarding/home without the reset notice; a seeded legacy store (created by a test fixture, not by the old app) shows the notice; "Continue" removes it and lands on the new home.
7. Add a medicine, mark a dose taken, reload: state persists in SQLite; the stored name in `medicines` is `v1.` prefixed (encryption on).

## Risks

- Sync `PreferencesService` getters need the cache loaded before first use; init order matters in `main.dart`.
- Services that read ObjectBox directly (ProfileService, AchievementService) have logic mixed with DB access; keep the logic, swap only the storage call.
- Notification payload change: old scheduled notifications cancelled during reset (P3). New ones use new payload.
