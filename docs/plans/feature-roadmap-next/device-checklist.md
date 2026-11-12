# Phase A device checklist

Record each result in the Result column. Replace PENDING with PASS, FAIL (note the issue), or N/A (note why).

## FAB

| Item | Device / OS | Result |
|---|---|---|
| FAB position, native bar (iOS 26) | iOS 26 | PENDING |
| FAB position, iOS below 26 | iOS <26 | PENDING |
| FAB position, not covering last list item | Android | PENDING |
| FAB position, not covering last list item | iOS 26 | PENDING |
| FAB position, not covering last list item | iOS <26 | PENDING |
| Menu open and close | Android | PENDING |
| Menu open and close | iOS 26 | PENDING |
| Menu open and close | iOS <26 | PENDING |
| Back button closes menu | Android | PENDING |
| Tab change closes menu | iOS 26 | PENDING |
| Tab change closes menu | iOS <26 | PENDING |
| Tap-through blocked while menu open | Android | PENDING |
| Tap-through blocked while menu open | iOS 26 | PENDING |
| Tap-through blocked while menu open | iOS <26 | PENDING |

## Voice

| Item | Device / OS | Result |
|---|---|---|
| Happy path: speak, transcript, review form opens | iOS | PENDING |
| Happy path: speak, transcript, review form opens | Android 13+ | PENDING |
| Mic permission denied: denied message, manual entry offered | iOS | PENDING |
| Mic permission denied: denied message, manual entry offered | Android 13+ | PENDING |
| No offline model: unavailable message | iOS | PENDING |
| Android below 13: unavailable message | Android <13 | PENDING |
| Stop with no final within 3s: idle, no review form | iOS | PENDING |
| Stop with no final within 3s: idle, no review form | Android 13+ | PENDING |

## Text styling

| Item | Device / OS | Result |
|---|---|---|
| Text styling on iOS pages after Material wrapper (`my_app.dart`) | iOS 26 | PENDING |
| Text styling on iOS pages after Material wrapper (`my_app.dart`) | iOS <26 | PENDING |

## Lint

`cd android && JAVA_HOME=<JDK 21> ./gradlew :app:lintDebug` (JDK 26 fails in jlink before lint runs).

| Finding | Result |
|---|---|
| `styles.xml` (values and values-night): `forceDarkAllowed` needs API 29, `windowLayoutInDisplayCutoutMode` needs API 27 (NewApi, minSdk 24) | Waiver: suppressed with `tools:ignore="NewApi"` on `LaunchTheme`. Both attributes are ignored below their API level. |
| `MainActivity.kt` | No findings |

## Dose actions

N2-3 matrix: each action from the notification, with the app foreground, background and killed. Each must change the DB state, and Today must show it. Verified by reading the code only so far (Android action list and iOS `dose` category with `foreground`). Run on a device.

| Item | Device / OS | Result |
|---|---|---|
| Taken from notification, app foreground | Android 13+ | PENDING |
| Taken from notification, app foreground | iOS | PENDING |
| Taken from notification, app background | Android 13+ | PENDING |
| Taken from notification, app background | iOS | PENDING |
| Taken from notification, app killed | Android 13+ | PENDING |
| Taken from notification, app killed | iOS | PENDING |
| Snooze from notification, app foreground | Android 13+ | PENDING |
| Snooze from notification, app foreground | iOS | PENDING |
| Snooze from notification, app background | Android 13+ | PENDING |
| Snooze from notification, app background | iOS | PENDING |
| Snooze from notification, app killed | Android 13+ | PENDING |
| Snooze from notification, app killed | iOS | PENDING |
| Skip from notification, app foreground | Android 13+ | PENDING |
| Skip from notification, app foreground | iOS | PENDING |
| Skip from notification, app background | Android 13+ | PENDING |
| Skip from notification, app background | iOS | PENDING |
| Skip from notification, app killed | Android 13+ | PENDING |
| Skip from notification, app killed | iOS | PENDING |
| Taken in app before the dose time: no reminder fires later | Android 13+ | PENDING |
| Taken in app before the dose time: no reminder fires later | iOS | PENDING |
| Snooze from app, then resume the app: snooze reminder still fires | Android 13+ | PENDING |
| Snooze from app, then resume the app: snooze reminder still fires | iOS | PENDING |
| Undo after Taken and after Skip: status back to scheduled, reminder returns | Android 13+ | PENDING |
| Undo after Taken and after Skip: status back to scheduled, reminder returns | iOS | PENDING |
| N2-4 race: take a dose from the notification while app resumes; no reminder fires later | Android 13+ | PENDING |
| N2-4 race: take a dose from the notification while app resumes; no reminder fires later | iOS | PENDING |

