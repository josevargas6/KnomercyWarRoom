---
id: KWR-258
title: Enable reticle on PvP training dummies in preview
owner: KWR
priority: medium
risk: low
status: completed
authority_references: [ARCHITECTURE.md, DESIGN_CONTRACT.md]
dependencies: []
affected_modules: [Features/CursorRing.lua]
---

# Objective

Allow the command reticle to be tested against official PvP training dummies while Design Preview is enabled.

# User outcome

The crosshair appears on an attackable PvP training dummy in Preview mode without enabling on ordinary world or PvE targets.

# Current behavior

The reticle requires both a PvP context and a player target.

# Required behavior

Permit a narrow exception only when Preview mode is active and the target GUID matches a reviewed PvP training-dummy NPC ID.

# Non-goals

Do not enable reticles on non-PvP dummies, NPCs, or player targets outside live PvP.

# Technical constraints

Use GUID identity rather than localized dummy names. Preserve the existing nameplate anchor, combat safety, and reticle settings.

# Acceptance criteria

- [x] Preview reticle displays for an attackable reviewed PvP training dummy.
- [x] Preview reticle remains hidden for other NPC targets.
- [x] Live PvP player-target behavior is unchanged.

# Verification

1. Run `tools/validate.ps1`.
2. Run `tools/test-lua.ps1`.
3. In Preview mode, target a PvP training dummy and verify the reticle follows its nameplate.

# Rollback

Revert this task's single commit to restore the PvP-player-only reticle gate.
