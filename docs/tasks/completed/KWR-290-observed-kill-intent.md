---
id: KWR-290
title: Make kill commitment consume observed target intent
owner: Codex
priority: critical
risk: high
status: completed
dependencies: [KWR-281, KWR-283, KWR-289]
affected_modules: [CombatIntel, BoardStateBuilder, EnemyProblemDetector, KillTargetSelector, TeamfightCommandPlanner, ExecutionCommandBuilder, CursorRing, tests]
authority_references: [AGENTS.md, PRODUCT_ROADMAP.md, RELEASE_READINESS.md, DESIGN_CONTRACT.md]
---

# Objective

Complete the next bounded OVR-03 correction. KWR-283 stopped preference from
setting `killable`, but `CombatIntel.killTarget` still aliases the highest-scored
pressure target. The detector can also make a Kill problem from overextension or
health even when the observed kill predicate is false. That lets a preferred
target appear to be a coordinated kill commitment.

# User outcome

The commander can show a nearby pressure target without calling it a kill. A
team kill, execution packet and KILL reticle appear only for a current observed
kill window. Defensive, unavailable-support and stale/unknown-vulnerability
states withdraw the commitment while retaining truthful pressure or swap help.

# Required behavior

- Publish separate `PRESSURE`, `OBSERVED_KILL_WINDOW`, `SWAP`, and `NONE` target
  intent from CombatIntel. Intent names the target, reason and whether a team
  kill commit is eligible.
- Keep `localTarget` as the preferred local pressure/watch target. Populate
  `killTarget` only from an observed kill-window candidate; never from ranking.
- Carry the intent through BoardState. The detector and selector must reject a
  Kill problem/selection when the target is not currently killable. Existing
  explicit legacy fixture inputs that set `killable=true` remain supported.
- Preserve a local `PRESSURE` execution fallback. Do not generate a team KILL,
  countdown, KILL reticle or audible kill command from pressure alone.
- Derive kill confidence from the qualifying target evidence; assignment count
  and support-control assignment count may rank/package work but cannot upgrade
  that confidence.

# Non-goals

This does not add a player manual-focus control, claim full physical range or
support-coverage certainty, infer cooldown ownership, add automation or relay
target commands. It does not complete typed FactStore expiry/conflict work,
feasible-control work, ActivePlay integration, live field proof or the release
candidate process.

# Technical constraints

Use the existing observed `killable` predicate as the sole bounded commitment
source. Do not write target intent to SavedVariables. Preserve current public
field names for compatible pressure displays while making their meaning exact.
Prefer no team target or a pressure call on missing/contradictory evidence.

# Acceptance criteria

- [x] A high-scored but non-killable enemy produces `PRESSURE`, no `killTarget`,
  no Kill problem and no team-kill execution/reticle.
- [x] A current observed low-health/support kill window produces
  `OBSERVED_KILL_WINDOW`, a Kill problem and a team kill target.
- [x] Active observed defense, target death, loss of local eligibility, and
  missing support evidence withdraw the kill intent and team commit.
- [x] Carrier/objective and legacy direct board inputs cannot bypass the
  selector's observed-kill requirement.
- [x] Kill confidence remains unchanged when only assignment/support count
  changes.
- [x] Source, package extraction and recorded-hash checks pass before closure.

# Verification

Extend the production `tactical_truth.lua` fixture through CombatIntel,
BoardState, EnemyProblemDetector, KillTargetSelector, Teamfight planner,
ExecutionCommandBuilder and CursorRing. Run source Smoke, validation and the
combined extraction package audit. Test target transitions with a controlled
clock and preserved live API mocks; no synthetic pass clears real-client proof.

September 7 source gate: Smoke (276 checks), the full Lua suite, validation and
diff whitespace check pass. The receipt
`artifacts/observed-kill-intent-20260907/source-checks.json` records exact input
hashes and results. The dirty interim package
`observed-kill-intent-20260907-package` passed extracted Commander/developer
Smoke and 500-refresh soak, validation, knowledge regeneration, DevTools
lifecycle, Sentinel transport and four ZIP-hash verification. Its audit records
396 distribution entries, 9,013 developer entries, six DevTools entries and
twelve Sentinel entries. Clean reproducibility was intentionally skipped; this
package is not installed or release-ready. See
`artifacts/observed-kill-intent-20260907-package/KWR_6_1_1_ALPHA_12_PACKAGE_AUDIT.json`.

# Rollback

Revert the target-intent projection, consumer gating and fixtures as one
transient runtime change. Do not modify installed add-ons or SavedVariables.
