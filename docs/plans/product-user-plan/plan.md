# Medify: user-perspective product plan

Status: DRAFT for approval. Planner: Opus. Built from code as of commit `27e6121` plus uncommitted Phase A work, `docs/architecture/user-flow.md`, and `docs/architecture/medify-2-0-0-release-plan.md`.

No user research has been done yet. Everything about users below is a hypothesis to test, not a finding.

---

## 1. Who Medify is for

| Persona | Situation | Core job | What fails them today |
|---|---|---|---|
| **Self-manager (Priya, 34)** | 1–3 meds, busy, phone always on her | "Remind me, then get out of my way." | Fine today. Risk: too many screens, noisy achievements. |
| **Chronic patient (Ramesh, 62)** | 4–8 meds, timed with food, refills monthly | "Never miss a dose, never run out." | Refill stock not proven to decrement. No pause/stop with reason. Small text, English only. |
| **Caregiver (Anita, 40, for her father)** | Manages parent's meds, sometimes remotely | "Know he took them; fix it when he didn't." | Profiles hidden. No missed-dose view for caregiver. No remote link (by design: local only). |
| **Elderly user (Kamla, 75)** | Low vision, low tech confidence, Hindi first language | "Tell me clearly, in my language, what to take now." | English only. Spoken reminder exists but English text. Voice entry English only. |

**Primary for 2.x:** Chronic patient and caregiver-on-same-device. They have the highest cost of failure (missed dose, ran out) and the biggest gap in the current app.

---

## 2. Jobs to be done, ranked by cost of failure

1. **Take the right dose at the right time.** Failure = health harm. Must be reliable even when the app is closed, the phone restarted, or the timezone changed.
2. **Don't run out.** Failure = gap in treatment. Needs correct stock count and a timely refill alert.
3. **Add a medicine correctly.** Failure = wrong reminders for weeks. Needs a review step every time (manual, voice, later camera).
4. **Know what happened.** Failure = can't tell the doctor or caregiver. Needs history with reasons and an export.
5. **Care for someone else.** Failure = caregiver acts on wrong person's data. Needs clear profile switch and isolation.
6. **Stay motivated.** Failure = drop-off. Streaks help some users, annoy others.

---

## 3. Key journeys (user view) and current state

| # | Journey | Current app | Gap |
|---|---|---|---|
| J1 | First run: install → permissions → first medicine | Onboarding + role page exist; permissions in onboarding | First medicine is not offered at the end of onboarding. No limited-mode banner if notifications denied (check). |
| J2 | Daily: notification → Taken / Skip / Snooze | Notification, alarm page, Today list with statuses, snooze setting, spoken reminder | Notification action buttons need device verification. Skip reason not found in UI. No Undo snackbar. |
| J3 | Add medicine (FAB → manual or voice → review → save) | Done this session. Voice on-device; review banner; never auto-saves | Device check pending. Camera/OCR from release plan not built. |
| J4 | Refill: stock low → alert → refill → update count | Fields exist; `RefillReminderService` checks stock | Decrement on Taken unverified. Alert may repeat. No "I refilled" quick action. |
| J5 | Change plan: pause, stop, edit times | Edit exists; DB has `state` and `stop_reason` | No pause/stop UI found. Schedule edits vs history not verified. |
| J6 | Review: history, stats, export for doctor | History with filters, CSV share, stats charts | No PDF report. CSV is not doctor-friendly. |
| J7 | Caregiver: switch to Dad → see missed doses → fix | Repos, schema, pages exist; hidden in nav | Not reachable. No missed-dose view per patient. |
| J8 | Safety: back up, move phone, delete data | Field encryption exists | No backup/restore. Delete-all flow not found. Changing phones = losing all data. |
| J9 | Accessibility: large text, screen reader, language | Semantics added on new widgets; 48dp targets on FAB | No text-size or contrast setting. English only. Large-text layout untested. |

---

## 4. Product principles (decision rules)

1. **Reliability over features.** A reminder that fails once loses trust forever. Fix J2 and J4 before adding anything.
2. **Review before save, always.** No input method writes data without the user confirming.
3. **On-device by default.** Health data does not leave the phone unless the user exports it.
4. **One patient visible at a time.** The active profile is always obvious; switching is explicit.
5. **Optional reasons, never forced.** Asking why a dose was skipped is useful; requiring it is a chore.
6. **Hide what one user doesn't need.** Profile switcher only with 2+ profiles. Achievements opt-out.

---

## 5. Roadmap (Now / Next / Later)

### Now (2.0.x — trust and core loop)
Finish what users touch every day. Ship nothing new until these hold.
- **N1 Finish Phase A**: device checklist for FAB and voice (`docs/plans/feature-roadmap-next/device-checklist.md`). Decide styles.xml lint.
- **N2 Dose loop reliability (J2)**: verify notification actions (Taken/Snooze) from background and killed app; Undo snackbar after Taken/Skip; optional skip reason.
- **N3 Refill correctness (J4)**: Phase D of roadmap — decrement once per Taken, alert once per threshold, "I refilled" action.
- **N4 Pause / stop medicine (J5)**: UI for existing `state` + `stop_reason` columns. Stop reason optional (resolves open question in user-flow.md).
- **N5 First medicine at end of onboarding (J1)**.

