# Feature roadmap: next implementation batch

Status: DRAFT, awaiting user approval. No code until approved.
Routing: Opus plans (this doc). Haiku implements (`model-implementer`), one phase per agent run. Sonnet reviews (`model-reviewer`) after each phase. Note: session currently set to Haiku by user; planning here is Opus-role work and should run on Opus.

Scope (user-selected): A. finish voice/FAB work, B. profiles (family/caregiver), C. localization (hi, bn), D. refill and reminder improvements.

Order: A → C (string moves touch every page; do before new UI) → B → D. Each phase ships behind its own commit and passes `flutter analyze` (0 issues) and `flutter test`.

---

## Phase A: finish voice and FAB

### PRD
**Problem.** Voice flow has a 3s UI timeout that resets to idle but does not cancel native STT. A late final result still opens the review form. Device checks for FAB and voice have not run.

**Outcome.** Voice session ends cleanly in every path. FAB verified on iOS 26, iOS <26, Android.

**Scope**
- Send native `cancel` on the timeout path, and ignore late finals after cancel.
- Lint for `@RequiresApi` in `MainActivity.kt` (`beginStt`).
- Device pass checklist (below) and fixes found.

**Non-goals.** No new voice features. No cloud STT.

**Acceptance**
- A-1 Stop with no final within 3s → native cancel sent, page idle, no review form opened afterwards.
- A-2 Late final after cancel → discarded, no draft.
- A-3 `flutter analyze` 0 issues; Android lint `NewApi` clean for `beginStt`.
- A-4 Device checklist complete (see below), results recorded in `docs/plans/feature-roadmap-next/device-checklist.md`.

**Device checklist**
- FAB position: iOS 26 native bar, iOS <26, Android. Not covering last list item.
- Menu open/close, back button, tab change, tap-through blocked while open.
- Voice: happy path, mic denied, no offline model (iOS), Android <13 (unavailable message).
- Text styling on iOS pages after Material wrapper (`my_app.dart`).

**Risks.** iOS 26 native bar may swallow FAB taps (R2 from ux-overhaul). If so, move FAB into bar region or hide during menu.

### Guidelines
Files:
- `lib/features/medicines/presentation/pages/voice_capture_page.dart`: timer → `cancelQuietly()` + set status idle + ignore events with generation id.
- `lib/core/voice/native_stt_channel.dart`: add generation/session id on `start`, drop events with stale id.
- `ios/Runner/AppDelegate.swift`, `android/app/src/main/kotlin/com/sumit/medify/MainActivity.kt`: confirm `cancel` tears down; no code change expected beyond verification.
- `android/app/src/main/kotlin/.../MainActivity.kt`: `@RequiresApi(Build.VERSION_CODES.TIRAMISU)` already on `beginStt`; verify with `flutter build apk --debug` and lint.

Verify: `dart format lib test`; `flutter analyze`; `flutter test`; `flutter build ios --no-codesign --debug`; `flutter build apk --debug`.

---

## Phase C: localization (hi, bn)

Do before profiles so new strings land in ARB once.

### PRD
**Problem.** Only English ARB live (`app_en.arb`, 159 keys). `app_hi.arb.bak` and `app_bn.arb.bak` are stale. Hardcoded English in pages (e.g. `medicine_list_page.dart`: "Medify", "Refresh", "Settings"; `history_page.dart` labels). Enum labels in `medicine.dart` (MedicineType, MedicineIntakeTiming) are hardcoded English. iOS `Info.plist` usage strings are English only.

**Outcome.** Hindi and Bengali selectable. All user-facing strings from ARB. Locale persisted in preferences.

**Scope**
- Restore `app_hi.arb` and `app_bn.arb` from `.bak`, reconcile keys against `app_en.arb`, add missing keys.
- Move hardcoded page strings to ARB.
- Enum labels → l10n lookup (keep `label` out of domain).
- `supportedLocales` in `my_app.dart` from `['en','hi','bn']`.
- Locale picker in settings.
- `InfoPlist.strings` for `en`, `hi`, `bn` (camera/mic/speech usage text).
- Date formats via `DateFormat(..., locale)`.

**Non-goals.** No RTL. No translation service. Translations drafted by Opus, reviewed by native speakers before release (flag in PR).

