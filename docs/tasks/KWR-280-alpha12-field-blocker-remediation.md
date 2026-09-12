---
id: KWR-280
title: Remediate Alpha 12 field-test blockers
owner: Codex
priority: critical
risk: medium
status: blocked
dependencies: [KWR-278]
affected_modules: [Runtime/Reporter.lua, Runtime/Commander.lua, Runtime/MatchRuntime.lua, Core/CommandReview.lua, UI/MainWindowReports.lua, tests/smoke.lua]
authority_references: [AGENTS.md, RELEASE_READINESS.md]
---

# Objective

Remove the correctness, stability, evidence, and telemetry blockers identified
in the Alpha 12 Warsong Gulch field export before the next controlled test.

# Required behavior

- Reporter keeps one track per observed player while identity is enriched from a
  temporary key or name to a GUID.
- A terminal tactical play cannot immediately recreate an equivalent failed
  call without a material battlefield-truth change.
- AAR command records receive bounded, truthful decision evidence.
- Tactical refreshes avoid copying the complete strategic snapshot when only
  local combat/enemy truth is refreshed.
- Performance output labels the timestamp/source of current and historical
  memory samples.

# Non-goals

Do not alter doctrine, capability weights, protected Blizzard UI, or infer
unobserved player positioning.

# Acceptance criteria

- [x] Identity enrichment preserves a single enemy Reporter track.
- [x] Equivalent terminal calls are suppressed until live truth changes.
- [x] AAR evidence is non-empty when score/objective/command truth exists.
- [x] Tactical refresh uses copy-on-write state and deterministic tests pass.
- [x] Source validation and Lua smoke tests pass.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.
3. Run one controlled WSG field regression with Reporter, command stability,
   AAR evidence, and telemetry captures.

# Current blocking condition

All source-level acceptance criteria are complete. The remaining criterion is
external to the repository: a controlled Warsong Gulch session must run against
an exact clean candidate archive and retain Reporter identity, command-stability,
AAR evidence, `/kwr verify`, and `/kwr perf` captures. The currently installed
Alpha 12 folders and retained SavedVariables are unbound to a clean candidate,
so they cannot clear this task. Do not substitute an injected-clock soak or a
historical field export for the required session.

# Rollback

Revert this bounded field-remediation change set. No saved-variable schema is
changed.
