---
id: KWR-038
title: Require Shift for tracker focus assignment
owner: unassigned
priority: medium
risk: medium
status: planned
authority_references: [AGENTS.md, SECURITY.md]
dependencies: []
affected_modules:
  - UI/CombatRoster.lua
  - UI/CombatRosterVisuals.lua
---

# Objective

Prevent accidental focus changes from tracker interaction during combat.

# User outcome

Left-click remains fast targeting, while focus assignment is an intentional Shift+Right-Click action.

# Required behavior

Team and enemy tracker rows require the Shift modifier for focus assignment.

# Non-goals

Do not change left-click targeting or the existing combat-lockdown safety boundary.

# Acceptance criteria

- [ ] Left-click still targets the clicked unit or enemy.
- [ ] Shift+Right-Click assigns focus.
- [ ] Plain right-click does not assign focus.
- [ ] Tooltips communicate the modified-click behavior.

# Verification

1. Run `tools/validate.ps1`.
2. Run `tools/test-lua.ps1`.
3. Verify team and enemy rows in and out of combat.

# Rollback

Restore the prior right-click focus bindings.
