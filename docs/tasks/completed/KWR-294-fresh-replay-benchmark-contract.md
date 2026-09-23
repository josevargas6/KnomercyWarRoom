---
id: KWR-294
title: Require fresh hash-bound replay benchmark results
owner: Codex
priority: critical
risk: medium
status: completed
dependencies: [KWR-040]
affected_modules: [Predictor, replay benchmark, golden corpus]
authority_references: [RELEASE_READINESS.md, PRODUCT_ROADMAP.md]
---

# Objective

Replace reliance on historical replay result files with a runner that creates
new results, records exact source/input/result hashes, and refuses incomplete
full-corpus coverage.

# Required behavior

`tools/fresh-replay-benchmark.ps1` writes a new result directory and manifest.
Its default is every replay; a full run fails if a replay lacks a golden label.
The bounded mode is explicitly marked non-certifying. It also exposed and fixed
missing derived `enemyNeeded` handling in every Predictor family.

# Acceptance criteria

- [x] All 2,003 current replay fixtures have a golden-label contract.
- [x] New replay output is bound to runner, driver, replay, label and result hashes.
- [x] A bounded fresh run passes and does not claim full-corpus evidence.
- [x] Node, orb, cart and resource prediction derive absent remaining score safely.

# Verification

Run `tools/test-fresh-replay-benchmark.ps1`, the two formerly unlabelled replay
fixtures, Smoke, corpus audit and validation. A default fresh run remains
required against the final clean candidate; it is intentionally not replaced by
the bounded fixture test.

## Current-source checkpoint — 2026-09-07

The fresh runner completed all 2,003 current-source fixtures in
`artifacts/fresh-replay-full-current-20260907-parallel24/`. Its 24 worker
manifests bind one replay-runner hash and one test-driver hash; the merged report
in `artifacts/fresh-replay-full-current-20260907-merged/` contains exactly 2,003
distinct results. No worker failed and no result emitted a forbidden action.

The follow-up source state that emits reviewed catalog plan tags completed the
same 2,003-fixture run in
`artifacts/fresh-replay-full-current-20260907-plan-tags-merged/`. Its
`discrepancy-report.json` confirms every result records at least one
`PLAN_TAG:*` value, separate from its concrete plan ID. This retains the
evidence required to review semantic-label claims without silently scoring them
as matches.

The decision score is deliberately **not** a pass: zero results matched their
primary expectation, 578 matched an allowed fallback, and 1,425 matched neither.
The old result corpus therefore cannot be treated as current tactical evidence.
This run is dirty-source diagnostic evidence only; it neither certifies the
labels nor substitutes for the required clean-source and extracted-package runs.
KWR-295 owns the per-fixture contract/behavior adjudication before OVR-20 can
advance.

Full-corpus and merged runs now set `RequirePrimaryForEveryResult`; an allowed
fallback remains in the evidence report but fails candidate scoring. The bounded
fresh-runner test retains fallback acceptance only because it verifies runner
execution, not release quality. `test-decision-benchmark.ps1` proves both modes
against the same fallback-only fixture.

# Rollback

Revert the runner, label migration and Predictor fallback together. No
SavedVariables or installed addons change.
