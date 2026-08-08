---
id: KWR-031
title: Repair resolution-safe commander layout
owner: unassigned
priority: high
risk: medium
dependencies: []
affected_modules:
  - UI/LayoutCoordinator.lua
  - UI/MainWindow.lua
  - UI/Options.lua
  - UI/QuickCalls.lua
---

# Objective

Repair the resolution failures reported by the commander field test without
shrinking required text below a readable size.

# User outcome

KWR-owned windows remain reachable at reduced resolutions, and the commander
board can expose lower-priority content through scrolling instead of clipping.

# Current behavior

The compact Setup Center and Options frame relied on fixed dimensions and
saved points. The main board had no vertical content viewport. Quick-call
buttons rendered a secondary group label inside a small action button.

# Required behavior

- Coordinate KWR window bounds from the current UIParent viewport.
- Clamp the Setup Center, Options frame, and command menu after display or UI
  scale changes.
- Keep the Setup Center at its saved position while lowering it beneath
  Blizzard Options.
- Keep KWR surfaces below Blizzard spellbook, map, quest, and options windows.
- Keep protected CombatRoster frames at a fixed creation-time layer; never
  change their frame strata from the periodic layout pass.
- Make the main command board's lower content scrollable.
- Keep quick-call intent metadata available while removing the colliding
  secondary visual label.
- Preserve the existing reset-position action as the layout reset path.

# Non-goals

- Rebuild page information architecture.
- Control or reposition Blizzard-owned tooltips and capture notifications.
- Treat external Snipping Tool overlays as addon UI.

# Technical constraints

- Use one shared layout coordinator; do not add per-window placement services.
- Preserve saved-variable compatibility and secure quick-call behavior.
- Do not mutate secure attributes in combat.

# Acceptance criteria

- [x] Shared viewport profiles and clamping are wired into the addon TOC.
- [x] Setup Center remains at its saved position while Blizzard Options is visible.
- [x] Options height adapts to the viewport while retaining its scroll child.
- [x] Main board content is exposed through a vertical scroll viewport.
- [x] Quick-call action labels no longer compete with a secondary line.
- [x] KWR surfaces demote below common Blizzard windows while those windows are open.
- [x] Protected CombatRoster frames are excluded from dynamic strata changes.
- [x] Existing deterministic tests and architecture validation pass.

# Verification

1. `tools/test-lua.ps1` — smoke, soak, and replay suites pass.
2. `tools/validate.ps1` — architecture and TOC validation pass.
3. Re-run the field matrix at 1920x1080, 1600x900, 1366x768, and 1280x720
   with Blizzard Options open before release sign-off.

# Rollback

Remove `UI/LayoutCoordinator.lua` from the TOC and revert the scroll viewport
and quick-call presentation changes. Saved position data remains compatible.
