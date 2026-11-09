# Medify review rules

## Architecture

- Feature-based modular Clean Architecture under `lib/features/<feature>/{domain,data,presentation}`.
- Shared infra only in `lib/core/` (di, database, notifications, theme, widgets, constants).
- App shell in `lib/app/` (`MyApp`, main navigation).
- Prefer Cubits + GetIt patterns already used in the app.
- Prefer imperative `MaterialPageRoute` navigation unless a full router migration is in scope.
- Cubit → Repository is enough; do not invent use-case layers without need.

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
