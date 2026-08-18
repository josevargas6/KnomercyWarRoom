---
id: KWR-259
title: Make command options close reliably in combat
owner: KWR
priority: high
risk: low
status: completed
authority_references: [ARCHITECTURE.md, DESIGN_CONTRACT.md]
dependencies: []
affected_modules: [UI/Options.lua]
---

# Objective

Make the KWR Options dialog a clean, closable modal surface during combat.

# User outcome

The X and Escape close the Options dialog directly, and the KWR launcher menu does not remain visible behind it.

# Current behavior

Options relies on an implicit template close behavior and does not consistently dismiss the launcher menu when opened.

# Required behavior

Bind the close button explicitly to the Options frame, register Escape closing, and hide only the non-protected launcher menu on Options open.

# Non-goals

Do not hide, move, or mutate protected combat roster frames during combat.

# Technical constraints

Use direct visibility on the non-secure Options and launcher frames only. Do not add secure handlers or combat-lockdown mutations.

# Acceptance criteria

- [x] The Options X closes the Options frame directly.
- [x] Escape recognizes the Options frame as a special closable frame.
- [x] Opening Options hides the KWR launcher menu.
- [x] The behavior does not invoke protected-frame operations.

# Verification

1. Run `tools/validate.ps1`.
2. Run `tools/test-lua.ps1`.
3. In combat, open Settings from the launcher and close with X and Escape.

# Rollback

Revert this task's single commit.
