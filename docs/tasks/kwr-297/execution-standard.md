# KWR-297 shared execution standard

This specification implements [KWR-297](../KWR-297-s-tier-completion-packages.md)
under [AGENTS.md](../../../AGENTS.md) and
[RELEASE_READINESS.md](../../../RELEASE_READINESS.md). Existing engineering and
release authorities remain in force. All contract additions below are proposed
requirements, not assertions that these fields or methods already exist.

## Read, reproduce, then change

1. Read the task, assigned package, relevant OVR/REC sections and actual caller /
   callee path. Record what is present, partially present and absent.
2. Add a deterministic failing assertion for the missing behavior. Exercise the
   real production module and public input path, not a copied implementation.
3. Make the smallest coherent implementation; preserve compatibility at existing
   boundaries. Update an ADR when changing shared schemas or ownership.
4. Run focused positive, negative, mutation and metamorphic tests. Run the full
   Lua/validation gates for integrated runtime changes and package tests when
   load graphs, generators or manifests change.
5. Record source/input/test hashes, exact command, exit status and raw receipt.
   Explain any remaining obligation using CODE, REVIEW, FIELD or RELEASE.

Do not mark pre-existing behavior missing solely because its filename differs.
Conversely, a method or fixture with the right name does not prove the behavior.
Prefer extending current modules; split a large module only at an actual stable
domain seam. No package requests an architectural rewrite by default.

## Shared data contracts

Map these semantic fields onto current owner tables and version migrations where
needed. One canonical owner per fact; use compatibility projections for callers.

| Contract | Required meaning and invariants | Existing owner to extend |
| --- | --- | --- |
| Fact | Stable subject/field and evidence identity; value or unknown; source; observation time; clock; expiry; match generation; authority/conflict state | Adapters, Sensors, FactStore, TruthContract |
| Objective | Canonical map/objective ID; typed family state; owner/carrier/progress only where known; independent evidence for each field; legal transitions | ObjectiveIntel, ObjectiveRules, map data |
| Reach | Actor, objective, earliest/latest arrival or unknown; route/version; assumptions and evidence expiry; no scalar invented certainty | Reporter, Maps |
| Feasibility | ALLOWED / FORBIDDEN / UNKNOWN; stable reason codes and evidence IDs; collective coverage effects | AssignmentScorer/Optimizer, Assignments |
| Plan candidate | Stable plan/revision; goal; movers/stayers/reserve; feasibility; evidence dependencies; success/abort/fallback predicates; deadline; alternatives | Strategist, StrategistNexus, Commander |
| Command projection | Match generation; command ID/revision; current action/jobs; shared start/deadline; active/retired state; trust and reason codes | Commander, CountdownState, CommandView |
| Decision episode | Command identity; generated/delivery/observed execution/outcome separately; clocks; doctrine/context revision; retained evidence IDs | CommandReview, AAR, Learning |

Missing mandatory evidence cannot become a number, a confirmed role or a legal
commit through defaulting. Zero and false are valid observations; nil, expired,
secret, unsupported and conflicting are distinguishable unknown reasons.
Existing enums differ between subsystems; add explicit mappings and rejection
tests rather than passing CONFIRMED/HIGH/OBSERVED strings interchangeably.

## Clock domains and identity

- Use monotonic session time for TTL, scheduler deadlines and responsiveness.
  Keep `observedAt`, `generatedAt`, `queuedAt`, `publishedAt` and `displayedAt`
  distinct. Projection at t=100 cannot refresh an observation from t=10.
- Persisted CommandReview currently uses `UNIX_SECONDS`. Retain that contract
  or perform a versioned migration. Never subtract a wall timestamp from client
  uptime. Persist session identity alongside monotonic values; after reload,
  old monotonic deadlines cannot authorize a new live action.
- Same map and bracket do not imply the same match. Namespace fact, packet,
  command, countdown, cache and episode IDs with a new match generation.
- Use GUID or canonical full realm identity for actors, canonical objective IDs
  for goals, and labels only for display. Ambiguous short names cannot bind secure
  units or count as confirmed observations. Reordering cannot change identity.

## Decision logic required of every package

The decision order is: validate available public evidence, determine legal state,
enforce individual and collective feasibility, compare feasible alternatives,
apply commitment/replacement rules, then publish one owned projection. Scoring,
manual preference and learned adjustments cannot override a hard prohibition.

UNKNOWN feasibility is not FORBIDDEN knowledge, but it cannot authorize an
evidence-dependent commit. It may support a clearly labeled conditional plan or
a no-regret observation/hold action when that action is itself feasible. If even
holding is unsafe, issue a bounded shortage/emergency message; do not manufacture
defenders or a harmless default. No fixed confidence derived solely from score.

Distinguish an observed outcome from causation. A friendly cap after a delivered
call can be an observed matching result; it is not proof that the addon caused
the cap or the match victory. Predicted win value is not calibrated win probability.

## Ownership, performance and safety

- Producers retain their inputs; Store owns published branches. Never mutate a
  previously published state through reconciliation, cache reuse or rendering.
  Copy only necessary branches once ownership is demonstrated by tests.
- Bound insertion as well as periodic pruning. Include old/future schema loads,
  rematches, flood packets and hidden UI in the bounds. Preserve active truth;
  shed derived diagnostics before authoritative match state.
- All visible/audio/copied/Sentinel command consumers use the same revision and
  cancellation. Critical invalidation withdraws stale cues before expensive work.
- Use legal adapters only. Secret values must not reach comparisons, arithmetic,
  formatting, logs, sorting or serialization. Do not try alternate APIs to recover
  information intentionally protected by the client.
- Secure actions remain user-triggered. No automatic targets, casts, movement,
  chat spam, protected attribute changes in combat or attempts to bypass lockdown.
- No network dependency for the live decision loop. Optional Sentinel stays an
  explicit, bounded feature with a fully useful local-only path.

## Medium, High and Astra responsibilities

Routing is a project work allocation, not an official guarantee about any model.
Both Terra settings have identical correctness and evidence obligations.

- **Medium:** implement one approved interface slice, explicit fixtures, schema
  validation, deterministic projections, localization, report/tool wiring and
  bounded mechanical edits. Document interface ambiguities with counterexamples.
- **High:** own cross-module contracts, threat model, clocks, state transitions,
  feasibility, search/selection policy, scheduler ownership and migrations. Resolve
  ambiguity before dependent production consumers are changed.
- **Astra review:** inspect a diff and independently run targeted checks. Return
  concrete findings and evidence, not an honorary grade. Engineering review by
  any model never substitutes for independent RBG tactical reviewers.

If Medium finds a High-owned contract unresolved, it may finish independent tests
or tooling without guessing the contract. It should hand off the exact decision
and failing case; a model setting alone is not a reason to label unrelated work
blocked. Do not change model settings or spawn tasks/agents without authorization.

## No shortcuts that close the wrong gate

Reject: broad fallback-to-primary promotion; labels copied from current outputs;
silenced assertions; accepting empty corpora; timestamp-only evidence; writing a
PASS JSON by hand; dirty HEAD presented as exact source identity; obsolete caches
used as live facts; synthetic timings sold as CPU results; “needs field testing”
used to conceal an unimplemented deterministic path; or auto-closing all OVR rows
because a build script returns zero.

Code-complete, reviewer-approved, client-verified and release-authorized must
remain separate. Where the product cannot lawfully observe a required field,
implement and test honest degradation and document the remaining capability
limit. Do not promise perfect information as an S-tier feature.
