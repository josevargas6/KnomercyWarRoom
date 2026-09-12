---
id: KWR-295
title: Adjudicate current replay contracts before release scoring
owner: Codex
priority: critical
risk: high
status: in_progress
dependencies: [KWR-294]
affected_modules: [replay runner, decision benchmark, golden corpus, Predictor, Strategist]
authority_references: [PRODUCT_ROADMAP.md, RELEASE_READINESS.md, BATTLEGROUND_VERIFICATION.md]
---

# Objective

Turn the fresh 2,003-fixture replay result into a trustworthy release gate.
Every non-primary outcome must have a reviewed explanation before the addon can
claim that its tactical corpus validates current behavior.

# Current evidence

`artifacts/fresh-replay-full-current-20260907-plan-tags-merged/` contains 2,003
unique, hash-bound current-source results. It reports zero forbidden outputs,
zero primary matches, 578 allowed fallback matches and 1,425 unmatched contracts.
Every result also has catalog plan-tag evidence. This result does not prove that
the planner is safe or that the labels are correct. It proves that historical
cached `.run.json` files were not a valid substitute for a fresh current-runtime
evaluation.

`discrepancy-report.json` now retains the raw tags, final plan, checkpoint
evidence, label expectations and hashes for each row. The first aggregation
shows a systemic contract-granularity mismatch: labels use semantic categories
such as `PLAN:RECOVERY` and `PLAN:PACE_AHEAD`, while the planner emits concrete
map plans such as `AB_RECOVERY_PROTECT_TWO_FORCE_TRADE` and
`AB_WIN_TWO_BASE_BS_SHELL`. This is a hypothesis to test, not permission to
declare those strings equivalent. The 1,425 unmatched rows still require
per-contract adjudication; the 578 fallback rows remain fallback-only evidence.

The replay runner now emits the selected plan's deterministic reviewed catalog
tags as separate `PLAN_TAG:*` evidence. It preserves the concrete `PLAN:*` ID
and does not add any semantic matching rule. This makes a later equivalence
decision auditable without changing the current failing score.

`replay-contract-adjudication.ps1` converts that evidence into an explicit
non-accepting review queue. The first queue has 446 exact catalog-taxonomy
candidates (250 recovery and 196 opening), 979 planner-or-label reviews and
578 fallback-only rows. Every row remains unadjudicated until a named reviewer
records a disposition; the script cannot mark an item accepted.

The September 7 full-corpus strict report exits nonzero with zero primary matches
and 578 fallback-only rows. This proves the release rule is enforced before any
future label or planner remediation can claim a green benchmark.

The source labels contain 1,201 `reviewer-a`, 800 `offline-foundation-pack` and
two `developer-fixture-contract` metadata rows. Those are fixture provenance,
not named independent tactical reviewers. The queue preserves this label
provenance separately from its empty adjudication reviewer field so it cannot
be counted as completed human review.

`replay-contract-cluster-report.ps1` groups the same baseline into 69 exact
review-navigation clusters: 15 fallback-only and 54 unmatched, with no forbidden
cluster. A cluster includes profile, primary and fallback contract, observed
concrete plan, and catalog plan tags; it does not merge contracts with different
fallback expectations. It is a workload receipt, not an evaluator: every one of
its 2,003 replay IDs still needs a named, evidence-backed disposition before a
benchmark can change status.

`replay-contract-adjudication-review.ps1` is the fail-closed ledger validator.
Place one `*.adjudication.json` record per replay in the selected review folder.
Each record must identify the replay, bind its `resultSha256` and `labelSha256`
to the queue, name the reviewer and role, cite at least one evidence item, give
a timestamp, and choose `EVALUATOR_DEFECT`, `LABEL_DEFECT`,
`INTENTIONAL_FALLBACK`, `PLANNER_DEFECT`, or `PRIMARY_CONFIRMED`. Run it with
`-RequireComplete`; it exits nonzero for missing, duplicate, stale, unnamed or
unevidenced reviews and never changes a replay benchmark score. The current
receipt has 2,003 missing reviews and zero valid records, which is the expected
unadjudicated baseline rather than a partial pass.

# Required behavior

