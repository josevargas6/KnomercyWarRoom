---
id: KWR-2026-07-30-TACTICAL-FRAME-FIT
title: Keep the tactical command page inside its window
owner: codex
priority: high
risk: low
dependencies: []
affected_modules:
  - UI/MainWindow.lua
  - tests/smoke.lua
---

# Objective

Fit every tactical-page card inside the command-center content area without
reducing the map to a secondary surface.

# User outcome

The tactical map, recent calls, next call, and command controls remain fully
visible and readable inside the KWR Command Center at supported UI scales.

# Current behavior

The tactical page uses roughly 678 vertical UI units inside a 616-unit content
area. Recent Calls and Controls extend through the command-center bottom border.

# Required behavior

- Keep all three tactical columns within the 616-unit content boundary.
- Preserve the proportional tactical-map canvas.
- Keep all ten team-job rows visible.
- Keep Recent Calls useful and contained.
- Keep every tactical control available without a second button row.

# Non-goals

- Changing tactical decision logic.
- Redesigning other command-center pages.
- Changing window scale or saved position behavior.

# Technical constraints

- Reuse the current card and theme primitives.
- Do not introduce per-frame layout work.
- Preserve combat-lockdown behavior and secure execution boundaries.

# Acceptance criteria

- [x] No tactical card extends below the command-center content frame.
- [x] The map and Recent Calls remain visible together.
- [x] All ten team jobs fit in their card.
- [x] PIVOT, RESCAN, COPY, MINI, and OPTIONS remain available.
- [x] Automated validation and Lua tests pass.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.
3. Reload WoW and capture the Tactical Map page in design preview.

Automated verification completed on 2026-07-30:

- `VALIDATION PASSED`
- `KWR_SMOKE_PASS checks=275`
- `KWR_SOAK_PASS refreshes=500`
- `KWR_REPLAY_RUN_PASS`
- `KWR_LUA_TESTS_PASS suite=All`

# Rollback

Revert the tactical-page geometry and matching smoke assertions.
