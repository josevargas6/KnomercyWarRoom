---
id: KWR-2026-07-31-LOGIN-MESSAGE
title: Align login-message option text with actual chat behavior
owner: Codex
priority: medium
risk: low
dependencies: []
affected_modules:
  - UI/Options.lua
---

# Objective

Remove confusion around the startup notification setting.

# User outcome

The options panel accurately describes that KWR currently posts a chat-line startup notice, not a visual popup banner.

# Current behavior

The setting label says it "Displays the KWR load banner when the addon initializes," but the code only prints a chat message on `PLAYER_LOGIN`.

# Required behavior

- Update the options label and helper text so they describe the real current behavior.

# Non-goals

- Do not build a new startup popup banner in this change.

# Technical constraints

- Keep the saved setting and behavior unchanged.

# Acceptance criteria

- [ ] The option text clearly says it controls a login chat message.

# Verification

1. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.

# Rollback

Revert the options copy changes.
