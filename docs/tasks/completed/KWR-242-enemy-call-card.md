---
id: KWR-242
title: Simplify the live enemy call card
owner: unassigned
priority: high
risk: low
status: completed
authority_references: [DESIGN_CONTRACT.md, RELEASE_READINESS.md]
dependencies: []
affected_modules:
  - UI/CombatRoster.lua
  - UI/CombatRosterState.lua
  - UI/CombatRosterVisuals.lua
  - Core/Diagnostics.lua
  - tests/smoke.lua
---

# Objective

Make the live Enemy tracker spotlight readable at a glance while calling a local crowd-control target, kill target, and coordinated switch.

# User outcome

The commander can immediately read the teammate, CC class and initial, kill class and initial, and the switch countdown without interpreting tracker badges or dense status text.

# Current behavior

The spotlight primarily presents a selected enemy's health, status badges, and secondary combat context. The local call data exists but is not presented as one compact call card.

# Required behavior

When local call data is available, render three concise lines:

1. `<team member> CC - <class> <initial>`
2. `KILL: <class> <initial>`
3. `SWITCH IN 5 4 3 2 1`

Hide competing health and badge elements for this mode, preserve the normal tracker view when no call card is active, and keep the spotlight fixed within the existing CombatRoster frame.

# Non-goals

- No changes to target selection, call generation, or combat decision logic.
- No dynamic frame strata changes.
- No automatic chat, voice, or protected-action behavior.

# Technical constraints

- Use the existing `localFight`, `countdown`, and enemy identity data.
- Do not guess missing identities; use `UNKNOWN` or `?` fallbacks.
- Keep the protected CombatRoster frame at its static strata.
- Preserve the existing normal enemy spotlight presentation outside call-card mode.

# Acceptance criteria

- [x] The local call card exposes CC caller/class/initial, kill class/initial, and switch countdown in three lines.
- [x] The card hides competing health and status elements while active.
- [x] The normal spotlight restores its original anchors and elements when call data is absent.
- [x] Deterministic smoke coverage verifies the rendered live card.
- [x] Validation and Lua tests pass.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.
3. In WoW, enter a battleground and verify the Enemy tracker call card against a live local kill/CC call.
4. Confirm Blizzard windows can still cover the tracker without relocation or strata errors.

# Rollback

Revert the KWR-242 changes to the CombatRoster call-card renderer, its state wiring, diagnostics expectation, smoke fixture, and changelog entry.
