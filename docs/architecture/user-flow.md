# Medify User Flow

Top-level navigation, onboarding, and role flows for Medify.

```mermaid
flowchart TD
    A(["App Open"]) --> B["Splash 2-3s"]
    B --> C{"Returning user?"}
    C -- "Yes" --> NAV
    C -- "No" --> O1

    subgraph ONB["First-run Onboarding (skippable, resumable)"]
        O1["Step 1: What Medify does"] --> O2["Step 2: Permissions<br/>with reason per permission"]
        O2 --> O2A{"Granted?"}
        O2A -- "Denied" --> O2B["Limited-mode banner<br/>reminders off, retry later"]
        O2A -- "Granted" --> O3
        O2B --> O3
        O3["Step 3: Who are you?"] --> ROLE{"Role"}
    end

    ROLE -- "Patient" --> PAT["Create own profile<br/>name, age, relation: self"]
    ROLE -- "Caregiver / Family" --> LINK{"Link model"}

    LINK -- "One-way invite" --> INV1["Create or accept invite<br/>caregiver gets access"]
    INV1 --> INVP{"Patient accepts?"}
    INVP -- "Pending" --> PEND["Pending card on Home<br/>caregiver sees nothing yet"]
    INVP -- "Accepted" --> SCOPE
    PEND -. "accepted later" .-> SCOPE

    LINK -- "Shared account" --> SHR["One login, add patient<br/>profiles under it"]
    SHR --> SCOPE

    PAT --> ADDMED{"Add first medicine now?"}
    SCOPE["Patient profile(s) ready"] --> ADDMED
    ADDMED -- "Yes" --> REV
    ADDMED -- "Later" --> NAV

    NAV[["Bottom Nav Bar<br/>tabs adapt to role"]]

    NAV --> T1["1. Home"]
    NAV --> T2["2. Medicines"]
    NAV --> T3["3. Family / Caregivers"]
    NAV --> T4["4. Settings"]
    NAV --> T5(("5. + FAB"))

    PS{{"Patient switcher<br/>shown only if 2+ patients<br/>global, persists across tabs"}}
    PS -. "scopes" .-> T1
    PS -. "scopes" .-> T2
    PS -. "scopes" .-> T3

    subgraph HOME["1. Home"]
        T1 --> H1["Today's schedule<br/>next dose first"]
        H1 --> H2["Dose actions<br/>Taken / Skip + reason / Snooze"]
        T1 --> H3["Timeline<br/>Taken / Upcoming / Missed"]
        T1 --> H4["Adherence chart<br/>last 7 days"]
        T1 --> H5["Streak card<br/>links to Achievements"]
        H2 --> H6{"Missed past window?"}
        H6 -- "Yes" --> H7["Missed card: ask reason<br/>skip the reason is allowed"]
    end

    subgraph MEDS["2. Medicines"]
        T2 --> M1["Medicine list<br/>active / paused / finished"]
        M1 --> M2["Medicine detail<br/>dose, schedule, stock, notes"]
        M1 --> M3["Filters<br/>status, time of day, low stock"]
        M1 --> M4["History<br/>per patient, per medicine"]
        M2 --> M5["Edit / pause / stop<br/>stop asks reason"]
    end

    subgraph FAM["3. Family / Caregivers"]
        T3 --> F1{"Role of current user"}
        F1 -- "Caregiver" --> F2["Patients list<br/>name, age, relation"]
        F1 -- "Patient" --> F3["Caregivers list<br/>access level, revoke"]
        F2 --> F4["Missed / skipped doses<br/>+ reason"]
        F4 --> F5["Filters<br/>date range, reason, medicine"]
        F4 --> F6["History per patient"]
    end

    subgraph SET["4. Settings"]
        T4 --> S1["1. Theme<br/>light / dark / system"]
        T4 --> S2["2. Accessibility<br/>text size, contrast, voice-over hints"]
        T4 --> S3["3. Notifications & Alerts<br/>per-medicine, quiet hours"]
        T4 --> S4["4. Achievements<br/>full list, streaks"]
        T4 --> S5["5. Reports & Backup<br/>PDF export, backup and restore"]
        T4 --> S6["6. About / Privacy / T&C"]
        T4 --> S7["7. Delete data<br/>type DELETE to confirm"]
        S7 --> S8{"Export first?"}
        S8 -- "Yes" --> S5
        S8 -- "Continue" --> S9["Wipe local DB<br/>cancel notifications<br/>revoke links"]
        S9 --> O1
    end

    subgraph FAB["5. FAB: Add medicine"]
        T5 --> A1{"Input method"}
        A1 --> A2["Manual: type name"]
        A1 --> A3["Voice: speak name and dose"]
        A1 --> A4["Camera: photo of pack"]
        A2 --> REV
        A3 --> REV
        A4 --> OCR["OCR, then name match"] --> REV
    end

    REV["Review screen (always)<br/>editable fields, low-confidence<br/>fields highlighted, name matched<br/>to database"] --> CONF{"Confirm for patient"}
    CONF -- "Edit" --> REV
    CONF -- "Save" --> SAVE["Save to selected patient<br/>schedule reminders"]
    SAVE --> UNDO["Snackbar with Undo"] --> T1
```

## Notes

- **Link model covers both cases.** One-way invite: caregiver is a separate account with scoped access, patient can revoke. Shared account: one login manages several profiles, no per-person permissions. Choose per patient, not app-wide.
- **Tabs adapt to role.** Patient sees "Caregivers" (access list). Caregiver sees "Patients" (missed doses, members). Same tab slot, different content.
- **Patient switcher is hidden with one patient.** Shows only when 2+ profiles exist, so single-patient users see no extra UI.
- **Review screen is the only save path** for manual, voice, and camera. Low-confidence OCR or voice fields are highlighted, so a wrong medicine name never saves silently.
- **Missed-dose reason is optional.** Asking is useful for the adherence report, but a required field would turn a forgotten dose into a chore. "Skip reason" and "no reason" are both valid.
- **Achievements moved toward Home.** Under Settings it is hard to find, so it appears as a streak card on Home and the full list stays in Settings.
- **Delete data offers export first.** Deleting health data is irreversible, so backup is the default, not an afterthought.

## Minimal architecture

- One dose-event model: `scheduled → taken | skipped(reason) | missed`. Home, adherence chart, history, and reports are all views of it.
- Offline-first local DB is the source of truth. Reminders fire without network. Sync is additive.
- BLoC per feature (Home, Medicines, Family, Settings, Add) plus one global `PatientScope` for the switcher and role.

## Open questions

- Settings → Delete data → Continue wipes DB and returns to onboarding. Confirm intended.
- Achievements shown on Home (streak card) and in Settings. Pick one source of truth.
- Stop medicine "asks reason" is not marked optional, unlike missed-dose reason. Confirm.
