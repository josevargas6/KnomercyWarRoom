---
id: KWR-238
title: Import and wire the KWR design-system icon and brand asset pack
owner: unassigned
priority: medium
risk: low
dependencies: []
affected_modules:
  - KnomercyWarRoom.toc
  - UI/IconRegistry.lua
  - UI/MainWindowLauncher.lua
  - UI/CombatRoster.lua
  - UI/CombatRosterVisuals.lua
  - UI/TacticalMap.lua
  - Assets/Brand
  - Assets/Icons
---

# Objective

Adopt the supplied KWR design-system package into production addon paths and wire
its brand and icon assets into shared runtime UI surfaces.

# User outcome

KWR no longer depends on text-only micro-markers for launcher branding, role
badges, and core tactical-map objective states. Shared semantic icons now provide
stable visual meaning across shell, roster, and map surfaces.

# Current behavior

KWR had a theme token layer and visual-direction docs, but no runtime-owned icon
registry. The launcher relied on text-only branding, combat-roster role badges
were letter blocks, and tactical-map markers depended heavily on letters and color.

# Required behavior

- Import the supplied brand marks and icon PNGs into KWR-owned runtime asset paths.
- Add a shared icon registry under the addon namespace.
- Use the imported assets for launcher branding.
- Use shared role icons in combat-roster role badges.
- Use shared semantic/objective icons in tactical-map markers where state meaning
  matters most.

# Non-goals

- Rewrite every KWR card and badge to use icons in this task.
- Import mockups, source SVGs, or non-runtime design artifacts into shipping paths.
- Add new polling or animation systems.

# Technical constraints

- Preserve current addon load order and module ownership.
- Keep icon lookups path-based and deterministic.
- Do not introduce combat-lockdown, secure-frame, taint, or per-frame rendering risk.
- Keep color plus text/icon redundancy for tactical readability.

# Acceptance criteria

- [ ] Runtime brand assets live under `Assets/Brand`.
- [ ] Runtime icon assets live under `Assets/Icons`.
- [ ] `UI/IconRegistry.lua` exposes canonical icon lookup helpers.
- [ ] Launcher, combat-roster role badges, and tactical-map markers consume the shared icon registry.
- [ ] Smoke coverage verifies registry path resolution and launcher brand wiring.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.
3. Confirm the addon TOC uses the imported KWR minimap icon texture.

# Rollback

Remove `UI/IconRegistry.lua`, revert the touched UI consumers, restore the prior
TOC icon path, and remove the imported runtime asset folders. No saved-variable
schema or migration behavior changes in this task.