**Acceptance**
- C-1 `grep` for hardcoded user-facing English literals in `lib/features/**/presentation` returns only allowed exceptions (listed in guidelines).
- C-2 Switching locale updates all screens without restart; persists across launch.
- C-3 Every key in `app_en.arb` exists in `app_hi.arb` and `app_bn.arb` (test script or `flutter gen-l10n` warnings clean).
- C-4 `flutter analyze` 0 issues; `flutter test` passes including a locale smoke test.

**Risks.** Bengali/Hindi plural and placeholder rules. Font coverage on iOS and Android for Devanagari/Bengali (Nunito lacks them: needs Noto Sans Devanagari/Bengali, add as asset or use system fallback — decision needed, see open questions).

### Guidelines
1. Restore: `git mv lib/l10n/app_hi.arb.bak lib/l10n/app_hi.arb`, same for bn. Reconcile keys with script or manual diff.
2. `l10n.yaml`: confirm `arb-dir: lib/l10n`, `output-localization-file: app_localizations.dart`.
3. Settings: `lib/features/settings/presentation/cubit/settings_cubit.dart` add `locale` state; persist in `preferences_service.dart` (`_keyLocale`, follow existing `snooze_duration` pattern).
4. `my_app.dart`: `supportedLocales` and `locale` from settings cubit.
5. Enums: `lib/features/medicines/domain/entities/medicine.dart` — remove `label` constructor args usage from presentation; add `lib/features/medicines/presentation/l10n/medicine_labels.dart` with `String localizedLabel(AppLocalizations l10n)` extensions.
6. Fonts: decide (open question Q2). Add to `pubspec.yaml` fonts only after decision.
7. `ios/Runner/<lang>.lproj/InfoPlist.strings` for hi, bn; add `CFBundleLocalizations`.
8. Pages to sweep: `medicine_list_page.dart`, `history_page.dart`, `settings_page.dart`, `schedule_page.dart`, `add_edit_profile_page.dart`, `voice_capture_page.dart`, `add_medicine_fab.dart`.

Verify: `flutter gen-l10n`; `dart format`; `flutter analyze`; `flutter test`; grep check C-1.

---

## Phase B: profiles (family and caregiver)

### PRD
**Problem.** Profiles feature is built but hidden (commented out in `app_router`/`my_app.dart`; `ProfileService` still runs). Schema already supports it: `profiles`, `care_links` (patient ↔ caregiver, unique, no self-link), and `medicines.profile_id`. Without a clear rule, caregivers cannot manage a patient's medicines safely.

**Outcome.** Users can add family profiles, switch active profile, and a caregiver can manage linked patient medicines and see their dose status. Patient data stays scoped per profile.

**Scope**
- Profiles page reachable from settings (not a tab, to keep 4 tabs).
- Create/edit/archive profiles (existing `add_edit_profile_page.dart`).
- Active profile switcher (existing `profile_switcher.dart`) on Today and Medicines.
- Medicines, schedules, logs filtered by active profile.
- Caregiver role: link to patient profile(s) via `care_links`; caregiver can view and edit linked patient's medicines; cannot delete patient history.
- Role page on first use of profile (existing `role_page.dart`).

**Non-goals.** No cloud sync between devices. No invites or accounts. No caregiver notifications for missed doses in this batch (note as next).

**Acceptance**
- B-1 Adding profile creates row; name unique (existing `isProfileNameExists`).
- B-2 Switching active profile changes Today and Medicines lists; no data bleed (test with two profiles).
- B-3 Caregiver link: link created via `care_links`; unlink removes; self-link rejected (DB CHECK + UI).
- B-4 Caregiver edit of patient medicine writes `profile_id` = patient; log `actor_profile_id` = caregiver (existing schema).
- B-5 Archive profile hides it and keeps data; default profile cannot be deleted.
- B-6 Existing single-user installs: migration assigns all data to default profile; no data loss (test with fixture DB).
- B-7 Feature visible only behind a flag in `preferences_service.dart` until B-1..B-6 pass, then enabled.

**Open decisions (must answer before implementation)**
- Q1: Can a caregiver delete a patient's medicine? Proposal: no, archive only.
- Q3: Is a profile's data protected by a PIN? Proposal: defer.

