---
id: KWR-270
title: Stabilize live battlefield refresh and command lifecycle
owner: Codex
priority: critical
risk: medium
status: in_progress
dependencies: [KWR-269]
affected_modules: [Runtime, Core, tests, docs]
authority_references: [AGENTS.md, DESIGN_CONTRACT.md, QA_CHECKLIST.md, RELEASE_READINESS.md]
---

# KWR-270 - Live Field Performance and Stability

## Objective

Use the supplied Battle for Gilneas field evidence to remove avoidable refresh work,
prevent terminal commands from being counted repeatedly, and bound live verification
retention without weakening tactical truth gates.

## User outcome

The local test build remains responsive and issues stable, explainable battlefield
calls during a full battleground rather than degrading under health/aura event volume.

## Current behavior

The field run recorded 104,898 lightweight health/aura events but still performed
1,790 full pipeline refreshes (20.211 ms average / 33.678 ms P95). It also recorded
repeated `PLAY_EXPIRED` invalidations after terminal plays and retained 60 oversized
verification entries, reaching 46.89 MB addon memory.

## Required behavior

- Health/aura observation that cannot change tactical truth must remain lightweight.
- A terminal ActivePlay transition is recorded once, then a new candidate begins cleanly.
- The verification ledger remains useful for its compact timeline report without
  retaining complete strategy snapshots.

## Non-goals

No doctrine changes, automation, external publishing, account data upload, or UI redesign.

## Technical constraints

Preserve the existing `MatchRuntime` event owner, the current command lifecycle, and
the direct current-report detail. Ledger compaction must not change `/kwr verify`.

## Acceptance criteria

- [x] Non-carrier health/aura events do not schedule a full strategic refresh.
- [x] Repeated refreshes after a terminal play do not increment invalidation metrics.
- [x] Ledger entries contain only the fields used by the timeline report.
- [x] Lua smoke, validation, bounded soak, reproducibility, and extracted-package checks pass.
- [x] A rebuilt local package is ready for the next user field test.
- [x] The package is installed into both local AddOns folders with WoW stopped.
- [ ] A fresh full-RBG `/kwr perf` and `/kwr verify` capture confirms the live budget.

## Verification

1. Run validation and Lua smoke tests.
2. Run the local soak/performance checks.
3. Build the local candidate and require a fresh `/kwr perf` plus `/kwr verify` capture.

## Current evidence

- `validate.ps1`: PASS.
- `test-lua.ps1 -Suite Smoke`: PASS, 276 checks.
- Full package build: reproducibility PASS; package audit PASS; extracted
  Commander and developer runtime PASS; Commander 398 entries, Sentinel 12.
- Candidate package SHA-256: Commander
  `8D18F9E79B4575A2AEBF19D4A67CA3AE5E6E1C1D91BFB86CE7324C85E08961C9`;
  Sentinel `DF9033BF457A9B630C09A2DBD39B58D200B7B867BD8A5AA0441676C8D4C39D9E`.
- Deployment was deferred until WoW exited, then completed through the guarded
  manifest-audit workflow.
- Deployed after WoW exited: Commander manifest audit PASS (398/398) and
  Sentinel manifest audit PASS (12/12), both with zero missing, changed, or
  extra files. Rollback snapshot:
  `D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KWR-Rollbacks\KWR-270-live-performance-test-20260819`.
- `deployment-certify.ps1` remains intentionally inapplicable: it correctly
  requires a committed clean source tree, while this user test candidate is
  deliberately an uncommitted local worktree.
- Follow-up optimization: live strategy now consumes compact scenario summaries
  instead of cloning full calibration and expert-corpus rows on every refresh;
  verification ledger updates build a compact record directly.
- Follow-up validation: smoke PASS (276 checks), bounded soak PASS (0.242 ms
  average / 0.800 ms P95 / 3.200 ms max), validation PASS, reproducibility
  PASS, and package audit PASS (Commander 398, developer 8969, Sentinel 12).
- Follow-up deployed candidate: Commander SHA-256
  `91EA5B1AE188C1050218A23EB56BF8AFBA8820A5FE4613738650D443010576AC`;
  Sentinel SHA-256
  `C22E8E44F20D888F5F17771674D2B24FDFBD7D816B0EECDF114F35189CC3479A`.
  Deployment manifest audits PASS with zero missing, changed, or extra files;
  rollback snapshot:
  `D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KWR-Rollbacks\KWR-270-runtime-copy-fix-20260819`.
- Fresh-client WORLD evidence confirms the runtime-copy candidate loaded: audit
  PASS, no runtime errors, 18.39 MB measured addon memory, 3.234 ms latest
  refresh, 3.904 ms maximum, and live stage telemetry. It is preflight-only:
  eight samples, no battleground state, no health/aura load, and no match AAR
  cannot certify the field budget.
- Telemetry qualification follow-up prevents a sub-ten-sample client from
  displaying `0.000 ms` as a P95 result; reports now state that P95 is pending
  until the first ten samples. Validation and smoke PASS (276).
- Follow-up package audit/reproducibility PASS. Commander SHA-256
  `31CDC91B3D087241E8275054FBA9E58F6287D95C93B32880B71D8D2B3BF840AB`;
  Sentinel SHA-256
  `C22E8E44F20D888F5F17771674D2B24FDFBD7D816B0EECDF114F35189CC3479A`.
  Installed with WoW stopped: Commander 398/398 and Sentinel 12/12, zero
  missing, changed, or extra entries; manifest verification PASS. Rollback:
  `D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KWR-Rollbacks\KWR-270-telemetry-qualification-20260819`.

## Rollback

Restore the prior local addon from
`D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KWR-Rollbacks\KWR-270-runtime-copy-fix-20260819`
if the current candidate cannot load or loses tactical updates.