## Pause and stop (N4)

Verified by reading the code and by repo tests (N4-1, N4-2) only so far. Run on a device.

| Item | Device / OS | Result |
|---|---|---|
| Pause from card menu: future doses gone from Today | Android 13+ | PENDING |
| Pause from card menu: future doses gone from Today | iOS | PENDING |
| Pause: no reminder fires for the paused medicine | Android 13+ | PENDING |
| Pause: no reminder fires for the paused medicine | iOS | PENDING |
| Resume: doses back on Today and reminders fire again | Android 13+ | PENDING |
| Resume: doses back on Today and reminders fire again | iOS | PENDING |
| Stop from card menu, with a reason: card shows Stopped, no menu, doses gone | Android 13+ | PENDING |
| Stop from card menu, with a reason: card shows Stopped, no menu, doses gone | iOS | PENDING |
| Stop without a reason: same as above | Android 13+ | PENDING |
| Stop without a reason: same as above | iOS | PENDING |
| Swipe on Medicines shows "Stop" and opens the same dialog | Android 13+ | PENDING |
| Swipe on Medicines shows "Stop" and opens the same dialog | iOS | PENDING |
| Cancel in the Stop dialog changes nothing | Android 13+ | PENDING |
| Stopped medicine: no pending reminder left (check after Stop) | Android 13+ | PENDING |
| Stopped medicine: no pending reminder left (check after Stop) | iOS | PENDING |

## First medicine offer (N5)

Verified by widget test (N5-1) only so far. Run on a device.

| Item | Device / OS | Result |
|---|---|---|
| Fresh install: choose Patient, offer shows, "Add a medicine" opens the add form in one tap | Android 13+ | PENDING |
| Fresh install: choose Patient, offer shows, "Add a medicine" opens the add form in one tap | iOS | PENDING |
| "Later" lands on Today, no form opens | Android 13+ | PENDING |
| "Later" lands on Today, no form opens | iOS | PENDING |
| Offer does not show again after relaunch | Android 13+ | PENDING |
| Offer does not show again after relaunch | iOS | PENDING |
| Caregiver path unchanged (no offer) | Android 13+ | PENDING |
| Caregiver path unchanged (no offer) | iOS | PENDING |

## Delete all data (N6)

Verified by unit and widget tests (N6-1, N6-2, N6-4) only so far. Run on a device.

| Item | Device / OS | Result |
|---|---|---|
| Pending notifications count is 0 after Delete all data (N6-3) | Android 13+ | PENDING |
| Pending notifications count is 0 after Delete all data (N6-3) | iOS | PENDING |
| App shows onboarding after the wipe (N6-3) | Android 13+ | PENDING |
| App shows onboarding after the wipe (N6-3) | iOS | PENDING |
| Finishing onboarding gives a fresh default profile, no medicines, no history (N6-3) | Android 13+ | PENDING |
| Finishing onboarding gives a fresh default profile, no medicines, no history (N6-3) | iOS | PENDING |
| Step 1 "Export history" shares a CSV, then step 2 appears | Android 13+ | PENDING |
| Step 1 "Export history" shares a CSV, then step 2 appears | iOS | PENDING |
| "Cancel" at step 1 or step 2 leaves all data in place | Android 13+ | PENDING |
| "Cancel" at step 1 or step 2 leaves all data in place | iOS | PENDING |
