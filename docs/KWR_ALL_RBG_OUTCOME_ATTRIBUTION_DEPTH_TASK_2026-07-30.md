---
id: KWR-237
title: Deepen all-map outcome attribution and replay review detail
owner: Codex
priority: high
risk: medium
dependencies: []
affected_modules:
  - tools/build-starter-corpus.ps1
  - tools/build-foundation-depth-corpus.ps1
  - tools/build-scenario-calibration.ps1
  - tools/build-scenario-adversarial-calibration.ps1
  - tests/smoke.lua
---

# Objective

Strengthen the offline corpus so reviewed cases explain not only what branch was
chosen, but whether the result was driven by decision quality, execution
quality, or battlefield-truth quality.

# User outcome

KWR’s offline case library becomes more coachable and more expert-reviewable:
reviewed scenarios can distinguish bad calls from bad execution and from low
truth states.

# Current behavior

- Corpus entries already link reviewed cases to doctrine branches.
- Outcome reviews still summarize results too lightly.
- Replay results still expose limited post-hoc attribution detail.
- Calibration counts reviewed cases well, but it does not yet summarize outcome
  drivers and lesson patterns strongly enough.

# Required behavior

- Enrich starter outcome reviews with explicit attribution blocks.
- Enrich reviewed variants and replay-run results with stronger attribution and
  lesson detail.
- Aggregate the new attribution evidence into scenario calibration.
- Aggregate fail-closed truth discipline patterns into adversarial calibration.
- Keep coverage equal across all supported rated battleground maps.

# Non-goals

- No fabricated live match evidence.
- No weakening of existing deterministic coverage.

# Technical constraints

- Preserve current schema compatibility.
- Keep generated data rebuildable from repository tooling.
- Use additive fields only unless a stronger change is required.

# Acceptance criteria

- [ ] Outcome reviews expose explicit attribution detail across the generated corpus.
- [ ] Replay run results expose stronger branch-review detail across the generated corpus.
- [ ] Scenario calibration aggregates attribution drivers and lesson patterns.
- [ ] Adversarial calibration aggregates truth-discipline patterns.
- [ ] Validation, knowledge audit, and Lua tests pass after regeneration.

# Verification

1. Rebuild starter and depth corpus artifacts.
2. Rebuild calibration artifacts.
3. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate.ps1`.
4. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\knowledge-audit.ps1`.
5. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.

# Rollback

Revert the builder changes, rebuild the previous corpus, and restore the
previous smoke expectations.
