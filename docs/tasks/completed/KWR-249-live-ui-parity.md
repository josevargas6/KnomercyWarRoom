---
id: KWR-249
title: Preserve live Commander UI corrections in reviewed source
owner: unassigned
priority: high
risk: medium
status: completed
authority_references: [DESIGN_CONTRACT.md, RELEASE_READINESS.md]
dependencies: []
affected_modules: [UI, tests]
---

# Objective

Bring the substantive UI differences in the live addon into reviewable source
control without changing the certified Alpha 32 artifact.

# User outcome

The next candidate preserves the live countdown display, launcher visibility,
coordinated layout reset, and compact quick-call labels.

# Current behavior

The installed live addon contains four UI corrections that are absent from the
public Alpha 32 source and archive.

# Required behavior

Track the live behavior through a draft PR, add deterministic coverage where
practical, and require visual/in-game evidence before a later public release.

# Non-goals

- Do not rewrite or replace Alpha 32.
- Do not promote an alpha to stable.
- Do not alter protected-frame or gameplay automation boundaries.

# Technical constraints

- Preserve secure quick-call button behavior.
- Keep rendering read-only with respect to domain state.
- Reuse LayoutCoordinator as the existing layout owner.

# Acceptance criteria

- [x] Spotlight rendering receives the reviewed countdown state.
- [x] The launcher remains visible at the live frame strata.
- [x] Reset delegates to LayoutCoordinator when available.
- [x] Compact quick calls do not render a competing metadata line.
- [x] Automated gates pass.
- [x] In-game screenshots or field-test evidence approve the UI behavior.

# Verification

1. Run the full automated validation and package gate.
2. Verify secure quick-call behavior in and out of combat.
3. Capture launcher, reset, quick-call, and countdown screenshots in Retail.

# Rollback

Revert KWR-249 before the next candidate; Alpha 32 remains the immutable public
baseline.
