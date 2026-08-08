---
id: KWR-045
title: Add deliberate system progress report
owner: Codex
priority: high
risk: low
dependencies: [KWR-042, KWR-043, KWR-044]
affected_modules: [tools/deliberate-system-report.ps1, knowledge/schemas/deliberate-system-report-schema.json, README.md, docs/WORKFLOW_NOW.md]
---

# Objective

Create a machine-readable progress report that tells the team what KWR is
building, what depth is still required, and where effort should go next.

# User outcome

The repository can report the real gap between current corpus depth and the
minimum deliberate system target, rather than relying on memory or ad hoc
status updates.

# Current behavior

The repository knows its current corpus counts and scenario matrix, but it does
not yet compute the gap from starter all-map coverage to a real reviewed
deliberate system target.

# Required behavior

- Add a report script that combines map count, scenario matrix, and corpus data.
- Make the target explicit: five base scenarios per map, five reviewed cases per
  scenario, and one adversarial case per scenario.
- Output both human-readable progress and machine-readable JSON.

# Non-goals

- Automatically generating the missing corpus.
- Claiming expert readiness before the corpus exists.

# Technical constraints

- Keep the current corpus honest.
- Do not mark progress as complete where the data does not exist.

# Acceptance criteria

- [x] The repository can report deliberate-system totals and gaps.
- [x] The report states starter, reviewed, and adversarial targets.
- [x] The report remains grounded in current files and scenario matrix data.

# Verification

1. Run `./tools/deliberate-system-report.ps1`.
2. Optionally emit JSON with `-OutFile`.
3. Confirm the gaps match the current all-map starter corpus.

# Rollback

Remove the report script/schema and revert documentation references.
