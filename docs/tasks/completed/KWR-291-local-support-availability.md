---
id: KWR-291
title: Require known friendly availability for support-based kill windows
owner: Codex
priority: critical
risk: high
status: completed
dependencies: [KWR-287, KWR-290]
affected_modules: [CombatIntel, Diagnostics, tactical_truth, tests]
authority_references: [AGENTS.md, PRODUCT_ROADMAP.md, RELEASE_READINESS.md]
---

# Objective

Close a bounded OVR-03/04 feasibility gap: `CombatIntel.localSupportState`
currently counts a friendly actor whenever `dead` is not true. An unknown or
disconnected player can therefore prove a favorable support count and open a
support-based kill window.

# Required behavior

Only a nearby friendly with explicit `dead=false` and `connected=true` counts
toward local support. A nearby friendly with unknown/dead/disconnected
availability makes support coverage unknown and cannot open the support-count
kill predicate. Direct observed low-health and trinket paths retain their own
evidence rules. Pressure selection remains available when a team commit is
withdrawn.

# Non-goals

This does not claim complete enemy-location coverage, physical spell range,
control readiness, assignment coverage, manual focus, relay target authority or
live proof. It adds no saved state or gameplay automation.

# Acceptance criteria

- [x] Unknown, dead or disconnected nearby friendlies cannot create a support kill window.
- [x] Explicitly alive/connected nearby friendlies can still support an observed local window.
- [x] Direct low-health evidence remains independently eligible; pressure remains when support proof is absent.
- [x] Source and extracted-package checks pass with recorded hashes.

# Verification

Extend the production tactical-truth fixture and Diagnostics with known and
unknown local-support cases. Run Smoke, full Lua, validation, then the combined
extracted package audit. No simulated result clears in-game feasibility proof.

September 7: source Smoke, full Lua, validation and the dirty interim
`local-support-availability-20260907-package` pass. The package audit verifies
396 distribution entries, 9,015 developer entries, six DevTools entries, twelve
Sentinel entries and four ZIP hashes; extracted player/developer smoke and soak,
knowledge, lifecycle and transport pass. Clean reproducibility was skipped, and
the package is neither installed nor a stable release.

# Rollback

Revert the local support predicate and its fixture together. Do not alter
installed add-ons or SavedVariables.
