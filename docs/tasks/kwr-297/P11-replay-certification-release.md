# P11 — Strict replay contracts, candidate certification and release evidence

Parent: [KWR-297](../KWR-297-s-tier-completion-packages.md).
Read [execution standard](execution-standard.md). OVR-20/22 and KWR-295.
Lead: Terra High; Medium can implement explicit tool-validation fixtures.
Begin harness work early; final verification depends on all required CODE slices,
including the Astra card rebuild, being integrated and frozen.

## What and why

Make the actual shipped decisions pass reviewed contracts. Certification must
fail when a required gate is missing, stale, skipped or mismatched. A default
replay PASS, identical ZIPs or 100,000 generated cases alone cannot establish this.

## Existing owners and boundaries

Continue `docs/tasks/KWR-295-replay-contract-adjudication.md` and its actual
per-replay review ledger. Extend `tools/replay-test-runner.lua`,
`fresh-replay-benchmark.ps1`, `decision-benchmark.ps1`,
`replay-semantic-parity.ps1`, adjudication tools, `certify-offline.ps1`,
`build.ps1`, `package-audit.ps1`, release manifests and candidate/readiness reports.
Use existing install/restore scripts for isolated checks; no live installation.

The September 7 2,003-result set and 69 clusters are investigation inputs, not
current repaired-candidate quality results. Existing extracted-root support and
the semantic comparator must be extended/tested, not recreated under new names.

## P11-A: resolve real replay defects

1. Inspect a cluster representative's fixture, reviewed label, concrete planner
   path, checkpoints and final result. Prove evaluator, fixture/label, planner or
   intentional-fallback cause with positive and negative examples.
2. Fix the responsible owner. Semantic mappings require explicit predicates,
   not similar plan names/tags. A planner defect changes planner logic; a label
   defect preserves the old label and reviewed rationale. Never generate expected
   labels from current output merely to obtain a green score.
3. Exercise every cluster member; split the cluster when predicates differ.
   Persist each replay's actual hashes, disposition, evidence and real reviewer
   role. Technical model review must not masquerade as independent RBG review.
4. Preserve strict primary acceptance. A reviewed conservative action can become
   that fixture's justified primary expectation; globally accepting fallback as
   primary is prohibited. Report primary/fallback/unmatched/forbidden separately.
5. Add counterfactual/negative inputs to the original audit defects: missing,
   expired, conflicting and secret facts; roster order; wrong generation;
   impossible timing; immutable state; wrong actor and unintended terminal churn.

## P11-B: strengthen semantic and provenance equality

Require identical expected replay ID sets and nonempty inputs. Verify each run's
input, label, ruleset/doctrine and executable source/package hashes, runner version
and completion. Then compare canonical semantic outputs: plan, action, objective,
actors/jobs, feasibility/rejection reasons, command revision relationships,
deadlines/abort state, target intent and checkpoint contract results.

Timestamps, absolute provenance paths and independent raw result hashes may
differ. Exclude only explicitly documented nondeterministic provenance, never a
decision-bearing field. Sort unordered sets canonically while preserving ordered
event/checkpoint semantics. Two identically wrong or empty outputs are not a pass.

Add negative comparator tests for empty folders, missing/extra/duplicate IDs,
input/label mismatch, stale runner/source, checkpoint omission, actor/target/
deadline divergence and changed forbidden results. Existing comparator projection
is narrower than these requirements; closure requires implementation, not prose.

## P11-C: one truthful certification entrypoint

1. Extend `certify-offline.ps1` to orchestrate source validation, security,
   automation, knowledge/generator checks, Lua, measured host workloads, required
   technical review accounting, fresh strict corpora, build/package audits,
   extracted semantic comparison and isolated install/upgrade/restore.
2. Distinguish diagnostic/dirty source checks from full clean release eligibility.
   Reuse existing channel semantics; add and test an explicit mode only if needed.
   `-SkipBuild`, partial corpora or skipped gates must never print full certification.
3. Resolve receipt ordering without circular self-hashes: freeze source/input
   digests; run source gates; build immutable archives with generated output
   receipts excluded; execute extracted tests; create external receipts bound to
   archive hashes; finally validate receipt integrity. Do not edit runtime inputs
   mid-freeze or use report booleans as substitutes for raw stage receipts.
