---
id: KWR-334
title: Repair runtime clock and work ownership
owner: Codex
priority: critical
risk: high
status: in_progress
dependencies: []
affected_modules: [MatchRuntime, Sensors, RosterInspector, Capabilities, Util, Commander]
authority_references: [AGENTS.md, DESIGN_CONTRACT.md, RELEASE_POLICY.md, RELEASE_READINESS.md, BATTLEGROUND_VERIFICATION.md]
---

# Objective

Resolve the underlying repeated work and command timing defects exposed by the
alpha25 Arathi Basin field captures, without weakening performance gates.

# User outcome

One coherent issued plan, correctly aging deadlines, and bounded work during
event bursts. No further matches requested merely to discover deterministic bugs.

# Current behavior

Field strategic P95 reached 34.561 ms and tactical P95 8.222 ms. Memory reached
44.26 MB during play and fell to 13.64 MB afterward; this alone does not prove a
retained leak. Inspection clears unrelated cached specs. Pre-execution coalesced
events cause redundant follow-up captures. Relative capture deadlines are used
as absolute uptime, and retained calls can mix plan generations.

# Required behavior

Define clock units at the prediction/command boundary; retain absolute deadlines
and issued duties together. Cache known immutable data without unbounded keys.
Inspection must only replace accepted identity-specific evidence. A queued refresh
consumes all evidence available when it starts; only later arrivals need follow-up.
High-volume health/aura events must not repeatedly run full enemy observations.

# Non-goals

No fabricated live benchmark, waived release gate, forced collection in combat,
removed commander capability, or promise of immunity from future client changes.

# Technical constraints

Preserve secret-value protections, saved-variable compatibility, manual command
delivery and the existing single runtime/Commander state owners. Do not deploy
while WoW runs. Offline clocks cannot certify Retail CPU or peak memory.

# Acceptance criteria

- [x] Relative durations are converted once to absolute play deadlines.
- [x] Retained calls cannot freeze their countdown or mix candidate duties.
- [x] Inspection preserves unrelated identities and refreshes only changed truth.
- [x] Burst work is bounded and newest truth is not discarded.
- [ ] Regression, soak, validation and package checks pass.
- [ ] Remaining live measurements are explicitly identified, not marked passed.

Automated runtime suite passed on September 19: smoke 276 checks, burst/clock/cache
ownership regression, Developer Tools lifecycle, Sentinel transport, 500-refresh
soak and replay. Soak durations use an injected clock and are not live CPU proof.

# Verification

Deterministic clock, cache, inspection and event-storm regressions; full Lua suite,
source validation, knowledge audit and audited package build. Compare equivalent
live CPU/memory captures only after offline defects are corrected.

# Rollback

Revert this task's commits and restore the previous audited alpha25 package using
the installation backup; retain SavedVariables and field evidence.
