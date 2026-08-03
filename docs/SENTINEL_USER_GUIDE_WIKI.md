Exit code: 0
Wall time: 0.2 seconds
Output:
# KWR Sentinel User Guide

KWR Sentinel is the compact player execution client for Knomercy War Room. It
shows each player one commander-linked assignment without replacing the
player's judgment or controls.

## Read the execution card

1. Commander trust and match state.
2. Your job and movement authority.
3. Your target responsibility, when one is reviewed.
4. The hold/win instruction.
5. Target confirmation: white means reviewed target, red means wrong target,
   and muted means no reviewed target instruction.

Sentinel never targets, focuses, casts, moves, runs macros, changes keybindings,
or sends addon-channel messages automatically.

## Install and start

Place `KWRSentinel` under `World of Warcraft/_retail_/Interface/AddOns/`,
restart the client or run `/reload`, and confirm the load message. Sentinel can
run safely by itself. When Commander is installed on the same client, Sentinel
consumes the reviewed `KWR.SentinelBridge` execution packet.

## Commands

| Command | Use |
| --- | --- |
| `/sentinel` or `/kwrs` | Toggle the execution card |
| `/kwrs map` | Toggle Blizzard's battlefield map |
| `/kwrs score` | Toggle Blizzard's scoreboard |
| `/kwrs raid` | Toggle Blizzard raid frames |
| `/kwrs reset` | Restore Sentinel panel positions |
| `/kwrs options` | Open Sentinel settings |
| `/kwrs show` / `/kwrs hide` | Explicitly show or hide the card |

## First-match training

1. Run `/kwrs` and place the card where it remains readable.
2. Identify your job, destination or target, movement authority, and hold/win
   instruction.
3. Confirm the assignment manually with the commander.
4. Execute with your own abilities and keybinds.
5. Follow the instruction until the card changes or the commander gives a new
   manual call.
6. If the card is stale, missing, or unclear, ask rather than guessing.

## Uncertainty and troubleshooting

Treat `UNKNOWN`, `STALE`, and missing target data as safety signals. A red cue
does not change your target; verify manually. Use `/kwrs show`, `/kwrs reset`,
or `/reload` as appropriate. Report suspected defects with the map, phase,
role, screenshot, and reproduction steps.

## Current boundaries

The current build includes the same-client Commander bridge, safe standalone
fallback, readiness alert, and native Blizzard map/scoreboard toggles. It does
not include cross-player addon-channel relay, automatic target or focus
changes, auto-casting, macro execution, or movement automation.

See the [Commander and Sentinel User Guide](https://github.com/josevargas6/KnomercyWarRoom/wiki/Commander-and-Sentinel-User-Guide)
for the full commander's training path.

