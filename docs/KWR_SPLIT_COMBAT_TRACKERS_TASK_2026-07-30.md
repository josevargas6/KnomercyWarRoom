---
id: KWR-035
title: Split compact combat roster into independent team and enemy trackers
owner: Codex
priority: high
risk: medium
dependencies: []
affected_modules:
  - Core/Addon.lua
  - UI/CombatRoster.lua
  - UI/CombatRosterState.lua
  - UI/MainWindowCommands.lua
  - UI/MainWindowShell.lua
  - UI/Presentation.lua
  - UI/Options.lua
  - tests/smoke.lua
---

# Objective

Replace the combined compact combat roster shell with separate compact Team and Enemy trackers.

# User outcome

Commanders can move the Team tracker and Enemy tracker independently, keep one open without the other, and still receive the same live battlefield information.

# Current behavior

The compact roster uses one shared frame with TEAM, ENEMY, and BOTH layout modes. This makes the surface large, coupled, and awkward during live combat.

# Required behavior

- Team and Enemy compact trackers use separate top-level frames.
- Each frame saves its own position.
- `/kwr teammini` toggles only the Team tracker.
- `/kwr enemymini` toggles only the Enemy tracker.
- `/kwr roster` opens or closes both trackers together.
- Existing live data, row binding, spotlight, and compact-surface suppression continue to work.

# Non-goals

- Redesign row content.
- Change strategic logic.
- Add any unsafe automation.

# Technical constraints

- Preserve secure click behavior.
- Respect combat-lockdown restrictions.
- Migrate old single-frame saved positions safely.
- Keep compact-surface suppression and restoration compatible with presentation mode and the main window.

# Acceptance criteria

- [ ] Team and Enemy trackers can be shown independently.
- [ ] Team and Enemy trackers can be moved independently.
- [ ] Old saved variables migrate without losing compact-roster visibility preferences.
- [ ] Compact-surface suppression and restoration still work.
- [ ] Automated validation and deterministic tests pass.

# Verification

1. Run automated validation.
2. Run deterministic Lua smoke coverage.
3. Verify both compact trackers can show, hide, move, and restore independently.

# Rollback

Revert compact tracker split and restore the prior unified combat roster shell.
