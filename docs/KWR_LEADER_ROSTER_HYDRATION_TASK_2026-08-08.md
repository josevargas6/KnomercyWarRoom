---
id: KWR-052
title: Prevent leader duplicates during battleground roster hydration
owner: codex
priority: high
risk: medium
dependencies: []
affected_modules:
  - Runtime/Sensors.lua
  - tests/smoke.lua
---

# Objective

Keep the Team tracker to one row per friendly player when the leader enters a
battleground before the full group roster has hydrated.

# User outcome

The leader appears once while teammates are still loading into the match.

# Current behavior

A transient party or raid token can resolve to the leader before its own
identity is stable, producing several provisional versions of the leader.

# Required behavior

- Retain the first token confirmed as the player.
- Reject subsequent non-player group tokens confirmed as the same unit.
- Preserve real teammates and same-short-name collision protection.
- Do not alter secure binding during combat.

# Non-goals

- No roster polling loop or tracker redesign.
- No merging of distinct players by display name.

# Technical constraints

- Apply the guard only in the existing `Sensors` capture boundary.
- Use Blizzard unit identity, not inferred names, for the leader-token guard.
- Keep incomplete rosters explicit rather than padding them.

# Acceptance criteria

- [x] A transient leader alias on `party1` does not add a second Team row.
- [x] The first player token and genuine party rows remain present.
- [ ] Retail leader-entry evidence confirms the Team tracker remains singular.

# Verification

1. Run `tools/validate.ps1`.
2. Run `tools/test-lua.ps1 -Suite Smoke`.
3. Join a battleground as leader before all teammates load and capture the
   Team tracker during roster hydration.

# Rollback

Revert the player-token guard in `Runtime/Sensors.lua`. No persistence change
or schema migration is required.
