# P03 — Reachable rotations, hard assignment feasibility and formation

Parent: [KWR-297](../KWR-297-s-tier-completion-packages.md).
Read [execution standard](execution-standard.md). OVR-04/14/17.
Lead: Terra High. Medium implements approved route fixtures and shortage UI data.
Dependencies: P01 evidence/bracket contract and P02 objective legality interface.

## In-progress implementation evidence (2026-09-11)

`Intelligence/AssignmentFeasibility.lua` is now the loaded pre-score gate for
teamfight assignment proposals. It reports stable `ALLOWED`, `FORBIDDEN` and
`UNKNOWN` outcomes, rejects unavailable actors, sole-defender abandonment and
guaranteed-deadline failures, and retains route source plus earliest/latest
modeled arrivals. `AssignmentOptimizer` records rejected candidates instead of
silently scoring them. The focused production-path fixture covers mandatory
coverage, explicit trade, deadline boundaries, unknown location and optimizer
rejection; Smoke passes. Commander location locks now use the same gate for hard
prohibitions and retain unknown route truth rather than fabricating an ETA. This
is only the first P03 slice: final-assignment integration, reviewed route data,
bracket/profile cache invalidation, exhaustive oracle comparison and the full
8/10 formation matrix remain open.

## Additional implementation evidence (2026-09-12)

`Data/Maps.lua` now carries explicitly labeled modeled route intervals
(`earliestSeconds`/`latestSeconds`), basis, revision and constraints rather
than leaving consumers to infer certainty from a display ETA.
`AssignmentFeasibility` preserves that provenance and uses the latest bound for
guaranteed deadlines. `AssignmentOptimizer` now reserves a departure during
its bounded set search, so two individually legal rotations cannot jointly
empty a mandatory friendly objective. The focused fixture covers a reviewed
6/8 interval pass, a 6/10 conservative deadline failure, and collective
coverage; `tools/test-lua.ps1 -Suite Smoke` passed 276 checks and
`tools/validate.ps1` passed on 2026-09-12. This is implementation evidence,
not reviewed live-route data or the complete formation/oracle acceptance matrix.

## What and why

Replace attractive but impossible assignments with feasible choices. Preserve
mandatory defense, carriers, healer/support coverage and a reserve as required by
the reviewed ruleset. Unknown reach cannot be solved by a high capability score.

## Existing implementation seams

- `Runtime/Reporter.lua`: `ObjectiveETAs`, `travelSpeed`, tracking freshness.
- `Data/Maps.lua`: existing `TravelEstimate`; map/profile route inputs.
- `Intelligence/AssignmentScorer.lua`: `Score` currently gates availability/role.
- `Intelligence/AssignmentOptimizer.lua`: `Optimize`, candidate sets, bounded
  search and assignment projection. Preserve its search cap and improve it safely.
- `Runtime/Assignments.lua`, `AssignmentOverrides.lua`, `FormationAdvisor.lua`,
  `State/FriendlyRoleState.lua`, `Data/PlayerControlProfiles.lua`.

## Required implementation

1. Extend the existing route interface with earliest/latest arrival, observed
   versus modeled basis, route ID/revision, constraints and evidence age. Use
   reviewed route edges/ranges for crossings/elevation where available. A
   straight-line screen distance is at most a labeled coarse estimate, not
   proof of navigable travel time. Do not create a movement/navigation bot.
2. Account for actor availability, current objective duty, carrier restrictions,
   combat/mobility assumptions and publicly known respawn state. Unknown release
   or resurrection phase yields an unknown component, not a guessed next wave.
   Keep aggregated ETA evidence at the age of its oldest required input.
3. Define a shared feasibility check before scoring, with stable ALLOWED,
   FORBIDDEN and UNKNOWN outcomes plus reasons. Apply it in candidate generation,
   manual overrides and final publication; callers must not bypass it by directly
   invoking the scorer or reusing an obsolete feasible result.
4. Evaluate timing conservatively when a guaranteed deadline is required:
   `latestArrival + requiredInteraction + safetyMargin <= earliestDeadline`.
   Values must share units/clock and have reviewed bounds. If intervals overlap,
   label the option uncertain/conditional; do not call it assured. A plan may
   intentionally accept risk only as explicit doctrine, never by hiding UNKNOWN.
5. Validate the assignment set, not only each actor/job pair. Reserve minimum
   coverage at retained objectives, required support and incompatible duties.
   Carry reservations into search; reject branches as soon as coverage fails.
   An explicit reviewed objective trade may change the coverage obligation, but
   a high scalar score or manual preference cannot silently erase it.
6. Make actor and objective tie-breaking deterministic using canonical identity,
   not short display names. Bound candidates/search nodes, retain a feasible
   incumbent, and report budget exhaustion. With no feasible set, publish the
   shortage and safest feasible partial duties; never assign one actor twice.
7. Complete both 10-player and verified 8-player formation profiles. Profile,
   roster/spec/connection/role and bracket revisions invalidate caches. Leader
   overrides are scoped and reversible; unknown/unavailable actors stay excluded
   from duties requiring those properties. Preserve no named-character bonuses.

## Synthetic examples to implement as tests

- Route A earliest/latest 6/8 seconds; interaction 2; safety margin 1; deadline
  12: timing check passes. Change latest to 10: it fails the guaranteed timing
  predicate. These are fixture values, not actual map travel claims.
- Two individually attractive rotations each remove a required defender; the
  combined assignment is rejected even when every actor is alive and nearby.
- Unknown rogue position plus strong control profile cannot authorize a local
  interrupt. A nearby publicly eligible backup can; otherwise report no solution.
- Rename actors while preserving GUIDs/capabilities: feasibility and utility stay
  equal. Reorder roster: deterministic selected identities stay equal.

## Verification matrix

Cover dead, disconnected, nil availability, missing capability, missing healer,
carrier, last defender, ambiguous cross-realm names, leaver, spec change, profile
change, long/blocked route, stale location, unknown resurrection and deadline
boundaries. Run each applicable case in both formation sizes. Test a legal
objective trade as well as an illegal abandonment; do not hardcode permanent
defense of every node regardless of doctrine.

Force the optimizer's node budget down to exercise its fallback; verify the
returned incumbent is still feasible. Compare production output with an exhaustive
oracle on deliberately small fixtures. Add a mutation that bypasses each hard
gate and require an impossible-assignment assertion to fail. Score changes alone
are not sufficient proof of feasibility.

## Acceptance criteria

- [ ] Route intervals and uncertainty survive all consumer projections.
- [ ] The same hard gates govern automatic proposals and manual overrides.
- [ ] Individual and collective constraints pass the full negative matrix.
- [ ] Bounded search is deterministic on equal inputs and never returns an
      infeasible incumbent; shortages are explicit and useful.
- [ ] Existing formation/cache fixes and all Lua regressions remain intact.

## Rollback and handoff

Keep a conservative, tested assignment path behind existing capability/feature
controls while integrating richer routes. Never fall back to forbidden actors
when an optimization fails. Handoff the feasibility reason catalog, route
provenance, reservation contract and search-oracle comparisons for High review.
