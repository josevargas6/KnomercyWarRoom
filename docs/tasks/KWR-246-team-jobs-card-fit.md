---
id: KWR-246
title: Fit all Team Jobs assignment rows
owner: unassigned
priority: medium
risk: low
status: planned
authority_references: [AGENTS.md, DESIGN_CONTRACT.md]
dependencies: []
affected_modules:
  - UI/MainWindow.lua
---

# Objective

Give the Tactical Map Team Jobs card enough vertical space for all ten assignment rows.

# User outcome

The final assignment remains fully visible inside the card and does not touch or cross the bottom border.

# Current behavior

The tenth line is positioned at the card’s lower edge and can be clipped.

# Required behavior

Increase only the Team Jobs card height while preserving the existing row spacing and neighboring card positions.

# Non-goals

Do not change assignment content, ordering, or card width.

# Technical constraints

Keep the change local to the Tactical Map page layout.

# Acceptance criteria

- [ ] All ten Team Jobs rows fit inside the card.
- [ ] Neighboring cards and assignment data remain unchanged.

# Verification

1. Run `tools/validate.ps1`.
2. Run `tools/test-lua.ps1`.
3. Inspect the Tactical Map page with a full ten-player roster.

# Rollback

Restore the Team Jobs card height to 186.
