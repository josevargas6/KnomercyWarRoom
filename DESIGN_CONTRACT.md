# KWR Endgame Design Contract

The approved endgame mockups define the product direction. They are not diagnostic illustrations.

## Required experience

1. **Scout workflow** - the Scout mockup explains how the compact and expanded views work together; it is not a separate product page.
2. **Tactical Command Board** - the primary user interface and expanded view, with map art, friendly/enemy evidence, objectives, assignments, focus, and command timeline.
3. **Scout HUD** - the compact view, showing live score, win condition, next objective, personal assignment, target caller, and kill target.
4. **Enemy Tracker** - a dense all-in-one intelligence table with priority, seen age, identity, health when visible, location evidence, readiness fields, and notes.
5. **Compact combat roster** - Team and Enemy minimize into clean clickable
   class-colored health bars with role symbols and a local kill-target glow.
6. **Reporter intelligence** - bounded background evidence used for calls and exposed on the existing Tactical Command Board; native `Shift-M` owns battlefield-map display. The historical Support View does not authorize another live map window.
7. **Learning loop** - match history, doctrine, evidence-based insights, and an After Action Review form.

## Non-negotiable principles

- The product must feel like a battlefield command system, not an API test window.
- One live state feeds every surface.
- Visual richness cannot be purchased with fabricated data.
- Preview fixtures are allowed only when unmistakably labeled not live.
- Unknown combat facts remain unknown.
- No automatic communication or protected action is added to imitate another
  addon. Reviewed, fixed secure actions are allowed only for player-click
  compact-roster target/focus and Objectives quick-call buttons.
- New capability belongs in a named domain module, not a patch file or duplicate page.

## Current overhaul contract — 2026-09-04

The vision is one fast, player-controlled command system: a justified win path,
one team call, named movers/stayers, my job/location, a supported deadline,
success/abort conditions and a fallback. Local target preference remains distinct
from an observed kill opportunity. Unknown facts, stale observations and
unavailable actors cannot become confident execution instructions.

[PRODUCT_ROADMAP.md](PRODUCT_ROADMAP.md) owns the active sequence and measurable
acceptance tests. Preserve module ownership and replace weak contracts in
reviewable stages. Correctness and performance come before additional strategy
volume or surfaces. [RELEASE_READINESS.md](RELEASE_READINESS.md) owns promotion.

Ten-player organized RBGs are primary; advertised Blitz support requires separate
verified rules and roster sizing. Preserve native health/names by default;
icon-only plates are explicit. HUD, board and optional audio share a play
revision and deadline.

## Historical Alpha 25 mapping

| Mockup surface | Alpha 25 implementation |
| --- | --- |
| Scout workflow mockup | Product flow reference; no duplicate page |
| Expanded Tactical Command Board | Primary interface in `UI/MainWindow.lua` |
| Compact Scout HUD | `UI/HUD.lua` |
| Reporter background intelligence | `Runtime/Reporter.lua` in the live pipeline |
| Reporter minimized dot map | `UI/ReporterMap.lua` compact Support View |
| Reporter expanded report | Tactical page plus Objectives page |
| Enemy Tracker | Enemies page plus `Runtime/EnemyIntel.lua` |
| Team/Enemy minimized bars | `UI/CombatRoster.lua` |
| Local kill-target glow | `Runtime/CombatIntel.lua` plus compact enemy row |
| Team assignments | Team and Assignments pages |
| AAR window | `UI/AARWindow.lua` |
| Learning library | Intel/AAR page plus `Runtime/AAR.lua` |
| Minimap launcher | Draggable KWR launcher |

Reporter, Team, Enemy, and combat processing do not depend on page visibility.
The September 4 audit identifies reproducible correctness defects, source/package
reconciliation, performance measurement gaps and live verification work. Stable
readiness requires all of them. Sentinel remains optional and separately packaged,
with transport off by default until independently verified.
