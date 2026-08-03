# KnoMercy War Room â€” Commander & Sentinel User Guide

> Canonical operator guide for the current field candidate. Keep this page aligned with `README.md`, `KWRSentinel/README.md`, and the release notes whenever commands or surfaces change.

## What KWR is

KnoMercy War Room turns verified battleground state into one readable next call, assignments, a win condition, and an abort condition. The Commander is the decision surface for the caller. Sentinel is the small execution surface for each player.

The system is advisory and player-controlled. It does not target, focus, cast, move, run macros, change keybindings, send chat automatically, or relay through an addon channel in the current build.

## Choose your role

| Role | Install | Primary job | Start here |
| --- | --- | --- | --- |
| Commander | `KnomercyWarRoom` | Read the battlefield, confirm the plan, and make the call manually | `/kwr`, then `/kwr explain` |
| Sentinel player | `KWRSentinel` | Read your personal assignment and execute it manually | `/kwrs` or `/sentinel` |
| Commander + player | Both | Use the Commander board while validating the same execution packet on Sentinel | `/kwr hud` and `/kwrs` |

## Installation and first launch

1. Place `KnomercyWarRoom` and/or `KWRSentinel` under `World of Warcraft/_retail_/Interface/AddOns/`.
2. Restart the client or run `/reload`.
3. Confirm the addon load message appears.
4. Outside a battleground, open `/kwr options` and position the surfaces.
5. In a test battleground, run `/kwr verify` before judging a call. Unknown or stale values are intentionally shown as unknown.

Sentinel can run without Commander and will fall back safely. When both are present on the same client, Sentinel consumes the reviewed `KWR.SentinelBridge` execution packet. It does not invent a command when Commander data is unavailable.

## Commander training path

### Drill 1 â€” Read the board

Run `/kwr` and identify, in order:

1. Match state and current phase.
2. The primary command: what to take, hold, escort, return, deny, or cap.
3. Who moves and who stays.
4. The success condition.
5. The abort or switch rule.

Use `/kwr explain` when the call needs context. It exposes the plan, composition read, counterplay, alternatives, and switch rule. Do not replace the visible call with a theory that is not supported by current evidence.

### Drill 2 â€” Validate assignments

Open `/kwr assignments`. Check coverage, teammate identity, destination, expected arrival, success condition, abort condition, and replacement semantics. Use `/kwr reassess` after a meaningful objective, roster, or fight-state change.

### Drill 3 â€” Manage the fight

Use `/kwr hud` for the compact synchronized call and local-fight card. Use `/kwr teammini` and `/kwr enemymini` for quick roster context. Secure target/focus controls require your hardware click; the addon never performs those actions for you.

### Drill 4 â€” Close the loop

After the match, open `/kwr aar`. Use `/kwr aar copy` for the existing manual copy box. Review `/kwr verify` or `/kwr evidence` when reporting a defect or comparing a decision with the observed result.

## Sentinel training path

Sentinel has one primary surface: the execution card. Read it top to bottom:

1. Commander trust and match state.
2. Your job and movement authority.
3. Your target responsibility, if one is reviewed.
4. The hold/win instruction.
5. The target-confirmation cue: white means reviewed target, red means wrong target, muted means no reviewed target instruction.

Your procedure is simple: read the card, confirm the assignment manually, execute using your own abilities and keybinds, and follow the hold/win instruction until the card changes. If the instruction is stale, missing, or unclear, ask the commander rather than guessing.

Sentinel utilities:

- `/sentinel` or `/kwrs` â€” toggle the execution card.
- `/kwrs map` â€” toggle Blizzard's battlefield map.
- `/kwrs score` â€” toggle Blizzard's scoreboard.
- `/kwrs raid` â€” toggle Blizzard raid frames.
- `/kwrs reset` â€” restore Sentinel panel positions.
- `/kwrs options` â€” open Sentinel settings.
- `/kwrs show` and `/kwrs hide` â€” explicitly show or hide the card.

