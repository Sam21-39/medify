# Review fixes batch

Source: three read-only reviews (data/security, DI/services/notifications/native, presentation). Fix only the items below. Owner decisions already taken:
- Medicine delete = archive (state `finished`), not hard delete. Hard purge is a later feature.
- Encryption format change (AAD) is accepted now, pre-release.
- Android legacy path: add `legacyDocumentsDirectory` to `medify/paths`.

Three implementers run in parallel. File sets are disjoint. Do not touch files outside your set. Do not commit. Run your verification list; stop at first failure. Report under 15 lines each.

## Set T1: data and security (implementer 1)

Files: `lib/features/medicines/data/sqflite/**`, `lib/features/schedule/data/sqflite/medicine_log_sqflite_repository.dart`, `lib/features/profiles/data/sqflite/**`, `lib/core/security/field_cipher.dart`, matching tests under `test/features/**/data/sqflite/**`, `test/core/security/**`.

1. (major) `updateMedicine`: do not overwrite `current_quantity` from the entity. Stock changes only through dose transitions. Keep stored `state` = `finished` unless the caller explicitly reactivates. Test: stock decremented by taken, then stale-entity update, stock unchanged.
2. (major) `_syncSchedules`: in the same transaction, for schedules being deactivated, delete occurrences with `status='scheduled' AND scheduled_at_utc > now`. Test: 08:00 schedule with pending future rows, change to 09:00, only 09:00 rows remain pending after regeneration.
3. (major) `updateLog` in `medicine_log_sqflite_repository.dart`: throw `InvalidTransitionException` when `current` is null (no `!`). Reject any change away from `taken`. Force `taken_at_utc` null for non-taken targets. Add tests: taken → revert throws; missing id throws typed exception.
4. (minor) colours `0xEF4444`, `0x3B82F6`, `0x8B5CF6` → `0xFF…` (alpha). Test or assert alpha.
5. (minor) `toggleMedicineStatus`: return `Left` when stored state is `finished`.
6. (minor) profiles: `deleteProfile` clears `active_profile_id` if it points at the archived profile; `setActiveProfile` rejects archived profiles.
7. (minor) `deleteMedicine`: archive (`state='finished'`, `is_active` semantics per mapper) instead of hard delete. Occurrences kept. Test: history survives delete.
8. (minor) `FieldCipher`: bind AAD. Pass `aad: utf8.encode('<table>.<column>.<row id>')` on seal and open. Callers pass the context. Update tests (wrong context → CorruptField).

Verification: `dart format --set-exit-if-changed lib/features/medicines/data/sqflite lib/features/schedule/data/sqflite lib/features/profiles/data/sqflite lib/core/security test/features test/core/security`; `flutter analyze lib test` (no new issues); `flutter test test/features test/core/security test/database`.

## Set T2: DI, notifications, reset, native (implementer 2)

Files: `lib/main.dart`, `lib/core/di/injection_container.dart`, `lib/core/notifications/notification_service.dart`, `lib/core/transition/legacy_reset.dart`, `lib/features/transition/presentation/reset_gate_cubit.dart` (only cubit logic, not screen layout), `lib/core/preferences/preferences_service.dart`, `lib/core/platform/medify_paths.dart`, `ios/Runner/AppDelegate.swift`, `android/app/src/main/kotlin/com/sumit/medify/MainActivity.kt`, tests under `test/core/**` and `test/features/transition/**`.

1. (major, Android upgrade) Add `legacyDocumentsDirectory` to channel `medify/paths` on both platforms. Android: `context.getDir("flutter", MODE_PRIVATE).absolutePath` (path_provider documents dir = `<dataDir>/app_flutter`). iOS: same as `documentsDirectory`. Legacy detection and deletion use `legacyDocumentsDirectory`. Keep the candidate list; include both. Update Dart wrapper and tests.
2. (major) `rescheduleUpcoming`: do not `cancelAll()`. Cancel only ids this app owns for occurrences being rescheduled (`occurrenceId*4 + {0,1,2}`) and pending requests whose payload decodes as Valid. Never cancel shown notifications. Snooze ids survive resume.
3. (major, Android) Snooze/Skip actions: set `showsUserInterface: true` so taps route through the foreground callback. Do not open DB in the background isolate.
4. (major) `main()` / `_launchApp`: wrap in try/catch; on failure `runApp` a minimal error screen with Retry (plain text, 48 px button). `onComplete` becomes `Future<void> Function()` and is awaited in `reset_gate_cubit` so `ResetGateFailed` is reachable. On retry, `getIt.reset()` before re-running DI init, or register `Database` only after the key check succeeds.
5. (minor) `showImmediateNotification` ids: move to a disjoint range (`0x40000000 + (n % 0x0FFFFFFF)`).
6. (minor) serialize `rescheduleUpcoming` and `_installationIdFor` with one in-flight `Future` each.
7. (minor) `markAsSkipped` result: check `Either`; log the `Left`.
8. (minor, parity) Android `temperature`/speech: missing `text` → `result.error("BAD_ARGS", ...)`. Shut down TTS in `onDestroy`.
9. (minor) `PreferencesService` setters: await the store write first, then update `_cache`; return the store result, not `true`.

Verification: `dart format --set-exit-if-changed lib/main.dart lib/core/di lib/core/notifications lib/core/transition lib/core/platform lib/core/preferences lib/features/transition test/core test/features/transition`; `flutter analyze lib test`; `flutter test test/core test/features/transition test/features/schedule`; `flutter build ios --no-codesign --debug` (no "pod install"); `flutter build apk --debug`.

## Set T3: presentation (implementer 3)

Files: `lib/features/medicines/presentation/cubit/medicine_cubit.dart`, `lib/features/profiles/presentation/pages/role_page.dart`, `lib/app/app_router.dart` (snackbar strings only), `lib/l10n/app_en.arb` (add keys for moved strings; regenerate l10n per project convention).

1. (major) `updateMedicine`: regenerate occurrences after every successful update (not only when times changed). Before regenerating, delete only `pending` future occurrences for this medicine (use `getLogsByMedicineId` + filter status == pending + `deleteLog`). Never delete taken or skipped rows.
2. (major) `role_page.dart`: `_choose` sets `_busy` for the whole method and disables cards while busy. Wrap `_pickPatient` and `setRoleChosen` in try/catch; on error show `AppMessenger` error snackbar and still navigate. Duplicate care link (`InvalidProfileException`) is treated as success.
3. (minor) `toggleMedicineStatus`: when resumed (`isActive`), call the occurrence generation.
4. (minor) `deleteMedicine`: cancel notifications only after a successful delete (Right).
5. (minor) `role_page.dart`: when no other patient profile exists for Caregiver, show a message: "Add a patient profile first" (localised), do not silently navigate.
6. (minor) hard-coded strings in role_page and app_router snackbar → `app_en.arb` keys; use `AppLocalizations`. Reset gate strings stay plain (outside MyApp).

Verification: `dart format --set-exit-if-changed lib/features/medicines/presentation lib/features/profiles/presentation lib/app`; `flutter gen-l10n` (or project's l10n command; report which); `flutter analyze lib test`; `flutter test test/features/medicines test/features/profiles`.

## Not in this batch

- Reset-gate layout and accessibility: reviewer found none.
- Cold-start notification tap: unverified; separate check at simulator run.
