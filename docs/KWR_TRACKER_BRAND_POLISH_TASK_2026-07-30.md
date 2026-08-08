---
id: KWR-037
title: Apply icon-system brand polish to compact operational trackers
owner: Codex
priority: high
risk: low
dependencies: [KWR-035, KWR-036]
affected_modules:
  - UI/CombatRoster.lua
  - UI/CombatRosterVisuals.lua
  - tests/smoke.lua
---

# Objective

Make the compact Team and Enemy trackers feel like first-class KWR operational surfaces by using the imported brand and semantic icon system in live combat.

# User outcome

The split trackers read as intentional KWR command tools, with clean shell branding and fast action recognition in rows and spotlight cards.

# Current behavior

The tracker split and clarity polish are in place, but the compact operational shell still relies too heavily on text-only structure.

# Required behavior

- Add KWR brand marks to compact tracker shell framing.
- Add semantic action icons to compact row/spotlight operational cues.
- Preserve clean single-line presentation and safe combat behavior.

# Non-goals

- Rebuild the expanded command center.
- Change strategic logic or decision outputs.

# Technical constraints

- Use the shared icon registry only.
- Do not introduce unstable local texture paths.
- Keep secure row click behavior intact.

# Acceptance criteria

- [ ] Team and Enemy compact shells display KWR brand assets.
- [ ] Compact operational cues show semantic icons where useful.
- [ ] Validation and deterministic tests pass.

# Verification

1. Run automated validation.
2. Run deterministic Lua smoke coverage.

# Rollback

Remove compact tracker brand/icon surfaces and restore prior text-only tracker presentation.
