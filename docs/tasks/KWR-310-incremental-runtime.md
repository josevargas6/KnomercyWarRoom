---
id: KWR-310
title: Incremental live runtime and selective publication
status: in_progress
owner: unassigned
priority: high
risk: high
dependencies: [KWR-309, live-field-certification]
affected_modules: [Runtime/Sensors.lua, Runtime/MatchRuntime.lua, Runtime/CombatIntel.lua, Runtime/EnemyIntel.lua, Core/Store.lua, UI/MainWindowReports.lua, tests/smoke.lua, tests/soak.lua]
authority_references: [AGENTS.md, RELEASE_POLICY.md]
---

# Objective

Bound the cost of public widget, status, and tactical pulses without losing
score, objective, roster, enemy, or command truth.

# User outcome

Live battleground UI remains responsive during score and combat bursts. Calls
change when verified battlefield facts change and remain stable on duplicate
or cosmetic pulses.

# Current behavior

An accepted widget pulse enters the full sensor, battlefield, strategy,
assignment, command, and store publication pipeline. Tactical pulses can
rebuild combat presentation when their observed inputs have not changed.

# Required behavior

- Classify widget pulses as score, objective, unchanged, or unrelated.
- Read public score and objective deltas without recapturing roster and enemies.
- Reuse published battlefield and tactical branches where their dependencies
  did not change. Recompute strategy and commands when material truth changes.
- Avoid publishing a new store revision for an unchanged pulse.
- Keep status and scoreboard freshness, transition, manual refresh, and match
  completion paths authoritative.
- Expose skip and reuse counters so field telemetry can verify the behavior.

# Non-goals

- Promise a Retail P95 based on synthetic timing.
- Infer hidden Blizzard state or change saved variable schemas.

# Technical constraints

Keep all widget reads behind Sensors. Do not retain mutable working tables
across publications. Preserve command state and delivery boundaries.

# Acceptance criteria

- [x] Duplicate and unrelated widget pulses do not execute strategic stages in deterministic tests.
- [x] A score or objective change publishes the new verified truth in deterministic tests.
- [x] Unchanged status pulses avoid the full pipeline in deterministic tests.
- [x] Tactical pulses with unchanged observed inputs reuse combat output in deterministic tests.
- [x] Manual, transition, and match-end refreshes remain complete; scoreboard captures stay full while downstream stages can skip unchanged input.
- [ ] Validation, deterministic smoke/soak, and extracted package audit pass for the final `-2` candidate (source checks passed; package pending).
- [ ] Retail P95 and UI safety are measured on the installed candidate.

# Verification

1. Exercise score, objective, duplicate, status, and tactical event fixtures.
2. Run validation, Lua smoke/soak, and package audit.
3. Bind live telemetry to the exact installed package.

Initial offline verification passed on commit `00739a0`: source validation,
complete Lua suite, knowledge audit, deterministic reproducibility, and
extracted package audit. Its installation is preserved as a rollback point in
`artifacts/alpha30-install-20260927-1/DEPLOYMENT.json`. The `-2` candidate
adds a lightweight freshness lane; repackage and redeploy it before testing.
Retail P95 and UI safety remain open.

# Rollback

Revert this runtime change. There is no persisted schema migration.
