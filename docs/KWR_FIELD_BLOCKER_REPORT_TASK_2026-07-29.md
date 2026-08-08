---
id: KWR-049
title: Generate the current candidate field blocker report
owner: codex
priority: high
risk: low
dependencies:
  - KWR-048
affected_modules:
  - docs/CANDIDATE_FIELD_CAPTURE_MATRIX_2026-07-29.md
  - knowledge/field-blocker-report.json
  - knowledge/schemas/field-blocker-report-schema.json
  - tools/field-blocker-report.ps1
  - tools/knowledge-audit.ps1
  - README.md
  - docs/WORKFLOW_NOW.md
---

# Objective

Generate one machine-readable and one human-readable report that names the
current field blockers for the exact candidate and the fastest live sessions to
clear them.

# User outcome

The first live sessions can be planned deliberately around the real blocking
defects and live-required evidence instead of broad exploratory testing.

# Current behavior

The repository has the current blocker docs and Twin Peaks evidence, but the
operator still has to manually combine them into a live capture plan.

# Required behavior

- Publish one blocker report for the current candidate version.
- Identify the current P1/P2 field defects that still block promotion.
- Tie each blocker to the best first live capture session.
- Distinguish blocker-clearing sessions from broader map-certification sessions.

# Non-goals

- Do not claim that blockers are fixed.
- Do not broaden this into implementation work for the blockers.
- Do not relax any release gate.

# Acceptance criteria

- [ ] One machine-readable blocker report exists.
- [ ] One human-readable capture matrix exists.
- [ ] Knowledge audit requires the blocker report artifact.

# Verification

1. Run `./tools/field-blocker-report.ps1`.
2. Run `./tools/knowledge-audit.ps1`.
3. Run `./tools/validate.ps1`.

# Rollback

Remove the blocker report artifact, generator, and linked documentation.
