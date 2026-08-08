---
id: KWR-240
title: Expand doctrine comparison and safe-counter branch depth to match the 200-scenario corpus
owner: Codex
priority: high
risk: medium
dependencies: [KWR-239]
affected_modules:
  - Data/DoctrineComparisons.lua
  - tests/smoke.lua
  - Runtime/Strategist.lua
  - Runtime/Commander.lua
---

# Objective

Increase the all-RBG doctrine-comparison and enemy-response branch library so
its depth matches the 200-scenario reviewed corpus rather than remaining at the
older branch floor.

# User outcome

KWR gains more expert-style branch comparisons and safe counters that can be
selected at runtime from legal battlefield facts across every supported rated
battleground map.

# Current behavior

- KWR has 12 comparisons per map and 12 responses per map.
- The branch library is shallower than the newly expanded 200-scenario matrix.

# Required behavior

- Expand doctrine comparisons to 20 per map.
- Expand safe-counter responses to 20 per map.
- Keep coverage even across all supported maps.
- Make the new entries selectable by the current strategist context flags.

# Non-goals

- No hidden automation.
- No unsupported sensory claims.
- No map-uneven doctrine inflation.

# Technical constraints

- Preserve deterministic runtime-safe Lua data.
- Keep commander-readable language.
- Avoid breaking existing branch-selection behavior while making the new branch
  depth reachable.

# Acceptance criteria

- [ ] Every supported map exposes 20 doctrine comparisons.
- [ ] Every supported map exposes 20 enemy-response safe counters.
- [ ] Runtime selection can choose from the expanded branch families.
- [ ] Validation and Lua tests pass.

# Verification

1. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.

# Rollback

Remove the new doctrine expansion pass and restore prior branch-selection
depth.
