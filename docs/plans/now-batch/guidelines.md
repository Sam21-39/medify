# Now batch (N1–N6): implementation guidelines

Read `prd.md` first. Its "What the code does today" table is the baseline these steps assume.

Rules:
- Order: N1, N3, N2, N4, N5, then N6. N3 goes before N2 because Undo depends on how stock is lowered.
- Commit each item on its own, and run the full verify block before each commit.
- Do not start N6 until the user has approved the copy (PRD question 6).
- Do not add new packages. Everything needed is already in `pubspec.yaml`: `flutter_local_notifications` 23.0.0, `share_plus`, `csv`, `sqflite`.
- Check plugin API names against `~/.pub-cache/hosted/pub.dev/flutter_local_notifications-23.0.0/lib/src/platform_specifics/darwin/`.
- New user-facing strings go in `lib/l10n/app_en.arb`. Run `flutter gen-l10n` (or a build) to regenerate.
- Tests use the existing pattern: `sqfliteFfiInit()` plus `MedifyDatabase.open(path: inMemoryDatabasePath)`, as in `test/features/schedule/data/sqflite/medicine_log_sqflite_repository_test.dart`.

Verify after each item:
```
dart format lib test
flutter analyze            # must be 0 issues
flutter test
flutter build ios --simulator --debug   # signed build; do NOT use --no-codesign
flutter build apk --debug
```

---

## N1 Device verification
1. Build a debug build for each device row in `docs/plans/feature-roadmap-next/device-checklist.md` and fill in the Result column.
2. Run `cd android && ./gradlew :app:lintDebug`. Paste the findings for `res/values*/styles.xml` and `MainActivity.kt` into the checklist under a new "Lint" section. Fix or suppress them according to the answer to PRD question 1.
3. Make code changes only for FAIL rows. Fix the root cause and reference the row in the commit message.

## N3 Refill correctness
Files:
- `lib/features/medicines/domain/entities/medicine.dart`
- `lib/features/medicines/domain/repositories/medicine_repository.dart`
- `lib/features/medicines/data/sqflite/medicine_sqflite_repository.dart`
- `lib/features/schedule/data/services/refill_reminder_service.dart`
- `lib/features/schedule/presentation/cubit/medicine_log_cubit.dart`
- `lib/core/di/injection_container.dart`
- `lib/features/medicines/presentation/pages/add_edit_medicine_page.dart`
- `lib/features/medicines/presentation/widgets/medicine_card.dart`
- `lib/features/schedule/presentation/pages/schedule_page.dart`

1. **Stop the second decrement.**
   - In `MedicineLogCubit.markAsTaken`, remove the `getLogById` and `decrementMedicineQuantity` lines.
   - Delete `RefillReminderService.decrementMedicineQuantity`.
   - Stock moves only in `SqfliteMedicineLogRepository.markAsTaken`. That method is already correct and already tested.
2. **Fix `Medicine.daysRemaining`.**
   - The daily use is `dosageAmount * reminderTimes.length`. Return null when that is 0.
   - Ignoring weekdays is a known ceiling. Mark it with a `// ponytail:` comment.
3. **Pure alert rule.** Put this as top-level functions in `refill_reminder_service.dart`. No new file.
   ```dart
   enum RefillLevel { none, low, out }
   RefillLevel refillLevel(Medicine m) // out if isOutOfStock, low if isLowStock, else none
   bool shouldAlert(RefillLevel previous, RefillLevel now) => now.index > previous.index;
   ```
4. **Dedupe store.**
   - Inject `SettingsStore` into `RefillReminderService`, and update its registration in `injection_container.dart`.
   - Key: `refill_alert_<medicineId>`. Read and write it with `getString` / `setString`, storing `RefillLevel.name`. A missing key means `none`.
   - In `_checkMedicineRefillStatus`:
     - Compute `now`.
     - If `shouldAlert(prev, now)`, send the existing notification for `now`. Send one of low or out, never both.
     - Always store `now`. Storing it when it drops is what re-arms the alert after a refill.
5. **Public `checkMedicine(int medicineId)`.**
   - It loads the medicine by id and runs `_checkMedicineRefillStatus`.
   - Call it from `MedicineLogCubit.markAsTaken` after the repo succeeds.
   - Call it from the notification Taken action (N2 step 3).
6. **Refill write.**
   - Add `Future<Either<Failure, Medicine>> refillStock(int id, double quantity)` to `MedicineRepository`.
   - Implement it in `SqfliteMedicineRepository`. It updates `current_quantity`, `last_refill_date` and `updated_at`, then calls `_refresh()` and returns `_byId`.
   - Reject a negative quantity with `Left`.
   - Rewrite `RefillReminderService.refillMedicine` so that it:
     - calls `refillStock`;
     - sets the dedupe key to `none`;
     - keeps the existing success notification, or replaces it with a snackbar from the UI (snackbar preferred). Drop the notification if you use the snackbar.
   - Find any test fakes of `MedicineRepository` with `grep -rn "implements MedicineRepository" test`, and add the method to each.
