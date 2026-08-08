---
id: KWR-047
title: Generate adversarial scenario calibration for fail-closed strategy
owner: codex
priority: high
risk: medium
dependencies:
  - KWR-041
  - KWR-043
  - KWR-046
  - KWR-037
affected_modules:
  - Data/ScenarioAdversarialCalibration.lua
  - Runtime/Strategist.lua
  - Runtime/Verification.lua
  - Data/KnowledgeManifest.lua
  - tools/build-scenario-adversarial-calibration.ps1
  - tools/knowledge-audit.ps1
  - tests/smoke.lua
  - knowledge/scenario-adversarial-calibration.json
  - knowledge/schemas/scenario-adversarial-calibration-schema.json
---

# Objective

Convert the adversarial replay pack into a generated fail-closed calibration
layer that teaches the strategist what should remain safe when battlefield
truth is degraded.

# User outcome

KWR can now attach reviewed uncertainty discipline to a live scenario: what
safe action survives degraded truth, what must stay covered, what escalation is
forbidden, and what evidence condition should reopen a harder commit.

# Current behavior

KWR already has reviewed scenario calibration and authored counterplay text, but
it does not yet consume the adversarial corpus to calibrate fail-closed
behavior per scenario.

# Required behavior

- Generate a per-scenario adversarial calibration artifact from the adversarial
  replay pack.
- Emit both a repository knowledge JSON artifact and a runtime Lua module.
- Surface safe-action discipline, forbidden commit, must-stay anchors, and
  escalation condition through the strategist and verification output.
- Require the artifacts through knowledge audit and cover them in smoke tests.

# Non-goals

- Do not claim hidden information.
- Do not automate decisions or protected actions.
- Do not replace existing doctrine, counters, or trust gating.
- Do not broaden scope into live UI redesign in this task.

# Technical constraints

- Runtime remains Lua 5.1-safe and offline during play.
- Generated fail-closed guidance must come only from repository adversarial
  artifacts and machine-readable public-fact assumptions.
- Adversarial calibration must reinforce conservative strategy rather than
  override legal battlefield truth.

# Acceptance criteria

- [ ] A generated scenario-adversarial calibration artifact exists for all base
      scenarios with at least one adversarial case each.
- [ ] A generated runtime Lua module exposes that calibration to the strategist.
- [ ] The strategist attaches adversarial discipline and uses it when trust is
      degraded or commits are not authorized.
- [ ] Verification and smoke coverage prove the adversarial calibration is
      present and readable.
- [ ] Knowledge audit fails if adversarial calibration artifacts are missing or
      incomplete.

# Verification

1. Run `./tools/build-scenario-adversarial-calibration.ps1`.
2. Run `./tools/knowledge-audit.ps1`.
3. Run `./tools/validate.ps1`.
4. Run `./tools/corpus-audit.ps1`.
5. Run `./tools/decision-benchmark.ps1`.

# Rollback

Remove the generated adversarial calibration artifact, generator, and runtime
integration. No SavedVariables migration is required.
