---
id: KWR-243
title: Rework the compact enemy target card
owner: unassigned
priority: high
risk: low
status: in_progress
authority_references: [DESIGN_CONTRACT.md, RELEASE_READINESS.md]
dependencies:
  - KWR-242
affected_modules:
  - UI/CombatRoster.lua
  - UI/CombatRosterVisuals.lua
  - tests/smoke.lua
---

# Objective

Replace the compact Enemy tracker spotlight's crowded badge row with a readable three-line target card.

# User outcome

During combat, the commander can read the selected enemy, its evidence state, and the required action without duplicate badges or clipped text.

# Current behavior

The narrow spotlight mixes a name, health value, two often-duplicated badges, detail text, and a clipped action in one lane.

# Required behavior

- Render target, status, and action on separate lines.
- Preserve health at the top right when available.
- Translate casts, defensives, carriers, kill windows, and pressure into full action text.
- Render an equally clear idle card when no enemy is selected.
- Keep the KWR-242 CC/kill switch card as the higher-priority presentation when a coordinated call exists.

# Non-goals

- No change to enemy acquisition, truth classification, targeting, or secure click behavior.
- No frame resizing or dynamic strata changes.

# Technical constraints

- Reuse the existing spotlight frame and text objects.
- Keep the spotlight at its existing 70-pixel height.
- Hide the legacy status badges in the redesigned presentation.

# Acceptance criteria

- [x] The normal target card has separate target, status, and action lines.
- [x] The idle card clearly tells the user how to select a target.
- [x] No duplicate LIVE badges or clipped WATCH label remain.
- [x] The coordinated call card still overrides the normal target card.
- [x] Automated validation and Lua tests pass.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.
3. In WoW, verify idle, live target, last-seen, cast, defensive, carrier, kill, and pressure states.

# Rollback

Revert the KWR-243 target-card renderer, idle-card layout, tests, and changelog entry.
