---
id: KWR-263
title: Certify Alpha 43 performance and retail release closure
owner: Codex
priority: high
risk: medium
status: completed
authority_references: [RELEASE_READINESS.md, DESIGN_CONTRACT.md, ARCHITECTURE.md, AGENTS.md]
dependencies: [KWR-261, KWR-262]
affected_modules:
  - UI/LayoutCoordinator.lua
  - KWRSentinel/HUD.lua
  - knowledge/candidate-package-report.json
  - knowledge/field-test-readiness.json
  - knowledge/field-blocker-report.json
  - knowledge/offline-completion-audit.json
---

# Objective

Establish Alpha 43 as the single certified retail candidate after the native
PvP identifiers, lightweight arena/world-PvP contexts, and idle-performance
changes are included in one reproducible package.

# Acceptance criteria

- [x] Alpha 43 Commander and Sentinel TOCs and release evidence agree.
- [x] Candidate, readiness, blocker, and completion reports bind to Alpha 43.
- [x] Upload checklists name only Alpha 43 archives and manifests.
- [x] Layout polling covers every managed visible surface and skips idle state.
- [x] Lua smoke, transport, soak, replay, validation, and GitHub certification pass.
- [x] PR merge, tagged release, CurseForge publication, and Discord publication
      are verified from the same certified package hashes.

# Verification

1. Run `tools/validate.ps1` and `tools/test-lua.ps1`.
2. Confirm the deterministic layout polling assertions in `tests/smoke.lua`.
3. Confirm the required GitHub CI certification is green on the final commit.
4. Verify release assets, CurseForge uploads, Discord receipts, and installed
   TOC hashes after publication.

# Rollback

Revert the Alpha 43 release commit and restore the previous certified tag;
never mix Alpha 42 and Alpha 43 package hashes or SavedVariables evidence.
