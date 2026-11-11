# UX overhaul: icons, platform widgets, FAB add flow, voice add

Status: DRAFT, awaiting user approval. Planner: Opus. Implementer: Haiku (`model-implementer`). Reviewer: Sonnet (`model-reviewer`).

## 1. Technical PRD

### Problem
- 28 SVG icons in `assets/icons/` are unused (only `medify-icon.png` is used). Tabs use stock Material/Cupertino icons.
- Material and Cupertino widgets are mixed without platform rules.
- Add-medicine entry is scattered: `/medicine/add` is pushed from list page empty state, list page actions.
- Settings and History pages have hardcoded English, deprecated APIs, Material dialogs on iOS.
- No voice entry. Typing doses is slow for elderly users.

### Outcome
One add entry point (FAB). Two ways in: manual, voice. Voice always ends in a review screen. UI looks native per platform.

### Scope
1. Map SVG icons into app via `flutter_svg` + flutter_gen `Assets.icons.*`.
2. Platform-correct widgets: Material on Android, Cupertino on iOS, via `adaptive_platform_ui` and `Theme.of(context).platform`/`PlatformInfo`.
3. Settings + History: localize strings, fix deprecations, platform dialogs/pickers.
4. FAB plus at end of bottom nav. Sole source of add-medicine. Remove other add entry points.
5. FAB tap expands to two options: Manual entry, Voice input.
6. Voice: native speech-to-text, parse to draft, open pre-filled add form as review. Save only on explicit user tap.

### Non-goals
- No cloud speech or LLM parsing. On-device only (privacy: health data).
- No new tabs. No Settings tab change.
- No change to DB schema, notification engine, encryption.
- Edit-medicine flow (`/medicine/edit`) unchanged except widget adaptation.

### Acceptance checks
- A1 Tab bar icons come from `Assets.icons` (home/medicine/history/statistics); FAB uses `add.svg`; voice option uses `voice_note.svg`; medicine type chips use capsule/tablets/pills/injection/drop/ointment/other_medicine; empty states, settings tiles use remaining icons.
- A2 `grep -rn "'/medicine/add'" lib` shows only the FAB-menu handlers (plus route def).
- A3 FAB visible on all 4 tabs; hidden on `/settings`, `/medicine/*`, `/alarm`.
- A4 FAB tap shows 2 options; tap outside or back closes; options meet 44pt/48dp touch target; labels have semantics.
- A5 Voice: mic permission denied -> message + manual fallback. Recognition result never saves directly. Review page shows parsed fields editable; Save writes via existing `MedicineCubit`.
- A6 Parse fixture tests pass: "Paracetamol 500 mg twice a day after food for 5 days" -> name, dosage 500 mg, 2 times, after meal, 5 days. Unparsed fields stay empty, never guessed.
- A7 `flutter analyze` clean (0 issues). `flutter test` passes.
- A8 Settings/History: no hardcoded user-facing English; no deprecated-member infos; dialogs are Cupertino on iOS, Material on Android.

### Risks / open questions
- R1 Speech: no SPM-safe plugin. Use native channel (existing pattern `medify/speech`, see `AppDelegate.swift`, `MainActivity.kt`). Needs iOS `NSSpeechRecognitionUsageDescription` + `NSMicrophoneUsageDescription` in `Info.plist`; Android `RECORD_AUDIO` in manifest. Material decision: confirm OK.
- R2 iOS 26 native tab bar (`useNativeBottomBar: true`) is a platform view. Detached FAB must overlay via `Stack`, positioned above safe area. Verify no tap-through.
- R3 Parse is English only for now. Other locales: voice shows raw transcript in notes, user fills fields.
- R4 `flutter_svg` is pure Dart: no Pods/SPM impact.
- R5 Dark mode: SVGs must be tinted via `ColorFilter`; check svg fills are not hardcoded (inspect each file).

## 2. Implementation guidelines (for Haiku)

Run `git status` first. Work only inside files listed. Stop and report if code conflicts with plan.

### Phase 1: icons
- `pubspec.yaml`: add `flutter_svg: ^2.0.0` under UI & Icons. Run `flutter pub get`, `dart run build_runner build -d` (regenerates `lib/gen/assets.gen.dart`; flutter_gen svg integration needs `flutter_gen: integrations: flutter_svg: true` in pubspec).
- New `lib/core/widgets/medify_icon.dart`: `MedifyIcon(SvgGenImage asset, {double size = 24, Color? color})` wraps `asset.svg(width,height,colorFilter: ColorFilter.mode(color ?? IconTheme.of(context).color!, BlendMode.srcIn))`.
- `lib/core/constants/` or `medicine_type` extension: map `MedicineType` -> `Assets.icons.*`. Reuse enum in `lib/core/database/enums.dart:5`. Put mapper next to `medicine_card.dart` widget.
- Tabs: `lib/app/main_navigation_page.dart`. `AdaptiveNavigationDestination.icon` accepts SF string or IconData only. Keep SF/Cupertino/Material icons for native bar (native bar cannot render SVG). Use SVGs inside Flutter-rendered parts: Android Material bar, FAB, cards, empty states, settings tiles. Android: replace `MedifyAdaptive.tabIcon` material path with SVG widget if API allows custom widget; otherwise keep IconData and document why.
- Replace `Icons.*` in: `medicine_card.dart`, `medicine_list_page.dart` (empty state), `empty_state.dart`, `settings_page.dart` tiles, `schedule_page.dart` where an asset exists (see asset list).

