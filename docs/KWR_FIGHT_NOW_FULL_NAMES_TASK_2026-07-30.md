---
id: KWR-2026-07-30-FIGHT-NOW-FULL-NAMES
title: Show full mover names in compact combat HUD
owner: Codex
priority: high
risk: low
dependencies: []
affected_modules:
  - Core/CommandView.lua
  - tests/smoke.lua
---

# Objective

Remove `+N` mover-list compression from the compact live combat HUD so the commander can read every assigned name without guessing.

# User outcome

During live combat, the `NOW`, `NEXT`, and `POSTURE` sections of the compact HUD show full mover names instead of truncating the list with `+2`, `+4`, or similar suffixes.

# Current behavior

The Fight-Now model compacts mover names to four visible entries and appends `+N` for the remainder. The compact HUD then renders that shortened mover string in the live combat path.

# Required behavior

- The Fight-Now model must keep full mover names for live combat HUD rendering.
- Existing compact/export-oriented text paths may remain compact where they are not part of the live combat HUD.

# Non-goals

- Rewriting general command summary/export formatting.
- Expanding unrelated roster or assignment surfaces.

# Technical constraints

- Preserve the existing Fight-Now data model shape.
- Keep short-name formatting, but do not append `+N` in the live combat HUD path.
- Maintain deterministic smoke coverage.

# Acceptance criteria

- [ ] Live Fight-Now `WHO` text shows every mover name in order.
- [ ] Live `OFF:` posture text shows the full mover list.
- [ ] Deterministic validation and smoke pass.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `tests/smoke.lua`.

# Rollback

Restore the previous compact mover rendering if the full-name live combat HUD causes unacceptable readability or layout regressions.
