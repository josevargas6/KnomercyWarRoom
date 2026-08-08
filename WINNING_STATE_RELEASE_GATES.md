# KWR Winning-State Release Gates

`RELEASE_VISION.md` owns the suite release direction. This file owns the
Commander `6.1.0-alpha.28` offline and Retail promotion gates.

This file is the repo-native release gate companion to
`WINNING_STATE_EXECUTION_MAP.md`.

Use it to answer one question:

What still must be proven before the current alpha can be promoted beyond
focused field testing?

## Gate policy

- A gate is `OFFLINE PASS` only when current repo evidence proves it.
- A gate is `LIVE REQUIRED` when the code path may already be complete but the
  proof must come from the Retail client.
- A gate is `OPEN` when the repo still needs offline work before live proof is
  even meaningful.
- A failed live gate drops the candidate back below promotion quality.

## Current gate board

| Gate | Status | Proof source | Notes |
| --- | --- | --- | --- |
| Runtime validation | `OFFLINE PASS` | `tools/validate.ps1` | Current worktree validates cleanly. |
| Deterministic smoke | `OFFLINE PASS` | `tests/smoke.lua` | Current smoke baseline passes. |
| Bounded refresh soak | `OFFLINE PASS` | `tests/soak.lua` | 500-refresh soak gate passes. |
| One primary command-center path | `OFFLINE PASS` | command-center routing + minimize slices | Default entry points now route to the command-center path. |
| Optional Sentinel packaging gate | `OFFLINE PASS` | `tools/build.ps1` | Sentinel is excluded from the default release bundle and ships only through `-IncludeSentinel`. |
| Command grammar normalization | `OFFLINE PASS` | core UI copy audit + `tests/smoke.lua` | Primary surfaces, support-view wording, review headings, and shell naming now follow the command-center contract offline. |
| Repo-native winning-state docs | `OFFLINE PASS` | repo docs set | Zip plan is translated into repo-native execution files. |
| Visual QA matrix | `OFFLINE PASS` | `LIVE_VISUAL_SCRUB_WORKSHEET_2026-07-12.md` | Working tester matrix exists in-repo; needs field completion, not more offline structure. |
| Release checklist synchronization | `OFFLINE PASS` | `RELEASE_READINESS.md`, `QA_CHECKLIST.md` | Repo-native readiness and QA files are synchronized to the current command-center candidate and current offline proof posture. |
| Zero Lua errors across 20 battlegrounds | `LIVE REQUIRED` | field log | Release-blocking live gate. |
| Zero taint / blocked-action events | `LIVE REQUIRED` | field log | Release-blocking live gate. |
| P95 refresh under field budget | `LIVE REQUIRED` | `/kwr perf` evidence | Offline soak is complete; live budget proof remains. |
| Memory growth within budget | `LIVE REQUIRED` | 30-minute field evidence | Must be measured after GC in-client. |
| Resolution / UI-scale screenshot matrix | `LIVE REQUIRED` | screenshot pack | Twin Peaks 2026-07-28 provides partial 1592x982-class and 2558x1438 evidence; truncation/position behavior remains open. |
| Map-family behavior proof | `LIVE REQUIRED` | `BATTLEGROUND_VERIFICATION.md` evidence | Twin Peaks has partial score/native-map/roster/final-AAR/flag-event evidence, but Team health/provenance, command stability, flag-target grammar, diagnostics, exact carrier truth, history count, and exit remain open. All other supported battlegrounds still require field certification. |

## Offline completion rule

Offline execution is done only when:

1. every `OPEN` gate above is closed by repo evidence;
2. every affected proof file is updated to match the current candidate; and
3. the only remaining gates are marked `LIVE REQUIRED`.

## Live promotion rule

The addon is eligible for broader release promotion only when:

1. every `LIVE REQUIRED` gate has captured evidence;
2. no new `P0` or `P1` defect appears during field certification; and
3. the current package still passes the offline gates after the last field fix.
