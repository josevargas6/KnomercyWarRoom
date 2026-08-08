---
id: KWR-040
title: Add machine-readable replay result and benchmark scoring
owner: unassigned
priority: high
risk: medium
dependencies:
  - KWR-038
  - KWR-039
affected_modules:
  - tools/replay-test-runner.lua
  - tools/decision-benchmark.ps1
  - knowledge/schemas/replay-run-result-schema.json
  - knowledge/schemas/benchmark-report-schema.json
  - tests/replay-results/
---

# Objective

Add machine-readable replay results and a benchmark scorer so reviewed replay
outputs can be measured against golden labels without manual interpretation.

# User outcome

Maintainers can compare engine replay results against reviewed acceptable and
forbidden decisions and produce a benchmark report that is consistent across
revisions.

# Current behavior

The replay runner emits human-readable text, but there is no structured result
format or benchmark scorer to aggregate replay outcomes against golden labels.

# Required behavior

- Add a JSON replay-run result format.
- Allow the replay runner to emit machine-readable results.
- Add a benchmark PowerShell script that scores replay results against golden
  labels.
- Add schemas and a synthetic sample result so the benchmark path can be
  validated offline before the runtime is available.

# Non-goals

- Do not claim benchmark success against a large reviewed corpus.
- Do not tune planner logic in this task.

# Technical constraints

- The JSON result format is developer-side only.
- Benchmark scoring must fail on forbidden hits.
- Reports must preserve replay and label identity.

# Acceptance criteria

- [x] Replay runner can emit JSON results.
- [x] Benchmark scorer can read replay results and golden labels.
- [x] Benchmark scorer produces a machine-readable report.
- [x] Sample result and report path pass audit.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `./tools/knowledge-audit.ps1`.
3. Run `./tools/corpus-audit.ps1`.
4. Run `./tools/decision-benchmark.ps1` against sample replay results.

# Rollback

Remove the JSON result schemas, replay result samples, and benchmark scorer, and
drop the `--json-out` path from `tools/replay-test-runner.lua`.
