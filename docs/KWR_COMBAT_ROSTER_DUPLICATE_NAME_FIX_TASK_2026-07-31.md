---
id: KWR-2026-07-31-ROSTER-DUPE
title: Collapse duplicate friendly roster rows caused by qualified and short-name hydration
owner: Codex
priority: high
risk: medium
dependencies: []
affected_modules:
  - Runtime/TeamResolver.lua
  - tests/smoke.lua
---

# Objective

Prevent the compact team roster from showing the same player twice during live battleground roster hydration.

# User outcome

Each friendly player appears once in the compact team roster, even when group and scoreboard identity data arrive with different name formats.

# Current behavior

During live hydration, KWR can keep both a realm-qualified row and an unqualified short-name row for the same player, which creates duplicate compact roster entries.

# Required behavior

- Normalize qualified and short-name friendly roster identities into one player when the short name is uniquely identifiable in the current roster.
- Preserve safe handling for actual same-short-name collisions.

# Non-goals

- Do not merge distinct players who legitimately share the same short name.
- Do not redesign the compact roster layout.

# Technical constraints

- Keep the fix inside the existing `TeamResolver:NormalizePublishedRoster` boundary.
- Prefer the stronger record when duplicate identities collapse.

# Acceptance criteria

- [x] A qualified-name row and matching unique short-name row normalize to one roster entry.
- [x] Same-short-name collisions are still protected by uniqueness checks.
- [x] Automated validation and Lua tests pass.

# Verification

1. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.

# Rollback

Revert the short-name identity aliasing in published roster normalization.
