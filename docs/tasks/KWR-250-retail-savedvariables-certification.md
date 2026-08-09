---
id: KWR-250
title: Bind Retail SavedVariables evidence to the deployed candidate
owner: unassigned
priority: high
risk: low
status: in_progress
authority_references: [RELEASE_READINESS.md, RELEASE_POLICY.md]
dependencies: [KWR-047]
affected_modules:
  - tools/retail-savedvariables-audit.ps1
  - tools/retail-savedvariables-export.lua
  - knowledge/retail-field-certification.json
---

# Objective

Convert the current local Retail SavedVariables journal into a deterministic,
read-only certification report bound to the exact deployed candidate.

# User outcome

Completed matches, interruptions, command stability, map coverage, and missing
proof are reported from real client data without manual transcription or
unsupported promotion claims.

# Current behavior

The read-only exporter and candidate-bound audit inspect Retail AAR records and
generate `knowledge/retail-field-certification.json`. Historical Alpha36 rows
are correctly reported as unbound to Alpha37. The task remains in progress
until Alpha37 is deployed and a fresh candidate-bound Retail session is
captured; implementation acceptance is complete, but field certification is
not.

# Required behavior

Read the SavedVariables file without modifying it, bind it to the deployment
receipt using schema and timestamps, summarize every bounded AAR record, and
fail closed when evidence is missing, stale, interrupted, or below budget.

# Non-goals

- Do not fabricate screenshots, taint results, or performance samples.
- Do not mutate SavedVariables while WoW is closed or running.
- Do not promote the release based only on partial AAR evidence.

# Technical constraints

- Use the cached deterministic Lua runtime to evaluate Lua table syntax.
- Emit sanitized structured data without player names or raw event prose.
- Keep the audit read-only and candidate-bound.

# Acceptance criteria

- [x] Exporter reads the journal and emits sanitized match rows.
- [x] Audit rejects evidence older than the certified deployment.
- [x] Audit distinguishes completed, interrupted, ready, and failed sessions.
- [x] Generated certification lists both proven and missing Retail gates.
- [x] Deterministic fixtures cover pass and fail-closed behavior.
- [x] Validation and automation tests pass.

# Verification

1. Run the SavedVariables audit against deterministic fixtures.
2. Run it against the current Retail SavedVariables file.
3. Run validation, knowledge audit, and Lua tests.

# Rollback

Remove the read-only exporter, audit wrapper, generated certification, and its
validation wiring. No client or SavedVariables rollback is required.
