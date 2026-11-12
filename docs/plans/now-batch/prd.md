# Now batch (N1–N6): Technical PRD

Source: `docs/plans/product-user-plan/plan.md` section 5. Implementation steps are in `guidelines.md`.

Already decided, not reopened here: the stop reason is optional. Delete all data wipes the local DB, cancels notifications, returns to onboarding and offers export first. Achievements become a streak card on Home (not part of this batch). The four tabs stay. Hindi and Bengali are deferred. Caregiver-first applies to Next.

## What the code does today (traced, 2026-11-11)

| Area | Current behaviour | Problem |
|---|---|---|
| Stock on Taken | `SqfliteMedicineLogRepository.markAsTaken` lowers `current_quantity` by `dose_snapshot_amount` in the same transaction, once (a second Taken returns Right with no change; a test covers this). | `MedicineLogCubit.markAsTaken` then calls `RefillReminderService.decrementMedicineQuantity`. That method goes through `updateMedicine`, which drops `current_quantity`, so stock is not lowered twice. But it runs the refill check on a quantity it calculated itself and that was never saved, which can trigger a false or duplicate alert. |
| Skip / Missed stock | No stock change. | OK |
| Refill alert | `checkAndScheduleRefillReminders()` runs on every cold start (`injection_container.dart`). | Alerts again on every launch while stock is low. Nothing removes duplicates. |
| `daysRemaining` | `currentQuantity / reminderTimes.length` | Ignores `dosageAmount`. With 2 tablets per dose, days left comes out twice as high. |
| "I refilled" | `RefillReminderService.refillMedicine` goes through `updateMedicine`. | Broken: `updateMedicine` strips `current_quantity`, so a refill never changes stock. Nothing in the UI calls it. |
| Refill fields in form | Commented out in `add_edit_medicine_page.dart` (around lines 375–460). | New medicines never get stock values, so all of N3 is unreachable. |
| Notification actions | Android only: `snooze` ("Snooze (5 min)") and `skip`. No `taken` action. iOS has no notification categories, so no action buttons appear. | Taken from the notification is not possible. Snooze ignores the `snooze_duration` setting and never writes `snoozed_until_utc`. |
| Killed app | `getNotificationAppLaunchDetails` is never read. | A tap or action that cold-starts the app is lost: no alarm page, no skip. |
| In-app Taken/Skip | Changes the DB only. | The notification and the 15-minute prior notice for that dose still fire. |
| In-app Snooze | Writes `snoozed_until_utc` only. | Nothing re-reminds the user. |
| Undo | `updateLog` forbids leaving `taken`. No undo exists. | |
| Skip reason | Column `occurrences.skip_reason` exists. `markAsSkipped` always writes NULL. The `MedicineLog` entity has no such field. | |
| Pause | `toggleMedicineStatus`, shown as a toggle icon on `MedicineCard`. | Future `scheduled` occurrences stay, so paused doses still show on Today. |
| Stop | The swipe labelled "Delete" calls `deleteMedicine`, which sets `state='finished'`. | It is really a stop. `stop_reason` is never written, the entity cannot tell paused from finished, and future occurrences stay. |
| Onboarding end | `OnboardingPage._completeOnboarding` goes to `/role`, then `RolePage._choose` goes to `/today`. | The real end of onboarding is `RolePage._choose`, not `onboarding_page.dart`. |
| Delete all | Not present. Settings has only "Reset settings". | |
| Restart | `_launchApp()` in `main.dart` is private. `MyApp` keeps the same `myAppKey`, and `MyAppState` builds the router once in `initState`. | Calling `runApp(MyApp(key: myAppKey))` again would keep the old router. The relaunch must mount a different widget first. |

## Items

### N1 Phase A device verification
- Run `docs/plans/feature-roadmap-next/device-checklist.md` on Android 13+, Android <13, iOS 26 and iOS <26, and record PASS/FAIL in the file.
- Run Android lint on `android/app/src/main/res/values*/styles.xml` and `MainActivity.kt`. Then decide whether to fix or suppress each finding (see Q1).
- Change code only for a FAIL, with one fix per FAIL.
- **Accept:** no PENDING rows left, and every FAIL has either a fix commit or a written waiver.
- **Risk:** iOS <26 device availability.

