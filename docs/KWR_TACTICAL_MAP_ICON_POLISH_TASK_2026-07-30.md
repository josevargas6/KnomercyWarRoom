---
id: KWR-2026-07-30-MAP-ICON-POLISH
title: Promote tactical map icon language over letter badges
owner: codex
priority: high
risk: medium
dependencies: []
affected_modules:
  - UI/TacticalMap.lua
  - UI/IconRegistry.lua
  - tests/smoke.lua
---

# Objective

Make tactical-map markers read faster in live battleground play by using the KWR icon system as the primary signal for roles, carriers, objectives, and target state.

# User outcome

Commanders can distinguish friendly and enemy battlefield markers at a glance without decoding small letter badges such as K, H, T, E, or !.

# Current behavior

The tactical map mixes icons with letter badges. Important player and objective markers still rely on text badges heavily, which slows visual parsing during play.

# Required behavior

- Tactical-map player markers should prefer role and state icons over letter badges.
- Friendly and enemy ownership should be differentiated by strong frame/ring color treatment.
- Flag and orb markers should prefer dedicated objective icons.
- Kill targets should remain visually prominent without requiring a K badge.
- Existing hover detail should remain available.

# Non-goals

- Rebuilding the full map rendering system.
- Adding new art assets outside the existing icon registry.
- Changing strategic logic or battlefield data collection.

# Technical constraints

- Must stay within the current TacticalMap marker pipeline.
- Must preserve compact mode usability.
- Must remain deterministic under smoke coverage.

# Acceptance criteria

- [ ] Tactical map uses icon-first presentation for player markers.
- [ ] Friendly and enemy markers are distinguished by visual framing, not only letters.
- [ ] Orb and flag states use dedicated icon assets when available.
- [ ] Hover tooltips remain intact.
- [ ] Automated validation and Lua tests pass.

# Verification

1. Run automated validation.
2. Run Lua smoke, soak, and replay coverage.
3. Review preview tactical map marker rendering and fallback live marker coverage.

# Rollback

Revert `UI/TacticalMap.lua` marker presentation updates and the related smoke assertions.
