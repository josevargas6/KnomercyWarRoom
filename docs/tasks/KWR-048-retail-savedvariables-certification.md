---
id: KWR-048
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

Retail AAR records exist in SavedVariables, but repository maintenance reports
do not inspect them. Live certification therefore remains blocked even when
usable post-deployment evidence exists.

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

- [ ] Exporter reads the journal and emits sanitized match rows.
- [ ] Audit rejects evidence older than the certified deployment.
- [ ] Audit distinguishes completed, interrupted, ready, and failed sessions.
- [ ] Generated certification lists both proven and missing Retail gates.
- [ ] Deterministic fixtures cover pass and fail-closed behavior.
- [ ] Validation and automation tests pass.

# Verification

1. Run the SavedVariables audit against deterministic fixtures.
2. Run it against the current Retail SavedVariables file.
3. Run validation, knowledge audit, and Lua tests.

# Rollback

Remove the read-only exporter, audit wrapper, generated certification, and its
validation wiring. No client or SavedVariables rollback is required.
