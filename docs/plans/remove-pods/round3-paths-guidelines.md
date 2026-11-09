# Round 3: remove path_provider (and its CocoaPods plugin) via native paths channel

Why: CocoaPods still runs. Only plugin without SPM in the graph is path_provider_foundation 2.6.0 (locked). drift_flutter 0.3.1 depends on path_provider. Owner decision: drop drift_flutter; use drift + NativeDatabase with a file path from native channel; remove path_provider from pubspec.

## Channel contract

- Name: `medify/paths`
- Method: `documentsDirectory` → returns String absolute path of app documents directory.
  - iOS: `FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path`
  - Android: `context.filesDir.absolutePath` (use filesDir to match path_provider's documents semantics on Android is NOT the same; record that difference in the report; use `context.filesDir`.)
- Error: `PlatformException` code `PATHS_UNAVAILABLE` on failure.

## Allowed write paths

- `pubspec.yaml`, `pubspec.lock` (only via `flutter pub remove drift_flutter path_provider`; `dart pub add drift` only if drift is not already a direct dependency — check first)
- `lib/core/platform/medify_paths.dart` (new): `MedifyPaths.documentsDirectory()` → `Future<String>`, MethodChannel `medify/paths`, throws on error.
- `lib/core/database/app_database.dart`: replace `AppDatabase.open()` (drift_flutter `driftDatabase(name: ...)`) with `NativeDatabase.createInBackground(File(p.join(dir, 'medify_v2.sqlite')))` from `drift/native.dart`. Keep constructor taking `QueryExecutor`. Keep onCreate triggers untouched. Use `package:path` (already direct dependency) for joining.
- `lib/core/database/objectbox_service.dart`: replace `getApplicationDocumentsDirectory()` with `MedifyPaths.documentsDirectory()`. Remove `path_provider` import. Keep `path` import.
- `lib/core/platform/` and any other lib file that imports `package:path_provider` (grep first: `grep -rn "path_provider" lib test`). Replace each the same way. Report the list.
- `ios/Runner/AppDelegate.swift`: add a second channel `medify/paths` in `didInitializeImplicitFlutterEngine`, after the existing speech channel. Use `engineBridge.pluginRegistry.registrar(forPlugin: "MedifyPaths")!.messenger()`. Do not change the speech channel code.
- `android/app/src/main/kotlin/com/sumit/medify/MainActivity.kt`: add `medify/paths` channel in `configureFlutterEngine`, returning `applicationContext.filesDir.absolutePath`. Keep the speech channel code.
- `test/core/platform/medify_paths_test.dart` (new): mock channel returns "/tmp/x" → expect that string; PlatformException → rethrown as expected by the wrapper.

Do NOT touch: `ios/Podfile*`, `ios/Pods/`, `ios/Flutter/*.xcconfig`, `ios/Runner.xcodeproj/**`, `ios/Runner.xcworkspace/**`, `ios/.gitignore`, `android/app/build.gradle.kts`, `docs/`. Do not commit.

## Steps

1. Baseline: `git status --short`. Record.
2. `grep -rn "path_provider\|drift_flutter\|driftDatabase" lib test`. Record every hit.
3. Dart side: create `medify_paths.dart`, update the files in step 2's list.
4. Native side: AppDelegate.swift and MainActivity.kt as above.
5. `flutter pub remove drift_flutter path_provider`. Confirm `grep -n "drift_flutter\|path_provider" pubspec.yaml` prints nothing. Note: `path_provider` may still be present as a transitive dependency through other plugins; check `grep -n "path_provider" pubspec.lock` and report which packages still pull it in.
6. Verify, stop on first failure:
   - `dart format --set-exit-if-changed lib/core/platform lib/core/database test/core/platform test/database`
   - `flutter analyze lib/core test`
   - `flutter test test/core/platform test/database test/core/voice`
   - `flutter build ios --no-codesign --debug` (record pass/fail and whether the log still shows "Running pod install")
   - `flutter build apk --debug` (must pass)
7. Report under 20 lines: files changed, the grep results from step 2, pub remove result, which packages still pull path_provider (if any), test results, the pod-install line from the iOS build log.

## Stop and report if

- A Drift call site needs a change beyond `AppDatabase.open()`.
- `flutter build apk --debug` fails.
- Any test in the verification list fails.
