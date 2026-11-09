# PRD: Step 3, Drift schema (first slice)

## Problem and outcome

Medify 2.0.0 replaces ObjectBox with Drift (ADR 0001). This slice creates the Drift database and its tables, typed settings, installation metadata, and schema tests. Nothing in the app reads from it yet. Legacy ObjectBox code keeps running untouched until the reset gate and repository slices.

Outcome: `lib/core/database/` holds a tested Drift schema matching the release plan data model, with constraints enforced in SQL.

## Scope

In:
- Drift database class, tables, `PRAGMA foreign_keys = ON`, schema version 1.
- Tables: `profiles`, `medicines`, `schedules`, `occurrences`, `achievements`, `settings`, `installation_metadata`.
- Enums stored by name (`textEnum`), never index. Achievement types are stable string values.
- `occurrences`: unique key on (`schedule_id`, `scheduled_at_utc`); status CHECK; FKs.
- Packages added to `pubspec.yaml`: `drift`, `drift_flutter`, `sqlite3_flutter_libs` only if `drift_flutter` requires it (check its README), dev: `drift_dev`. Latest stable, published at least two weeks ago.
- Schema snapshot dump and an in-memory test suite.

Out (later slices):
- Reset gate, journal, legacy deletion (ADR 0001 §3–5).
- Repository rewrite. ObjectBox and `shared_preferences` stay in place.
- `flutter_secure_storage` (added with backup slice).
- Native channels (speech, TTS, OCR). Separate PRD.

## Decisions fixed

- ADR 0001 governs reset and storage. Release plan governs table list.
- Native channel for any feature whose package lacks iOS SPM support (owner rule). Drift is pure Dart plus sqlite; no channel planned.
- Build number stays `2.0.0+5`.
- Profiles and family are in scope (owner decision). Local-only household, no accounts.

## Acceptance checks

1. `dart run build_runner build` (or `dart run drift_dev`) generates `app_database.g.dart` without errors.
2. `flutter analyze` reports zero new issues in `lib/core/database/`.
3. Tests pass: foreign key enforcement; CHECK rejects invalid status; unique occurrence key rejects duplicate; enum round trip stores name; patient-scoped rows cannot reference another patient's medicine through `schedules`.
4. Schema dump saved under `lib/core/database/drift_schemas/` (version 1).
5. `git diff --stat` shows changes only in `pubspec.yaml`, `pubspec.lock`, `lib/core/database/`, `test/database/`, and generated files.
6. ObjectBox and `shared_preferences` code unchanged.

## Risks and open questions

- Drift version may need the build hook path; confirm with `drift_flutter` docs before adding `sqlite3_flutter_libs`.
- Legacy `profileId` maps to `profile_id`. Legacy `reminderTimes` (seconds list) and `daysOfWeek` become normalised `schedules` rows, not columns. Confirm mapping in guidelines.
- Release plan says `status` per occurrence and `dose snapshot`. Snapshot columns mirror medicine dose fields at generation time.
