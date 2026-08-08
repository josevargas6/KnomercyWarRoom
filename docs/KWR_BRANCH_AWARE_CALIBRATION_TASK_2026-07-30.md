---
id: KWR-064
title: Make scenario calibration branch-aware
owner: Codex
priority: high
risk: low
dependencies: [KWR-063]
affected_modules: [tools/build-scenario-calibration.ps1, tools/build-scenario-adversarial-calibration.ps1, knowledge/scenario-calibration.json, knowledge/scenario-adversarial-calibration.json, Data/ScenarioCalibration.lua, Data/ScenarioAdversarialCalibration.lua]
---

# Objective

Extend reviewed and adversarial scenario calibration so they summarize branch
families, variant shapes, and safe-counter evidence from the richer corpus.

# User outcome

KWR’s calibration layer can explain not only win rates and top failures, but the
decision-family evidence those outcomes came from.

# Current behavior

- Scenario calibration tracks reviewed cases, wins, losses, and primary failure.
- Adversarial calibration tracks safe primary/fallback actions and truth risk.
- Neither artifact summarizes the richer branch-family evidence now present in
  labels and outcomes.

# Required behavior

- Aggregate branch-family counts from reviewed labels/outcomes into scenario
  calibration.
- Aggregate observed variant shapes/classifications into scenario calibration.
- Aggregate safe-counter and truth-stress evidence from adversarial corpus into
  adversarial calibration.
- Preserve runtime-safe generated Lua outputs.

# Non-goals

- Changing strategist behavior directly in this task.
- Replacing the current reviewed/adversarial calibration fields.

# Technical constraints

- Use additive fields only.
- Preserve deterministic generation and test compatibility.
- Keep artifacts schema-valid with existing required fields.

# Acceptance criteria

- [ ] Scenario calibration exposes branch-family summaries.
- [ ] Scenario calibration exposes reviewed variant-shape summaries.
- [ ] Adversarial calibration exposes branch-family summaries and truth-stress
      evidence.
- [ ] Generated Lua outputs rebuild cleanly.

# Verification

1. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build-scenario-calibration.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build-scenario-adversarial-calibration.ps1`.
3. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\knowledge-audit.ps1`.
4. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.
5. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate.ps1`.

# Rollback

Remove the additive branch-aware aggregation fields and regenerate the prior
calibration artifacts.
