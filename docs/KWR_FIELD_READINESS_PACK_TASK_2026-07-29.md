---
id: KWR-048
title: Build the final offline field-readiness pack
owner: codex
priority: critical
risk: low
dependencies:
  - KWR-036
  - KWR-037
  - KWR-047
affected_modules:
  - docs/FIELD_READINESS_PACK_2026-07-29.md
  - docs/FIELD_TEST_SESSION_TEMPLATE_2026-07-29.md
  - docs/FIELD_TEST_MAP_MATRIX_2026-07-29.md
  - docs/FIELD_PROMOTION_GATES_2026-07-29.md
  - knowledge/field-test-readiness.json
  - knowledge/schemas/field-test-readiness-schema.json
  - tools/field-readiness-report.ps1
  - tools/knowledge-audit.ps1
  - README.md
  - docs/WORKFLOW_NOW.md
---

# Objective

Create the final offline preparation pack that converts KWR's corpus,
calibration, safety, and release requirements into one field-testing system.

# User outcome

The project owner can take the exact alpha candidate into live battlegrounds
with a single pack that says what to capture, what to prove, which maps and
scenarios matter, what blocks promotion, and what still remains only live
provable.

# Current behavior

The repository already contains field notes, screenshot evidence, release
vision, and expert-tier planning, but not one current field-readiness pack tied
to the new offline corpus and calibration layers.

# Required behavior

- Define one field-readiness pack rooted in the current offline evidence.
- Publish a machine-readable field-readiness report.
- List exact map/scenario live verification targets.
- Define session workflow, required evidence, stop conditions, and promotion
  gates.
- Distinguish what is offline-complete from what remains live-required.

# Non-goals

- Do not claim field certification is complete.
- Do not soften any live-required gate.
- Do not add runtime behavior or UI changes in this task.

# Technical constraints

- Report must derive from current repository artifacts and pass deterministically.
- Any claim about readiness must stay scoped to the exact current alpha
  candidate and current offline evidence.

# Acceptance criteria

- [ ] One field-readiness pack exists and is discoverable in the repository.
- [ ] One machine-readable readiness report exists and states offline-complete
      versus live-required work honestly.
- [ ] The pack includes session setup, evidence capture, map/scenario matrix,
      stop conditions, and promotion gates.
- [ ] Knowledge audit requires the readiness report artifacts.

# Verification

1. Run `./tools/field-readiness-report.ps1`.
2. Run `./tools/knowledge-audit.ps1`.
3. Run `./tools/validate.ps1`.

# Rollback

Remove the readiness pack documents and generated readiness report. No runtime
or SavedVariables change is required.
