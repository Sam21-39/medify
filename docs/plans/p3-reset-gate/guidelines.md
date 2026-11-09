# Guidelines: P3 reset gate (ADR 0001)

Audience: `model-implementer`. Source of truth: `docs/adr/0001-reset-legacy-objectbox-storage.md` (sections 1–6). Follow it. Where this file and the ADR disagree, the ADR wins; report the disagreement.

Scope: build the gate and journal as standalone, tested code. Do NOT wire it into `lib/main.dart` or `lib/core/di/**` yet (wiring is the switch-over slice, P9). The gate must be runnable as a separate entry point for manual testing only if needed; prefer pure Dart units plus widget tests.

## Read first

- `docs/adr/0001-reset-legacy-objectbox-storage.md`
- `lib/core/platform/medify_paths.dart` (documents dir channel; see Android note below)
- `lib/core/notifications/notification_service.dart` (cancelAll access)
- `lib/core/preferences/preferences_service.dart` (legacy prefs keys listed in ADR)
- `lib/core/theme/` (for the gate screen theme)

## Android note (verify, do not assume)

Legacy ObjectBox store was opened under `getApplicationDocumentsDirectory()` (path_provider). On Android that may not be `filesDir`. Do not guess. The gate must probe every candidate path that exists: `<filesDir>/medify-db` and `<filesDir>/app_flutter/medify-db`. Report which candidates your probe found. Deletion covers only paths that exist and are named `medify-db`. Add a native method `legacyDocumentsDirectory` to the `medify/paths` channel only if the probe needs it; report why.

## Allowed write paths

- `lib/core/transition/**` (new): journal, stages, state machine, legacy cleanup.
- `lib/features/transition/presentation/**` (new): gate screen and its cubit.
- `lib/core/platform/medify_prefs_channel.dart` (new): Dart wrapper for channel `medify/prefs` method `clearLegacyPrefs`.
- `ios/Runner/AppDelegate.swift`: add channel `medify/prefs` (registrar name `"MedifyPrefs"`), method `clearLegacyPrefs`: remove UserDefaults keys with prefix `flutter.`. Keep other channels unchanged.
- `android/app/src/main/kotlin/com/sumit/medify/MainActivity.kt`: same channel, method clears `FlutterSharedPreferences` (`getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE).edit().clear().commit()`). Keep other channels unchanged.
- `test/core/transition/**` (new), `test/features/transition/**` (new).

Do NOT touch: `lib/main.dart`, `lib/core/di/**`, `lib/core/database/**`, `lib/features/**` except `transition/`, `pubspec.yaml` unless a package is strictly needed (report first), `ios/Podfile*` (already removed), `ios/Runner.xcodeproj/**`, `android/app/build.gradle.kts`, `docs/**` (except report). Do not commit.

## Journal (ADR section 4)

- File: `<appSupport>/v2_transition.json` (path_provider is removed; use a channel method or `MedifyPaths` extension for application-support dir; if none exists, add `applicationSupportDirectory` to `medify/paths` on both platforms and report).
- Content: `{"stage": "...", "updatedAt": "<ISO UTC>"}`.
- Write: temp file, flush, rename over the journal. Atomic.
- Stages in order: `started`, `reminders_cancelled`, `prefs_cleared`, `legacy_deleted`, `v2_created`, `complete`.
- Each stage idempotent. Resume from recorded stage.
- Malformed journal → recovery mode: gate shows recovery message, deletes NOTHING.
- Existing valid v2 database is never deleted, even if journal is missing or says otherwise. Check v2 DB presence first.
- Once `complete`, reset never runs again. Leftover legacy files after `complete` are removed silently, best effort, errors ignored.
- Fresh install (no legacy store, no journal) → write journal `complete`, no deletion.

## Stage actions (ADR section 5)

- `reminders_cancelled`: call `FlutterLocalNotificationsPlugin.cancelAll()` through the existing `NotificationService` only if it can be used without full DI init; otherwise add a thin wrapper that takes the plugin instance. Report which.
- `prefs_cleared`: `medify/prefs` `clearLegacyPrefs`.
- `legacy_deleted`: delete each existing candidate `medify-db` directory. Nothing else.
- `v2_created`: create v2 database file via `MedifyDatabase.open()` (sqflite path from `getDatabasesPath()`), then close it. Schema must be created. Verify tables exist.
- `complete`: write journal.

## Gate UI (ADR section 1–2)

- Minimal app: `MaterialApp` with the app theme from `lib/core/theme/`. No BLoC, no DI, no notifications.
- Screen explains the reset in plain words. Warning text: "All medicines, schedules, history, and settings on this device will be deleted. Medify will restart with a new, empty database." Include that the deletion is permanent.
- Actions: "Reset and continue" (requires a checkbox "I understand this cannot be undone"), "Not now" (changes nothing, returns to state "reconsider later"), "Exit" (SystemNavigator.pop on Android; on iOS, hide Exit and show only Not now).
- Accessibility: buttons at least 48 px tall, semantic labels, text scaling respected.
- Progress indicator during stages. Errors shown with plain message and a Retry button that resumes from journal stage.

## Tests

- Journal: atomic write (temp then rename); malformed JSON → recovery, no deletion; idempotent stage re-run; resume from each stage (simulate kill by stopping after each stage write).
- Existing v2 DB present + journal missing → no deletion.
- Journal `complete` → no action, legacy leftovers removed.
- Fresh install → journal `complete`, no deletion.
- Gate widget: "Not now" changes no file; "Reset and continue" disabled until checkbox ticked.
- Use temp dirs and a fake channel for `medify/prefs` and `medify/paths` (`TestDefaultBinaryMessengerBinding`).

## Verification, stop on first failure

- `dart format --set-exit-if-changed lib/core/transition lib/features/transition lib/core/platform test/core/transition test/features/transition`
- `flutter analyze lib test`
- `flutter test test/core/transition test/features/transition`
- `flutter build apk --debug` (must pass)
- `flutter build ios --no-codesign --debug` (must pass; no "pod install" in log)
- `git diff --stat -- lib/main.dart lib/core/di lib/core/database` must be empty.

## Report (under 25 lines)

Files, probe result for Android legacy paths, channel methods added, test results, build results, any deviation from the ADR.

## Stop and report if

- ADR and this file conflict beyond the Android note.
- A stage needs DI or main.dart changes.
- Any build fails.
