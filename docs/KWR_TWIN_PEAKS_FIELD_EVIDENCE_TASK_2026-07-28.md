---
id: KWR-031
title: Review and preserve Twin Peaks Alpha 28 field evidence
owner: codex
priority: high
risk: low
dependencies:
  - RELEASE_VISION.md
affected_modules:
  - UI/MainWindow.lua
  - UI/MainWindowPages.lua
  - UI/CombatRoster.lua
  - UI/CombatRosterVisuals.lua
  - Runtime/Sensors.lua
  - Runtime/AAR.lua
  - QA_CHECKLIST.md
  - BATTLEGROUND_VERIFICATION.md
---

# Objective

Convert the supplied Twin Peaks screenshots into durable release evidence,
identify confirmed pass/fail states, and route observed defects to their
existing owners and release gates.

# User outcome

The field session advances testing instead of remaining an unstructured group
of screenshots. Confirmed working behavior is retained, visible failures are
not marked as passed, and the next field session has a bounded evidence list.

# Current behavior

Fourteen screenshots captured an Alpha 28 Twin Peaks Standard session:

- lobby and compact surfaces;
- all six Command Center pages;
- the live opening;
- a live enemy score change and player death;
- an urgent carrier-recovery state;
- final `0-3` defeat, AAR, Team, Enemies, and Assignments state.

The screenshots show substantial working live behavior, but they do not
include `/kwr verify`, `/kwr perf`, `/kwr evidence`, BugSack output, final-match
state, or instance-exit state.

# Required behavior

- Preserve the screenshots under a stable repository evidence path.
- Record dimensions, capture order, and SHA-256 hashes.
- Separate visible proof from inference.
- Trace visible failures to the existing UI, sensor, AAR, and QA boundaries.
- Update Twin Peaks and QA status without claiming full map certification.
- Do not change runtime behavior until the confirmed defects receive bounded
  implementation tasks and deterministic coverage.

# Non-goals

- No claim that Twin Peaks is fully verified.
- No taint, performance, error-free, or match-exit pass without the required
  diagnostics.
- No automatic repair based only on visual inference.
- No Sentinel acceptance closure; Sentinel is not visibly present in this
  evidence set.

# Technical constraints

- Unknown evidence must remain unknown.
- A merely visible or recently seen enemy must not become a commander kill
  target without the reviewed local-fight gate.
- Historical specialization provenance must remain visible across surfaces.
- Direct health display must respect Retail secret-value restrictions.
- AAR diagnosis must preserve existing history until duplicate-entry behavior
  is reproduced or disproved.

# Acceptance criteria

- [x] All fourteen screenshots are cataloged in capture order.
- [x] Evidence files have stable names and SHA-256 hashes.
- [x] Confirmed live passes are recorded.
- [x] Confirmed health and provenance failures are recorded.
- [x] Resolution/readability concerns are routed to the screenshot matrix.
- [x] AAR history concerns are labeled `NEEDS DATA`, not asserted as fact.
- [x] Twin Peaks remains partial rather than falsely certified.
- [x] Repository validation passes after the evidence update.

# Verification

1. Review `docs/field-evidence/2026-07-28-twin-peaks/README.md`.
2. Confirm all fourteen image hashes against the preserved PNG files.
3. Confirm QA and battleground matrices link to the evidence record.
4. Run `tools/validate.ps1`.

# Rollback

Remove this task and the dated evidence directory, then revert only the Twin
Peaks/QA evidence notes. No runtime or saved-variable behavior changes in this
task.