7. **UI.**
   - In `add_edit_medicine_page.dart`, uncomment the refill section (around lines 375–460) behind the "Track stock" switch. The switch already exists as `_enableRefillTracking`.
   - Add the helper text "Stock goes down when you mark a dose Taken."
   - On edit, stock cannot be changed here, which matches the repo rule.
   - On `MedicineCard`, when `currentQuantity != null`, add an "I refilled" `TextButton` next to the stock indicator.
   - On the "Refill soon" banner in `schedule_page.dart` (around line 243), add the same action for the first low medicine.
   - Both open one shared dialog: a number field prefilled with `totalQuantity`, with Cancel and Save buttons. Save calls `getIt<RefillReminderService>().refillMedicine(id, newQuantity: x)` and then `getIt<MedicineCubit>().loadMedicines()`.
   - Put the dialog as a top-level function in `medicine_card.dart`. No new file.
8. **Tests.**
   - `test/features/schedule/refill_rules_test.dart`: `shouldAlert` for none→low, low→low, low→out, out→none→low, and `daysRemaining` with dosageAmount 2.
   - Extend `medicine_log_sqflite_repository_test.dart`: Skip leaves stock unchanged, and Missed leaves stock unchanged.
   - Add a test for `refillStock` in the medicine repo test.

## N2 Dose loop reliability
Files:
- `lib/core/notifications/notification_service.dart`
- `lib/main.dart`
- `lib/core/ui/app_messenger.dart`
- `lib/features/schedule/domain/repositories/medicine_log_repository.dart`
- `lib/features/schedule/data/sqflite/medicine_log_sqflite_repository.dart`
- `lib/features/schedule/data/sqflite/medicine_log_row_mapper.dart`
- `lib/features/schedule/domain/entities/medicine_log.dart`
- `lib/features/schedule/presentation/cubit/medicine_log_cubit.dart`
- `lib/features/schedule/presentation/cubit/medicine_log_state.dart`
- `lib/features/schedule/presentation/pages/schedule_page.dart`
- `lib/features/schedule/presentation/widgets/medicine_log_card.dart`
- `lib/features/schedule/presentation/pages/alarm_page.dart`

1. **Repo.**
   - Change the signature to `markAsSkipped(int id, {String? reason})` and write `skip_reason: reason`. Update both callers.
   - Add `Future<Either<Failure, MedicineLog>> revertToScheduled(int id)` using `_transition`:
     - `taken`: set `status='scheduled'` and `taken_at_utc=NULL` (the CHECK requires both together). Then run `UPDATE medicines SET current_quantity = current_quantity + ? WHERE id = ? AND current_quantity IS NOT NULL` with `dose_snapshot_amount`.
     - `skipped`: set `status='scheduled'` and `skip_reason=NULL`.
     - `scheduled`: return `Right` with no change. This makes a second undo do nothing.
     - `missed`: return `Left`.
   - Add a `// ponytail:` comment on the stock restore: if the earlier decrement was clamped at 0, the restore over-credits; fix with a stored delta if it matters.
   - Add `skipReason` to `MedicineLog` (field, constructor, `copyWith`, `props`) and read it in `MedicineLogRowMapper.fromRow`.
2. **NotificationService: one path for actions.**
   - Add `Future<void> cancelOccurrence(int id)`. It cancels `_mainId`, `_priorId` and `_snoozeId`.
   - Add `Future<void> snooze(int occurrenceId, int minutes)`. It calls `repo.snoozeLog`, then schedules the `_snoozeId` reminder at now + minutes. This is the current `_handleSnoozeAction` body with `minutes` as a parameter. Delete `_handleSnoozeAction`.
   - Change the Android action list to `taken` ('Taken'), `snooze` ('Snooze') and `skip` ('Skip'), all with `showsUserInterface: true`.
   - iOS:
     - Add `notificationCategories: [DarwinNotificationCategory('dose', actions: [...plain('taken', 'Taken', options: {DarwinNotificationActionOption.foreground}), snooze, skip])]` to the `DarwinInitializationSettings`.
     - Add `categoryIdentifier: 'dose'` to the iOS details in `_reminderDetails`.
     - Do this only in `_reminderDetails`. Leave prior notices without actions.
   - In `_handleResponse`, switch on `actionId`:
     - `taken`: `repo.markAsTaken`, then `cancelOccurrence`, then `getIt<RefillReminderService>().checkMedicine(log.medicineId)`.
     - `snooze`: `snooze(id, getIt<PreferencesService>().snoozeDuration)`.
     - `skip`: `repo.markAsSkipped(id)`, then `cancelOccurrence`.
     - anything else: the existing `/alarm` route.
   - After any DB change, call `getIt<MedicineLogCubit>().loadTodayLogs()` so Today updates.
   - Add `Future<void> handleLaunchDetails()`. It calls `_notifications.getNotificationAppLaunchDetails()`. If `didNotificationLaunchApp` is true and `notificationResponse != null`, it calls `_handleResponse`.
   - Call it from `main.dart` `_launchApp` right after `runApp`, with `unawaited`.
   - Leave `_onBackgroundNotificationTapped` as it is. It is unused, because every action opens the app.
