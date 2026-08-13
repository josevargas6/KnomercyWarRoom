---
id: KWR-254
title: Activate Alpha40 season-prep corpus in advisory mode
owner: unassigned
priority: high
risk: medium
status: in_progress
authority_references: [RELEASE_READINESS.md, DATA_GOVERNANCE.md]
dependencies: [KWR-053, KWR-253]
affected_modules: [Data/PatchData.lua, Data/ScenarioExpertCorpus.lua, Runtime/Strategist.lua]
---

# Objective

Expose the Alpha40 1,000-entry season-prep corpus and matrix to runtime expert
guidance without promoting its pending entries as verified live doctrine.

# Required behavior

- Activate only through the PatchData advisory flag.
- Preserve every row's `PENDING_SEASON_REVIEW` status.
- Keep Commander, live truth, assignments, and safety gates authoritative.
- Make the activation mode observable in corpus metadata.

# Acceptance criteria

- [x] Alpha40 activates pending matrix/corpus entries as advisory guidance.
- [x] Pending rows remain visibly pending and require Retail validation.
- [x] Deterministic selection proves advisory activation.
- [ ] Retail evidence confirms advisory guidance is useful and never overrules live truth.

# Verification

1. Run validation, knowledge audit, and Lua tests.
2. Confirm one opening and one later-phase advisory row on each map family.
3. Capture Retail evidence showing the Commander retains live-evidence authority.

# Rollback

Set `seasonPrepCorpus.active` to false in the active PatchData pack.
