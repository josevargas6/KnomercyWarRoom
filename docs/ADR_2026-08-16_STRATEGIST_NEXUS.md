# ADR: Evidence-gated Strategist Nexus

## Status

Accepted for implementation on 2026-08-16.

## Context

KWR has reviewed map doctrine, capability summaries, composition archetypes,
counterplay, scenario calibration, expert labels, enemy-response planning, and
5,000 deterministic Season 2 branch simulations. These inputs are valuable but the
runtime orchestration is concentrated in `Runtime/Strategist.lua`, and the raw
simulation corpus is too large and too weakly authoritative to load directly.

Simulation breadth is not live proof and the generated cases contain balanced
categorical branches rather than empirical outcome probabilities. The runtime
may use them to prove that a decision branch was exercised, but not to estimate
which tactic wins. Reviewed doctrine, capability math, and score-state theory
provide the production prior. Truth-qualified, player-reviewed AAR outcomes
provide the only adaptive learning input.

## Decision

Adopt one `StrategistNexus` runtime boundary between candidate generation and
final decision publication.

The Nexus:

1. receives normalized BoardState, prediction, capability summaries,
   composition classification, and legal candidates;
2. retrieves a constant-size aggregate from a generated corpus index;
3. applies bounded matchup, composition-theory, score-state, reversibility,
   and evidence-risk adjustments;
4. penalizes a branch if audited simulation coverage is missing, but gives no
   positive score for synthetic case counts or generated outcome labels;
5. preserves the ObjectiveRules legality result and never makes an illegal
   candidate viable;
6. returns ranked candidates and one Decision Envelope containing the primary
   call, fallback, likely enemy response, safe reply, success/abort conditions,
   confidence, and provenance.

The deterministic compiler owns the full 5,000-case JSON. The addon packages only an
aggregate Lua index keyed by map and phase with categorical counts and a schema
version. Generated evidence remains marked `SIMULATION_ONLY` and
`COVERAGE_GUARD_ONLY`. It is never promoted in place. Live refinement uses the
separate reviewed AAR learning path, which requires truth-qualified completed
matches, explicit player feedback, current-patch data, and at least five
samples before any bounded adjustment.

Composition matching uses KWR's capability vectors and reviewed archetypes.
Exact spec templates remain useful examples but are not required for the Nexus
to reason about off-meta rosters.

## Consequences

- Runtime work is bounded and deterministic.
- Strategy output gains a stable, inspectable response contract.
- Corpus changes are rebuildable and auditable without rewriting runtime code.
- Patch invalidation and evidence authority stay explicit.
- The unused zero-row simulation promotion lifecycle is removed; it cannot be
  mistaken for field evidence.
- The Nexus can be disabled or removed without deleting existing strategy
  systems.
- Live validation remains required before simulation priors gain authority.

## Safety invariants

- Unknown information remains unknown.
- Simulation evidence can only penalize a missing coverage branch; it cannot
  reward a tactic or masquerade as a win rate.
- Legal objective and low-truth gates always win.
- KWR continues to display recommendations only; the player performs every
  target, movement, communication, and combat action.
