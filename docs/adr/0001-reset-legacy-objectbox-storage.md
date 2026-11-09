# ADR 0001: Reset legacy ObjectBox storage in 2.0.0

- Status: Accepted
- Date: 2026-11-10

## Context

Medify 1.x (latest 1.1.0+2) keeps its data in two places:

- An ObjectBox store at `<applicationDocuments>/medify-db`.
- `shared_preferences` (keys: `first_launch`, `first_launch_date`, `theme_mode`, `notifications_enabled`, `snooze_duration`, `last_log_generation_date`, `role_chosen`, `speak_reminder`, `acting_patient_id`, `active_profile_id`).

The legacy model has problems that are hard to fix in place:

- Enums are persisted as indexes. Reordering or inserting a value silently changes the meaning of old rows.
- There are no foreign keys, CHECK constraints, or unique keys. Duplicate logs and orphaned rows are possible.
- Dose actions are not transactional, so two concurrent "Taken" callbacks can decrement stock twice.
- Reminders repeat daily and ignore weekdays and end dates. Legacy notification IDs (`medicineId*100+i`, `+50000`, `medicineId*100+999`) and payloads (`{"medicineId","scheduledSeconds"}`) do not map onto an occurrence model.
- There is almost no test coverage of the storage layer.

Medify 2.0.0 moves to Drift (SQLite) because it gives us:

- SQL constraints (`CHECK`, `UNIQUE`, `NOT NULL`) and `PRAGMA foreign_keys = ON`.
- Real transactions and conditional updates.
- Enums stored by name (`textEnum`), not by index.
- Schema snapshots (`drift_dev schema dump`) and generated migration tests.
- No native plugin pods. sqlite3 arrives through build hooks, which helps the iOS goal of Swift Package Manager only (no CocoaPods). ObjectBox ships native libraries through a CocoaPods plugin, so it blocks that goal.

## Amendment (2026-11-10, owner)

Simplified. The staged journal (section 3–4 below) is dropped. Deletion is idempotent, so it needs no stage machine.

- New install: no reset screen, no legacy code path shown.
- Existing user (legacy ObjectBox store present, v2 DB absent): one notice screen saying Medify 2.0 changed the database and data resets. "Continue" resets; "Not now" changes nothing and the notice returns on next launch.
- Reset: cancel reminders, clear legacy prefs, delete legacy `medify-db` directories, create v2 sqflite DB. Each step idempotent. Errors show Retry.
- ObjectBox is removed from the codebase after the switch-over (P9). Only the detection and delete remain.

## Decision

2.0.0 permanently deletes legacy ObjectBox data, legacy preferences, and legacy scheduled notifications. It does so only after the user explicitly confirms on a blocking gate.

1. **The gate comes first.** The gate is shown before any database, notification, background, or dependency-injection initialisation. It runs as a minimal themed app with none of those services.
2. **"Not now" changes nothing.** No data, preference, or notification is touched. The gate offers "Reconsider" and an exit option.
3. **Confirm runs a staged reset** recorded in a journal at `<appSupport>/v2_transition.json`. Stages, in order:
   `started` -> `reminders_cancelled` -> `prefs_cleared` -> `legacy_deleted` -> `v2_created` -> `complete`.
4. **Journal rules.**
   - Every write goes to a temp file, is flushed, then renamed over the journal (atomic).
   - Every stage is idempotent, and an interrupted reset resumes from the recorded stage.
   - A malformed journal puts the gate in recovery mode. Nothing is deleted in that mode.
   - An existing v2 database is never deleted, even if the journal is missing or says otherwise.
   - A completed reset never repeats. Leftover legacy files after `complete` are cleaned up silently, best effort.
5. **What each stage removes.**
   - `reminders_cancelled`: `FlutterLocalNotificationsPlugin.cancelAll()`.
   - `prefs_cleared`: native channel call. Android clears `FlutterSharedPreferences`. iOS removes `UserDefaults` keys prefixed `flutter.`.
   - `legacy_deleted`: deletes the `medify-db` directory only.
6. **Fresh installs** create the v2 database and write the journal as `complete`.

### Related decisions recorded here

- **`flutter_secure_storage` reinstated (amended 2026-11-10).** The release plan requires platform secure storage for backup-key material. Owner decision: release plan wins over this ADR's original "no secure storage" line. Store only secret key material there. Secure-storage failure blocks secret-dependent operations and never authorises deletion. Passphrase itself is still never stored. Package added with the backup slice, not earlier.
- **Speech and TTS use custom platform channels** (`medify/speech`): Apple Speech and `AVSpeechSynthesizer` on iOS, `SpeechRecognizer` and `TextToSpeech` on Android. `flutter_tts` is removed; it is the last CocoaPods plugin.
- **Family is a local household.** All profiles live on one device. There are no accounts, logins, network calls, or invites. "Invite / pending / revoke" becomes add / archive local profile.

## OCR on iOS: pending spike

Camera capture uses `image_picker`. For text recognition:

- If `google_mlkit_text_recognition` requires CocoaPods on iOS, use Apple Vision `VNRecognizeTextRequest` through a native channel on iOS, and the ML Kit text-recognition Gradle library (in Kotlin, via the same channel) on Android.
- If it builds clean with SPM only on iOS 15, use the plugin on both platforms.

Outcome: **TBD.** The Phase 2 spike decides this, and this section is updated with the result.

## Consequences

- **Irreversible data loss for users who confirm.** Medicines, schedules, history, achievements, and settings from 1.x are gone and cannot be recovered by the app.
- Users who tap "Not now" cannot use 2.0.0 until they confirm. They can keep 1.x installed or confirm later.
- Mitigations:
  - The gate states plainly what will be deleted and that it cannot be undone.
  - Nothing is deleted before explicit confirmation, and "Not now" is always available.
  - The journal makes interruptions (crash, kill, battery) safe to resume.
  - The never-delete-v2 rule protects new data from a confused journal.
  - Release notes tell users to write down their medicines before updating.
- We take on a one-off test burden: kill-after-each-stage tests, malformed journal, residual legacy directory, and a legacy-fixture integration test.
- The startup sequence changes: `Startup.run()` executes before `initializeDependencies()`.

## Alternatives rejected

- **ObjectBox -> Drift import.** Persisted enum indexes, daily-repeating reminders with no weekday or end-date data, and ambiguous profile and care-link rows make a faithful mapping unreliable. A wrong import of medication data is worse than a clean start. It would also keep ObjectBox (and its pods) in the dependency graph for a one-time use.
- **Read-only legacy viewer.** It would keep ObjectBox and its native libraries in the app, which defeats the SPM-only goal, and it adds a second data path to test and keep accessible.
- **Keep ObjectBox.** It leaves us without SQL constraints, schema migration tests, and transactional dose actions, and it keeps CocoaPods on iOS.
