---
id: KWR-2026-07-31-ALTERNATIVES
title: Surface midgame alternate plans from reviewed strategist options
owner: Codex
priority: high
risk: medium
dependencies: []
affected_modules:
  - UI/MainWindow.lua
  - UI/MainWindowCommands.lua
  - UI/MainWindowReports.lua
  - tests/smoke.lua
---

# Objective

Give the commander a fast in-match way to review alternate plan options when the current fight stalls.

# User outcome

When the current objective is going nowhere, the commander can press one button and immediately read the best reviewed alternate paths instead of waiting on another reassess that may repeat the same plan.

# Current behavior

The tactical board exposes `PIVOT`, which forces a reassessment, but if the strategist still ranks the same plan first the window continues to show the same objective. Alternate options exist in strategist data and the long explain report, but not in a fast commander-facing control.

# Required behavior

- Expose a tactical-board control for alternate plan review during live PvP.
- Keep the options surface available outside live PvP.
- Provide a concise local review payload that shows the current plan and the top alternate reviewed options in commander-readable language.
- Provide a slash fallback so the same review can be opened without relying on the button.

# Non-goals

- Do not auto-switch plans.
- Do not bypass objective legality, data safety, or commander approval.
- Do not create a new strategic state model separate from the current strategist output.

# Technical constraints

- Reuse strategist `alternativeReview`, `alternatives`, and simulation data already computed by the runtime.
- Keep the review local-only through the existing copy dialog.
- Preserve the tactical control row footprint.

# Acceptance criteria

- [ ] During live PvP, the last tactical control opens alternate reviewed plans instead of generic options.
- [ ] Outside live PvP, the same control still opens KWR options.
- [ ] `/kwr alts` and `/kwr alternatives` open the same alternate-plan review.
- [ ] The alternate-plan review explains the current plan and up to three reviewed alternate paths without placeholder text.
- [ ] Automated smoke coverage verifies the new payload and slash/button accessibility path.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.

# Rollback

Revert the tactical control relabel, remove the slash command, and delete the alternate-plan review payload builder.