### Guidelines
1. Re-enable: `lib/app/my_app.dart:91` uncomment `ProfileCubit` provider; `lib/app/app_router.dart` add `/profiles` route (not shell branch); `lib/features/settings/presentation/pages/settings_page.dart` add "Profiles" tile (replace commented block ~line 663).
2. Active profile: `ProfileService` is source of truth. Filter in `medicine_sqflite_repository.dart` queries by `profile_id = ?` using `getActiveProfile()`. Do not filter in widgets.
3. Schedule and logs: `medicine_log_sqflite_repository.dart` already stores `actor_profile_id`. Add profile filter on `getLogsByDate`.
4. Caregiver: new `lib/features/profiles/domain/services/care_access.dart` (pure): `canEdit(actor, patient)`, `canDelete`. Use in `medicine_cubit.dart` before writes.
5. Migration: check `lib/core/transition/legacy_reset.dart` and `injection_container.dart` profile bootstrap (`loadOrCreate(databaseHasData:)`). Add fixture test `test/profiles/migration_test.dart`.
6. UI: profile switcher only shows when >1 active profile.
7. Flag: `PreferencesService.profilesEnabled` default false until B-7.

Verify: `flutter analyze`; `flutter test` (include two-profile isolation test, migration test, care_access unit test); manual two-profile run.

---

## Phase D: refill and reminder improvements

### PRD
**Problem.** Refill reminder check runs (`refill_reminder_service.dart`) using `current_quantity`, `refill_remind_days`, `last_refill_date`. Unknown: whether a taken dose decrements `current_quantity` (verify first). Snooze duration is a setting, not clearly tied to alarm page. Spoken reminder repeats 3 times with no user control of count.

**Outcome.** Stock decrements on taken, refill alerts are timely and accurate, snooze and spoken reminder behave as shown in settings.

**Scope**
- Verify and fix: taken dose decrements `current_quantity` by `dosage_amount`; skipped/missed do not.
- Refill alert: fire once per threshold crossing (no daily spam); tap opens medicine.
- Refill edit: set quantity and last refill date from medicine form.
- Snooze: alarm page snooze uses `snooze_duration`; test reschedule.
- Spoken reminder: setting for repeat count (1, 2, 3) — default 3 unchanged.

**Non-goals.** No pharmacy integration. No refill ordering.

**Acceptance**
- D-1 Mark taken → `current_quantity` decreases by dose; skipped → unchanged. Unit test on pure function.
- D-2 Quantity crosses `refill_remind_days` threshold → exactly one notification; later checks same day do not repeat.
- D-3 Snooze from alarm reschedules by `snooze_duration`; test with fake clock.
- D-4 Spoken reminder count setting persists; default 3.
- D-5 `flutter analyze` 0 issues; `flutter test` passes.

**Risks.** Double decrement if taken is edited (undo). Need idempotency key per occurrence.

### Guidelines
1. Pure logic first: `lib/features/schedule/domain/engine/refill_rules.dart` (new): `int? stockAfterTaken(...)`, `bool shouldNotifyRefill(prev, now, threshold, lastNotifiedDay)`. Tests in `test/schedule/refill_rules_test.dart`.
2. Decrement: `lib/features/schedule/data/sqflite/medicine_log_sqflite_repository.dart` on transition to `taken`, same transaction as occurrence update. Undo path reverses only if occurrence was taken and not already reversed.
3. Notification dedupe: store `last_refill_notified_on` in `settings` table (existing) keyed per medicine, or add column via migration (decision Q4).
4. Snooze: `lib/features/schedule/presentation/pages/alarm_page.dart` read `snooze_duration`; `notification_service.dart` reschedule.
5. Spoken count: `lib/core/voice/reminder_voice.dart` replace hardcoded `3` with `PreferencesService` value; add settings tile in `settings_page.dart`.

Verify: `flutter analyze`; `flutter test`; manual check on device for notification timing.

---

## Cross-cutting

- Commits: one per phase, message lists phase and acceptance IDs. Co-Authored-By line uses the model that wrote the commit.
- Each phase: Haiku implements → Sonnet reviews → fix blockers → user checks device steps → next phase.
- No commit/push without user approval per phase (user asked push on dev previously; confirm each batch).

## Open questions for user

- Q1 Caregiver delete rights: archive only (proposed) or full delete?
- Q2 Devanagari and Bengali fonts: bundle Noto Sans (larger app) or rely on system fallback (inconsistent look)?
- Q3 Profile PIN lock: in scope or later?
- Q4 Refill notification dedupe: settings key (no migration) or new column (migration)?
- Q5 Which languages first to ship: Hindi and Bengali both, or one first?
