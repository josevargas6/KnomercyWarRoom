---
id: KWR-261
title: Clarify native PvP identifiers and target reticle
owner: Codex
priority: high
risk: low
status: completed
authority_references: [DESIGN_CONTRACT.md, ARCHITECTURE.md, AGENTS.md]
dependencies: [KWR-256]
affected_modules:
  - Features/CursorRing.lua
  - Core/Addon.lua
  - UI/Options.lua
  - tests/smoke.lua
---

# Objective

Replace the visually dense nameplate tokens with native KWR PvP identifiers
that preserve the standard Blizzard nameplate and make target priority clear at
a glance.

# User outcome

- Enemy players have a 42-pixel class icon in a circular native orb, matching
  the readable scale of the supplied reference addon, without a duplicate KWR
  name or health strip.
- Friendly players have a square role badge: healer shield/cross, tank shield,
  or DPS crossed swords. Objective carriers replace that role icon with the
  coloured orb or flag appropriate to the battleground.
- The target reticle remains KWR-native and restrained: its class icon is in
  the centre, while the tactical cue stays to the left. The ordinary target
  nameplate stays visible below it.

# Current behavior

KWR renders a centred ring with icon, duplicate player name, health/cast
strips, and a text role badge. It is legible but competes with the native
nameplate and has more visual weight than required during live combat.

# Required behavior

- Render enemy class icons at exactly 42 by 42 pixels inside a circular orb.
- Render friendly role icons inside a square badge instead of friendly class icons.
- Continue using the existing carrier icon and colour logic for orb and flag
  maps.
- Anchor the compact marker above the native nameplate; never hide, replace,
  or fabricate its normal name.
- Add the target class icon to the existing reticle and move its tactical cue
  to the left side.

# Non-goals

- No copied code, assets, dependency, or runtime bridge to EnjoyPvPIcons or
  FuryCrosshair.
- No prohibited range query or combat interaction API call.
- No target selection, assignment, or protected-frame changes.

# Technical constraints

The markers are mouse-disabled, allocate only per visible nameplate, and use
existing Blizzard texture atlases. Nameplate API calls remain limited to valid
nameplate unit tokens. No persisted schema migration is needed.

# Acceptance criteria

- [x] Enemy class marker is exactly 42 pixels square and has no duplicate KWR name.
- [x] Friendly healer, tank, and damage records select their respective native role icons.
- [x] Carrier records still replace the friendly role icon with a coloured orb or flag.
- [x] Reticle centre displays the reviewed target class when available.
- [x] Standard nameplate remains unmodified by KWR marker rendering.
- [x] Validation and deterministic Lua smoke tests pass.

# Verification

1. Run `tools/validate.ps1`.
2. Run `tools/test-lua.ps1`.
3. In a battleground, inspect enemy, teammate-role, orb-carrier, flag-carrier,
   target, reload, and combat-lockdown states.

# Rollback

Revert the bounded CursorRing and settings changes. No saved-variable data is
lost and no external addon is required.
