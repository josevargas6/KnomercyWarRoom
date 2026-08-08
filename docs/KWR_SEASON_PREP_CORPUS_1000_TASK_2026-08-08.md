---
id: KWR-053
title: Build 1,000 evenly distributed season-prep matrix and corpus entries
owner: codex
priority: high
risk: medium
dependencies: []
affected_modules:
  - knowledge/rbg-scenario-matrix.json
  - knowledge/scenario-expert-corpus.json
  - Data/ScenarioExpertCorpus.lua
  - tests/replays
  - tests/golden
  - tests/replay-results
  - tests/outcomes
---

# Objective

Add 1,000 deterministic season-prep scenarios and matching corpus fixtures,
distributed equally across all ten supported battleground families.

# User outcome

Each battleground has 100 additional commander-rehearsal branches ready for
new-season review, without any pre-season scenario being presented as proven
live doctrine.

# Required behavior

- Add exactly 100 scenarios per supported map and one corpus fixture set per
  scenario.
- Mark every new entry `PENDING_SEASON_REVIEW`.
- Keep pending entries out of runtime expert selection until official patch
  notes and field evidence approve them.
- Retain all current reviewed scenarios as the active live-safe corpus.

# Verification

1. Run `tools/expand-season-prep-matrix.ps1 -AddPerMap 100`.
2. Run `tools/build-starter-corpus.ps1`.
3. Run `tools/build-scenario-expert-corpus.ps1`.
4. Run corpus, knowledge, Lua, and validation gates.

# Rollback

Restore the prior matrix and generated corpus artifacts, then rerun the
existing corpus generators. No persisted schema change is required.
