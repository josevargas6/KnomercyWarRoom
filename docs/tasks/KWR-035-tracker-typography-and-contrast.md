---
id: KWR-035
title: Improve tracker name and health text contrast
owner: unassigned
priority: high
risk: low
status: planned
authority_references: [AGENTS.md, DESIGN_CONTRACT.md]
dependencies: []
affected_modules:
  - UI/CombatRoster.lua
  - UI/CombatRosterVisuals.lua
---

# Objective

Make team and enemy tracker rows readable during combat effects and health-state overlays.

# User outcome

Players can identify class-colored names and health percentages immediately without the status fill obscuring the text.

# Current behavior

Tracker names are visually thin and class colors are muted. Health percentages inherit the amber/red/green fill color, causing them to blend into the bar.

# Required behavior

Use bold outlined tracker names with bright class colors. Render health text as high-contrast white outlined text above the status bar fill.

# Non-goals

Do not change tracker dimensions, assignment logic, combat data, or protected frame behavior.

# Technical constraints

Keep status bars below text and avoid changing secure attributes during combat.

# Acceptance criteria

- [ ] Team and enemy row names use bold outlined text and bright class colors.
- [ ] Health values remain white, outlined, and visually above amber/red/green fills.
- [ ] Existing tracker layout and data behavior remain unchanged.

# Verification

1. Run `tools/validate.ps1`.
2. Run `tools/test-lua.ps1`.
3. Verify team and enemy trackers in setup and live battleground states.

# Rollback

Revert the typography, draw-layer, and color changes in the two UI modules.
