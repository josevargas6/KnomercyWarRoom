---
id: KWR-127
title: Retire the redundant Support HUD and use the native map
owner: codex
priority: high
risk: medium
dependencies:
  - synchronized execution command
  - Runtime/Reporter
affected_modules:
  - UI/Presentation
  - UI/MainWindowLauncher
  - UI/MainWindowCommands
  - UI/MainWindowShell
  - UI/Options
---

# Objective

Make the synchronized mini HUD the primary KWR battlefield surface and stop maintaining a redundant standalone Support HUD.

# User outcome

Players use KWR for commands and personal assignments, Sentinel for their individual job, and native Shift-M for the battlefield map.

# Current behavior

KWR loads a standalone ReporterMap window in addition to the compact command HUD, expanded tactical board, and combat roster. The duplicate map adds presentation and maintenance cost without improving command synchronization.

# Required behavior

- Remove `UI/ReporterMap.lua` from the production load graph and preserve it as a non-loadable archived rollback artifact.
- Retain `Runtime/Reporter.lua` as KWR-owned battlefield intelligence.
- Remove Support HUD restoration and minimization paths.
- Route legacy reporter commands to clear native Shift-M guidance.
- Do not detect, recommend, integrate with, or depend on an external map addon.
- Preserve legacy saved variables for backward compatibility and rollback.

# Non-goals

- Adding any external battleground-map dependency or compatibility layer.
- Replacing KWR's internal intelligence engine.
- Programmatically opening or controlling Blizzard's battlefield map.

# Technical constraints

- KWR must remain standalone and must not inspect external-addon state.
- The compact HUD, Sentinel bridge, runtime assignments, and audio must remain unchanged.

# Acceptance criteria

- [x] Production TOC no longer loads the standalone KWR ReporterMap.
- [x] Internal Reporter intelligence remains in the runtime pipeline.
- [x] Launcher and legacy commands direct users only to native Shift-M.
- [x] Presentation and shell code no longer restore or minimize to ReporterMap.
- [x] No external battleground-map detection, recommendation, code, assets, state, or messages remain.
- [x] Validation, smoke, soak, and package audits pass.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `./tools/knowledge-audit.ps1`.
3. Run `fengari tests/smoke.lua`.
4. Run `fengari tests/soak.lua`.
5. Run `./tools/build.ps1`.
6. In WoW, verify KWR mini HUD and Sentinel operate while native Shift-M is opened and closed.

# Rollback

Move `docs/archive/ReporterMap.lua.retired` back to `UI/ReporterMap.lua`, restore it to the TOC, and restore its launcher, commands, presentation, shell, and option paths. Legacy profile values remain intact for this purpose.
