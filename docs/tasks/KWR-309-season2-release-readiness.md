---
id: KWR-309
title: Refresh Season 2 team building and release readiness
status: in_progress
owner: unassigned
priority: high
risk: medium
dependencies: [live-field-certification, protected-release-workflow]
affected_modules: [Data/PatchData.lua, Data/Compositions.lua, Runtime/FormationAdvisor.lua, tests/smoke.lua]
authority_references: [AGENTS.md, RELEASE_POLICY.md, RELEASE_READINESS.md]
---

# Objective

Bring the premade-builder's source review current and remove misleading automatic build choices before the next field candidate.

# User outcome

A premade leader sees role-valid, map-appropriate choices, including a flag-carrier support shell, without unsupported claims that a patch note proves a ladder tier. A public package is published only through the repository's release gates.

# Current behavior

The patch watch stops at September 4. Automatic target selection treats one extra matching spec as more important than an incompatible map. Some historical and provisional tiers appear more certain than their evidence warrants.

# Required behavior

- Record reviewed official PvP changes through September 22 without inventing capability weights or observed ranking.
- Prefer a map-compatible automatic target on a known battleground; retain a user-selected target as an explicit choice.
- Preserve role-balanced, ten-player shells and add an advisory flag-carrier escort build with Augmentation support.
- Keep release authorization, exact package provenance, and live certification separate from local test readiness.

# Non-goals

- Claiming a statistically validated Season 2 specialization tier list from directional hotfixes.
- Turning a local build or field candidate into a stable public release without protected checks.

# Technical constraints

No SavedVariables schema change. No new live combat API calls. World-context advice must remain map-neutral. All additions must keep the existing deterministic load order.

# Acceptance criteria

- [ ] Official review date and advisory provenance are current.
- [ ] Known-map automatic selection never chooses a map-incompatible shell when a compatible shell is available.
- [ ] A flag-map Augmentation escort shell is available and not mislabeled as a proven tier.
- [ ] Relevant Lua, knowledge, package, and release audits pass or report explicit holds.

# Verification

1. Run validation, knowledge audit, Lua smoke/soak, and packaging checks.
2. Assert map fit and advisory selection with deterministic tests.
3. Bind any field claims to an exact installed package and live evidence.

# Rollback

Revert this bounded data and selection change; no persisted migration is involved. For a published build, use the protected superseding-release process rather than replacing artifact bytes.
