---
id: KWR-334
title: Repair runtime clock and work ownership
owner: Codex
priority: critical
risk: high
status: completed
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
- [x] Regression, soak, validation and package checks pass.
- [x] Remaining live measurements are explicitly identified, not marked passed.

Automated runtime suite passed on September 19: smoke 276 checks, burst/clock/cache
ownership regression, Developer Tools lifecycle, Sentinel transport, 500-refresh
soak and replay. Soak durations use an injected clock and are not live CPU proof.

Final source commit: `2a8c260ae9d838492d957179f2ac1d400999bed4` (clean at build).
Follow-up inspection coverage verifies failed-read retry limits and invalidation
of shared short-name/realm-qualified aliases without renewing old evidence.

Final evidence, September 19:

- `artifacts/alpha26-runtime-final-tests.json`: full Lua suite PASS.
- `artifacts/alpha26-runtime-20260919-final/KWR_6_1_1_ALPHA_26_PACKAGE_AUDIT.json`:
  extracted distribution/developer smoke and soak, hashes and reproducibility PASS.
- Source validation: zero errors/warnings; full knowledge audit: zero errors.
- `artifacts/alpha26-install-20260919/DEPLOYMENT.json`: INSTALLED_VERIFIED;
  Commander, Sentinel and separate LoadOnDemand Developer Tools all alpha26;
  zero missing, changed or extra files against the final archives.
- `artifacts/alpha26-backup-20260919`: previous addon files and four KWR
  SavedVariables files backed up; isolated restore rehearsal PASS.

Completion means the offline repair and authorized diagnostic installation, not
stable-release approval. Remaining Retail CPU/peak-memory, taint, readability,
decision/delivery and map-family evidence remains unverified. Follow
`docs/ALPHA26_FIELD_CHECKLIST.md`: at most two normal games, then targeted
reproduction or explicitly restricted/unverified scope, not an open-ended grind.
Generated release reports retain their broader release scenarios and strict
clean-source certification requirements; they do not prescribe extra matches for
this bounded repair check or certify this diagnostic install as a public release.

# Verification

Deterministic clock, cache, inspection and event-storm regressions; full Lua suite,
source validation, knowledge audit and audited package build. Compare equivalent
live CPU/memory captures only after offline defects are corrected.

# Rollback

Revert this task's commits and restore the previous audited alpha25 package using
the installation backup; retain SavedVariables and field evidence.