The owner requires offline completion before field testing. Follow the executable
pattern-by-pattern procedure in
[RELEASE_READINESS.md](../../RELEASE_READINESS.md#replay-remediation-that-can-proceed-offline).
This task is IN_PROGRESS, not blocked pending 2,003 manual owner reviews.
The engineer can investigate and fix technical contracts now, naming their real
reviewer identity and technical role. Independent tactical label review remains
separate required evidence and must never be fabricated or confused with coding
self-review. One shared explanation may support multiple per-replay records only
after every member satisfies its explicit predicate and regression.

- Produce a compact discrepancy report with replay ID, profile, observed plan and
  action tags, label primary/fallback/forbidden expectations, and evidence inputs.
- Normalize only semantically equivalent action identifiers in one documented,
  tested evaluator layer. Do not silently convert a planner-specific plan ID into
  a generic label match unless the equivalence is explicitly reviewed.
- Classify every unmatched or fallback-only fixture as one of: evaluator defect,
  fixture/label defect, intentional conservative fallback, or planner defect.
- Correct planner behavior only where its output is illegal, fabricated,
  unexplainable, or contradicts reviewed tactical doctrine. Correct labels only
  after their fixture contract has been reviewed; do not bulk-relabel to make a
  score green.
- Require independently reviewed labels for every advertised map, bracket and
  phase. A fallback must remain visible in the report and cannot silently satisfy
  a primary tactical-quality claim.
- Require a primary match for every result in a full-corpus or merged candidate
  benchmark. Bounded diagnostic runs may retain fallback acceptance only to prove
  runner execution; they are never release evidence.
- Re-run the complete corpus from a clean candidate and the extracted production
  package; require exact source/package agreement for all accepted inputs.

# Acceptance criteria

- [x] The benchmark exposes enough per-fixture evidence to reproduce each score.
- [ ] Every 2,003 fixture outcome has a persisted adjudication record and reviewer.
- [ ] No forbidden output is accepted; every accepted fallback is explicitly
  justified and reported separately from primary matches.
- [ ] Mutation checks show that missing, stale, secret and roster-order facts do
  not manufacture an accepted recommendation.
- [ ] Clean source and extracted-player runs cover equal replay IDs, input/label
  hashes and semantic decisions/reviewed scores. Retain each result's own hash;
  timestamps and provenance paths can differ without a decision mismatch.

# Next implementation steps

1. Select one of the existing 69 clusters and inspect its representative fixture,
   label predicate, checkpoint outputs and actual evaluator/planner code path.
   Record the proven defect and an explicit positive/negative regression.
2. Fix the owning evaluator, planner or reviewed label contract. Preserve prior
   expectations and the rationale. Do not map names based on similar wording,
   promote fallback globally or make generated labels count as independent review.
3. Run every cluster member and missing/stale/secret/roster-permutation cases.
   Split a cluster if its members require different contract interpretations.
   Persist per-replay records with actual evidence and reviewer role.
4. Repeat for unresolved patterns while other offline tasks proceed. Submit a
   compact held-out tactical review packet for the independent-review requirement;
   that review does not halt unrelated implementation.
5. Add an explicit extracted-runtime root to the fresh runner/driver and a
   semantic source/package comparator. The existing source-root runner alone
   cannot prove extracted-package parity. Negative checks must reject omitted IDs,
   changed labels/inputs, divergent actions and stale provenance.
6. Once bounded repairs pass, run the complete frozen source and extracted-player
   corpora, preserve distinct provenance/result hashes and require exact semantic
   agreement. Keep the strict primary gate and fallback counts visible.

Offline status: IN_PROGRESS. Field status: SEPARATE_DOWNSTREAM_GATE.

September 12 verification checkpoint: a fresh, frozen 2,003-result source run
and a separately executed 2,003-result extracted-player run both completed with
complete reviewed-label coverage and no runner failures. The strict provenance
comparator recorded equal replay IDs, input/label hashes, runner hashes and
semantic decisions: `artifacts/replay-semantic-parity-full-provenance-20260912.json`.
Both current discrepancy reports retain the same honest score: zero primary,
578 fallback-only, 1,425 unmatched and zero forbidden. The source queue at
`artifacts/replay-full-source-20260912/adjudication-queue.json` has 2,003 rows;
its corresponding ledger reports zero valid reviews and 2,003 missing records.
This is current parity evidence, not a passing tactical contract or an
independent review substitute.

September 9 implementation checkpoint: the replay driver now accepts an
extracted addon root and loads it in release-only mode. The fresh benchmark
records that root, while `tools/replay-semantic-parity.ps1` compares replay ID,
final plan/status/tags, checkpoint calls and evaluation result. A real locally
built player ZIP and source match on the Twin Peaks recovery probe; see
`artifacts/replay-semantic-parity-probe.json`. The full-corpus strict and
independent-review requirements remain unchanged.

# Verification

Use the merged September 7 report only as a baseline. Run the fresh runner,
decision benchmark, replay test suite, mutation/metamorphic checks, source
validation and extracted-package comparison after each reviewed contract or
planner change. Complete the candidate-bound in-game matrix separately; replay
results cannot establish live API, taint, performance or tactical usefulness.

# Rollback

Block promotion and retain the last certified fixture/package pair. Revert a
bounded evaluator, label or planner change with its regression evidence; never
replace the installed addon or mutate SavedVariables as part of replay work.
