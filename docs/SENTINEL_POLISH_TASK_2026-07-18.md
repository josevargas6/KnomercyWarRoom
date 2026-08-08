---
id: KWR-SENTINEL-001
title: Polish Sentinel execution card for live testing
owner: unassigned
priority: high
risk: low
dependencies:
  - docs/SENTINEL_DESIGN_HANDOFF.md
affected_modules:
  - KWRSentinel/Core.lua
  - KWRSentinel/HUD.lua
  - KWRSentinel/MinimapButton.lua
  - KWRSentinel/Theme.lua
---

# Objective

Make the installed Sentinel player card feel like a polished alpha surface
rather than a developer HUD.

# User outcome

The player can read trust state, job, movement, target, and hold/win guidance
quickly without rough truncation or visual clutter.

# Current behavior

The card is functional but visually flat. Several commander-derived lines are
too long and truncate abruptly. The default position sits close to the minimap
and the utility buttons feel bolted on.

# Required behavior

- Improve hierarchy for title, match pace, job, move, target, and footer.
- Normalize long commander prose into short player-facing lines.
- Preserve compact one-card scope from the Sentinel design handoff.
- Add a reset command for recovering the card position.
- Add a minimap logo that opens and closes Sentinel without affecting
  Commander.
- Match Sentinel's target cue to the KWR Commander crosshair visual language
  while anchoring it to the reviewed target nameplate.
- Keep standalone fallback and same-client KWR bridge behavior unchanged.

# Non-goals

- No cross-player addon communication.
- No new commander UI.
- No new strategy, assignment, targeting, focus, cast, macro, or movement
  behavior.

# Technical constraints

- No protected action automation.
- No new dependencies.
- Keep TOC order deterministic.
- Keep work bounded to visible HUD refresh.

# Acceptance criteria

- [ ] `TO HOLD` and `TO WIN` render compact player lines without rough
      truncation in the observed AB preview case.
- [ ] `MY JOB`, `MOVE`, and `TARGET` have stronger hierarchy than supporting
      text.
- [ ] The default card position is less likely to collide with minimap/right
      commander surfaces.
- [ ] Sentinel renders a commander-style crosshair on the reviewed target
      nameplate rather than a boxed text marker or fixed screen-center overlay.
- [ ] `/kwrs reset` restores the polished default position.
- [ ] The Sentinel minimap logo toggles the execution card and target cue off
      so Commander can be tested without duplicate overlays.
- [ ] Validation and package audit pass.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `fengari tests/smoke.lua`.
3. Run `./tools/build.ps1 -IncludeSentinel`.
4. Reinstall the generated `KWRSentinel` package into the WoW AddOns folder.

# Rollback

Restore the previous `KWRSentinel/Core.lua`, `KWRSentinel/HUD.lua`, and
`KWRSentinel/Theme.lua` revisions, rebuild with `-IncludeSentinel`, and
reinstall the previous package.
