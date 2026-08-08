---
id: KWR-2026-07-31-SCROLL-GUARD
title: Guard report scroll clamping against recursive scrollbar callbacks
owner: Codex
priority: high
risk: low
dependencies: []
affected_modules:
  - UI/CopyDialog.lua
  - UI/MainWindowPages.lua
  - tests/smoke.lua
---

# Objective

Prevent recursive scrollbar callback loops in KWR report and review surfaces.

# User outcome

When opening or scrolling KWR evidence, review, or explanation windows, the UI remains stable and does not throw `C stack overflow`.

# Current behavior

KWR clamps scrollbar position during scroll callbacks on Blizzard `UIPanelScrollFrameTemplate` frames. In some callback orders, setting the scroll position during Blizzard's own scroll handling can re-trigger the same path indefinitely.

# Required behavior

- Guard scroll clamping against re-entry.
- Only call `SetVerticalScroll` when the clamped target differs from the current value.
- Preserve current scroll behavior and manual copy/review flows.

# Non-goals

- Do not redesign the report/export windows.
- Do not replace Blizzard scroll templates.

# Technical constraints

- Keep the fix localized to existing scroll helper utilities.
- Maintain compatibility with missing or nil scroll APIs in tests.

# Acceptance criteria

- [ ] Copy and report windows no longer recursively set the same scroll position during clamp operations.
- [ ] Existing smoke coverage for copy/report windows still passes.
- [ ] Automated validation and Lua tests pass.

# Verification

1. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.

# Rollback

Revert the guarded clamp helpers in the affected UI modules.
