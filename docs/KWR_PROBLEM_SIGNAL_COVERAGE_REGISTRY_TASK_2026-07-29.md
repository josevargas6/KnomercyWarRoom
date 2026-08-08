---
id: KWR-037
title: Add machine-auditable problem signal coverage registry
owner: unassigned
priority: high
risk: medium
dependencies:
  - KWR-036
affected_modules:
  - Data/EnemyProblemTypes.lua
  - Data/ProblemSignalRegistry.lua
  - Runtime/Verification.lua
  - tests/smoke.lua
---

# Objective

Create the ET-01 Problem Signal Coverage Registry so the addon can state, in
machine-auditable form, which enemy/objective problem types are fully supported,
which are intentionally disabled, and which must not be treated as expert-tier
truth yet.

# User outcome

Maintainers can open `/kwr verify` and see whether every declared problem type
has real source-to-command-to-AAR coverage or is explicitly disabled. Offline
benchmark and replay work can build on a stable truth contract instead of
implied behavior.

# Current behavior

Problem types exist in `Data/EnemyProblemTypes.lua`, but no canonical registry
states which of them are safe, supported, partial, legacy-only, or disabled.
Verification cannot currently fail when the problem model drifts away from the
documented expert-tier plan.

# Required behavior

- Add a canonical registry for problem signal coverage and disabled reasons.
- Normalize legacy aliases to canonical problem keys.
- Expose registry summary and active-problem coverage in live verification.
- Make verification warn if an active problem is undeclared, disabled, or
  enabled without full coverage.
- Add deterministic smoke coverage so drift fails offline validation.

# Non-goals

- Do not change live battlefield assignments or command logic.
- Do not enable dormant advanced problem types that lack truth-qualified
  detectors.
- Do not implement the replay engine, corpus schema, or benchmark system in
  this task.

# Technical constraints

- Preserve existing runtime behavior and bounded refresh cost.
- Keep the registry read-only with respect to command generation.
- Do not add new SavedVariables or migrations.
- Keep legacy aliases backward-compatible.

# Acceptance criteria

- [x] Every declared problem type resolves through a canonical registry row.
- [x] Disabled problem types state why they are disabled.
- [x] `/kwr verify` includes registry summary and active-problem coverage.
- [x] Verification warns when active problems are unknown, disabled, or partial.
- [x] Smoke tests fail if registry coverage drifts.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `fengari tests/smoke.lua`.
3. Run `./tools/knowledge-audit.ps1`.
4. Confirm verification output includes the problem-signal registry summary.

# Rollback

Remove `Data/ProblemSignalRegistry.lua`, undo TOC and smoke wiring, and revert
verification formatting changes. No persisted state needs migration.
