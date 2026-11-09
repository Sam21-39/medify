# Guidelines: enable Flutter SPM, then remove CocoaPods

Owner decision: enable SPM first, verify a clean iOS build, then delete Pods. Native channel for any plugin without SPM. Do not delete Pods unless the build passes without them.

## Allowed write paths

- Global Flutter config: `flutter config --enable-swift-package-manager` (machine-wide, record the output).
- `ios/Podfile`, `ios/Podfile.lock`, `ios/Pods/` (delete, only in step 4)
- `ios/Flutter/Debug.xcconfig`, `ios/Flutter/Release.xcconfig` (remove the Pods `#include?` lines only)
- `ios/Runner.xcodeproj/project.pbxproj` (remove Pods build phases / references only, if any)
- `ios/.gitignore` (remove `**/Pods/` line only)
- `ios/Runner.xcworkspace/` (remove if it exists only because of Pods; check contents first)

Do not touch: `lib/`, `pubspec.yaml`, `pubspec.lock`, `test/`, `android/`, `docs/adr/`, `docs/architecture/`. Do not commit.

Note: `pubspec.yaml` and `pubspec.lock` may be edited by another agent in parallel (Drift schema). Do not edit them. If `flutter pub get` changes the lock, that is fine; do not hand-edit.

## Steps

1. Baseline. Record in report:
   - `flutter --version`, `xcodebuild -version`
   - `git status --short ios/`
   - `ls ios/Pods | head`

2. Enable SPM:
   - `flutter config --enable-swift-package-manager`
   - `flutter config | grep -i swift`

3. Build without deleting anything:
   - `flutter pub get`
   - `flutter build ios --no-codesign --debug`
   - Record pass/fail and the shortest decisive error line.
   - After: `ls ios/Swift* ios/Flutter 2>/dev/null` and `find ios -maxdepth 3 -name Package.swift` to note SPM packages.
   - Check whether the build still invoked CocoaPods: `grep -i "pod install\|CocoaPods" <build log>`. Save log to scratchpad, not the repo.

4. Decide:
   - If step 3 failed: STOP. Do not delete Pods. Report the failing plugin and the error line. Planner will replace that plugin with a native channel.
   - If step 3 passed: continue to step 5.

5. Delete Pods infrastructure (only after step 3 passed):
   - `rm -rf ios/Pods ios/Podfile ios/Podfile.lock`
   - Remove from `ios/Flutter/Debug.xcconfig` and `ios/Flutter/Release.xcconfig` any line containing `Pods/` (keep `#include "Generated.xcconfig"`).
   - `grep -n "Pods" ios/Runner.xcodeproj/project.pbxproj` → remove only lines that reference Pods build phases or Pods-Runner files. Show diff.
   - Remove the `**/Pods/` line from `ios/.gitignore`.

6. Re-verify:
   - `flutter clean`
   - `flutter pub get`
   - `flutter build ios --no-codesign --debug` must pass with no Pods directory present.
   - `ls ios/Pods 2>/dev/null` must print nothing.
   - `grep -ri "cocoapods\|pod install" ios/ --include=*.pbxproj --include=*.xcconfig --include=*.xcscheme` must print nothing.

7. Report under 25 lines: SPM flag output, build results (step 3 and step 6), files deleted, files edited, any stop reason.

## Stop and report if

- Step 3 build fails for any reason. Do not delete anything.
- `flutter` or `xcodebuild` missing.
- `pbxproj` edit would touch lines outside Pods references.
