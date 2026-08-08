---
id: KWR-038
title: Add versioned replay and golden-corpus schema
owner: unassigned
priority: high
risk: medium
dependencies:
  - KWR-037
affected_modules:
  - knowledge/schemas/replay-schema.json
  - knowledge/schemas/golden-label-schema.json
  - knowledge/fixtures/replay-template.json
  - knowledge/fixtures/golden-label-template.json
  - tests/replays/
  - tools/corpus-audit.ps1
---

# Objective

Create the ET-03 versioned schema contract for sanitized battleground replays,
golden decision labels, and outcome checkpoints so future replay, benchmark,
and attribution tooling use one stable data shape.

# User outcome

Maintainers can build a reviewed decision corpus and timeline replay library
without inventing new ad hoc formats for every tool. A replay or label file can
be audited automatically before it is trusted by benchmark or training work.

# Current behavior

The project has deterministic smoke scenarios and bounded AAR export, but no
canonical schema for developer-side timeline fixtures, expert labels, or
outcome review records.

# Required behavior

- Add a versioned JSON schema for sanitized replay records.
- Add a versioned JSON schema for golden decision labels.
- Add fixture templates and at least one valid sample replay.
- Add a PowerShell audit script that validates required schema and fixture
  fields.
- Keep the schema legal: no raw account identifiers, secrets, or unsupported
  data claims.

# Non-goals

- Do not build the event-by-event replay executor in this task.
- Do not change live runtime decisions or AAR behavior.
- Do not add numeric training, benchmarking, or planner tuning in this task.

# Technical constraints

- Developer-side artifacts may use JSON.
- Runtime addon knowledge remains Lua-first and must not require a JSON parser.
- Replay files must preserve missing or unavailable truth explicitly rather than
  silently inventing values.
- The schema must support future outcome attribution and reviewer disagreement.

# Acceptance criteria

- [x] Replay schema captures provenance, roster, transitions, labels, and
  outcome checkpoints.
- [x] Golden-label schema captures acceptable, fallback, forbidden, coverage,
  and rationale requirements.
- [x] A sanitized sample replay passes the audit.
- [x] Corpus audit fails missing or malformed required fields.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `./tools/knowledge-audit.ps1`.
3. Run `./tools/corpus-audit.ps1`.
4. Confirm the sample replay and label template pass.

# Rollback

Remove the schema, templates, sample fixtures, and `tools/corpus-audit.ps1`.
No runtime persistence changes are involved.
