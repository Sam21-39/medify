# Medify 2.0.0 Full Release Plan

## Summary

- Ship the complete proposal as one `2.0.0` release for Android and iOS 15+.
- Permanently remove legacy ObjectBox data only after explicit confirmation.
- Replace ObjectBox with Drift. Keep existing domain, repository, Cubit, notification, navigation, and design patterns where suitable.
- Keep ordinary preferences in Drift. Use `flutter_secure_storage` only for secrets such as backup-key material.
- Build first, then validate completed release candidates with users. No pre-build research gate.
- Record the storage-reset decision in an ADR. Produce the retained-template system-design document after plan approval.

## Product and UX

- Show a blocking reset gate before database, reminder, onboarding, or background-handler initialization.
- “Not now” leaves legacy files and reminders unchanged. User can reconsider or exit; no empty v2 app access.
- Confirmed reset uses the approved warning, requires explicit action, cancels reminders, deletes only known app-owned legacy data, then enters onboarding.
- Deliver Home, Medicines/detail, Family, Settings, onboarding, patient switcher, manual/voice/camera capture, editable recognition review, reports, backup/restore, achievements, and deletion.
- Retain Medify teal identity, logo, Nunito, existing Flutter semantic tokens, and shared controls. Do not introduce web UI libraries.
- Support light/dark/system themes, 48-pixel targets, text scaling, increased contrast, reduced motion, screen-reader semantics, and non-color status indicators.
- Voice and OCR remain on-device. Latin-script OCR only. Unsupported recognition falls back to manual entry.
- Test completed flows with 5–8 representative patients/caregivers during release-candidate validation. Do not describe those findings until research occurs.

## Architecture and Interfaces

- Startup becomes: legacy/v2 detection → transition recovery or reset gate → Drift open and verification → preferences load → notifications/background handlers → repositories and Cubits → UI.
- Introduce one Drift database as source of truth for profiles, medicines, schedules, occurrences, achievements, settings, and installation metadata.
- Store the reset journal in a small app-support file outside both databases. Use explicit stages, atomic replacement, and idempotent recovery.
- Store only secret key material in platform secure storage. Secure-storage failure must block secret-dependent operations, never imply fresh installation or authorize deletion.
- Preserve repository interfaces where their semantics still fit. Extend them with mandatory patient-scoped queries and transactional dose actions.
- Route Taken, Skipped, Missed, snooze, pause, stop, schedule edits, stock changes, and Undo through repository transactions.
- Use stable string-backed statuses and achievement types. Never persist Dart enum indexes.
- Notification payloads contain installation ID and occurrence ID. Reject missing, malformed, legacy, or mismatched payloads.
- Use device-local schedule rules for future occurrences and UTC instants plus local-date snapshots for history.
- Use Flutter’s SPM integration exclusively. Remove CocoaPods only after every plugin passes a clean iOS build. Flutter may otherwise fall back to CocoaPods, so fallback detection is a release failure ([Flutter SPM guidance](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers)).
- Raise iOS deployment target to 15 for SPM-compatible on-device OCR. Bundle and verify required Latin OCR resources ([ML Kit package requirements](https://pub.dev/packages/google_mlkit_text_recognition)).
- Replace any non-SPM TTS or speech dependency with narrow platform channels backed by Apple Speech/AVSpeechSynthesizer and Android SpeechRecognizer/TextToSpeech.

### Data model

- `profiles`: stable ID, name, birth date or entered age, relation, role, presentation fields, lifecycle state.
- `medicines`: patient ID, name, dose value/unit, notes, photo reference, stock, state, stop reason.
- `schedules`: medicine ID, local times, weekdays, end date, notification flag, missed window.
- `occurrences`: patient/medicine/schedule IDs, scheduled instant, local date, status, taken time, snooze time, reason, actor ID, dose snapshot.
- `achievements`: patient ID, stable type, progress, unlock time.
- `settings`: typed key/value records for theme, accessibility, onboarding, selected actor/patient, notifications, quiet hours, and snooze duration.
- `installation_metadata`: installation ID, schema lifecycle state, transition completion, creation time.
- Enforce foreign keys, status checks, patient ownership, and a unique schedule-occurrence key.

### Backup contract

- Export one versioned encrypted container containing manifest, database payload, settings, and referenced media.
- Derive an AES-256-GCM key from the user passphrase using PBKDF2-HMAC-SHA256 with a random salt and recorded work factor.
- Authenticate the complete payload and manifest. Never store the passphrase.
- Restore into a staging area, validate authentication, schema, references, and media, then atomically replace current data.
- Create a recovery copy before replacement. Wrong passwords, corruption, incompatibility, cancellation, or interruption leave current data untouched.
- Reports remain separate patient/date-scoped PDF and CSV exports.

## Delivery Sequence

1. Confirm store build history, choose the next valid build number, retain application IDs and signing, and add the ADR.
2. Run dependency and SPM compatibility spikes for Drift, secure storage, notifications, OCR, speech, TTS, camera, PDF, and encryption.
3. Add Drift schema, snapshots, typed settings, installation metadata, and transactional repositories.
4. Add pre-initialization transition detection, blocking consent UI, journal recovery, targeted legacy cleanup, and stale-callback rejection.
5. Implement patient-scoped occurrence generation, dose transactions, stock consistency, schedule mutation, lifecycle states, and reconciliation.
6. Integrate full navigation and redesigned screens using existing Flutter design primitives.
7. Add manual, speech, and OCR capture with editable review and patient binding.
8. Add encrypted backup/restore, PDF/CSV reports, household deletion, legal pages, and release copy.
9. Remove ObjectBox, generated bindings, `shared_preferences`, unused packages, Podfiles, locks, Pods, and stale build references only after callers and clean builds prove removal.
10. Run release-candidate research, accessibility checks, real-device validation, and store submission checks.

## Test Plan

- Fresh install, legacy detection, “Not now,” confirmed reset, and termination after every journal stage.
- Completed reset never repeats because of residual legacy files, malformed settings, secure-storage failure, or app update.
- No reset path can delete an existing valid v2 database.
- Foreign keys, patient isolation, duplicate occurrence prevention, concurrent Taken callbacks, stock decrement exactly once, and conflicting completed actions.
- Schedule edits preserve resolved history and replace only affected future occurrences.
- Midnight, weekdays, end dates, snooze, quiet hours, timezone changes, DST, startup, resume, and OS suspension.
- Foreground, background, and terminated notification actions reject stale installation IDs.
- Recognition denial, unsupported language/device, cancellation, uncertain fields, review edits, patient switching, and safe Undo.
- Backup round trip, wrong password, modified ciphertext, missing media, unsupported schema, low storage, cancellation, and interruption at every replacement stage.
- Typed `DELETE`, export-first option, notification cleanup, app-owned media cleanup, and preservation of external exports.
- Small/large phones, tablets, portrait/landscape, largest text, dark mode, increased contrast, reduced motion, VoiceOver, and TalkBack.
- FVM formatting, generation, analysis, unit/widget/integration tests, Android release build, and clean SPM-only iOS 15 build.

## Assumptions and Risks

- Legacy deletion is an approved product decision. No ObjectBox import or read-only viewer will be built.
- Full scope is release-blocking; OCR, voice, backup, reports, and redesign are not deferred.
- Remote accounts, authenticated household identities, extra languages, online medicine catalogues, and database-at-rest encryption remain deferred.
- Existing store build history must be checked before choosing `2.0.0+3`.
- Highest risk remains irreversible legacy deletion and plugin-level SPM compatibility. No production dependency audit or real-device test has been completed yet.
