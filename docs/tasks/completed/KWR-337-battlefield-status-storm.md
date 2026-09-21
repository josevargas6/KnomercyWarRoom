---
id: KWR-337
title: Bound battlefield-status refresh storms
owner: Codex
priority: critical
risk: high
status: completed
dependencies: [KWR-336]
affected_modules: [Runtime/MatchRuntime, Runtime/Sensors]
authority_references: [AGENTS.md, RELEASE_POLICY.md, RELEASE_READINESS.md]
---

# Objective

Correct the live Twin Peaks alpha27 refresh storm without weakening score,
objective or flag truth.

# User outcome

Commander remains usable and truthful during a real rated match without status
pulses consuming combat CPU or crossing the memory hard limit.

# Current behavior

Alpha27 Twin Peaks evidence recorded 436 `UPDATE_BATTLEFIELD_STATUS` status
pulses, 612 strategic refreshes, strategic P95 29.133 ms and a 40.47 MB sampled
peak. The handler treated every status pulse as a world transition and created a
six-step hydration sweep. Tactical enemy visibility/location changes also caused
96 unnecessary strategic escalations.

# Required behavior

Only actual enter/leave/zone transitions schedule hydration sweeps. Battlefield
status pulses are coalesced into one bounded trailing refresh and still consume
the most recent state. Tactical movement/visibility changes remain tactical;
only enemy carrier/death changes can promote strategic recomputation.

# Non-goals

Do not suppress real score, flag, match lifecycle or objective widget truth; do
not raise budgets or claim a live pass before a replacement candidate is tested.

# Technical constraints

Retain queue freshness semantics, active/inactive lifecycle handling and safe
combat event registration. Do not overwrite the active live installation while
WoW is running.

# Acceptance criteria

- [x] A status pulse schedules no transition sweep.
- [x] Burst status truth receives one trailing refresh.
- [x] Full regression, soak, validation, knowledge and package checks pass.
- [x] Candidate and remaining Retail validation limits are documented.

# Verification

Run deterministic event/queue regression plus full source and extracted-package
tests. A follow-up field session can use any offered rated battleground.

Completed engineering/deployment evidence: source commit
`d87d3fbc99619c10530e1fca225842e3a21f24f0`; reproducible build
`artifacts/alpha28-status-20260920-final`; full deterministic suite and package
audit passed. `artifacts/alpha28-install-20260920/DEPLOYMENT.json` records
INSTALLED_VERIFIED with zero differences for Commander, Sentinel and DevTools;
the restore rehearsal passed and four saved-variable files are backed up under
`artifacts/alpha28-backup-20260920`.

This completes the targeted repair and diagnostic deployment. Retail timing,
sampled peak memory, taint and delivery remain separate field-release gates.

# Rollback

Keep alpha27 deployment archive and backup intact until a later candidate is
verified and installed.
