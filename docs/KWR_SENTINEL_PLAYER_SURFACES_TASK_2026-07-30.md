---
id: KWR-241
title: Expand Sentinel player execution surfaces without creating a second commander
owner: unassigned
priority: high
risk: medium
dependencies:
  - KWR-SENTINEL-001
  - KWR-128
affected_modules:
  - Runtime/SentinelBridge.lua
  - KWRSentinel/Core.lua
  - KWRSentinel/Bridge.lua
  - KWRSentinel/HUD.lua
  - KWRSentinel/MinimapButton.lua
  - KWRSentinel/KWRSentinel.toc
  - KWRSentinel/Options.lua
  - KWRSentinel/Panels.lua
---

# Objective

Extend KWRSentinel so a non-commander player can see more of their own
commander-owned execution truth, plus a few compact optional helper surfaces,
without turning Sentinel into a second tactical board or assignment engine.

# User outcome

The player can optionally enable compact helper surfaces for personal status,
team tracking, and enemy tracking while still receiving one commander-owned
execution card and target cue as the primary live guidance path.

# Current behavior

Sentinel currently renders one compact execution card, a target confirmation
cue, a readiness alert, and native Blizzard utility toggles. It does not expose
its own options window, compact helper trackers, or a dedicated player-status
surface for cooldown and respawn context.

# Required behavior

- Keep commander truth single-owner through `Runtime/SentinelBridge.lua`.
- Add a Sentinel options window with explicit enable/disable controls for the
  execution card, target cue, player status panel, compact team tracker,
  compact enemy tracker, minimap button, and native utility buttons.
- Expand the commander bridge view to include compact requirement lines and
  compact team/enemy summaries suitable for Sentinel-side rendering.
- Add a compact Sentinel player-status panel that can show personal local
  cooldown, trinket, assignment staging, and respawn context.
- Add optional compact team and enemy helper trackers that remain player-safe,
  compact, and subordinate to the execution card.
- Preserve standalone fallback when KWR is not installed locally.
- Preserve the commander-style crosshair cue and keep it visual only.

# Non-goals

- No cross-player Sentinel transport changes in this task.
- No new commander assignment logic or second strategy engine.
- No secure targeting automation, focus automation, macro injection, keybinding
  writes, or `Tab` override behavior.
- No full tactical board, reporter map, or commander dashboard inside
  Sentinel.

# Technical constraints

- Respect the current Sentinel product contract: compact player execution
  client first, optional helper surfaces second.
- Keep protected-action safety intact and pass repository validation.
- Keep TOC loading order deterministic.
- Keep refresh work bounded and local-only on the Sentinel side.

# Acceptance criteria

- [ ] Sentinel exposes a dedicated options window with grouped surface toggles.
- [ ] Commander-owned bridge data includes compact requirement text and compact
      team/enemy summaries for the local player view.
- [ ] Sentinel can render an optional player-status helper panel with personal
      cooldown and respawn context.
- [ ] Sentinel can render optional compact Team and Enemy helper trackers from
      commander-owned truth when local KWR is present.
- [ ] Standalone Sentinel degrades safely to unknown/empty helper states.
- [ ] No protected-action validation failures are introduced.
- [ ] The implementation explicitly documents that `Tab` targeting override was
      not added because it violates the repository safety gate and protected
      action rules.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.
3. Exercise combined KWR plus Sentinel and standalone Sentinel load paths.

# Rollback

Remove the new Sentinel helper-surface modules and revert the bridge/view-model
expansion, then rebuild and retest the previous compact execution-card-only
behavior.
