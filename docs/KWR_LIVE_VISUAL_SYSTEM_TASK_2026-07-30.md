---
id: KWR-038
title: Complete live visual system polish across launcher, header, and compact surfaces
owner: Codex
priority: high
risk: low
dependencies: [KWR-035, KWR-036, KWR-037]
affected_modules:
  - UI/MainWindowLauncher.lua
  - UI/MainWindow.lua
  - UI/MainWindowShell.lua
  - tests/smoke.lua
---

# Objective

Finish the live visual workload by aligning launcher, compact trackers, and command-center header with the imported KWR icon and brand system.

# User outcome

The battlefield-facing KWR surfaces look like one intentional product family and use the same fast commander language during play.

# Current behavior

The compact trackers are branded, but the launcher menu and header still present more like older text-first surfaces.

# Required behavior

- Launcher menu rows use semantic KWR icons.
- Launcher menu wording matches the live commander vocabulary.
- Main command-center header carries brand and badge icons.
- Shared vocabulary stays short and operational.

# Non-goals

- Redesign every expanded page.
- Change gameplay logic.

# Technical constraints

- Use the shared icon registry.
- Preserve field-test-safe behavior.

# Acceptance criteria

- [ ] Launcher menu rows have semantic icons.
- [ ] Main header includes KWR brand/icon polish.
- [ ] Tests and validation pass.

# Verification

1. Run validation.
2. Run Lua smoke/soak/replay coverage.

# Rollback

Restore prior launcher and header presentation.