### Next (2.1 — care and access)
- **X1 Profiles + caregiver on same device (J7)**: roadmap Phase B. Missed-dose view per patient.
- **X2 Hindi and Bengali (J9)**: roadmap Phase C. Includes fonts, spoken reminders in chosen language, Info.plist strings.
- **X3 Accessibility settings (J9)**: text size, increased contrast, reduced motion; test with largest text, VoiceOver, TalkBack.
- **X4 Doctor report (J6)**: PDF export per patient and date range, on-device.

### Later (2.2+ — safety and convenience)
- **L1 Encrypted backup and restore (J8)**: per release-plan backup contract.
- **L2 Delete all data with export-first (J8)**.
- **L3 Camera/OCR add (J3)**: Latin only, on-device, same review screen.
- **L4 Voice parser for hi/bn**.
- **L5 Remote caregiver link**: needs accounts and sync; out of scope until local caregiver proves value.

**Conflict to resolve:** release plan lists "extra languages" as deferred, but roadmap Phase C plans hi/bn. This plan puts them in Next, because the elderly persona depends on them. Confirm.

**Conflict to resolve:** user-flow.md tabs are Home / Medicines / Family / Settings. App ships Today / Medicines / History / Stats. Proposal: keep current 4 tabs for 2.0; when profiles ship, show caregiver content in Today (missed doses card) rather than adding a tab.

---

## 6. Success measures

No analytics in the app today (privacy-first). Measure through opt-in research and local-only counters shown to the user.

| Measure | Target | How |
|---|---|---|
| Dose logged on time (Taken within window) | ≥ 85% for active users | Local adherence stat (already computed for Stats tab) |
| Reminder delivered when scheduled | 100% in device test matrix | Test plan: killed app, reboot, DST, timezone change |
| Add-medicine completion | ≥ 90% start → save in usability test | Research sessions |
| Voice draft fields correct before edit | ≥ 70% on test phrases | Parser test corpus + sessions |
| Ran out unexpectedly | 0 reports in research cohort | Interview question |
| Caregiver picks wrong profile | 0 in usability test | Research sessions |

---

## 7. User research plan

Goal: validate personas and the Now list before building Next.

- **Who:** 6–8 people. 2 chronic patients 55+, 2 caregivers, 2 elderly users (one Hindi-first), 1–2 self-managers.
- **Method:** 45-min moderated sessions on a release-candidate build, on their own phone if possible.
- **Tasks:**
  1. Add a medicine by voice and by hand.
  2. Respond to a reminder (we trigger it).
  3. Mark a dose skipped and undo it.
  4. Find when you'll run out.
  5. (Caregiver) Switch to another person and check their doses.
- **Questions:**
  - How do you remember medicines today? What fails?
  - Who else is involved in your medicines?
  - Would you trust a spoken entry? What would make you check it?
  - Spoken reminder: helpful or annoying? How many repeats?
  - What would you show your doctor?
- **Output:** findings doc in `docs/research/`, then re-rank Next and Later.

---

## 8. Risks

- **Silent reminder failure** (OS kills app, exact-alarm permission on Android 12+, iOS notification limits of 64 pending). Highest risk to trust. Needs the device test matrix in N2.
- **Data loss on phone change** until backup ships (L1). Mitigation: show CSV/PDF export prominently; message in Settings.
- **Voice mis-parse** shown as fact. Mitigation exists (review screen); add low-confidence highlighting.
- **Profile data bleed** when caregiver ships. Mitigation: filter in repositories, isolation test (roadmap B-2).
- **Translation quality** for medical terms. Mitigation: native-speaker review before release.

---

## 9. Decisions made (2026-11-11)

1. **Persona priority:** caregiver first. Build X1 (same-phone caregiver) before the chronic-patient-only items.
2. **Build order:** Now list (N1–N5) next, before profiles and languages.
3. **Hindi and Bengali:** deferred. Stays out of Next; revisit after research.
4. **Tabs:** keep Today / Medicines / History / Stats for 2.0. Caregiver content goes in Today.
5. **Achievements:** streak card on Home. Full list stays in Settings.
6. **Order of work:** research before Next, then build Next.

Sequence: Now (build) → research sessions (7, section 7) → re-rank → Next (caregiver first) → Later.

## 10. Decisions still open

- Stop-medicine reason: optional or required (user-flow.md open question).
- Delete data flow: confirm the wipe-then-onboarding behaviour in user-flow.md.

## 11. Decisions needed (resolved above; kept for reference)

1. Approve persona priority: chronic patient + same-device caregiver first.
2. Approve Now list (N1–N5) as the next build batch, ahead of profiles and languages.
3. Languages: move hi/bn to Next (this plan) or keep deferred (release plan)?
4. Tabs: keep Today / Medicines / History / Stats for 2.0?
5. Achievements: Home streak card, Settings list, or opt-out toggle?
6. Run research sessions before Next, or build Next in parallel?
