# PRD: Medify 2.0.0 foundation (dependency spike, then Drift schema)

## Problem and outcome

Medify 2.0.0 replaces the ObjectBox storage layer with Drift and removes CocoaPods in favour of Swift Package Manager. Current dependencies (`objectbox`, `flutter_tts`, `shared_preferences`) block the iOS SPM goal. Before any schema or code work, we must confirm which replacement packages build on iOS 15 with SPM only. Dependency choices drive the schema and channel design, so they go first.

Outcome of this slice: a go/no-go table for each candidate package, recorded in the repo. No app code changes.

## Scope

In:
- Step 2 of `docs/architecture/medify-2-0-0-release-plan.md`: dependency and SPM compatibility spikes.
- Candidates: `drift`, `drift_flutter`, `sqlite3_flutter_libs` (only if needed), `cryptography`, `image_picker`, `google_mlkit_text_recognition`, `pdf`, `printing`, `share_plus` (already present, re-verify).
- Native channel feasibility for speech (`medify/speech`) and TTS, per ADR 0001.

Out:
- Any change under `lib/`, `test/`, `ios/Runner`, `android/`, or `pubspec.yaml`.
- Drift schema, repositories, migrations (next slice, after this spike is approved).
- Reset gate implementation (ADR 0001).

## Decisions already fixed (do not re-open)

- If a package has no iOS SPM support, use a native platform channel instead. Verdict is `go-with-channel`, not `no-go`. `no-go` only when neither a package nor a native API covers the need.

- ADR 0001 (`docs/adr/0001-reset-legacy-objectbox-storage.md`) governs. Specifically: no `flutter_secure_storage`; `flutter_tts` removed; speech and TTS via custom channels `medify/speech`; Family is local-only.
- Release plan wording "store only secret key material in secure storage" is superseded by ADR 0001. Backup key is derived from passphrase and never stored.
- Build number stays `2.0.0+5`.

## Acceptance checks

1. `docs/plans/medify-2-0-0-foundation/spike-results.md` exists, one row per candidate: package, version, pub.dev publish date, iOS SPM support (yes/no/how verified), Android status, min iOS, verdict (go / go-with-channel / no-go), evidence link.
2. Each row with a verdict was verified by an actual build in a scratch project outside the repo, not by reading docs alone. Where a build was impossible (no Xcode, no network), the row says `unverified` and the reason.
3. Versions chosen are at least two weeks old per the project rule.
4. OCR row states the fallback path from ADR 0001 (Vision via channel on iOS, ML Kit Gradle on Android) if the plugin fails the SPM build.
5. No file in the repo changed except the two new docs under `docs/plans/medify-2-0-0-foundation/`.
6. `git status` shows only those new files, plus pre-existing uncommitted changes unrelated to this task.

## Risks and open questions

- Plugin-level SPM gaps are the main risk. A no-go on OCR or Drift would force a plan change. Stop and report to planner; do not work around it.
- Conflict to surface, not decide: release plan lists `flutter_secure_storage`; ADR removed it. ADR wins unless user says otherwise.
- `drift` iOS native sqlite: confirm which build hook supplies sqlite3 without CocoaPods.
- Xcode version on the machine limits what can be built. Record it.
