# P01 — Facts, match context and current-build capability boundaries

Parent: [KWR-297](../KWR-297-s-tier-completion-packages.md).
Read [execution standard](execution-standard.md). OVR-02/06/07/16.
Lead: Terra High. Medium may implement fixtures and explicit reviewed mappings.
Prerequisite: P00 baseline recorded; P00 final ledger closure is not required.

## What and why

Complete a single public-evidence contract from Sensors through the board and
all decision consumers. The field repair fixes score truth at the Sentinel
boundary; it does not complete objective identity, per-field freshness, bracket
generation or every protected API return path.

## Actual code seams

- `State/FactStore.lua`: `FromSnapshot` and observation/confidence helpers.
- `State/BoardStateBuilder.lua`: `Build`, `keyFor`, `confidenceFor`.
- `Runtime/TruthContract.lua`: `ScoreEvidence`, `Contract`.
- `Runtime/Sensors.lua`, `TeamResolver.lua`, `MatchRuntime.lua` and existing
  RulesetLoader/Adapters own observation and match transitions.
- `Core/Util.lua`, `Adapters/SafeBattlegroundAdapter.lua`, Compliance modules,
  `Data/PatchData.lua`, `SourceRegistry.lua`, `KnowledgeManifest.lua`.
- Existing `tactical_truth.lua` and `observation_bracket.lua` fixtures.

## Required contract and implementation

1. Inventory every used API and return field: acquisition call, public/secret
   test, permitted decision/display use, freshness, fallback, current-build
   review source and affected consumers. Read official current API/hotfix sources
   at implementation/freeze; do not infer permission from a successful mock.
   If working offline with no current source, keep that review explicitly open.
2. Extend canonical fact records with stable map/objective/actor/field identity,
   evidence identity, observation clock/time, expiry, source authority and match
   generation. Preserve separate projection time. Add score/objective fact paths
   or explicit typed projections through the existing owners, not a parallel store.
3. Resolve field conflicts deterministically: reject wrong generation/invalid
   type, apply field-specific source authority, then recency only among comparable
   sources. Equal-authority contradictory observations yield conflict/unknown
   until resolved; display refresh or dictionary iteration cannot pick a winner.
4. Project canonical objective IDs rather than labels/indexes. Preserve every
   row, uncertainty and evidence dependency through board, predictor and UI.
   Reordering or localized labels must not create a new objective.
5. Establish explicit match mode and generation. Map current enums to
   STANDARD_RBG, BLITZ, UNRATED, TRAINING and UNKNOWN semantics. Never infer Blitz
   solely from partial roster size. Use verified context and degrade honestly
   when unavailable. Reload/same-map rematch clears incompatible live generations.
6. Guard every risky return before math, equality, string formatting or export.
   Preserve sparse return slots, false and zero. An unknown build disables only
   unsupported evidence-dependent behavior and reports the reason; it must not
   silently disable all useful local UI or call unknown health healthy.
7. Dependency invalidation removes only actions relying on expired/conflicting
   facts; retain unrelated valid objectives and safe duties. Feed P05 cancellation
   and P07 dirty revisions from the same canonical change, not UI heuristics.

## Verification — decisive tests

| Case | Expected result |
| --- | --- |
| Observe objective at t=10; project at 100 and 200 | Original observation retained; expires, never becomes fresh |
| Reorder identical rows, translate labels | Same semantic fact IDs and decisions |
| Two same-authority contradictory owners | Conflict/unknown, no manufactured capture |
| Known 0-0 versus numeric source=none defaults | Real tie versus UNKNOWN, including bridge/HUD |
| Missing side or future observation | Dependent action withheld; no new certainty |
| Eight hydrated players in standard RBG | No roster-size-only Blitz latch |
| Verified Blitz, late hydration, mercenary side | Consistent bracket/team projection |
| Same map rematch and reload | No previous packet, fact, countdown or cache reused as live |
| Throwing API, sparse returns, secret proxy, NaN/Inf | Bounded unknown; no forbidden operations/log leaks |
| Remove one supporting fact | Its commit eligibility cannot increase |

Exercise the actual Sensors -> FactStore/board -> Predictor -> command/UI path.
Unit tests of a new helper alone are insufficient. Secret proxies should throw
on forbidden operations so accidental formatting is detected deterministically.

## Acceptance criteria and handoff

- [ ] The field/API matrix covers every current acquisition and consumer path.
- [ ] All tests above pass in existing harnesses; supported-map scope preserved.
- [ ] P02/P03/P05 consume the same identities, clocks and unknown reason codes.
- [ ] Patch/source review records identify reviewer, date, affected slice and
      expiry; metadata dates alone are not review evidence.
- [ ] Missing real-client permission proof is labeled FIELD, not falsely passed.

High must review identity/clock/conflict policy before Medium changes consumers.
Rollback keeps unknown-safe behavior and compatibility readers; it must never
restore a numeric-default truth leak. Actual client capability checks remain a
separate field obligation, not a reason to skip offline mock paths.

## September 11 source evidence — stable fact identity slice

`State/FactStore.lua` now gives enemy and friendly identity facts a stable
GUID-or-canonical-full-name subject and evidence ID, namespaced with the current
match generation. `State/BoardStateBuilder.lua` consumes those IDs instead of
minting index-based evidence IDs. `observation_bracket.lua` exercises a real
FactStore-to-Board projection after enemy/roster reordering and an objective-label
translation; fact, enemy and friendly evidence identities remain unchanged.

`tools/test-lua.ps1 -Suite Smoke` passed (276 checks) with receipt
`artifacts/p01-stable-fact-identity-smoke-20260911.json`; development validation
also passed. This is a bounded CODE slice only. API-permission inventory,
field-conflict resolution across every producer, P02/P03/P05 consumer migration,
client evidence, and P01 review remain open.

September 12 adds match-generation namespacing to FactStore evidence IDs. The
same fixture now proves reordered/localized rows retain their IDs within a
generation, while a same-map rematch receives different enemy/friendly/objective
evidence IDs without changing the canonical objective ID. This closes the
specific prior-generation evidence-reuse defect; the broader P01 inventory and
conflict-policy work remain open.
