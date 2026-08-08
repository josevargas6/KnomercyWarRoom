---
id: KWR-062
title: Deepen all-RBG doctrine comparison branch density
owner: Codex
priority: high
risk: low
dependencies: [KWR-061]
affected_modules: [Data/DoctrineComparisons.lua, tests/smoke.lua]
---

# Objective

Expand the doctrine comparison and safe-counter library from a starter layer into
a deeper equal-coverage branch set for every supported RBG.

# User outcome

KWR has a broader expert-style branch library across hold, rotate, collapse,
split, recover, bait, deny, escort, return windows, and late-game score
protection before the next live field test.

# Current behavior

- Every supported RBG map has four comparison entries and four safe-counter
  responses.
- Runtime strategist can surface one selected comparison and one selected
  response.

# Required behavior

- Deepen the library to ten comparisons and ten responses per map.
- Preserve equal coverage across all supported RBGs.
- Keep the added branch families grounded in safe observable map truth.
- Extend selection helpers so the deeper branch set is actually reachable at
  runtime.

# Non-goals

- Rewriting existing strategist scoring.
- Claiming field-certified proof beyond current offline evidence grade.

# Technical constraints

- Preserve deterministic selection order.
- Avoid placeholder filler; use map-authentic objective language.
- Keep smoke coverage aligned to the deeper counts.

# Acceptance criteria

- [ ] Each supported RBG exposes ten doctrine comparisons.
- [ ] Each supported RBG exposes ten safe-counter responses.
- [ ] Runtime selection can reach the deeper branch tier.
- [ ] Smoke coverage enforces the new counts.

# Verification

1. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.

# Rollback

Remove the expanded branch templates and restore the prior counts/assertions.
