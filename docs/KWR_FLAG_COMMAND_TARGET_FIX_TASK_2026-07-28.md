---
id: KWR-034
title: Prevent flag-event prose from becoming a command target
owner: unassigned
priority: high
risk: medium
status: LIVE_ONLY_REMAINDER
dependencies:
  - docs/field-evidence/2026-07-28-twin-peaks/README.md
affected_modules:
  - Runtime/ObjectiveIntel.lua
  - Runtime/Reporter.lua
  - Runtime/Strategist.lua
  - Runtime/Assignments.lua
  - Runtime/Commander.lua
  - tests/smoke.lua
---

# Objective

Keep raw battleground flag-event sentences as evidence while ensuring every
tactical action target is a canonical objective, location, carrier, or
assignment.

# User outcome

Flag calls remain concise and actionable. The user sees a command such as
covering the friendly carrier or reinforcing a reviewed route, never an action
whose target is a complete Blizzard system sentence.

# Current behavior

The live Twin Peaks Tactical page rendered:

`COVER Our FC: Jade. REINFORCE Alliance Flag has been picked up`

The pickup sentence is useful evidence, but it is not a tactical location or
action target. It entered the response/action path and produced malformed
commander copy.

# Required behavior

- Define the canonical command-target contract for flag maps.
- Normalize faction-specific flag messages against the assigned team:
  friendly carrier, enemy carrier, Our FC, Enemy FC, Home, Mid, or another
  reviewed map location.
- Keep the original system sentence in the event/evidence timeline.
- Reject prose, timestamps, player pickup sentences, and unknown widget labels
  at the command-target boundary.
- Fall back conservatively when a canonical target cannot be resolved.
- Keep carrier identity, owner, drop, return, capture, and reset semantics
  intact.

# Non-goals

- No automatic chat.
- No new objective parser outside `ObjectiveIntel`.
- No fabricated flag ownership.
- No hard-coded assumption that the player's native faction is the assigned
  battleground team.
- No unrelated command-stability change.

# Technical constraints

- Assigned-team truth determines friendly/enemy wording.
- Localized messages remain bounded by the existing grammar boundary.
- Adapters/events provide observations; strategy consumes normalized facts.
- Unknown remains unknown.

# Acceptance criteria

- [x] Alliance and Horde pickup messages normalize correctly for both assigned
  battleground sides.
- [x] Drop, return, capture, and reset messages retain the affected flag.
- [x] Raw event prose remains available in Last Events and AAR evidence.
- [x] Raw event prose never appears as a `REINFORCE`, `ROTATE`, `HOLD`, or
  `COVER` target.
- [x] A missing canonical target produces a conservative `VERIFY`/hold call.
- [x] Deterministic tests cover faction, mercenary/cross-faction, and unknown
  cases.
- [x] Validate, knowledge audit, smoke, and soak pass.
- [ ] Live Twin Peaks evidence shows an actionable carrier/route call.

# Offline implementation result

Reopened on 2026-08-03 as an offline implementation blocker. The existing
ObjectiveIntel event timeline remains raw evidence, while the new canonical
target boundary derives friendly/enemy carrier semantics from assigned team
truth and falls back to `VERIFY`; unrecognized targets force `HOLD CURRENT
PLAN`. Live carrier-state evidence remains live-only.

# Verification

1. Replay reviewed Alliance/Horde pickup, drop, return, and capture messages.
2. Run `tools/validate.ps1`.
3. Run `tools/knowledge-audit.ps1`.
4. Run `fengari tests/smoke.lua`.
5. Run `fengari tests/soak.lua`.
6. Capture the Tactical page and `/kwr explain` during a live carrier change.

# Rollback

Restore the previous target path and tests together. No persisted schema change
is required.
