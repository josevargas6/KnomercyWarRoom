---
id: KWR-262
title: Keep lightweight KWR targeting available outside rated battlegrounds
owner: Codex
priority: high
risk: medium
status: completed
authority_references: [DESIGN_CONTRACT.md, ARCHITECTURE.md, AGENTS.md]
dependencies: [KWR-261]
affected_modules:
  - Core/Addon.lua
  - Features/CursorRing.lua
  - UI/Options.lua
  - tests/smoke.lua
---

# Objective

Give KWR a low-cost arena and world-PvP presentation mode without allowing
Rated Battleground commander surfaces or protected targeting behavior to leak
into those contexts.

# User outcome

- RBGs retain the full Commander experience.
- Arenas hide KWR boards/rosters but retain the target reticle and legal
  player-nameplate markers.
- World PvP retains a target reticle only for attackable player targets; mobs
  and pets are not presented as a PvP target.
- The player no longer has to disable KWR merely to enter an arena or world
  PvP zone.

# Current behavior

KWR suppresses all CursorRing work in arenas. Its reticle only permits an
active battleground, a supported training dummy preview, or an RBG state.

# Required behavior

- Keep full Commander, roster, assignment, and strategy surfaces suppressed in
  arena and world contexts.
- Permit only the bounded reticle and valid nameplate unit-token marker work
  in arenas.
- Permit the reticle in world PvP only after the existing attackable-player
  checks succeed.
- Do not set, replace, bind, or intercept TAB/Shift-TAB. Target-key behavior
  remains the responsibility of a dedicated targeting addon and Blizzard.

# Non-goals

- No arena strategy engine, pet classifier, automatic target selection, or
  third-party addon bridge.
- No protected-frame, secure binding, or combat-time settings mutation.

# Technical constraints

Use the existing context API, `UnitCanAttack`, `UnitIsPlayer`, and valid
nameplate unit tokens. Retain the existing 0.20/0.25-second reticle/marker
refresh backoffs and hide the driver when no visual is active.

# Acceptance criteria

- [x] Arena context retains only the lightweight target/nameplate layer.
- [x] World-PvP reticle rejects attackable mobs and non-player targets.
- [x] RBG Commander surfaces remain unaffected.
- [x] No TAB binding or protected-action call is introduced.
- [x] Context settings are visible and reversible in Options.
- [x] Lua, validation, and soak tests pass.

# Verification

1. Run `tools/validate.ps1`.
2. Run `tools/test-lua.ps1`.
3. Test a battleground, arena, outdoor PvP player target, outdoor mob target,
   pet target, reload, and combat-lockdown transition.

# Rollback

Disable the two lightweight-context preferences or revert this bounded
CursorRing/settings change. It does not alter key bindings or saved bindings.