### Phase 2: platform widgets
- Add `lib/core/design/adaptive.dart` helpers: `showMedifyDialog`, `showMedifyTimePicker`, `showMedifyDatePicker`. iOS -> `showCupertinoDialog` / `CupertinoDatePicker` in `showCupertinoModalPopup`; Android -> Material equivalents. Prefer `adaptive_platform_ui` widgets when they exist (`AdaptiveAlertDialog`, `AdaptiveSwitch`, `AdaptiveButton`) before hand-rolling.
- Replace `showTimePicker` at `add_edit_medicine_page.dart:568`, `AlertDialog` in `history_page.dart:465`, `settings_page.dart:777`, `SwitchListTile`-style at `settings_page.dart:61`, `DropdownButtonFormField` in history filter -> adaptive picker/action sheet.

### Phase 3: settings + history fixes
- Move literals to `lib/l10n/app_en.arb` (keys: historyTitle, filterHistory, allMedicines, allStatuses, clearAll, retry, apply, cancel, exportSuccess, exporting, settingsTitle, speakReminder, theme, snoozeDuration, achievements, version, resetSettings, reset). Run `flutter gen-l10n`.
- Fix deprecations: `history_page.dart:479,511` `value` -> `initialValue` (or replaced by adaptive picker); `settings_page.dart:272,618` `withOpacity` -> `withValues(alpha:)`; `history_cubit.dart:140` `Share.shareXFiles` -> `SharePlus.instance.share(ShareParams(files: [...]))`; `medicine_card.dart:2` drop unused import; `add_edit_profile_page.dart:122,190` same fixes.

### Phase 4: FAB + add menu
- New `lib/app/add_medicine_fab.dart`: `AddMedicineFab` stateful. Collapsed: circular button with `Assets.icons.add`. Expanded: scrim + two labeled actions (`Assets.icons.medicine` "Manual entry", `Assets.icons.voiceNote` "Voice input"). Animation via `AnimatedSwitcher`/`AnimationController`, durations from `lib/core/design/tokens/motion_tokens.dart`. Respect `MediaQuery.disableAnimations`.
- `main_navigation_page.dart`: wrap scaffold body in `Stack`; place `AddMedicineFab` bottom-end above the tab bar (`Positioned`, bottom = `MediaQuery.padding.bottom + 64`, end = 16). Android: use Material `FloatingActionButton` via `floatingActionButton` if `AdaptiveScaffold` supports it, else Stack. Hide when current location starts with `/settings`; since shell only wraps 4 tabs, nothing else needed.
- Remove add entry points: `medicine_list_page.dart` `_navigateToAddMedicine`, empty-state `onAction` (replace with hint text pointing to plus), any AppBar add action. Grep `'/medicine/add'`.
- Router `app_router.dart`: keep `/medicine/add`; add `/medicine/add/voice` (builds `VoiceCapturePage`) and make `/medicine/add` accept `state.extra` as `MedicineDraft?` to prefill.

### Phase 5: voice input
- Dart: `lib/core/voice/native_stt_channel.dart` mirroring `native_speech_channel.dart`: `MethodChannel('medify/stt')`, methods `start`, `stop`, event channel `medify/stt/events` for partial/final transcript, errors `permission_denied`, `unavailable`.
- iOS: add to `AppDelegate.swift` using `SFSpeechRecognizer` + `AVAudioEngine`, `requiresOnDeviceRecognition = true` when supported. Add Info.plist usage strings.
- Android: add to `MainActivity.kt` using `SpeechRecognizer` with `EXTRA_PREFER_OFFLINE`. Manifest `RECORD_AUDIO`.
- Parser: `lib/features/medicines/domain/voice/medicine_draft_parser.dart`: pure function `MedicineDraft parse(String transcript)`. Fields: name, dosageAmount, unit, medicineType, timesPerDay -> default `reminderTimes`, intakeTiming (before/after food), durationDays -> endDate, notes = full transcript. Unknown = null. Test: `test/medicine_draft_parser_test.dart` with fixtures from A6.
- UI: `lib/features/medicines/presentation/pages/voice_capture_page.dart`: big mic button (`voice_note.svg`), live transcript, Stop, Cancel. On final transcript -> `context.push('/medicine/add', extra: draft)`. Permission denied -> `AppMessenger.show` + button "Enter manually".
- `add_edit_medicine_page.dart`: constructor gets `MedicineDraft? draft`; seed controllers in `initState`; when draft present show banner "Review voice entry. Nothing saved yet." AppBar action label "Save" unchanged. Do not auto-save.

### Verification (run in order)
```
dart format lib test
flutter gen-l10n
dart run build_runner build -d
flutter analyze
flutter test
```
Manual: run on iOS sim + Android emu, check A3, A4, A5.

### Files allowed to touch
pubspec.yaml, lib/gen/*, lib/l10n/app_en.arb (+generated), lib/app/*, lib/core/design/adaptive.dart, lib/core/widgets/*, lib/core/voice/*, lib/features/{medicines,history,settings,schedule,profiles}/presentation/**, lib/features/medicines/domain/voice/*, test/*, ios/Runner/{AppDelegate.swift,Info.plist}, android/app/src/main/{AndroidManifest.xml,kotlin/**/MainActivity.kt}.
