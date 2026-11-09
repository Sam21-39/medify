# Implementation guidelines: dependency spike (step 2)

Audience: `model-implementer` (Haiku). Follow literally. Stop and report on any conflict with the code.

## Allowed write paths

- Create only: `docs/plans/medify-2-0-0-foundation/spike-results.md`
- Scratch work only under: `/private/tmp/claude-501/-Users-sp-Dev-Product-medify/5731fd71-a9d6-458b-a972-7e0e25398d0a/scratchpad/spike/`

Do not edit `pubspec.yaml`, `lib/`, `test/`, `ios/`, `android/`, `docs/adr/`, or `docs/architecture/`. Do not run `flutter pub add` inside the repo. Do not commit.

## Steps

1. Record environment in `spike-results.md`:
   - `flutter --version`, `xcodebuild -version`, `pod --version` (if present), `sw_vers`.
   - Read `/Users/sp/Dev/Product/medify/ios/Podfile` and `ios/Runner.xcodeproj` deployment target (expect 15.0).
2. Create scratch project:
   - `flutter create --platforms=ios,android spike_app` inside the scratchpad `spike/` directory.
   - Set iOS deployment target to 15.0 in `spike_app/ios/Podfile` and the Xcode project.
   - Enable SPM: `flutter config --enable-swift-package-manager` (check current flag name with `flutter config --help` first; record the exact command used).
3. For each candidate, one at a time, add it to the scratch `pubspec.yaml` with `flutter pub add <pkg>`:
   - `drift`, `drift_flutter`, `cryptography`, `image_picker`, `google_mlkit_text_recognition`, `pdf`, `printing`.
   - After each add: `flutter pub get` must succeed.
4. iOS build check, once after all packages are added:
   - `cd spike_app && flutter build ios --no-codesign --debug`
   - Then `ls ios/Pods 2>/dev/null` and record whether any Pods directory was created. Pods present = CocoaPods fallback = that package is a no-go for SPM-only, unless the build passes with SPM and Pods is only from unrelated plugins; record which plugin pulled it in if you can see it in `ios/Podfile`.
   - If the build fails, quote the shortest decisive error line only (not the full log) and mark the responsible package.
5. Android check: `cd spike_app && flutter build apk --debug`. Record pass/fail.
6. Version and date: for each package, run `flutter pub deps` or read `pubspec.lock`. Get publish date from `https://pub.dev/packages/<pkg>` via `curl -s` only if the network is available; otherwise mark `unverified`.
7. Speech/TTS channel feasibility: no package build. Write one paragraph confirming `SFSpeechRecognizer`, `AVSpeechSynthesizer` (iOS) and `SpeechRecognizer`, `TextToSpeech` (Android) are native SDK classes requiring no CocoaPods. Mark verdict `go-with-channel`.
8. Write `spike-results.md` using this table:

| Package | Version | Published | iOS SPM build | Min iOS | Android build | Verdict | Evidence |
|---|---|---|---|---|---|---|---|

Verdict values: `go`, `go-with-channel`, `no-go`, `unverified`.

## Verification

- `spike-results.md` exists and has one row per package in the list above plus the speech/TTS row.
- `cd /Users/sp/Dev/Product/medify && git status --short` shows no new or modified files outside `docs/plans/medify-2-0-0-foundation/`, apart from the pre-existing modified files `ios/Flutter/Debug.xcconfig`, `ios/Flutter/Release.xcconfig`, `pubspec.yaml` and untracked `.claude/`, `docs/adr/`, `docs/architecture/`.

## Stop and report if

- Any package verdict is `no-go` for iOS SPM. Do not substitute a package. Report to planner.
- `flutter` or `xcodebuild` is missing. Mark affected rows `unverified` and report.
- Scratch build needs a network download that is blocked. Record and report; do not retry in a loop.
