# Round 2: remove flutter_tts, then remove CocoaPods

Previous round stopped because flutter_tts still needed CocoaPods. The native channel (medify/speech) now replaces it in lib/ and ios/. Drift slice is finished, so pubspec.yaml is free.

Owner rule: native channel when no SPM. Pods removal happens only after a clean build without Pods.

## Allowed write paths

- `pubspec.yaml`, `pubspec.lock` (via `flutter pub remove flutter_tts` only; no hand edits)
- `ios/Podfile`, `ios/Podfile.lock`, `ios/Pods/` (delete)
- `ios/Flutter/Debug.xcconfig`, `ios/Flutter/Release.xcconfig` (remove Pods `#include?` lines only)
- `ios/Runner.xcodeproj/project.pbxproj` (remove Pods build phases / references only; restore from HEAD first if the only diffs are Pods content, then reapply nothing else)
- `ios/Runner.xcworkspace/contents.xcworkspacedata` (restore from HEAD if only Pods content)
- `ios/.gitignore` (remove `**/Pods/` line only)

Do NOT touch: `lib/`, `test/`, `android/`, `docs/`. Another agent is fixing `android/app/build.gradle.kts`. Do not commit.

Before editing any ios/ file, record `git diff` for it so the report shows what changed.

## Steps

1. Baseline: `git status --short`, `flutter --version`, `ls ios/Pods | head -3`.
2. `flutter pub remove flutter_tts`. Confirm `grep -n flutter_tts pubspec.yaml` prints nothing.
3. Clean and build with Pods still present: `flutter clean && flutter pub get && flutter build ios --no-codesign --debug`. Record pass/fail and whether the log still shows "Running pod install". Save log to scratchpad, not repo.
4. Decision:
   - Build fails: STOP. Do not delete Pods. Report the error line.
   - Build passes and log has no "pod install": go to step 5.
   - Build passes but log still shows "pod install": a plugin still needs CocoaPods. STOP. Report which plugin: `grep -l "" ios/Podfile 2>/dev/null; cat .flutter-plugins-dependencies | python3 -c "import json,sys; [print(p['name']) for p in json.load(sys.stdin)['plugins']['ios']]"`.
5. Delete Pods infrastructure: `rm -rf ios/Pods ios/Podfile ios/Podfile.lock`. Remove the Pods `#include?` lines from both xcconfig files. Restore `ios/Runner.xcodeproj/project.pbxproj` and `ios/Runner.xcworkspace/contents.xcworkspacedata` from HEAD (`git checkout HEAD -- <file>`) only if their current diff is Pods-only; show the diff first. Remove `**/Pods/` from `ios/.gitignore`.
6. Verify, stop on first failure:
   - `flutter clean && flutter pub get`
   - `flutter build ios --no-codesign --debug` must pass
   - `ls ios/Pods 2>/dev/null` must print nothing
   - `ls ios/Podfile ios/Podfile.lock 2>/dev/null` must print nothing
   - `grep -rn "Pods" ios/Runner.xcodeproj/project.pbxproj ios/Flutter/*.xcconfig` must print nothing
   - `grep -n "flutter_tts" pubspec.yaml` must print nothing
   - `flutter test test/core/voice test/database` must pass
7. Report under 20 lines: each step's result, files deleted/edited, the exact build log line for "pod install" (present or absent).

## Stop and report if

- Step 3 build fails.
- Any plugin still needs CocoaPods after flutter_tts is removed.
- A pbxproj diff contains non-Pods changes.