3. **Cubit.**
   - `markAsTaken(id)`: repo, then `cancelOccurrence(id)`, then `checkMedicine` (from N3), then achievements. Emit `MedicineLogOperationSuccess('Marked as taken', undoId: id)`.
   - `markAsSkipped(id, {String? reason})`: repo with the reason, then `cancelOccurrence`, then emit with `undoId: id`.
   - `snoozeLog(id, minutes)`: delegate to `getIt<NotificationService>().snooze(id, minutes)`.
   - `undo(id)`: `repo.revertToScheduled(id)`, then `getIt<NotificationService>().rescheduleUpcoming()`, then `loadTodayLogs()`.
   - Add `final int? undoId` to `MedicineLogOperationSuccess`, and include it in `props`.
4. **AppMessenger.** Add `{String? actionLabel, VoidCallback? onAction}` to `show`. When both are set, attach a `SnackBarAction` and set `duration: Duration(seconds: 5)`.
5. **Today.**
   - In the `schedule_page.dart` listener, when `state.undoId != null`, call `show(state.message, actionLabel: 'Undo', onAction: () => getIt<MedicineLogCubit>().undo(state.undoId!))`.
   - The skip button in `MedicineLogCard` (around line 303) calls a new `_showSkipReasons(context)` bottom sheet, modelled on the existing `_showSnoozeOptions`.
   - The sheet lists one `ListTile` per preset (PRD question 2) and a final "Skip without reason" tile. Change the callback type to `onSkip: void Function(String? reason)`.
   - Update the call site in `schedule_page.dart`.
   - Store the stable preset key, for example `felt_unwell`, not the label.
6. **Alarm page.** No reason sheet, to keep it one tap. `_act` continues to work through the cubit.
7. **Tests.** Repo tests for N2-1 and N2-2. Add the device-matrix rows to `device-checklist.md` under "## Dose actions".

## N4 Pause / stop
Files:
- `lib/features/medicines/domain/entities/medicine.dart`
- `lib/features/medicines/data/sqflite/medicine_row_mapper.dart`
- `lib/features/medicines/domain/repositories/medicine_repository.dart`
- `lib/features/medicines/data/sqflite/medicine_sqflite_repository.dart`
- `lib/features/medicines/presentation/cubit/medicine_cubit.dart`
- `lib/features/medicines/presentation/widgets/medicine_card.dart`
- `lib/features/medicines/presentation/pages/medicine_list_page.dart`

1. **Entity.**
   - Add `final bool isStopped` (default false) and `final String? stopReason`.
   - The mapper sets `isStopped` to `state == finished` and reads `stop_reason` as a plain preset key (PRD question 3).
   - `toRow` must not write `stop_reason`. The stop method owns that column.
2. **Repo.**
   - Add `Future<Either<Failure, void>> stopMedicine(int id, {String? reason})`. It is the current `deleteMedicine` body plus `stop_reason`.
   - Make `deleteMedicine` call `stopMedicine(id)` so that existing callers keep working, or remove `deleteMedicine` and update its callers. Prefer removing it: there is one caller.
   - In `stopMedicine` and in `toggleMedicineStatus`, when the result is not active, run this in the same transaction:
     `DELETE FROM occurrences WHERE medicine_id = ? AND status = 'scheduled' AND scheduled_at_utc > ?` with now in UTC milliseconds.
   - This is the same rule `MedicineCubit.updateMedicine` uses.
3. **Cubit order (critical).**
   - In `toggleMedicineStatus` and `stopMedicine`, when going inactive, call `cancelMedicineReminders(id)` **before** the repo call. It looks up occurrence ids in the DB.
   - Resume keeps the current order: repo, then `_generateOccurrences`, then schedule.
4. **UI.**
   - `MedicineCard`: replace the toggle `IconButton` with a `PopupMenuButton` that has Pause/Resume (hidden when stopped) and Stop (hidden when stopped).
   - When stopped, show a "Stopped" chip and grey out the card. The existing `isActive` styling already handles the grey.
   - Stop opens one dialog with optional preset `RadioListTile`s and "Stop medicine" / "Cancel" buttons. Nothing selected means the reason is null.
   - `medicine_list_page.dart` swipe: depends on PRD question 4. By default, relabel the swipe to "Stop" and route it through the same dialog. `confirmDismiss` returns the dialog result.
