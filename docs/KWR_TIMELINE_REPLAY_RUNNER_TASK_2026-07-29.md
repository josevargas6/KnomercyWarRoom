---
id: KWR-039
title: Add deterministic timeline replay runner for the real planner stack
owner: unassigned
priority: high
risk: medium
dependencies:
  - KWR-038
affected_modules:
  - tests/smoke.lua
  - tools/replay-test-runner.lua
  - tests/replays/
---

# Objective

Add the ET-04 deterministic replay runner so sanitized battleground timelines
can execute the actual KWR planner stack offline and produce comparable command
outputs across checkpoints.

# User outcome

Maintainers can run a replay fixture through the real command engine, inspect
what KWR called at each timeline step, and compare those calls against reviewed
acceptable or forbidden tags before the next live build.

# Current behavior

`tools/replay-test-runner.lua` only launches `tests/smoke.lua`. There is no
timeline evaluator that consumes the new replay schema or exercises the planner
stack checkpoint by checkpoint.

# Required behavior

- Turn the smoke harness into a reusable deterministic bootstrap.
- Load sanitized replay JSON fixtures.
- Build production-shaped snapshots from replay state.
- Execute the actual planner stack at each timeline step.
- Emit comparable tags and summaries for offline inspection.
- Support optional strict checking against acceptable/fallback decision tags.

# Non-goals

- Do not add a second planner or offline-only decision engine.
- Do not alter live battleground behavior in this task.
- Do not claim expert benchmark success yet.

# Technical constraints

- The runner is a developer-side Lua tool and may include its own JSON parser.
- The addon runtime must not gain a JSON dependency.
- Replay execution must remain deterministic for identical inputs.
- The runner must stay bounded and avoid unreviewed persistent state writes.

# Acceptance criteria

- [x] The replay runner uses the real KWR planner stack, not a fake planner.
- [x] The smoke harness can return a bootstrap without running the full smoke suite.
- [x] A replay fixture can produce timeline checkpoints and final decision tags.
- [x] Strict mode can fail on forbidden or unsupported replay outcomes.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `./tools/knowledge-audit.ps1`.
3. Run `./tools/corpus-audit.ps1`.
4. Run `lua tools/replay-test-runner.lua tests/replays/... --check` when a Lua runtime is available.

# Rollback

Restore the thin replay launcher and remove the bootstrap-only path from
`tests/smoke.lua`. No persisted state requires migration.
