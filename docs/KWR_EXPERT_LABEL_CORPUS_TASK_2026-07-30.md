---
id: KWR-237
title: Build expert label corpus and strategist review layer
owner: Codex
priority: high
risk: medium
dependencies: []
affected_modules:
  - Data/ScenarioExpertCorpus.lua
  - Runtime/Strategist.lua
  - Data/KnowledgeManifest.lua
  - tools/build-scenario-expert-corpus.ps1
  - tools/knowledge-audit.ps1
  - tests/smoke.lua
  - KnomercyWarRoom.toc
---

# Objective

Build a reviewed expert-label corpus from the existing golden labels and
outcome reviews, then expose that corpus to the strategist as a first-class
offline review layer.

# User outcome

KWR carries a reviewed scenario-by-scenario expert answer set that strengthens
offline decision memory before more field testing.

# Current behavior

- Scenario calibration summarizes reviewed results and failure patterns.
- Doctrine comparisons and responses are deeper across all supported maps.
- Golden labels and outcome reviews exist, but there is no dedicated
  strategist-facing expert corpus layer that aggregates reviewed decisions into
  one clean scenario record.

# Required behavior

- Generate a scenario expert corpus from reviewed golden labels and outcome
  reviews.
- Produce both a JSON knowledge artifact and a Lua runtime module from the same
  builder.
- Expose scenario, map, and map-phase expert summaries.
- Attach the expert review layer to strategist output without replacing live
  logic.
- Cover the new layer in knowledge audit and deterministic smoke tests.

# Non-goals

- No fake live evidence.
- No replacement of the strategist with hard-coded review answers.
- No player-facing UI rewrite in this task.

# Technical constraints

- Preserve the current scenario matrix as the base scenario authority.
- Keep the corpus fully rebuildable from repository scripts.
- Keep supported map coverage equal across all ten rated battlegrounds.
- Keep commander-facing strings safe and non-technical.

# Acceptance criteria

- [ ] Every base scenario has an expert review row.
- [ ] The expert corpus exposes map and map-phase summaries for all supported maps.
- [ ] Strategist output attaches expert review data for the selected scenario.
- [ ] Knowledge audit validates the new expert corpus artifact.
- [ ] Validation and Lua tests pass after generation.

# Verification

1. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build-scenario-expert-corpus.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate.ps1`.
3. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\knowledge-audit.ps1`.
4. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.

# Rollback

Remove the expert corpus builder, generated artifacts, and strategist hook, then
restore the previous TOC, audit, and smoke coverage.
