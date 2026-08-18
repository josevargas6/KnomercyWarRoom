---
id: KWR-256
title: Make battlefield health-bar identifiers readable at live nameplate scale
owner: Codex
priority: high
risk: low
status: completed
authority_references: [DESIGN_CONTRACT.md, ARCHITECTURE.md]
dependencies: [KWR-255]
affected_modules:
  - Features/CursorRing.lua
  - tests/smoke.lua
---

# Objective

Increase the visual size of KWR battlefield identifiers so their ring, class
icon, and role marker are legible on live health bars.

# User outcome

The player can identify a teammate role, target class, and carrier marker at a
glance without the marker reading as a tiny dot.

# Current behavior

The nameplate ring is 22 pixels and its icon is 14 pixels, which is too small
against the default Retail health-bar scale.

# Required behavior

- Render an integrated 36-pixel ring and 24-pixel icon.
- Scale the surrounding label, health, and cast strips proportionally.
- Keep nameplate anchoring, non-interaction, and tactical meaning unchanged.

# Non-goals

- No changes to target selection, assignments, protected clicks, or marker
  modes.

# Technical constraints

The frame stays mouse-disabled and retains the existing nameplate-center
anchor. No per-frame allocation or saved-variable migration is permitted.

# Acceptance criteria

- [x] Native marker ring is at least 36 by 36 pixels.
- [x] Native marker icon is at least 24 by 24 pixels.
- [x] The marker remains centered on its originating nameplate.
- [x] Validation and Lua tests pass.

# Verification

1. Run `tools/validate.ps1`.
2. Run `tools/test-lua.ps1`.
3. Inspect friendly, enemy, carrier, health, and cast states in a battleground.

# Rollback

Revert the marker size constants. No saved variables are changed.
