---
id: KWR-337
title: Bound battlefield-status refresh storms
owner: Codex
priority: critical
risk: high
status: in_progress
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

- [ ] A status pulse schedules no transition sweep.
- [ ] Burst status truth receives one trailing refresh.
- [ ] Full regression, soak, validation, knowledge and package checks pass.
- [ ] Candidate and remaining Retail validation limits are documented.

# Verification

Run deterministic event/queue regression plus full source and extracted-package
tests. A follow-up field session can use any offered rated battleground.

# Rollback

Keep alpha27 deployment archive and backup intact until a later candidate is
verified and installed.
