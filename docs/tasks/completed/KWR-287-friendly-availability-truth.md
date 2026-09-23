---
id: KWR-287
title: Preserve unknown friendly availability through assignment selection
owner: Codex
priority: high
risk: medium
status: completed
dependencies: [KWR-281, KWR-283]
affected_modules: [Util, Sensors, TeamResolver, BoardStateBuilder, FriendlyRoleState, PlayerControlProfiles, AssignmentScorer, tests]
authority_references: [AGENTS.md, PRODUCT_ROADMAP.md, RELEASE_READINESS.md]
---

# Objective

Implement the OVR-02/04 unknown-friendly availability and role contract.

# User outcome

A missing or restricted roster reading cannot turn a teammate into an available
local actor. Their identity remains visible while an executable job stays unfilled
until public availability and role information support it.

# Current behavior

Sensors defaults missing death/connection readings to alive/online and labels
every friendly visible. BoardState repeats those defaults. FriendlyRoleState
treats absent fields as availability and unconditional confirmation, while the
control profile gives an unknown role the damage-role base scores.

# Required behavior

Preserve public true/false/nil values across sensor and board boundaries. Secret,
missing, invalid or throwing APIs produce unknown; known dead or offline remains
unavailable even when the other field is unknown. Availability requires explicit
alive and connected values. Read visibility only from the corresponding public
unit API on stable unit identity. Keep unknown roles unconfirmed, remove their
damage-role fallback and exclude them from executable control assignments.

# Non-goals

Range/capability/DR feasibility, objective coverage, spec-cache expiry, complete
field-level fact migration and enemy intent confidence remain separate OVR work.
No persistence migration, installation or new feature.

# Technical constraints

Preserve existing Util:Boolean behavior for callers that intentionally use a
default; add an optional boolean reader for this boundary. Existing known-role,
alive/online cases continue to produce assignments. Do not hide unknown roster
identities or infer visibility from group membership.

# Acceptance criteria

- [x] Missing, invalid, protected and throwing API readings remain unknown.
- [x] Known dead/offline excludes an actor; both positive availability readings
  are required before scoring an executable job.
- [x] Unknown roles retain identity without receiving a damage-role profile.
- [x] Roster identity alone does not assert physical visibility.
- [x] Source capture, board and optimizer regressions pass, including recovery.
- [x] Extracted-package regressions pass with content-bound evidence.

# Verification

Exercise the actual Sensors module with isolated API mocks and the actual
BoardState/FriendlyRoleState/AssignmentOptimizer pipeline. Cover nil, false,
true, invalid and protected values, API errors, unstable raid tokens, recovery
and known valid assignments. Run validation and smoke, then the extracted gate.
Live roster hydration/combat restrictions remain candidate-bound field checks.

September 6 source checkpoint: Smoke, validation (zero errors/warnings) and
diff checks pass. `tests/fixtures/friendly_availability.lua` exercises actual
capture/board/assignment behavior, including a million-point problem that cannot
override unknown availability, known-dead/offline cases with the other field
unknown, known-role recovery and unstable/stable raid-token hydration.

Follow-up source review found TeamResolver's complete-scoreboard repair path
also defaulted missing readings and converted known offline to connected.
It now preserves optional booleans from matched group observations and keeps
scoreboard-only physical state unknown. The expanded smoke fixture passes for
both known-offline and unmatched scoreboard actors. The interim
`generation-availability-20260906-package` passed extraction for the earlier
scope but predates this repair; it cannot close this task. Include the repair
and expanded fixture in the next combined candidate before closure.

Package closure: `artifacts/explicit-countdown-20260906-package/` includes the
complete-scoreboard repair and expanded fixture. Extracted player/developer
smoke and 500-refresh soak, knowledge regeneration, Sentinel transport, DevTools
lifecycle and four ZIP hashes pass. The source receipt is
`artifacts/friendly-repair-20260906/source-checks.json`, with later smoke-driver
hashes in `artifacts/explicit-countdown-20260906/source-checks.json`. This dirty
interim build skipped clean reproducibility. Broader OVR-02/04 and live gates remain.

# Rollback

Revert this boundary change with its tests while retaining known-unavailable
filtering and previous recovery work. Never restore false availability by
rewriting saved user data.