### N2 Dose loop reliability
- Add a Taken action next to Snooze and Skip on Android and iOS (iOS uses a `DarwinNotificationCategory`). Every action opens the app, so it is handled in the main isolate with DI. No background-isolate DI.
- Handle a cold start from a notification through `getNotificationAppLaunchDetails` after `runApp`.
- Taken and Skip from anywhere cancel that dose's reminder, prior notice and snooze notifications.
- Snooze from anywhere (notification, alarm page, Today card) writes `snoozed_until_utc` and schedules one reminder at now + minutes. The notification action uses `snooze_duration`.
- Undo snackbar for about 5 s after Taken or Skip on Today. Undo returns the dose to `scheduled`, puts the stock back on Taken, clears `skip_reason`, and reschedules the reminders.
- Skip opens a sheet with optional preset reasons and a "Skip without reason" button. The notification Skip action stores no reason.
- **Accept:**
  - N2-1 Repo tests: undo taken→scheduled restores stock exactly once (a second undo does nothing), and undo skipped→scheduled clears the reason.
  - N2-2 Repo test: `markAsSkipped(id, reason: 'x')` stores the reason and `MedicineLog.skipReason` reads it back.
  - N2-3 Device matrix (append to the checklist): Taken, Snooze and Skip from the notification, each with the app in foreground, background and killed, on Android 13+ and iOS. Each changes the DB state and Today shows it.
  - N2-4 Taken in the app before the dose time: no reminder fires later.
- **Risks:**
  - iOS critical-alert categories need the `foreground` option.
  - The 64 pending-notification cap on iOS (already a plan risk).
  - Undo after the stock was clamped at 0 can restore more than was taken off (documented as a limit).

### N3 Refill correctness
- Remove the `decrementMedicineQuantity` call from the cubit, and delete the method. The repo is the only place that lowers stock.
- Fix `daysRemaining` to `currentQuantity / (dosageAmount × reminderTimes.length)`.
- Alert once per level crossing (none → low → out). Store the last alerted level per medicine in the `settings` table (key `refill_alert_<medicineId>`), so no migration is needed. Refilling clears the key. Check after every Taken and at startup.
- Add `MedicineRepository.refillStock(id, quantity)`, which writes `current_quantity` and `last_refill_date`. Rewrite `RefillReminderService.refillMedicine` to use it.
- Add an "I refilled" action on `MedicineCard` and on the Today "Refill soon" banner, when stock tracking is on. It opens a dialog prefilled with `totalQuantity`.
- Turn the refill tracking section in the medicine form back on.
- **Accept:**
  - N3-1 Repo test: Taken lowers stock by the dose snapshot; Skip and Missed leave it unchanged; Taken twice lowers it once.
  - N3-2 Unit test on the pure level function: none→low alerts, low→low does not, low→out alerts, and after a refill none→low alerts again.
  - N3-3 Repo test: `refillStock` sets the quantity and date.
  - N3-4 Cold start twice while stock is low gives exactly one notification.
- **Risk:** editing a medicine still cannot change stock (by design: stock changes only through Taken and refill). Tell the user this in the form helper text.

### N4 Pause / stop medicine
- Medicine detail actions (from `MedicineCard`) are Pause/Resume and Stop. Stop asks for an optional reason (presets, see Q3) and writes `state='finished'` and `stop_reason`.
- The swipe action becomes "Stop" and uses the same flow (see Q4).
- Pause and Stop cancel notifications first, then delete future `scheduled` occurrences in the same repo transaction as the state change. Past history is kept.
- The entity gains `isStopped` and `stopReason`. Stopped medicines show a "Stopped" label and no toggle. Resume is only for paused medicines.
- **Accept:**
  - N4-1 Repo test: pause and stop delete only future `scheduled` occurrences, and keep taken, skipped and missed ones.
  - N4-2 Repo test: stop with and without a reason; `stop_reason` reads back.
  - N4-3 Pause, then Today: the dose is gone. Resume: doses come back.
- **Risk:** if occurrences are deleted before the notifications are cancelled, those notifications are orphaned, because `cancelMedicineReminders` looks up occurrence ids in the DB. The order is fixed in the guidelines.

