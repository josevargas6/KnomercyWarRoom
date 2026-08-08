---
id: KWR-061
title: Build all-RBG doctrine comparison and safe-counter library
owner: Codex
priority: high
risk: low
dependencies: [KWR-060]
affected_modules: [Data/DoctrineComparisons.lua, Data/KnowledgeManifest.lua, KnomercyWarRoom.toc, tests/smoke.lua]
---

# Objective

Add one structured all-RBG doctrine comparison library that captures explicit
commander tradeoffs and safe enemy-response branches for every supported map.

# User outcome

KWR gains a durable offline layer for expert-style map reasoning:
"option A vs option B" and "enemy does X, safest counter is Y" without hiding
that logic inside generic prose.

# Current behavior

- KWR has broad doctrine in `Doctrine`, `BattlePlans`, `OpenerDoctrine`,
  `RecoveryDoctrine`, and `EndgameDoctrine`.
- The repository does not yet expose one authoritative structured library of
  map-specific comparison choices and safe response branches.

# Required behavior

- Add a runtime-safe data module containing equal coverage for all supported
  RBG maps.
- Cover both:
  - commander option comparisons
  - enemy-pattern safe-counter responses
- Keep entries grounded in safe observable battlefield facts.
- Expose counts and retrieval helpers for smoke coverage and future runtime use.

# Non-goals

- Automatically executing these branches without strategist review.
- Claiming field proof beyond the current offline-reviewed status.
- Rewriting existing doctrine systems.

# Technical constraints

- Lua-only implementation.
- No accidental globals.
- Keep wording commander-readable, short, and map-authentic.
- Preserve deterministic load and test behavior.

# Acceptance criteria

- [ ] Every supported RBG map has equal doctrine-comparison coverage.
- [ ] Every supported RBG map has equal enemy-response coverage.
- [ ] The module is loaded by the addon and visible to tests.
- [ ] Knowledge summary reflects the new library counts.
- [ ] Smoke coverage asserts the library is present and returns expected data.

# Verification

1. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate.ps1`.

# Rollback

Remove the module, TOC reference, manifest counters, and smoke assertions.
