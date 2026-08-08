# ADR: Native battlefield map boundary

## Status

Accepted for 6.1.0-alpha.28.

## Context

KWR had both a synchronized command HUD and a standalone Support HUD. Blizzard already provides the native Shift-M battlefield map, while KWR's highest-value responsibility is command clarity rather than maintaining a competing map window.

## Decision

KWR remains standalone and owns commands, assignments, intelligence, Sentinel routing, and audio. The redundant standalone Support HUD is retired. Native Shift-M is the sole battlefield-map guidance. KWR does not detect, recommend, control, or integrate with external map addons.

## Consequences

- KWR removes a redundant window and its active subscription from production.
- `Runtime/Reporter.lua` remains an internal KWR intelligence provider despite its historical name.
- External addon installation and upgrade state cannot affect KWR.
- KWR's supported live surface is the synchronized mini HUD, with Sentinel carrying the personal assignment.
