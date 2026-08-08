---
id: KWR-037
title: Generate reviewed scenario calibration for the live strategist
owner: codex
priority: high
risk: medium
dependencies:
  - KWR-032
  - KWR-033
  - KWR-034
  - KWR-035
  - KWR-036
affected_modules:
  - Data/ScenarioCalibration.lua
  - Runtime/Strategist.lua
  - Runtime/Verification.lua
  - Data/KnowledgeManifest.lua
  - tools/build-scenario-calibration.ps1
  - tools/knowledge-audit.ps1
  - tests/smoke.lua
  - knowledge/scenario-calibration.json
  - knowledge/schemas/scenario-calibration-schema.json
---

# Objective

Convert the reviewed offline RBG corpus into a generated, runtime-readable
scenario calibration layer that the strategist can surface during live decision
making.

# User outcome

KWR no longer treats reviewed offline cases as disconnected lab assets. The
live strategy result can now say how many reviewed cases support the active
scenario, what usually breaks that line, and what discipline rule should stay
attached to the call before field testing.

# Current behavior

KWR already selects a reviewed scenario contract in `ScenarioLibrary`, but the
runtime does not consume the larger offline corpus to calibrate confidence,
surface dominant failure patterns, or distinguish disciplined reviewed lines
from thin ones.

# Required behavior

- Generate a per-scenario calibration artifact from the reviewed outcome corpus.
- Emit both a human-readable knowledge JSON artifact and a runtime Lua module.
- Surface reviewed case count, win rate, dominant failure pattern, and a
  discipline rule in the strategist result.
- Make the calibration visible to verification and knowledge summaries.
- Add deterministic smoke coverage and knowledge-audit checks.

# Non-goals

- Do not add hidden-information planning.
- Do not automate commands, targeting, or chat.
- Do not replace the existing strategist, doctrine, or scenario library.
- Do not claim expert-tier readiness from calibration alone.

# Technical constraints

- Runtime remains Lua 5.1-safe and offline during play.
- Live strategy may consume only generated static data and legal battlefield
  facts.
- Calibration guidance must stay conservative and human-readable.
- Generated artifacts must stay reproducible from repository knowledge inputs.

# Acceptance criteria

- [ ] A generated scenario-calibration knowledge artifact exists for all base
      RBG scenarios.
- [ ] A generated runtime Lua module exposes the same scenario calibration data.
- [ ] The strategist attaches reviewed calibration to the selected scenario when
      available.
- [ ] Verification and smoke coverage prove the calibration is present and
      readable.
- [ ] Knowledge audit fails if calibration artifacts are missing or incomplete.

# Verification

1. Run `./tools/build-scenario-calibration.ps1`.
2. Run `./tools/knowledge-audit.ps1`.
3. Run `./tools/validate.ps1`.
4. Run `./tools/corpus-audit.ps1`.
5. Run `./tools/decision-benchmark.ps1`.

# Rollback

Remove the generated calibration artifact, the generator, and the strategist
integration. No SavedVariables schema changes are required.
