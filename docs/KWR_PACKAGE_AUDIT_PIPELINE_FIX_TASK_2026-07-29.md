---
id: KWR-2026-07-29-PACKAGE-AUDIT-PIPELINE
title: Stabilize candidate package audit and reproducibility flow
owner: Codex
priority: high
risk: medium
dependencies: []
affected_modules:
  - tools/build.ps1
  - tools/package-audit.ps1
---

# Objective

Repair the offline package pipeline so reproducibility, package audit, and extracted runtime verification can run in consistent modes without false failures.

# User outcome

Engineers can build and audit candidate packages locally, including a full proof mode and a content-only mode used by nested reproducibility checks.

# Current behavior

`tools/package-audit.ps1` hard-requires the reproducibility report even when reproducibility was intentionally skipped, which breaks content-only audit flows.

# Required behavior

- Nested reproducibility builds must remain content-only.
- Package audit must support an explicit mode where reproducibility validation is skipped.
- The default full candidate path must still require a PASS-compatible reproducibility report.

# Non-goals

- Changing release payload contents.
- Relaxing full candidate proof requirements.
- Altering battlefield runtime logic.

# Technical constraints

- Preserve existing artifact names and core output structure.
- Keep the default candidate flow strict.
- Maintain deterministic extracted smoke and soak validation.

# Acceptance criteria

- [ ] `tools/build.ps1 -SkipReproducibilityAudit` can still complete package audit in explicit skip-repro mode.
- [ ] Default full build still produces a PASS-compatible package audit result.
- [ ] Reproducibility notes reflect that nested package audit is disabled in the secondary pass.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `tests/smoke.lua` and `tests/soak.lua` through the configured Fengari runtime.
3. Run a full `tools/build.ps1` candidate build and confirm package audit passes.

# Rollback

Revert the package tooling changes and restore the prior strict audit coupling if the new mode weakens candidate proof integrity.