4. Every required stage is PASS / FAIL / NOT_RUN with exit status, marker, paths,
   input/source hashes and scope. Missing or stale evidence fails eligibility;
   available metrics cannot hide a failed gate. Dirty builds remain diagnostic.
5. Pin/discover runtimes reproducibly. Require clean reviewed committed source
   for formal release; do not reset unrelated changes or commit the entire dirty
   tree to manufacture cleanliness. Prepare bounded review/commit work under the
   normal repository process. No publish/tag/merge permission is implied.
6. Verify all Commander/Sentinel/DevTools and developer archives, explicit TOCs,
   versions, roots, allowlists, licenses/assets and links. Reproduce binary hashes
   twice. Exercise addon and SavedVariables upgrade/rollback compatibility in
   isolated directories, including tampered backups and extra candidate files.

## Verification and acceptance criteria

Use [verification and review](verification-and-review.md) for currently available
commands. Any new parameter/suite is a deliverable and needs its own negative
tests before it appears in an operator command.

- [ ] Every current acceptance ID has a current justified contract/result, with
      required technical and independent tactical review distinguished.
- [ ] Strict primary gate passes; zero forbidden/unexplained fallback outcomes.
- [ ] Source/extracted decisions and all relevant input identities agree.
- [ ] Missing, stale, skipped, empty, dirty-for-release and tampered evidence
      reliably prevents full certification.
- [ ] Binary reproducibility, extracted load graphs and isolated restoration pass.
- [ ] RELEASE_READINESS reports CODE/REVIEW/FIELD/RELEASE separately and exactly.

## Current implementation evidence — September 11, 2026

The source-only diagnostic build at
`artifacts/kwr297-build-20260911-local-fixed` completed its deterministic
two-build comparison and extracted-package audit. The archive SHA-256 hashes
matched byte-for-byte for Commander, Sentinel, DevTools and Developer archives;
the package audit passed extracted runtime, DevTools lifecycle, 276-check
developer smoke, soak, validation, documentation/control-surface, knowledge and
100,000-case simulation gates. The authoritative machine receipts are
`KWR_6_1_1_ALPHA_12_REPRODUCIBILITY.json` and
`KWR_6_1_1_ALPHA_12_PACKAGE_AUDIT.json` in that directory.

The package audit initially uncovered a host portability defect: a nested
no-profile PowerShell process did not expose `Get-FileHash`. The release,
reconciliation, review-packet and replay-evidence scripts now use the shared
platform-SHA256 fallback in `tools/hash-utils.ps1`; the intentional missing-cmdlet
regression and `tools/test-automation.ps1` pass (238 checks) afterward. This
is evidence for the implemented portability slice only. It does not close P11:
the 2,003 replay contracts, strict corpus/adjudication, extracted semantic
comparison, clean-provenance certification and isolated upgrade/rollback proof
remain required.

September 12 evidence added a complete source/extracted-player replay pair:
each fresh runner completed all 2,003 reviewed fixtures with a passing execution
manifest. `replay-semantic-parity.ps1 -RequireProvenance` now fails closed unless
both manifests describe complete passing runs, runner hashes agree, every replay
and label input hash agrees, and every semantic decision agrees. Its receipt is
`artifacts/replay-semantic-parity-full-provenance-20260912.json`. This closes the
input/provenance parity slice only. The strict primary benchmark and 2,003 named,
evidence-backed adjudications remain open.

The integrated installed r6 candidate repeated that check on September 12 using
four bounded source workers and four extracted-player-package workers. The
merged manifests each contain all 2,003 reviewed fixtures; strict semantic
parity passed with zero semantic and provenance differences in
`artifacts/replay-semantic-parity-r6-provenance-20260912.json`. The r6
discrepancy report remains fail-closed: 0 primary, 578 fallback, 1,425 unmatched
and 0 forbidden outputs; its review ledger has 2,003 missing named reviews.
This proves source/package equality for r6, not tactical correctness or release
eligibility.

## Rollback and handoff

Preserve the frozen baseline, old labels, review decisions and failed receipts.
Rollback bounded planner/evaluator changes; never weaken acceptance to keep green.
Handoff one evidence index, exact artifact hashes, all gates and residual external
requirements. Do not replace the owner's installed field candidate during this task.
