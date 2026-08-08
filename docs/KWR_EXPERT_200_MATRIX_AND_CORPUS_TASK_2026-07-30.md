---
id: KWR-239
title: Push the reviewed all-RBG matrix and corpus to 200 expert scenarios
owner: Codex
priority: high
risk: medium
dependencies: []
affected_modules:
  - knowledge/rbg-scenario-matrix.json
  - tests/smoke.lua
  - tools/build-starter-corpus.ps1
  - tools/build-foundation-depth-corpus.ps1
  - tools/build-scenario-calibration.ps1
  - tools/build-scenario-adversarial-calibration.ps1
  - knowledge/scenario-calibration.json
  - knowledge/scenario-adversarial-calibration.json
  - Data/ScenarioCalibration.lua
  - Data/ScenarioAdversarialCalibration.lua
---

# Objective

Expand the production reviewed battleground scenario matrix from 120 to 200
base scenarios while keeping depth equal across every supported rated
battleground map.

# User outcome

KWR gains a deeper offline expert corpus with more realistic opening, stabilize,
pressure, recovery, and score-protection situations for every supported RBG
map, not just one or two favorites.

# Current behavior

- The source-of-truth matrix currently contains 12 scenarios per map.
- Corpus and calibration outputs are already deterministic, but they are still
  bounded by the 120-scenario base matrix.

# Required behavior

- Increase `targetBaseScenariosPerMap` from 12 to 20.
- Add eight new reviewed expert scenarios to every supported map.
- Keep the new scenarios map-specific, commander-usable, and safe-fact based.
- Regenerate starter corpus, depth corpus, calibration, and adversarial
  calibration from the expanded matrix.
- Update deterministic expectations to the new reviewed depth.

# Non-goals

- No placeholder scenarios.
- No fake live battleground evidence.
- No narrowing the work to only flag maps or node maps.

# Technical constraints

- Preserve supported map keys and existing profile wiring.
- Maintain equal per-map depth.
- Keep the deterministic offline gate green after regeneration.

# Acceptance criteria

- [ ] The reviewed matrix contains 20 base scenarios for each supported map.
- [ ] Every supported map receives eight additional expert-tier scenarios.
- [ ] Starter corpus and deeper reviewed/adversarial corpus rebuild from the
      200-scenario matrix.
- [ ] Scenario calibration and adversarial calibration rebuild to 200 rows.
- [ ] Validation, knowledge audit, and Lua tests pass after regeneration.

# Verification

1. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build-starter-corpus.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build-foundation-depth-corpus.ps1`.
3. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build-scenario-calibration.ps1`.
4. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build-scenario-adversarial-calibration.ps1`.
5. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate.ps1`.
6. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\knowledge-audit.ps1`.
7. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.

# Rollback

Restore the previous 120-scenario matrix, rebuild the prior corpus/calibration
artifacts, and return deterministic expectations to the earlier reviewed depth.
