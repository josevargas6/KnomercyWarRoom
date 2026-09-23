# P04 — Feasible tactical alternatives, counterplay and target intent

Parent: [KWR-297](../KWR-297-s-tier-completion-packages.md).
Read [execution standard](execution-standard.md). OVR-03/15.
Lead: Terra High; Medium implements explicitly reviewed table/fixture slices.
Dependencies: P01 evidence, P02 objectives, P03 feasibility contracts. Integrate
with P05 lifecycle; use its contract before final end-to-end closure.

## What and why

Make materially different public states produce meaningfully different feasible
calls. The addon should compare protecting a lead, recovering an objective,
reinforcing, trading and regrouping using concrete constraints—not cosmetic
variations of one generic recommendation or fabricated enemy intent.

## Actual owners

Extend `Runtime/Strategist.lua` (`Evaluate`, `candidateSimulation`,
`compareAlternatives`, `AssessExecution`), `Runtime/StrategistNexus.lua`,
`Data/StrategistNexusPolicy.lua`, `OpenerDoctrine.lua`, `RecoveryDoctrine.lua`,
`EndgameDoctrine.lua` and `DoctrineComparisons.lua`. Trace assignments and
Commander composition instead of installing a second planner.

For tactical targeting extend `Runtime/CombatIntel.lua`,
`Intelligence/EnemyProblemDetector.lua`, `KillTargetSelector.lua`,
`ExecutionCommandBuilder.lua` and the existing control/counterplay data.

## How to implement the strategic selection

1. Derive current legal goals from P02; generate applicable candidates from the
   existing doctrine catalog. Include a feasible incumbent/hold option and
   recovery options where supported. Do not invent three choices when only one
   legal action exists; record why alternatives are unavailable.
2. Give each candidate an explicit success predicate, abort condition, required
   facts, movers/stayers/reserve, deadline, risk and fallback. These fields must
   drive behavior and review—not just explanatory strings appended afterward.
3. Apply P03 individual/collective feasibility first. Preserve rejection reason
   codes for the best discarded alternatives. Missing mandatory evidence cannot
   be compensated by score, character reputation or learned success counts.
4. Compare only feasible options. Start with hard objective/win-floor obligations,
   then reviewed tactical utility, downside, arrival uncertainty, switching cost
   and reversibility. Keep terms in documented units or normalize with explicit
   bounds. Avoid arbitrary weights that conceal forbidden outcomes.
5. Evaluate bounded plausible enemy responses from observed facts and reviewed
   doctrine: defend, reinforce, counter-trade, retreat, split or carrier response
   where the family permits. Unknown enemies are uncertainty/risk, not confirmed
   locations/cooldowns. Do not label uncalibrated utilities as win probabilities.
6. Retain commitment while differences are immaterial; replace immediately when
   required truth is invalidated. For noncritical switches use existing reviewed
   hysteresis/commitment rules and measured switching costs. Retire failed or
   terminal plans until material truth changes; integrate P05's reasoned bypass.
7. Publish the selected plan plus a bounded explanation of its strongest viable
   alternative and why it lost. A commander needs the decision-changing reason,
   not a dump of every score term. Explanations cite the actual selection inputs.

## Tactical target/control contract

Keep manual preference, pressure opportunity, observed vulnerability and kill
commit distinct. Missing health, immunity, visibility, range or capability must
not become a kill opportunity. Honor observed immunity and control/DR limits
before scoring. If a cooldown/DR field is not lawfully observable on the current
build, use an explicit unknown/conditional control recommendation, not a made-up
timer. Preserve the distinction across HUD, reticle, audio, copied call and
Sentinel. No legal target is a calm empty state, not a random fallback target.

Leader preference may rank equally feasible targets or propose a conditional
plan. It cannot force a protected/unknown target into a confirmed kill state.
Counterplay recommendations remain human-executed advice.

## Verification

For every advertised map/bracket, extend reviewed opening/lead/deficit/tie/
transition/endgame cases. Each nontrivial case needs positive and negative
counterexamples for its decision-changing predicate. Required contrasts include:

- safe lead hold versus reachable necessary trade; reinforcements arrive before
  versus after a deadline; defend minimum intact versus violated;
- carrier safe versus carrier threat confirmed versus carrier location unknown;
- supported enemy split versus insufficient evidence of split; recovery after
  failed opening versus blindly repeating the same failed plan;
- observed kill evidence versus manual favorite only; immunity active versus
  expired; unknown DR versus confirmed actionable control;
- same facts reordered/renamed versus one materially changed fact.

Mutation tests remove hard gates, corrupt a deadline, and turn unknown into zero.
All must fail. Explain each fixture using objective/feasibility predicates before
recording its expected plan; never derive the label by running the candidate.
Use P11's adjudication process for existing disputed labels and distinguish
technical review from independent tactical review.

## Acceptance criteria

- [ ] Selected plans expose and obey goal, roles, conditions, deadlines and
      fallback; infeasible candidates never win scoring.
- [ ] Held-out contrasting states produce justified, useful differences.
- [ ] Removing evidence cannot upgrade target intent or action certainty.
- [ ] Alternatives/explanations match actual evaluated state and remain bounded.
- [ ] No empirical-win or comparative-quality claim comes from generated fixtures.

## Current implementation evidence — September 11, 2026

The strategic result now retains bounded operational detail for every exposed
alternative: feasibility/missing requirements, goal, switch condition, abort
condition, role hints and stable plan tags. Simulation alternatives retain their
success, abort, reversibility, opportunity cost and observed evidence. The
Commander alternate-plan review projects an explicit `ABORT` condition rather
than treating an alternative as a score-only suggestion. Regression evidence is
`artifacts/kwr297-p04-alternatives-20260911.json` (Smoke PASS).

This is a source-contract improvement, not P04 closure: full map/bracket
contrast coverage, reviewed tactical labels, mutation suites and independent
RBG usefulness assessment remain open.

The public strategic result now calls its selected numerical value
`projectedDecisionUtility`, not win probability. It is still a bounded,
uncalibrated ordering aid and must not be interpreted as an outcome forecast;
review/AAR records retain the same distinction.

September 12 P04 hard-gate repair: objective-rule-gated simulations now sort
below legal alternatives both before and after enemy-response adjustments. The
Smoke regression permits only synthetic HOLD and proves a numerically stronger
prohibited option cannot publish; Smoke (276 checks) and validation passed.
This strengthens the implementation slice but does not replace the remaining
reviewed map/bracket contrast and independent tactical-review acceptance work.

## Rollback and handoff

Retain a tested feasible conservative option during rollout. Disable a new
doctrine branch by stable ID if it regresses; do not disable hard truth checks.
Handoff includes reviewed predicates/units, counterexample fixtures, rejected
alternative examples and a P11 review packet. Astra engineering review evaluates
the reasoning and tests; independent RBG usefulness remains P12.
