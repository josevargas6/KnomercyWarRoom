---
id: KWR-028
title: Stabilize team tracker identity during battleground roster hydration
owner: unassigned
priority: high
risk: medium
dependencies: []
affected_modules:
  - Runtime/Sensors.lua
  - UI/CombatRoster.lua
  - UI/CombatRosterState.lua
  - tests/smoke.lua
---

# Objective

Prevent one friendly player from occupying multiple team-tracker rows while a battleground raid and scoreboard are still loading.

# User outcome

The team tracker converges to one row per actual teammate regardless of join order, including when the local player enters before the rest of the raid.

# Current behavior

Transient realm-qualified names, GUIDs, scoreboard rows, and raid-unit tokens can describe the same player as separate identities. A loading snapshot can therefore fill two secure rows with the local player.

# Required behavior

Reconcile friendly identity using authoritative raid-unit ownership, exact full names, GUIDs, and safe transitional aliases. Reject mismatched raid-name/unit pairs and collapse stale local-player aliases before publishing the roster.
Show the expected roster size and a loading state until every published identity has a stable raid-unit binding.

# Non-goals

- Do not collapse two verified teammates who genuinely share a short name across realms.
- Do not alter enemy identity handling or assignment doctrine.
- Do not mutate secure unit attributes during combat lockdown.

# Technical constraints

- Blizzard unit and scoreboard feeds hydrate asynchronously.
- Secure row bindings may only change outside combat lockdown.
- Unknown identity must remain unknown; no fabricated GUIDs or unit ownership.
- Roster refresh work must remain bounded to battleground team size.

# Acceptance criteria

- [x] Early local-player and later authoritative raid records converge to one row.
- [x] Realm-mismatched raid-name/unit pairs are not treated as stable bindings.
- [x] Two verified raid units with the same short name remain distinct.
- [x] Published friendly roster cardinality never exceeds the expected group count because of aliases.
- [x] Existing secure-row combat behavior remains intact.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `fengari tests/smoke.lua`.
3. Run `fengari tests/soak.lua`.
4. Field-test entering a battleground before the rest of the team and capture the final tracker plus `/kwr verify`.

Automated evidence on 2026-07-18:

- `validate.ps1`: passed with 118 Lua files, 0 errors, and 0 warnings.
- `knowledge-audit.ps1`: passed with 0 errors.
- `smoke.lua`: passed, including partial hydration, realm mismatch, same-short-name, loading-heading, and secure rebind assertions.
- `soak.lua`: passed 500 refreshes with 120 bounded duration samples, 0 runtime errors, 0.234 ms average, 0.800 ms p95, and 3.200 ms maximum refresh time.
- Live early-entry field confirmation remains the final user-side check after `/reload`.

# Rollback

Revert the bounded identity reconciliation and its regression assertions; no saved-variable migration is involved.
