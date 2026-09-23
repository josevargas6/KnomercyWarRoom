---
id: KWR-283
title: Restore objective projection and separate preference from feasible actions
owner: Codex
priority: critical
risk: high
status: completed
dependencies: [KWR-281]
affected_modules: [BoardStateBuilder, CombatIntel, AssignmentScorer, AssignmentOptimizer, PlayerControlProfiles, tests]
authority_references: [AGENTS.md, PRODUCT_ROADMAP.md, RELEASE_READINESS.md, DESIGN_CONTRACT.md]
---

# Objective

Fix the reproduced missing-objective, preferred-target promotion and dead-actor
defects under OVR-02/03/04 without adding tactical features.

# User outcome

The tactical board includes captured objectives. Choosing an enemy to watch
does not manufacture evidence that it can be killed. Known dead/disconnected
players cannot receive control jobs regardless of their score or name.

# Current behavior

The board iterates the objective summary rather than its `rows`. CombatIntel
overwrites its own evidence predicate by setting the top-ranked enemy killable.
Unavailable actors receive a soft -200 penalty that positive weights overcome.
Hardcoded short-name weights prefer Knomercy and Stan without capability proof.

# Required behavior

- Read the canonical objective rows, retaining the bounded array fallback for
  existing callers. Preserve row identity, location and existing board caps.
- Recompute target flags every analysis. Keep the preferred local target for
  watch/UI compatibility while deriving `killable` only from existing observed
  vulnerability checks. Clear selection flags from previous winners.
- Exclude known unavailable actors before optimizer candidate trimming. Scoring
  must independently refuse unavailable input; no score can overcome that rule.
- Remove name-specific capability bonuses; role/spec capability data remains.

# Non-goals

This task does not complete typed per-field provenance/expiry, unknown friendly
availability, support coverage certainty, DR/cooldown/range feasibility, execution
deadlines or migration of the legacy `combat.killTarget` watch-target alias.
Those broader OVR-02/03/04/05 gates remain explicit and open.

# Technical constraints

Keep the existing pipeline and output fields. No saved schema or default
changes. Preserve KWR-280 work and KWR-282 fixes. A safe fallback is no control
assignment when every actor is unavailable, not a best-effort impossible call.

# Acceptance criteria

- [x] Canonical and legacy objective inputs produce bounded, correct board rows.
- [x] Unknown health/support does not become killable merely by winning preference.
- [x] Observed low-health candidates still qualify; active defenses suppress them.
- [x] Former winners lose their target marker on selection change or death.
- [x] Dead/offline actors cannot consume candidate slots or produce assignments,
  even with extreme positive severity/capability values.
- [x] Renaming an otherwise identical player does not change capability scores.
- [x] Relevant Lua regressions and source validation pass with evidence recorded.
- [x] Verify these changes in the next extracted package before task closure.

# Verification

Extend source smoke coverage, also used on extracted Commander. Keep the original
audit reproductions unchanged. Capture the relevant source hashes and results.
Live tactical quality and fresh package verification remain separate gates.

September 5: `tools/test-lua.ps1 -Suite Smoke` and `tools/validate.ps1` passed
after the change. `tests/fixtures/tactical_truth.lua` exercises actual board,
combat, detector, scorer and optimizer modules. The regression includes a
million-point impossible assignment and more unavailable actors than candidate
slots, plus downstream rejection of a kill problem for unknown vulnerability.
The local source receipt is `artifacts/tactical-truth-20260905/source-checks.json`.

Package closure: `artifacts/audited-regressions-20260905-02/` passed extracted
player/developer smoke and soak, Sentinel transport, DevTools lifecycle and four
ZIP checksums. Its source manifest/provenance bind the tested content. Clean
reproducibility was skipped for this dirty interim build. Broader OVR-02/03/04
truth, feasibility and field requirements remain open.

# Rollback

Revert this bounded projection/selection/scoring change with its tests, retaining
all prior source recovery and boundary fixes. Do not change installed addons.