## Commander command reference

| Command | Use |
| --- | --- |
| `/kwr` | Open or close the Tactical Command Board |
| `/kwr hud` | Toggle the compact synchronized command HUD |
| `/kwr tactical` | Open the tactical map board |
| `/kwr objectives` | Open objective control |
| `/kwr team` / `/kwr enemies` | Open team or enemy intelligence |
| `/kwr roster` | Toggle both compact trackers |
| `/kwr assignments` | Open smart assignments |
| `/kwr explain` | Explain plan, counters, alternatives, and switch rule |
| `/kwr refresh` / `/kwr reassess` | Request a refresh or rebuild the plan |
| `/kwr verify` | Capture current truth, decision, and performance evidence |
| `/kwr status` | Print compact current status |
| `/kwr aar` | Open the latest After Action Review |
| `/kwr aar copy` | Open the manual AAR copy box |
| `/kwr options` | Open settings |
| `/kwr cursor` | Toggle the optional Cursor Ring |
| `/kwr mode` | Toggle compact Command or expanded Learning guidance |
| `/kwr copy` | Prepare a one-line current call for manual copying |

Developer-only commands such as `/kwr test` and `/kwr preview` are not player training tools.

## How to make a good call

Say the action, owner, target or destination, timing, success condition, and abort condition. Example structure: â€œTwo rotate Farm now; three hold Blacksmith; pressure their healer; win when Farm is secure; abort if we lose mid and return.â€ KWR supplies evidence and alternatives; the commander remains the final authority.

## When the display is uncertain

`UNKNOWN`, `STALE`, `HIST`, and similar labels are safety signals. Treat them as missing confirmation, not permission to fill in the gap. Prefer map fundamentals and a reversible call. Reassess after the next reliable scoreboard, roster, objective, or unit update.

## Troubleshooting

| Symptom | Response |
| --- | --- |
| No Commander board | Run `/kwr`; then `/kwr status` and `/kwr verify`. Check that the addon is enabled. |
| Sentinel card is empty | Ensure Commander is loaded on the same client, run `/reload`, and run `/kwr refresh`. Standalone Sentinel safely shows fallback state. |
| Wrong target cue | Stop and verify the assignment manually. The cue is advisory; Sentinel never changes target or focus. |
| Panel is misplaced | Commander: use `/kwr options`; Sentinel: `/kwrs reset`. |
| Data says unknown or stale | Wait for reliable game state, use `/kwr reassess`, and do not infer hidden information. |
| Suspected defect | Run `/kwr bug`, preserve the output, and include map, phase, role, and reproduction steps. |

## Safety and privacy

KWR does not provide automation that would play the game for you. Do not treat heuristic scores as win probabilities. Do not paste private SavedVariables, account identifiers, or unredacted combat evidence into public reports.

## Managed-page policy

This file is the repository-owned source for the user-facing wiki page. Maintenance should:

1. Update this page when a public command, surface, safety boundary, or training flow changes.
2. Cross-check `README.md`, `KWRSentinel/README.md`, and the active release notes.
3. Run `./tools/validate.ps1` and the relevant Lua tests before publishing.
4. Record material guide changes in `CHANGELOG.md`.

The page is intentionally documentation-only. It must not become a second runtime configuration, command registry, or source of game truth.

## Quick-start cards

**Commander:** `/kwr` â†’ read call â†’ check assignments â†’ speak manually â†’ `/kwr reassess` after a real change â†’ `/kwr aar` after the match.

**Sentinel:** `/kwrs` â†’ read job/target/hold instruction â†’ act manually â†’ report unclear or stale state to the commander.

## Source links

- [Commander README](../README.md)
- [Sentinel README](../KWRSentinel/README.md)
- [Sentinel product contract](SENTINEL_PRODUCT_CONTRACT.md)
- [Autonomous operations contract](KWR_AUTONOMOUS_OPERATIONS_CONTRACT.md)

