---
id: KWR-248
title: Require Shift for tracker focus assignment
owner: unassigned
priority: medium
risk: medium
status: in_progress
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

# Current behavior

Friendly and enemy rows retain left-click targeting. Their right-click macros
put every focus operation behind `mod:shift`, and deterministic smoke coverage
asserts the exact secure attributes. Retail interaction verification remains
open for the complete in-combat cycle.

# Non-goals

Do not change left-click targeting or the existing combat-lockdown safety boundary.

# Acceptance criteria

- [x] Left-click still targets the clicked unit or enemy.
- [x] Shift+Right-Click assigns focus.
- [x] Plain right-click does not assign focus.
- [x] Tooltips communicate the modified-click behavior.

# Verification

1. Run `tools/validate.ps1`.
2. Run `tools/test-lua.ps1`.
3. Verify team and enemy rows in and out of combat.

# Rollback

Restore the prior right-click focus bindings.
