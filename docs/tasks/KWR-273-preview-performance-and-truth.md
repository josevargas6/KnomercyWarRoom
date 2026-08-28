---
id: KWR-273
title: Stabilize design-preview truth and refresh cost
owner: Codex
priority: critical
risk: medium
status: in_progress
dependencies: [KWR-272]
affected_modules: [Runtime/Preview.lua, Runtime/MatchRuntime.lua, Runtime/Verification.lua, tests/smoke.lua]
authority_references: [AGENTS.md, DESIGN_CONTRACT.md, QA_CHECKLIST.md, RELEASE_READINESS.md]
---

# Objective

Make the developer-only design preview represent a resolved synthetic
battleground without repeatedly executing the full live strategic pipeline for
unchanged preview data.

# Required behavior

- Preview supplies explicit synthetic assigned-team truth and bounded evidence
  timestamps without representing that truth as Retail-authoritative.
- Unchanged queued preview refreshes reuse the existing published preview state.
- Explicit preview activation and manual reassessment still execute the full
  preview pipeline; live PvP behavior is unchanged.
- Manual roster rescan never requests Retail inspection for synthetic preview
  rows.
- Add deterministic coverage for preview team truth and refresh reuse.

# Verification

1. Run `tools/validate.ps1`.
2. Run the Lua smoke suite.
3. Build a new versioned candidate before field installation.

# Rollback

Disable preview mode or reinstall the previous Alpha 6 archive; no live PvP
or persisted decision contract is changed.
