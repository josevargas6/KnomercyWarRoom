---
id: KWR-275
title: Keep native bag windows above KWR surfaces
owner: Codex
priority: high
risk: low
status: completed
dependencies: []
affected_modules: [UI/LayoutCoordinator.lua, tests/smoke.lua]
authority_references: [AGENTS.md]
---

# Objective

Preserve access to Blizzard's combined backpack and individual bag windows
when they overlap the KWR command surfaces.

# User outcome

Opening the backpack during a battleground keeps every visible bag slot and
bag control above the KWR HUD instead of allowing the addon to cover the bag.

# Current behavior

KWR lowers its high-strata surfaces for several native Blizzard panels, but
the combined backpack and numbered container frames are not recognized. During
combat, the layout coordinator also returns before applying safe strata-only
changes.

# Required behavior

- Treat the combined backpack and numbered Blizzard container frames as native
  windows that take visual priority over KWR.
- Restore KWR's normal strata after every bag window closes.
- Apply only the strata decision during combat; continue deferring frame
  anchors, scaling, clamping, and other layout work until combat ends.

# Non-goals

- Do not move or resize the backpack or any KWR surface.
- Do not alter secure attributes, saved variables, or battleground logic.
- Do not change the priority of KWR's modal dialogs beyond the existing native
  window policy.

# Technical constraints

- Reuse `LayoutCoordinator` as the sole surface-layer owner.
- Keep the polling path bounded and allocation-free.
- Do not re-anchor, scale, or clamp frames during combat lockdown.

# Acceptance criteria

- [x] The combined backpack lowers KWR surfaces from `HIGH` to `MEDIUM`.
- [x] An individual numbered bag also lowers KWR surfaces.
- [x] Closing all bag windows restores KWR surfaces to `HIGH`.
- [x] Opening or closing bags in combat updates strata while all other layout
      work remains deferred.
- [x] Validation and deterministic Lua smoke tests pass.

# Verification

1. Run `tools/validate.ps1`.
2. Run the Lua smoke suite.
3. In Retail, open and close the combined backpack over the Fight Now HUD both
   out of combat and during combat lockdown.

# Rollback

Revert the `LayoutCoordinator` container detection and combat-safe strata call.
No persisted data migration or SavedVariables rollback is required.
