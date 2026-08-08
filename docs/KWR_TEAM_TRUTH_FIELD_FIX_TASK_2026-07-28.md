---
id: KWR-032
title: Repair expanded Team health and specialization provenance
owner: unassigned
priority: high
risk: medium
status: LIVE_ONLY_REMAINDER
dependencies:
  - docs/field-evidence/2026-07-28-twin-peaks/README.md
affected_modules:
  - Runtime/Sensors.lua
  - UI/MainWindow.lua
  - UI/MainWindowPages.lua
  - UI/CombatRosterVisuals.lua
  - tests/smoke.lua
---

# Objective

Close the two P1 Team-page trust defects confirmed by the 2026-07-28 Twin
Peaks field evidence.

# User outcome

The expanded Team page presents usable legal friendly health and the same
specialization provenance as the compact roster, without unsafe secret-value
arithmetic or fabricated certainty.

# Current behavior

- Compact Team rows show live health values, while the expanded Team page shows
  empty/dim bars with no useful health text for the same connected roster.
- Compact Team rows label historical specializations `(HIST)`, while the
  expanded Team page shows the same specialization names without provenance.

# Required behavior

- When a stable friendly unit token exists, bind the expanded Team StatusBar to
  legal direct health values without comparing or performing arithmetic on
  secret values.
- Show bounded health text such as a safe abbreviated value, percentage when
  normalized public data exists, or `LIVE`; never leave a successful direct
  display visually indistinguishable from unknown.
- Preserve explicit `UNKNOWN` when no legal unit or normalized health exists.
- Preserve `specSource` through roster reconciliation and render `(HIST)` on
  every Team/assignment surface that displays historical specialization
  evidence.
- Keep live/verified specialization evidence free of the historical label.
- Do not alter assignment roles, strategy, targeting, focus, or secure
  attributes.

# Non-goals

- No enemy secret-health inference.
- No new health polling loop.
- No automatic inspect behavior.
- No redesign of the Team page.
- No unrelated resolution or AAR changes.

# Technical constraints

- Retail secret values may be passed to protected/native display primitives
  only where allowed; they must not be compared, divided, rounded, or converted
  to strings.
- Reuse the existing runtime refresh and direct-health boundaries.
- Historical evidence remains advisory and visibly labeled.
- Add deterministic coverage for normalized, direct-live, unknown, historical,
  cached, and verified states.

# Acceptance criteria

- [x] Expanded Team health bars visibly render for legal friendly unit tokens.
- [x] Direct-live health does not perform secret-value arithmetic; direct values
  are passed only to native status-bar primitives and display `LIVE`.
- [x] Unknown health remains explicitly `UNKNOWN`.
- [x] Historical friendly specs show `(HIST)` on compact and expanded Team
  surfaces.
- [x] Verified/live specs do not show `(HIST)`.
- [x] Assignments preserve the same specialization provenance.
- [x] Deterministic tests cover normalized, direct-live, unknown, historical,
  cached, verified, and cross-surface contracts.
- [x] Validate, knowledge audit, smoke, and soak pass.
- [ ] A new in-client screenshot confirms both repairs.

# Offline implementation result

Reopened on 2026-08-03 as an offline implementation blocker. The direct-health
renderer was repaired to avoid secret-value arithmetic, while the existing
roster reconciliation and `RosterPresentation:SpecLabel` path preserve
provenance across Team and Assignments. Deterministic evidence is recorded by
the final smoke/soak gate; the screenshot remains live-only.

# Verification

1. Run `tools/validate.ps1`.
2. Run `tools/knowledge-audit.ps1`.
3. Run `fengari tests/smoke.lua`.
4. Run `fengari tests/soak.lua`.
5. Open the expanded Team and Assignments pages in a live battleground.
6. Compare the same players against the compact Team rows.
7. Capture one historical and one verified specialization if available.

# Rollback

Restore the prior Team render/fallback behavior and its tests. No saved-variable
migration is required.
