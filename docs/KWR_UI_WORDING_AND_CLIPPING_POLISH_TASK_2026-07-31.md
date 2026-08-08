---
id: KWR-2026-07-31-UI-POLISH
title: Fix clipped tactical controls and trim backroom wording from commander surfaces
owner: Codex
priority: high
risk: low
dependencies: []
affected_modules:
  - UI/MainWindow.lua
  - UI/MainWindowPages.lua
  - tests/smoke.lua
---

# Objective

Polish commander-facing pages so labels fit cleanly and player-visible wording stays tactical instead of internal.

# User outcome

The command center reads cleanly in live and preview states, without clipped controls or internal engineering language leaking into battlefield views.

# Current behavior

- The non-PvP tactical control button label `OPTIONS` clips.
- The quick-call live/footer strip sits too low and partially hides the live badge/footer text.
- Some setup and preview text uses backroom/internal wording that is not ideal for end users.

# Required behavior

- Use a shorter non-PvP tactical control label that fits the control row.
- Raise and shorten the quick-call footer strip so it remains visible.
- Replace setup/preview/internal phrases with commander-facing wording where practical.

# Non-goals

- Do not redesign page structure.
- Do not remove reviewed strategic detail from deeper diagnostics or reports.

# Technical constraints

- Preserve current actions and page behavior.
- Keep live PvP `ALTS` behavior intact.

# Acceptance criteria

- [ ] Non-PvP tactical controls no longer crop the final button label.
- [ ] Objectives quick-call footer remains visible.
- [ ] Setup/right-rail wording removes obvious backroom phrasing.

# Verification

1. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.

# Rollback

Revert the affected UI label and positioning changes.
