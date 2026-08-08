---
id: KWR-2026-07-30-COMPACT-ROSTER-RESTORE
title: Restore both compact trackers from large-board minimize actions
owner: codex
priority: high
risk: low
dependencies: []
affected_modules:
  - UI/MainWindow.lua
---

# Objective

Make the large Team and Enemy page minimize actions restore the full compact battlefield roster layout instead of only one side.

# User outcome

When a commander minimizes from the main Team or Enemy pages, both compact trackers return without needing a second click.

# Current behavior

The Team page mini button opens only compact Team, and the Enemy page minimize button opens only compact Enemy.

# Required behavior

- Team page mini restores both compact trackers.
- Enemy page minimize restores both compact trackers.
- Existing compact toolbar side-toggle behavior remains available.

# Non-goals

- Reworking compact tracker layout.
- Changing compact roster visibility rules in combat lockdown.

# Technical constraints

- Must preserve the existing CombatRoster `BOTH` mode.
- Must not affect HUD-only minimize behavior.

# Acceptance criteria

- [ ] Minimizing from Team page opens both compact trackers.
- [ ] Minimizing from Enemy page opens both compact trackers.
- [ ] Validation and Lua tests pass.

# Verification

1. Run automated validation.
2. Run Lua smoke, soak, and replay coverage.

# Rollback

Revert the `MinimizeTo("ROSTER", "BOTH")` button wiring in `UI/MainWindow.lua`.
