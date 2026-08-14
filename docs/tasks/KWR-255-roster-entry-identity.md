---
id: KWR-255
title: Suppress provisional duplicate friendly roster identities at battleground entry
owner: Codex
priority: high
risk: low
status: in_progress
authority_references: [ARCHITECTURE.md, DESIGN_CONTRACT.md]
dependencies: []
affected_modules:
  - Runtime/Sensors.lua
  - tests/smoke.lua
---

# Objective

Prevent repeated local-player rows in the Team tracker while WoW raid tokens
are still hydrating after a battleground loads.

# User outcome

The Team tracker shows one row per verified teammate, or a reduced count while
it synchronizes; it never presents several assignments for one player.

# Current behavior

The entry transition can expose distinct realm-qualified provisional rows with
the same short name before unit or GUID identity is stable.

# Required behavior

- Deduplicate unbound, GUID-less provisional roster rows by short name.
- Preserve distinct same-short-name teammates once unit or GUID identity is
  stable.
- Add deterministic coverage for the entry-race input.

# Non-goals

- No changes to strategic assignments, persisted settings, or enemy identity.

# Technical constraints

The roster capture path must remain bounded, avoid protected operations, and
prefer omission over guessing during the Blizzard API hydration window.

# Acceptance criteria

- [ ] A provisional `Verite-Area52` / `Verite-Illidan` pair yields one Team row.
- [ ] Existing stable same-short-name behavior remains covered by smoke tests.
- [ ] Lua validation and smoke tests pass.

# Verification

1. Run `tools/validate.ps1`.
2. Run `tools/test-lua.ps1`.
3. Enter a battleground and confirm the Team tracker shows no duplicate rows.

# Rollback

Revert the `seenUnstableShortName` capture guard. No saved variables or schema
are changed.
