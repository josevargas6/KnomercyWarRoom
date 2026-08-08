---
id: KWR-060
title: Expand all-RBG scenario matrix to expert-tier base depth
owner: Codex
priority: high
risk: medium
dependencies: [KWR-042, KWR-043, KWR-044, KWR-046, KWR-047]
affected_modules: [knowledge/rbg-scenario-matrix.json, tools/knowledge-audit.ps1, tests/replays, tests/golden, tests/replay-results, tests/outcomes, tests/adversarial, knowledge/corpus-manifest.json, knowledge/scenario-calibration.json, knowledge/scenario-adversarial-calibration.json, knowledge/field-test-readiness.json, knowledge/deliberate-system-report.json]
---

# Objective

Expand the all-map Rated Battleground scenario foundation from five base
scenarios per map to ten production-grade scenarios per map, then rebuild the
offline corpus and calibration artifacts from that stronger base.

# User outcome

KWR has a broader, more deliberate offline decision foundation for every
supported RBG map before the next live field session, with no fake placeholder
depth and no stale audit assumptions.

# Current behavior

- The repository has ten supported RBG maps.
- Each map currently has five base scenarios.
- The generated corpus and calibration layers are valid, but their breadth is
  still limited by the shallow scenario matrix.
- One knowledge-audit check still assumes a fixed fifty-scenario base instead of
  deriving the expected count from the scenario matrix.

# Required behavior

- Increase `targetBaseScenariosPerMap` to ten.
- Add five additional strong, map-specific scenarios for each supported RBG.
- Keep the scenario families grounded in safe, human-visible battleground truth.
- Ensure the knowledge audit derives target scenario counts from the matrix
  rather than a hardcoded fifty-scenario assumption.
- Rebuild starter corpus, reviewed variants, adversarial cases, manifest,
  calibration outputs, and readiness reports from the new matrix.

# Non-goals

- Claiming the expanded synthetic corpus is equal to expert-reviewed live match
  evidence.
- Replacing the need for field testing, commander review, or real replay intake.
- Changing live battleground UI behavior in this task.

# Technical constraints

- Keep every scenario deterministic, schema-valid, and map-authentic.
- Use only safe, legal battlefield facts that a human commander can observe.
- Preserve all current build, audit, and Lua-test compatibility.
- Avoid historical-document churn unless the artifact is explicitly regenerated.

# Acceptance criteria

- [ ] All ten supported RBG maps define ten base scenarios each.
- [ ] The scenario matrix expresses broader opening, stabilize, pressure,
      recovery, and endgame decision families without generic filler.
- [ ] Knowledge audit target counts derive from the matrix truth.
- [ ] Starter corpus, reviewed variants, and adversarial cases regenerate
      cleanly from the expanded matrix.
- [ ] Corpus/audit/calibration/readiness artifacts all pass after regeneration.

# Verification

1. Run `./tools/build-starter-corpus.ps1`.
2. Run `./tools/build-foundation-depth-corpus.ps1`.
3. Run `./tools/build-scenario-calibration.ps1`.
4. Run `./tools/build-scenario-adversarial-calibration.ps1`.
5. Run `./tools/deliberate-system-report.ps1 -OutFile knowledge/deliberate-system-report.json`.
6. Run `./tools/field-readiness-report.ps1`.
7. Run `./tools/candidate-package-report.ps1`.
8. Run `./tools/offline-completion-audit.ps1`.
9. Run `./tools/corpus-audit.ps1`.
10. Run `./tools/knowledge-audit.ps1`.
11. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.
12. Run `./tools/validate.ps1`.

# Rollback

Restore the previous scenario matrix and generated knowledge/corpus artifacts,
then rerun the standard audit/build scripts.
