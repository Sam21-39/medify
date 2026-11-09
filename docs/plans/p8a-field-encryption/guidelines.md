# Guidelines: P8a field-level encryption

Owner decision: field-level encryption, not SQLCipher (SQLCipher plugin needs CocoaPods on iOS; SPM-only rule). Native SQLite encryption is NOT provided by this slice. Report that clearly in any user-facing summary.

Packages (verified):
- `cryptography` (pure Dart): AES-256-GCM. Latest stable published ≥14 days ago.
- `flutter_secure_storage`: iOS darwin plugin `flutter_secure_storage_darwin` 0.4.3 ships `Package.swift` (SPM OK). Use the version resolved by the newest `flutter_secure_storage` release that depends on it; confirm `pubspec.lock` shows no CocoaPods requirement after `flutter build ios`.
- `crypto` is NOT used for encryption (hash/HMAC only). Do not add it.

## Read first

- `docs/adr/0001-reset-legacy-objectbox-storage.md` (amendment; "Related decisions": secure storage reinstated for key material)
- `lib/core/database/schema.dart`, `medify_database.dart`
- `lib/features/medicines/data/sqflite/medicine_row_mapper.dart`, `lib/features/profiles/data/sqflite/profile_row_mapper.dart`, `lib/features/schedule/data/sqflite/medicine_log_row_mapper.dart`
- Repos under `lib/features/*/data/sqflite/`

## Encrypted columns (decided)

- `profiles.name`, `profiles.notes`
- `medicines.name`, `medicines.notes`, `medicines.stop_reason`
- `occurrences.skip_reason`

Plain (needed for queries, FKs, uniqueness, ordering): ids, `*_utc` and `local_date`, status/state/enum columns, quantities, weekdays, times, flags, `color_value`, `relation`, `role`.

Known consequence: name-based duplicate checks (`isProfileNameExists`) and any name search must decrypt and compare in Dart. Report every such method.

## Allowed write paths

- `lib/core/security/**` (new):
  - `field_cipher.dart`: `FieldCipher` with `Future<String> seal(String plain)` and `Future<String> open(String stored)`. Format: `v1.<base64 nonce 12 bytes>.<base64 ciphertext+tag>`. AES-256-GCM with random nonce per write. `open` of a value without the `v1.` prefix is an error (no silent plaintext fallback). Null in → null out.
  - `key_store.dart`: `DatabaseKeyStore` reads or creates a 32-byte random key stored in `flutter_secure_storage` under key `medify.db.key.v1` (base64). Creation only when the key is absent. A read error is NOT treated as absent: throw `KeyStoreUnavailable`. Never delete the key from here.
  - `security_exceptions.dart`.
- `lib/features/*/data/sqflite/*_row_mapper.dart` and repos: encrypt on write, decrypt on read, for the columns above only. Make mappers take `FieldCipher` as a parameter; do not construct it inside.
- `pubspec.yaml`, `pubspec.lock`: `flutter pub add cryptography flutter_secure_storage` (check versions age).
- `test/core/security/**` (new), tests for repos touched (`test/features/**/data/sqflite/**`).

Do NOT touch: `lib/main.dart`, `lib/core/di/**`, `lib/core/transition/**`, `lib/features/transition/**` (P3 in progress), `lib/core/notifications/**`, `lib/core/database/schema.dart` (schema unchanged: encrypted values are still TEXT), `ios/Podfile*`, `ios/Runner/AppDelegate.swift` and `android/**` unless a plugin needs setup (report first), `docs/**` (except report). Do not commit.

## Rules

- Key is generated once and never regenerated automatically. If the key is missing but an encrypted DB has rows, do not overwrite: throw `KeyMismatch` (mapping for P9 handling).
- Secure-storage failure blocks every secret-dependent operation (repo open). It never deletes data and never implies fresh install.
- AES-GCM authentication failure on `open` → `CorruptField` exception. Do not return partial data.
- No logging of plaintext or key material.

## Steps

1. Baseline `git status --short`.
2. Add packages. Run `flutter pub get`.
3. `field_cipher.dart` + tests: round trip; tampered ciphertext → exception; wrong prefix → exception; nonce differs per call.
4. `key_store.dart` + tests with a fake secure storage interface (inject `FlutterSecureStorage` behind an interface `SecretStore`): creates when absent; reads when present; read error → `KeyStoreUnavailable`; does not overwrite existing key.
5. Update row mappers and repos for the encrypted columns. Repo constructors take `FieldCipher`.
6. Tests: encrypted columns stored as `v1.` values in raw SQL (`SELECT name FROM medicines`); decrypt on read; plain columns unchanged; duplicate profile-name check still works.
7. Verification, stop on first failure:
   - `dart format --set-exit-if-changed lib/core/security lib/features/medicines/data/sqflite lib/features/profiles/data/sqflite lib/features/schedule/data/sqflite test/core/security test/features`
   - `flutter analyze lib test` (only pre-existing info issues allowed)
   - `flutter test test/core/security test/features test/database test/core/database`
   - `flutter build ios --no-codesign --debug` (must pass; log must not contain "pod install")
   - `flutter build apk --debug` (must pass)
   - `grep -rn "sqlcipher\|crypto:" pubspec.yaml` must print nothing

## Report (under 25 lines)

Files, packages and versions with publish dates, test results, both build results, methods that now decrypt in Dart (duplicate checks, searches), any column that needed a decision.

## Stop and report if

- `flutter build ios` shows CocoaPods (pod install) after adding the packages.
- A repo needs an encrypted column for a query, FK, or unique key.
- Any build fails.
