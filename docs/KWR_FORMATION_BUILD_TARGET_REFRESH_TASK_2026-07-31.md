---
id: KWR-039
title: Refresh formation setup board after build target change
owner: Codex
priority: high
risk: low
dependencies: []
affected_modules:
  - UI/MainWindow.lua
  - tests/smoke.lua
---

# Objective

Make the visible RBG setup board update immediately when the player presses the
formation `AUTO`, `PREV`, or `NEXT` buttons.

# User outcome

When the build target changes, the setup page changes on screen right away
instead of only printing the new build target in chat.

# Current behavior

The formation controls update the selected build target and print confirmation
to chat, but the visible tactical setup board can remain stale until a later
store notification or another refresh path repaints the page.

# Required behavior

- After a successful formation build target change, the main window should
  repaint from the refreshed store snapshot immediately when visible.
- Smoke coverage should prove that the visible setup board reflects the
  selected build target.

# Non-goals

- Formation advisor logic changes.
- Roster recommendation scoring changes.

# Technical constraints

- Do not add a new ticker or polling path.
- Reuse the existing `ForceRefresh` and main-window render pipeline.

# Acceptance criteria

- [x] `AUTO`, `PREV`, and `NEXT` build-target actions repaint the visible setup board immediately.
- [x] Smoke coverage asserts that the tactical setup board text changes with the selected build target.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1 -Suite Smoke`.

# Rollback

Revert the immediate main-window repaint path and the smoke assertion changes.
