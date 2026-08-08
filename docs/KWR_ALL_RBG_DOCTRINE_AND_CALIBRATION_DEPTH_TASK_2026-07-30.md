---
id: KWR-236
title: Deepen all-map doctrine branches and calibration summaries
owner: Codex
priority: high
risk: medium
dependencies: []
affected_modules:
  - Data/DoctrineComparisons.lua
  - Data/ScenarioCalibration.lua
  - Data/ScenarioAdversarialCalibration.lua
  - tools/build-scenario-calibration.ps1
  - tools/build-scenario-adversarial-calibration.ps1
  - tests/smoke.lua
---

# Objective

Increase expert-grade offline decision depth evenly across every supported rated
battleground map by adding more reviewed doctrine branches and stronger
calibration summaries.

# User outcome

KWR has deeper all-map branch comparisons, safer enemy-counter answers, and
clearer calibration summaries that make offline doctrine review stronger before
field testing resumes.

# Current behavior

- Every supported map already has 10 scenario families.
- Corpus depth is already equal across all maps.
- Doctrine comparisons expose equal all-map coverage, but the next expert-depth
  gain is more branch and counter nuance.
- Calibration is strong per scenario, but map-level summary surfaces are still
  thin.

# Required behavior

- Add more production-grade doctrine comparisons evenly across all supported
  maps.
- Add more production-grade enemy-counter response branches evenly across all
  supported maps.
- Strengthen scenario calibration with map and map-phase summaries.
- Strengthen adversarial calibration with map and map-phase summaries.
- Keep generated Lua and JSON artifacts aligned with the source builders.

# Non-goals

- No fake live evidence.
- No speculative unsafe sensor claims.
- No map-scope changes beyond supported rated battlegrounds.

# Technical constraints

- Preserve current supported map keys and doctrine structure.
- Keep commander logic additive and deterministic.
- Keep generated artifacts rebuildable from repository scripts.
- Maintain equal coverage across all ten supported maps.

# Acceptance criteria

- [ ] Doctrine comparisons expose deeper equal all-map branch coverage.
- [ ] Doctrine responses expose deeper equal all-map safe-counter coverage.
- [ ] Scenario calibration exposes map and phase summaries for all maps.
- [ ] Adversarial calibration exposes map and phase summaries for all maps.
- [ ] Offline validation and Lua tests pass after regeneration.

# Verification

1. Rebuild calibration artifacts from the PowerShell generators.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate.ps1`.
3. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.

# Rollback

Revert the doctrine additions, regenerate artifacts from the previous builders,
and restore the previous smoke expectations.
