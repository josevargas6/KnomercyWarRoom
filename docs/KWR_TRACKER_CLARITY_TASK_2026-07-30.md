---
id: KWR-036
title: Tighten compact tracker text for clean single-line commander readability
owner: Codex
priority: high
risk: low
dependencies: [KWR-035]
affected_modules:
  - Core/Util.lua
  - UI/CombatRoster.lua
  - UI/CombatRosterVisuals.lua
  - UI/RosterPresentation.lua
  - tests/smoke.lua
---

# Objective

Make compact Team and Enemy trackers read cleanly in live combat with no word wrap, no ellipsis filler, and no accidental overflow language.

# User outcome

Commanders can glance at the split compact trackers and immediately understand names, status, jobs, and local fight details without wrapped lines or trailing dots.

# Current behavior

Shared text helpers and default font behavior can introduce wrapped text or `...` truncation in compact tracker surfaces.

# Required behavior

- Compact tracker text is single-line where intended.
- Compact tracker text does not append `...`.
- Tracker labels stay short, on-brand, and commander-readable.

# Non-goals

- Redesign expanded pages.
- Change battlefield logic or assignments.

# Technical constraints

- Keep tooltip detail intact.
- Limit text changes to compact tracker presentation unless a shared helper is clearly safer.

# Acceptance criteria

- [ ] Compact tracker titles, headings, rows, and spotlight stay single-line.
- [ ] Compact tracker displayed text does not contain `...` from truncation.
- [ ] Automated validation and Lua tests pass.

# Verification

1. Run automated validation.
2. Run deterministic Lua smoke coverage.

# Rollback

Restore prior tracker text helpers and font behavior.
