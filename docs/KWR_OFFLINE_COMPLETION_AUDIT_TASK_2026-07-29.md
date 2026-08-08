---
id: KWR-050
title: Generate the offline completion audit
owner: codex
priority: high
risk: low
dependencies:
  - KWR-048
  - KWR-049
affected_modules:
  - docs/OFFLINE_COMPLETION_AUDIT_2026-07-29.md
  - knowledge/offline-completion-audit.json
  - knowledge/schemas/offline-completion-audit-schema.json
  - tools/offline-completion-audit.ps1
  - tools/knowledge-audit.ps1
  - README.md
  - docs/WORKFLOW_NOW.md
---

# Objective

Publish one final offline completion audit that states exactly what the
repository proves today and exactly what still requires live evidence.

# User outcome

The project has one unambiguous offline finish line report: offline work is
substantially complete, field testing is prepared, and remaining open items are
live-only rather than vague or implied.

# Current behavior

The repo has readiness, blocker, and session artifacts, but no single audit
that explicitly answers whether offline work is complete enough to begin field
testing and why the broader goal is not yet fully complete.

# Required behavior

- Generate one machine-readable offline completion audit.
- Generate one human-readable offline completion audit.
- State offline-complete evidence, live-only blockers, and environment limits.
- Require the new audit through knowledge audit.

# Non-goals

- Do not claim full project completion.
- Do not soften any live-required blocker.
- Do not invent live evidence.

# Acceptance criteria

- [ ] One offline completion audit JSON artifact exists.
- [ ] One offline completion audit Markdown report exists.
- [ ] The audit states both the offline-complete evidence and the remaining
      live-only blockers honestly.
- [ ] Knowledge audit requires the new audit artifact.

# Verification

1. Run `./tools/offline-completion-audit.ps1`.
2. Run `./tools/knowledge-audit.ps1`.
3. Run `./tools/validate.ps1`.

# Rollback

Remove the audit artifact, generator, and linked docs.
