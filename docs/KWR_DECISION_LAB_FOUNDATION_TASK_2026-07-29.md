---
id: KWR-041
title: Complete Decision Lab foundation scaffolding
owner: unassigned
priority: high
risk: medium
dependencies:
  - KWR-037
  - KWR-038
  - KWR-039
  - KWR-040
affected_modules:
  - knowledge/corpus-manifest.json
  - knowledge/schemas/corpus-manifest-schema.json
  - knowledge/schemas/outcome-review-schema.json
  - knowledge/fixtures/adversarial-replay-template.json
  - knowledge/fixtures/outcome-review-template.json
  - tests/adversarial/
  - tests/outcomes/
  - tests/replays/
  - tests/golden/
  - tests/replay-results/
  - tools/corpus-audit.ps1
  - tools/outcome-report.ps1
---

# Objective

Complete the non-runtime Decision Lab foundation so KWR has a stable corpus
manifest, adversarial fixture shape, outcome-attribution shape, and more than
one battleground slice to build from.

# User outcome

Maintainers can grow the replay corpus, benchmark it, and record reviewed
outcome attribution without inventing new schemas or folder conventions for
every next task.

# Current behavior

The replay, label, runner, and benchmark layers exist, but the wider Decision
Lab foundation is incomplete. There is no corpus manifest, no formal
outcome-review schema, no adversarial replay template, and the sample corpus is
still effectively Twin Peaks only.

# Required behavior

- Add a corpus manifest schema and manifest file.
- Add an outcome-review schema, template, and aggregate report script.
- Add an adversarial replay template and one sample adversarial replay.
- Add a second battleground slice with replay, label, run result, and outcome
  review.
- Extend audits to validate the new artifacts.

# Non-goals

- Do not claim expert-tier benchmark readiness.
- Do not change live battleground planner logic.
- Do not add learning/tuning behavior in runtime.

# Technical constraints

- All new artifacts remain developer-side and JSON-based.
- Outcome reviews must use explicit classification labels.
- Manifest data must remain patch-scoped and reviewable by humans.

# Acceptance criteria

- [x] Corpus manifest exists and validates.
- [x] Outcome review schema/template and report script exist and validate.
- [x] Adversarial fixture template exists and one sample adversarial replay validates.
- [x] A second battleground slice exists across replay, label, result, and outcome layers.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `./tools/knowledge-audit.ps1`.
3. Run `./tools/corpus-audit.ps1`.
4. Run `./tools/decision-benchmark.ps1`.
5. Run `./tools/outcome-report.ps1`.

# Rollback

Remove the Decision Lab manifest, outcome/adversarial schemas and fixtures, the
second battleground sample slice, and the outcome reporting tool. No runtime
SavedVariables are affected.
