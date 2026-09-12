# P02 — Complete objective-family transition engines

Parent: [KWR-297](../KWR-297-s-tier-completion-packages.md).
Read [execution standard](execution-standard.md). OVR-13.
Lead: Terra High for transitions; Medium for reviewed tables and fixtures.
Dependencies: P01 canonical facts, match generation, bracket and capabilities.

## What and why

A top-level commander must understand how the current objective can actually be
won, lost, contested or become unavailable. A map label plus generic HOLD/ROTATE
text is not an objective engine. Complete the existing engines instead of adding
another disconnected tactical database.

## Existing code and scope

Extend `Runtime/ObjectiveIntel.lua`, `Data/ObjectiveRules.lua`, `Data/Maps.lua`,
`Data/RBGMapProfiles.lua` and the family functions in `Runtime/Predictor.lua`.
Trace corresponding Commander family milestone/invalidation helpers. Retain
current localized message grammars, but require reviewed exact grammar/identity
resolution before a message becomes evidence. Unsupported text remains unknown.

## In-progress implementation evidence (2026-09-11)

`ObjectiveIntel` now treats a concrete `instanceID` as authoritative session
identity when both its retained state and a new sensor snapshot provide one.
Consequently, a same-map rematch clears retained carrier and assault-timer state
instead of inheriting the preceding match's facts. The compatibility path for
reviewed system chat that initially contains only a map identity remains intact;
the subsequent full snapshot supplies the instance boundary. `tests/smoke.lua`
covers the old-instance/new-instance rejection. Reviewed flag grammar now also
emits distinct `FLAG_RETURN`, `FLAG_CAPTURE`, and `FLAG_RESET` facts; capture
retains the observed capturer instead of being collapsed into the return branch.
The Commander public-outcome consumer accepts only an exact opponent-flag
capture for an eligible explicit capture command. This is bounded transition
work, not completion of the required family transition matrix.

September 12 adds a common transition-clock guard: a typed event must carry a
finite nonnegative observation time and cannot be older than the retained
objective transition. The production fixture verifies a stale node-assault fact
does not advance the prior controlled state. This closes the out-of-order input
path only; it does not claim the full family matrix.

The current advertised map keys are ARATHI, GILNEAS, DEEPWIND, WSG, TWINPEAKS,
EOTS, TEMPLE, SILVERSHARD, DEEPHAUL and SEETHING. Read current supported bracket
metadata; do not assume every map is available in every live queue. Any advertised
combination needs an explicit capability/ruleset entry, not silent removal.

`ObjectiveRules:Transition` now provides a pure, family-aware accepted/rejected
transition contract. `ObjectiveIntel` feeds typed system events through that
contract and exports accepted transitions alongside raw events; unsupported or
cross-family events leave prior state unchanged. Smoke covers observed assault,
flag capture, cross-family rejection and the live flag-event projection. This
is bounded transition infrastructure only: the complete family/bracket matrix,
reviewed constants/provenance, deadline projections and all consumer migration
remain open.

## How to code it correctly

1. Inventory present family fields and all consumers. Define a typed transition
   contract inside the existing owner: previous state + accepted public fact +
   ruleset + session clock -> next state and material-change reasons.
2. Separate observed state, modeled consequence and unknown. Each field keeps its
   own evidence/time. An assault does not prove ownership; a pickup does not
   prove delivery; a predicted completion is not an observed capture.
3. Encode allowed transitions and necessary preconditions as reviewed data or
   small pure functions. Invalid/stale/wrong-session transitions cannot advance
   state. Recovery after missing observations may rehydrate from an authoritative
   snapshot without inventing the unseen intermediate sequence.
4. Keep bracket/build-specific score rules and timings in reviewed map/ruleset
   data with source and version, not inline UI strings. Do not fill uncertain
   game mechanics from memory. Synthetic test constants must be labeled fixtures.
5. Produce a projection containing current legal opportunities, objective value
   basis, earliest/latest meaningful deadline, and missing conditions. Predictor
   computes only from supported known inputs; impossible or unknowable times
   remain nil/unknown, never infinity-as-an-action or zero-as-instant-win.
6. Update family-specific Commander success/abort predicates to use canonical
   transitions. UI, assignments, AAR and Sentinel read those same IDs/states.
   Retain backward-compatible display projections until every consumer migrates.

## Family completion matrix

| Family / maps | State and decision work required | Critical negative case |
| --- | --- | --- |
| Node / ARATHI, GILNEAS, DEEPWIND | Ownership, assault/contest, defend/recover, pending completion, score rate and win-floor obligations | Contested node counted as safely owned or its last defender released |
| Flag / WSG, TWINPEAKS | Base/carried/dropped/returned/captured/reset; carrier identity; return-before-cap eligibility; terminal agreement | Stale carrier or unresolved friendly-flag state authorizes a cap/escort commit |
| Hybrid / EOTS | Tower ownership and flag opportunity/value under the selected ruleset, coupled constraints | Flag value treated as constant or a capture assumed legal without its prerequisites |
| Orb / TEMPLE | Orb identity/holder, possession/loss/respawn, zone value only when supported, survivability uncertainty | Unknown position or holder converted into confirmed high-value control |
| Cart / SILVERSHARD, DEEPHAUL | Map-specific cart/resource mechanics, contest/progress/endpoint, relevant route/switch state only when observed | Reusing one map's cart rules blindly or expired progress yielding a precise cap time |
| Resource / SEETHING | Spawn/available/channel/collected/exhausted cycle with observed ownership/progress | Spawn estimate treated as an active resource, channel start counted as collected |

The row names are implementation responsibilities, not a claim that all current
mechanics have been externally reviewed in this specification.

## Verification

For each supported map/bracket pair use opening, lead, deficit, tie, transition,
endgame, unknown, conflicting and terminal fixture states. Include every legal
transition and at least one rejected predecessor/event pair. Test a missed-event
rehydration and a same-map rematch. Compare sensors/objectives, predictor, jobs,
command, UI projection and AAR against the same expected objective state.

Use boundary clocks just before, at and after deadlines. Duplicate accepted
observations must be idempotent; out-of-order inputs must not resurrect older
state. Ended matches cannot issue another completion call from unchanged truth.
Changing one material ownership/carrier/resource fact must change the relevant
legal opportunity; changing labels/row order must not.

Add rule mutations: remove a cap precondition, count contested ownership, swap
team side, reuse a previous generation. Each mutation must fail the owning test.
Run focused family fixtures, full Lua and knowledge/scenario-generation audits.

## Acceptance criteria

- [ ] Every advertised family has reviewed states, transitions, unknown paths,
      deadlines and consumer integration; no generic prose stands in for logic.
- [ ] All matrix and boundary tests pass through the production path.
- [ ] Map/bracket/build constants have provenance and capability fallbacks.
- [ ] P03/P04/P05/P06 consume identical canonical objective contracts.

## Rollback and handoff

Keep family implementations bounded; disable only an unverified advanced branch
with an explicit capability reason while preserving safe existing display.
Record this as incomplete advertised behavior, not a passing scope reduction.
Handoff the transition tables, consumer map, rule references, tests and actual
remaining unknown capabilities. High reviews logic before Medium fills tables.