### N5 Add first medicine at end of onboarding
- In `RolePage._choose`, after the patient role is saved: if the active profile has no medicines, show an offer with "Add medicine", "Speak it" and "Not now". Go to `/today` first, then push the matching route. This is the same routes as `AddMedicineFab`.
- Caregiver path: unchanged (Next).
- **Accept:** N5-1 widget test: choosing the patient role with 0 medicines shows the offer, and "Not now" lands on `/today`. N5-2 device check: a fresh install reaches the add form in one tap after the role choice.

### N6 Delete all data (irreversible)
- Settings gets a "Delete all data" destructive tile below Reset settings.
- Step 1: offer export (CSV of all history through a new `HistoryCubit.exportAll`), with buttons Export / Continue without export / Cancel.
- Step 2: type `DELETE` (exact, case-sensitive) to enable the destructive button.
- Then:
  1. Cancel all notifications. If this throws, abort.
  2. Close the DB.
  3. `deleteDatabase(medify_v2.db)`.
  4. Mount a placeholder app.
  5. Re-run the launch path. Settings reset, so the router opens `/onboarding`.
- The secure-storage DB key is kept. An empty DB with the existing key is valid, and `DatabaseKeyStore` never deletes keys by design.
- **Copy approval gate:** the strings below are a DRAFT. The implementer must not start N6 until the user approves the exact copy in writing.
  - Tile: "Delete all data"
  - Export step title: "Export your history first?" Body: "Deleting removes all medicines, doses, history and settings from this phone. Medify has no cloud copy, so this cannot be undone." Buttons: "Export history" / "Continue without export" / "Cancel"
  - Confirm step title: "Delete everything?" Body: "Type DELETE to confirm. This cannot be undone." Field hint: "DELETE". Buttons: "Cancel" / "Delete all data" (destructive, disabled until the text matches)
  - Failure: "Could not delete data. Nothing was removed."
- **Accept:**
  - N6-1 Test: the confirm button is disabled for "", "delete" and "DELETE " and enabled for "DELETE".
  - N6-2 Test with a temp-file DB: after the wipe the file is gone and reopening gives an empty schema.
  - N6-3 Device: pending notifications count is 0 after the wipe, the app shows onboarding, and finishing onboarding gives a fresh default profile with no medicines and no history.
  - N6-4 If cancelling notifications fails, the DB is untouched.
- **Risks:**
  - In-flight async work on the closed DB throws (it is caught already).
  - `_DayChangeObserver` gets added twice on relaunch, so it needs a guard.
  - Export CSVs in the temp dir survive the wipe. The OS clears them.

## Verify (every item)
```
dart format lib test
flutter analyze            # 0 issues
flutter test
flutter build ios --simulator --debug   # signed; --no-codesign breaks keychain read
flutter build apk --debug
```

## Out of scope
Streak card on Home, profiles/caregiver, hi/bn, backup/restore, hard delete of a single medicine, refill notification tap opening the medicine, spoken-reminder repeat count.

## Open questions
1. **N1 styles.xml lint:** which finding is meant? Fix it, or suppress it with `tools:ignore`? (Default: run lint, fix if it is a one-liner, otherwise suppress with a comment.)
2. **Skip reason presets:** proposed "Felt unwell", "Side effects", "Ran out", "Doctor advised", "Other". Store as stable keys (plaintext, no free text) so no encryption is needed. OK, or do you want free text (would be encrypted like `notes`)?
3. **Stop reason presets:** proposed "Course finished", "Doctor stopped it", "Side effects", "Other". Same storage question as Q2.
4. **Swipe on Medicines:** rename the "Delete" swipe to "Stop" (it already archives, it never deleted)? Or remove the swipe and keep Stop only in the card actions?
5. **N5 placement:** the trace shows onboarding ends in `RolePage`, not `onboarding_page.dart`. OK to put the offer there, after the patient role?
6. **N6 copy:** approve or edit the draft strings above. Implementation of N6 is blocked until you do.
7. **N3 form:** turn the refill section back on as it was (total quantity, remind days before), or hide it behind a "Track stock" switch defaulting off? (Default: switch, off.)
