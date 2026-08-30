---
id: KWR-276
title: Record August 27 official hotfix provenance
owner: Codex
priority: medium
risk: low
status: completed
dependencies: []
affected_modules: [Data/PatchData.lua, Data/SourceRegistry.lua, META_SOURCES.md, tests/smoke.lua]
authority_references: [AGENTS.md]
---

# Objective

Advance the Retail 12.1 official-hotfix review boundary through August 27, 2026
without inventing a capability, target-priority, or doctrine change.

# User outcome

Release and field-test evidence identifies the latest reviewed Blizzard ledger
entry and distinguishes gameplay-scope and reward-progression repairs from KWR
strategic inputs.

# Current behavior

The active patch pack stops at the August 26 Training Grounds correction.

# Required behavior

- Record the August 27 Vicious Saddle progression repair.
- Record the August 27 repair that prevents Blur's PvP adjustment from affecting
  PvE while preserving the already reviewed PvP value.
- Keep both entries advisory and leave capabilities and doctrine unchanged.

# Non-goals

- No class-weight, cooldown, target-priority, or battleground-doctrine changes.
- No inference from unofficial sources.

# Technical constraints

- Use Blizzard's canonical hotfix ledger as the source.
- Keep the 12.1 capability overlay fail-closed.

# Acceptance criteria

- [x] Patch and source provenance are reviewed through 2026-08-27.
- [x] Vicious Saddle and Blur scope repairs are present in the advisory watchlist.
- [x] The active capability overlay remains empty.
- [x] Deterministic smoke and knowledge validation cover the updated boundary.

# Verification

1. Run `tools/validate.ps1`.
2. Run `tools/knowledge-audit.ps1`.
3. Run the Lua smoke suite.

# Rollback

Revert the provenance-only changes. No runtime state or SavedVariables migration
is involved.
