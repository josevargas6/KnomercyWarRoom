---
id: KWR-034
title: Synchronize local fight truth with commander surfaces
owner: unassigned
priority: critical
risk: medium
status: in_progress
authority_references: [ARCHITECTURE.md, DESIGN_CONTRACT.md]
dependencies:
  - KWR-032
  - KWR-033
affected_modules:
  - Core/CommandView.lua
  - UI/CombatRosterVisuals.lua
  - tests/smoke.lua
---

# Objective

Prevent unresolved local-fight placeholders from becoming target calls and make Fight Now react immediately to confirmed local combat.

# User outcome

When the team is fighting at an observed location, Fight Now reports that fight under NOW while retaining the approved strategic play under NEXT. Unknown identities never appear as actionable CC or kill calls.

# Current behavior

The Enemy tracker can render abbreviated placeholder identities as `UNKNOWN`, and Fight Now can continue presenting only its stabilized strategic play while a confirmed local fight evolves elsewhere.

# Required behavior

- Publish an Enemy call card only when the kill or assigned CC target resolves to a confirmed enemy record.
- Use the confirmed active local kill/pressure target and location for Fight Now's NOW recommendation.
- Preserve the stabilized strategic play under NEXT with an `AFTER FIGHT` transition.
- Revert automatically to the normal target card and strategic current call when local-fight truth clears.

# Non-goals

- No automatic chat or voice output.
- No invented enemy identity, class, location, or tactical recommendation.
- No change to secure targeting or frame strata.

# Technical constraints

- Use only the existing `executionCommand.localFight` packet and published enemy records.
- Require an exact GUID/name match before displaying an actionable Enemy call card.
- Keep strategic command stabilization intact; this is a current-versus-next presentation split.

# Acceptance criteria

- [x] Unresolved targets such as `U`, `S`, or `UNKNOWN` do not produce a switch card.
- [x] A confirmed local fight updates Fight Now's action and location under NOW.
- [x] The stabilized strategic play remains visible under NEXT.
- [x] Deterministic coverage verifies both confirmed and unresolved cases.
- [x] Validation, smoke, soak, and replay tests pass.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.
3. In a live battleground, fight at an observed objective and verify NOW follows the local fight while NEXT retains the strategic play.
4. Clear or lose local enemy truth and verify the local override disappears.

# Rollback

Revert the KWR-034 CommandView override, Enemy call-card validity gate, deterministic assertions, changelog entry, and this task brief.
