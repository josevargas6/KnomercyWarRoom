# Pillar Status Report

Date: 2026-07-06  
Addon version: `6.1.0-alpha.23`

## Pillar 1 - Truth Stabilization

Status: engineering-ready, live certification still required.

Completed in code:
- Team-side truth still prefers scoreboard self/roster evidence over native fallback.
- compact HUD bounded refresh scheduling remains covered by smoke.
- post-match final-truth freeze remains covered by smoke.
- enemy truth still promotes through `LOCAL` and `ENGAGED`.
- same-faction scoreboard rows are now pruned more aggressively before enemy surfaces render them.
- deterministic smoke now proves next-best-target promotion when one engaged target disappears and another remains live.

Live checks still required:
- Horde / Alliance assigned side on battleground entry.
- compact HUD freshness across transition, combat release, and match end.
- post-match frozen score/objective truth before battleground exit.
- `LOCAL` / `ENGAGED` continuity after target swaps and combat transitions.
- next-best-target promotion after the kill target disappears.

## Pillar 2 - Roster / Surface Stability

Status: code pass complete, live reload and combat certification still required.

Completed in code:
- split toolbar now anchors independently from split panes.
- split-toolbar profile is stored in defaults and reset flow.
- expanded-window suppression now uses `CombatRoster:Request(...)` instead of direct secure-frame show/hide.
- enemy surface pruning now also respects resolved friendly score faction.

Live checks still required:
- drag both panes and the split toolbar, `/reload`, and confirm exact restoration.
- open/close expanded War Room around combat transitions and confirm no protected-action fallout.
- confirm no friendly duplication appears in the enemy pane during scoreboard instability.

## Doctrine Review

Status: reviewed and tightened.

Updated reviewed plans now state more explicitly:
- who moves;
- who stays;
- what must remain covered.

Deepened map families:
- node maps: Arathi Basin, Battle for Gilneas
- flag maps: Warsong Gulch, Twin Peaks
- cart maps: Silvershard Mines, Deephaul Ravine

## Offline Verification

Command:

```powershell
npx --yes -p fengari-node-cli fengari tests/smoke.lua
```

Current result:
- `KWR_SMOKE_PASS checks=244`
