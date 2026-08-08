---
id: KWR-051
title: Keep Presentation independent of Better Blizzard Frames
owner: codex
priority: high
risk: low
dependencies: []
affected_modules:
  - Core/Addon.lua
  - UI/Presentation.lua
  - tests/smoke.lua
---

# Objective

Prevent KWR Presentation from crashing or conflicting when Better Blizzard
Frames, or another addon, owns Blizzard compact raid frames.

# User outcome

KWR battleground presentation continues to manage only KWR-owned surfaces and
remains usable with Better Blizzard Frames enabled.

# Current behavior

Presentation captured Blizzard compact raid-frame visibility on activation even
though it no longer changes that visibility. Addon-managed replacement or hook
behavior made that unnecessary read a compatibility risk.

# Required behavior

- Do not read, hide, show, reparent, resize, or set attributes on Blizzard
  compact raid frames.
- Keep the legacy `hideRaidFrames` preference migration-safe but inert.
- Preserve KWR compact-roster auto-show and restoration behavior.
- Add deterministic coverage proving an externally managed raid-frame object
  is never queried.

# Non-goals

- No compatibility dependency on Better Blizzard Frames.
- No attempt to synchronize settings with third-party addons.
- No change to secure target/focus row behavior.

# Technical constraints

- KWR must remain limited to KWR-owned UI frames.
- No protected-frame mutation in or out of combat.
- Saved profiles must remain readable without a schema migration.

# Acceptance criteria

- [x] Presentation makes no call to Blizzard compact raid-frame objects.
- [x] The legacy profile preference remains safely readable and inert.
- [x] Smoke coverage fails if Presentation queries an addon-managed raid frame.
- [ ] In-client regression is confirmed with Better Blizzard Frames enabled.

# Verification

1. Run `tools/validate.ps1`.
2. Run `tools/knowledge-audit.ps1`.
3. Run `tools/test-lua.ps1 -Suite All`.
4. Enable Better Blizzard Frames and KWR, enter and leave a battleground, and
   attach any Lua error text or `/kwr bug` export if one remains.

# Rollback

Restore the prior Presentation visibility-capture code. No saved-variable
migration is required.