5. **Tests.** N4-1 and N4-2 in the medicine repo test file. Insert past taken, past scheduled and future scheduled occurrences, then assert that only the future scheduled one is deleted.

## N5 First medicine offer
File: `lib/features/profiles/presentation/pages/role_page.dart`.

1. In `_choose`, when `role == 0`, before `go('/today')`:
   - Read `(await getIt<MedicineRepository>().getActiveMedicines()).fold((_) => const [], (m) => m)`.
   - If the list is empty, show a dialog with the buttons "Add medicine", "Speak it" and "Not now".
2. Then:
   - Call `go('/today')` in every case.
   - For "Add medicine", also `push('/medicine/add')`.
   - For "Speak it", do the same two-step flow as `AddMedicineFab._openVoice`: push voice, then push add with the draft. Copy those three lines; do not extract a helper unless a third caller appears.
3. Test: a widget test with a fake `MedicineRepository` that returns an empty list asserts the dialog appears and "Not now" navigates to `/today`. Use the existing get_it test setup pattern if one exists (`grep -rn "getIt.register" test`). Otherwise register the fakes in `setUp` and call `getIt.reset()` in `tearDown`.

## N6 Delete all data (blocked until copy is approved)
Files:
- `lib/main.dart`
- new `lib/app/launch.dart`
- `lib/core/notifications/notification_service.dart`
- `lib/features/history/presentation/cubit/history_cubit.dart`
- `lib/features/settings/presentation/pages/settings_page.dart`

1. **Make the launch path reusable.**
   - Move `_launchApp`, `_scheduleUpcoming` and `_DayChangeObserver` from `main.dart` into `lib/app/launch.dart` as a public `launchApp()`. `main.dart` calls it.
   - Guard the observer with `static bool _added` so a relaunch does not add a second one.
   - Add `Future<void> handleLaunchDetails()` from N2 there as well.
2. **Wipe function**, in `launch.dart`:
   ```dart
   Future<void> wipeAllDataAndRelaunch() async {
     await FlutterLocalNotificationsPlugin().cancelAll(); // throws → abort, DB untouched
     final db = getIt<Database>();
     final path = db.path;
     await db.close();
     await deleteDatabase(path);
     runApp(const SizedBox.shrink());           // unmount MyApp: its router lives in initState
     await WidgetsBinding.instance.endOfFrame;
     await launchApp();                          // getIt.reset + fresh DB + first_launch=true → /onboarding
   }
   ```
   - Do not delete the secure-storage key. `DatabaseKeyStore` reuses it with the empty DB, which is valid.
   - If `deleteDatabase` throws after the close, call `launchApp()` anyway (it reopens the DB) and show the failure message.
3. **Export all.**
   - Add `HistoryCubit.exportAll()`. It uses `getAllLogs()` and `getAllMedicines()`, then the existing `_generateCSVData` and share code.
   - Extract the save-and-share part of `exportToCSV` into a private helper that both methods call. Do not copy it.
   - `exportAll` must not depend on `state is HistoryLoaded`.
   - It returns `Future<bool>`: true when a file was shared.
4. **Settings UI.**
   - Add a "Delete all data" destructive `TextButton` below the reset button.
   - Flow: export dialog (approved copy) → confirm dialog → `wipeAllDataAndRelaunch()` with a blocking progress indicator → on an exception, `AppMessenger.show(failure, error: true)`.
   - The confirm dialog is a `StatefulBuilder` with a `TextField` and a `ValueListenableBuilder` on its controller.
   - The destructive button's `onPressed` is null unless `controller.text == 'DELETE'`. The comparison is exact, with no trim and no case folding.
   - Use `showDialog`, not `AdaptiveAlertDialog`, because the dialog needs a text field.
5. **Tests.**
   - A widget test for the confirm dialog (N6-1).
   - A unit test that opens `MedifyDatabase` at a temp file path, inserts a row, closes it, calls `deleteDatabase`, reopens, and asserts the tables are empty (N6-2).
   - Test the abort-on-cancel-failure ordering (N6-4) by passing a `cancelAll` function in as a parameter with a default, the same pattern as `LegacyReset.cancelReminders`.

---

## Reviewer checklist (Sonnet)
- No path lowers stock other than `SqfliteMedicineLogRepository.markAsTaken`.
- `revertToScheduled` and the `taken_at_utc` CHECK constraint stay consistent.
- Every inactive transition cancels notifications before it deletes occurrences.
- N6 cancels notifications before touching the DB, and the copy matches the approved text exactly.
- No new packages.
- `flutter analyze` reports 0 issues.
- Both builds pass.
