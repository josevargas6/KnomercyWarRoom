---
id: KWR-252
title: Dock Sentinel beside active Commander surfaces
owner: unassigned
priority: high
risk: low
status: in_progress
authority_references: [DESIGN_CONTRACT.md, RELEASE_READINESS.md]
dependencies: [KWR-251]
affected_modules: [UI/LayoutCoordinator.lua, KWRSentinel/HUD.lua, KWRSentinel/Panels.lua]
---

# Objective

Prevent the Sentinel execution card and status helper from covering active
Commander UI on the same WoW client.

# User outcome

Sentinel follows the one Commander layout authority by choosing a screen-edge
side stack with the smallest overlap; a player drag remains authoritative.

# Required behavior

- Use `KWR.LayoutCoordinator` as the sole automatic layout owner.
- Respect manual Sentinel positioning until `/kwrs reset` restores managed docking.
- Clamp all Sentinel surfaces to the viewport.
- Do not change secure state or mutate layout while a player is dragging.

# Acceptance criteria

- [x] Managed Sentinel placement avoids active KWR Commander surfaces.
- [x] Manual Sentinel dragging disables managed repositioning for that surface.
- [x] Reset restores managed docking.
- [x] Retail screenshot verifies the card and helper do not overlap Commander surfaces (owner-attested).

# Verification

1. Run validation and deterministic tests.
2. With both addons enabled, show Commander Fight Now, compact rosters, and Sentinel.
3. Capture a Retail screenshot before and after a manual drag/reset cycle.

# Rollback

Revert KWR-252. Sentinel keeps its independent saved anchors.
