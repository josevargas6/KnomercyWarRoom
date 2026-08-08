---
id: KWR-2026-07-29-FIGHT-LANGUAGE
title: Compress live commander language for combat surfaces
owner: Codex
priority: high
risk: medium
dependencies: []
affected_modules:
  - UI/HUD.lua
  - UI/MainWindow.lua
  - UI/MainWindowPages.lua
---

# Objective

Reduce combat-facing wording to short battlefield language that helps a commander act immediately.

# User outcome

During a live RBG fight, the addon reads like a commander tool instead of a technical dashboard.

# Current behavior

Several live cards still use system-facing wording such as `CURRENT CALL`, `NEXT MOVE`, `TARGET CALLER`, `LIVE UI`, `VERIFY`, `STABLE`, and `CHECK COVERAGE`.

# Required behavior

- Live combat surfaces should prefer short battlefield labels such as `LIVE`, `NOW`, `NEXT`, `WIN PATH`, `CALL TEAM`, `POSTURE`, and `KILL / CC`.
- Reassessment and uncertainty language should read like battlefield caution, not engineering state.
- Technical or review-oriented wording should remain in setup, review, or debug surfaces instead of the live fight lane.

# Non-goals

- Rewriting command logic.
- Reworking AAR or debug detail into shallow summaries.
- Altering assignment math or battlefield state ownership.

# Technical constraints

- Preserve existing surface layout and state flow.
- Keep setup mode informative for roster formation.
- Avoid introducing fake certainty where the data is partial.

# Acceptance criteria

- [ ] The compact HUD uses commander-first labels in live combat mode.
- [ ] The expanded live tactical and assignment cards use the same live language.
- [ ] Live truth badges prefer `LIVE` over `LIVE UI`.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `tests/smoke.lua`.
3. Run `tests/soak.lua`.
4. Inspect the live HUD and tactical card strings in deterministic rendering.

# Rollback

Revert the label and wording changes if the live surfaces lose clarity or hide required context.
