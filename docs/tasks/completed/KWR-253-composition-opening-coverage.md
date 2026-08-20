---
id: KWR-253
title: Expand composition-aware opening doctrine coverage
owner: unassigned
priority: high
risk: medium
status: completed
authority_references: [DESIGN_CONTRACT.md, RELEASE_READINESS.md]
dependencies: [KWR-251]
affected_modules: [Data/OpenerDoctrine.lua, Runtime/Strategist.lua, tests/smoke.lua]
---

# Objective

Provide at least ten additional composition-aware opening branches for each
supported battleground without creating a second strategist.

# User outcome

Opening calls adapt to the observed friendly/enemy composition matchup and
qualified roster tier while retaining explicit uncertainty and safe fallbacks.

# Required behavior

- Keep `OpenerDoctrine` the authoritative opening branch owner.
- Add ten matchup branches per supported map beyond the existing five.
- Select an exact friendly/enemy archetype matchup before generic threat rules.
- Use qualified tier-specific branches only when the tier is valid for the map.
- Mark every branch as theory reviewed and requiring live match validation.

# Acceptance criteria

- [x] Every supported map exposes at least fifteen opening branches.
- [x] Ten new friendly/enemy matchup branches are available per map.
- [x] Tier-aware selection is passed through the existing strategist.
- [x] Deterministic selection assertions pass.
- [ ] Retail opening captures validate representative matchup branches.

# Verification

1. Run validation and Lua tests.
2. Assert branch count and representative archetype/tier selections for all maps.
3. Capture live opening evidence for each map family and matchup class.

# Rollback

Revert KWR-253; generic reviewed opener branches remain available.

# Closure disposition

Closed 2026-08-19 as implementation-complete. Representative Retail opening
captures remain a field-validation gate and do not promote theory-reviewed
branches to verified live doctrine.
