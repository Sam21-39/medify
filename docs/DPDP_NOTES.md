# DPDP Act 2023 — Requirements Checklist

Captured in Phase 0 so consent-screen (Phase 1.1) and Firestore rules (Phase 1.1/1.6)
work doesn't lose track of these obligations.

## Consent
- A dedicated, explicit consent screen is required before any health-profile
  data (name, blood group, allergies, chronic conditions, emergency contact,
  doctor contact) is collected — separate from general app Terms of Service.
- Consent must be an explicit affirmative action (checkbox/button), not
  implied by continuing to use the app.
- Store a timestamped consent record per user: `users/{uid}/consent` with
  `{ acceptedAt, version }` so consent-version changes can be tracked.

## Data minimization
- No raw health field values (medicine names, dosages, conditions) may be
  sent to third-party analytics SDKs — event names only
  (e.g. `medicine_added`), never field values.
- Caregiver SMS bodies must use a fixed template, never free-text
  interpolation of arbitrary health fields (Cloud Functions, Phase 1.8).
- OCR-captured label images are processed on-device and discarded
  immediately after parse — never uploaded to Storage (Phase 1.9).

## Access control
- Firestore security rules: strict per-`uid` document ownership; no
  client-side cross-user reads ever. Caregiver contacts are phone-number
  metadata only — a caregiver has no read access to the app's data, they
  only receive an SMS (Phase 1.8).
- Cloud Function service accounts scoped to the minimum Firestore paths
  they need (missed-dose scan should only need read on `doseLogs`, not the
  full user document).

## Secrets
- Firebase config / API keys are never committed in plaintext — handled via
  gitignored `env/{dev,staging,prod}.json` consumed through
  `--dart-define-from-file`, populated in CI from GitHub Actions secrets.
