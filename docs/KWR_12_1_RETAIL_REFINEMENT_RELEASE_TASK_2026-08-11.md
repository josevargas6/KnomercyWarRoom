---
id: KWR-054
title: Authorize Retail 12.1 compatibility release and refinement mode
owner: product-owner
priority: high
risk: medium
dependencies: []
affected_modules:
  - Data/PatchData.lua
  - knowledge/field-verification-attestation.json
  - tools/field-blocker-report.ps1
  - RELEASE_READINESS.md
---

# Objective

Prepare the Commander and Sentinel pair for the installed Retail 12.1.0 client
while moving owner-authorized, unimported field evidence out of the release
blocker queue and into refinement monitoring.

# Required behavior

- Ship synchronized Alpha 41 metadata for Commander and Sentinel.
- Use 12.1 compatibility mode and prevent the reviewed 12.0.7 capability/meta
  overlay from affecting live command scoring.
- Keep generic strategy, conservative unknown handling, and the advisory
  season-prep corpus available.
- Record authorization precisely: it closes the internal release-blocker queue,
  but does not assert that missing field evidence was captured or reviewed.
- Retain external journal import, official 12.1 tuning review, and cross-PC
  Sentinel proof as refinement work.

# Verification

1. Run validation, knowledge audit, Lua smoke/soak, and a synchronized package build.
2. Regenerate the field-blocker report and confirm it has no blocking defects.
3. Deploy only exact package contents to both Retail addon folders.

# Rollback

Restore the Alpha 40 Commander and Sentinel packages and set the active patch
data back to 12.0.7. Saved-variable schema is unchanged.
