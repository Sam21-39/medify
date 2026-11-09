# Medify review rules

## Architecture

- Keep Clean Architecture layering: `domain` / `data` / `presentation` / `core`.
- Prefer Cubits + GetIt patterns already used in the app.
- Prefer imperative `MaterialPageRoute` navigation unless a full router migration is in scope.

## Flutter / Dart

- Target Flutter 3.47.x and Dart 3.13.x constraints in `pubspec.yaml`.
- Do not suggest `google_fonts` for Nunito; fonts ship as local assets.
- Generated ObjectBox / l10n files are ignored; ask for `build_runner` when generators are missing.

## Native

- Android: AGP 9.1.x, Gradle 9.3.x, Kotlin 2.4.x, Java 17, `android.builtInKotlin=false` / `android.newDsl=false` until plugins migrate.
- iOS: Swift Package Manager only. No CocoaPods.

## Product

- Accessibility and elderly-friendly UX matter (large targets, clear contrast).
- Privacy-first: no secrets in source; keep keystore / `key.properties` out of git.
