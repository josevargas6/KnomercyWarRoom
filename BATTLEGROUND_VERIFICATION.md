# Battleground Verification Matrix

This matrix is the release authority for map-specific behavior. A battleground
is not considered verified because its window opens; its sensor truth,
prediction, command, assignment, presentation, and match result must all agree.

## Automated coverage

The Alpha 12 `/kwr test` and `tests/smoke.lua` suite contains 232 deterministic
checks and must prove:

1. the map resolves to the correct key and mechanic family;
2. public score and objective values are normalized to the assigned battlefield team;
3. the unique mechanic produces the expected prediction and recovery action;
4. a reviewed match records the correct friendly score and result;
5. unavailable data remains unknown.

## Live capture procedure

For every map, capture screenshots at lobby/start, first score change, objective
transition, winning projection, losing projection, match completion, and exit.
Record `/kwr verify`, `/kwr explain`, and `/kwr perf` at the same transitions;
export `/kwr evidence` before leaving the match.
Pass only when Blizzard UI, Scout HUD, Tactical page, Objectives page,
Assignments page, and AAR all describe the same friendly team and game state.
Arathi Basin, Battle for Gilneas, Deepwind Gorge, and Eye of the Storm require
separate Standard and Blitz evidence because their scoring or capture rules differ.

Random queues are expected. Record whichever map appears and accumulate
coverage over time; a duplicate map remains useful when it supplies a different
team side, bracket, score state, or result. One clean match gives initial
coverage. Three clean matches per map provide beta confidence. Stable promotion
requires both winning and losing live evidence for every map family.

Use this compact record for each match:

```text
Date / version:
Map / bracket:
Assigned team / native faction:
Result / final score:
Score and objectives: PASS / FAIL
Map and Reporter: PASS / FAIL
Strategy and assignments: PASS / FAIL
Roster and specializations: PASS / FAIL
Quick Call: PASS / FAIL / NOT TESTED
AAR: PASS / FAIL
BugSack errors:
CPU / memory / FPS:
Evidence: screenshots + /kwr verify + /kwr evidence
```

| Battleground | Unique mechanic KWR must answer | Automated proof | Live proof status |
| --- | --- | --- | --- |
| Arathi Basin | Five-node tick race, minimum bases, capture deadline | Standard clocks, Blitz clocks, and incoming-capture flips | Standard and Blitz retest required |
| Battle for Gilneas | Three nodes; two-base hold is complete win condition | 2-1 winning-clock fixture; Blitz rules loaded | Standard and Blitz required |
| Deepwind Gorge | Five nodes using score widget 2074; wide response rotations | Verified widget ID, 3-2 fixture, and Blitz rules | Standard and Blitz retest required |
| Eye of the Storm | Tower tick race plus tower-scaled flag value | Standard and Blitz tower/flag-value fixtures | Standard and Blitz required |
| Warsong Gulch | Flag possession, return-and-cap synchronization | Lead/deficit and both-carrier fixtures | Required |
| Twin Peaks | Flag possession plus route/return pressure | Deficit return-and-cap fixture | Required |
| Temple of Kotmogu | Orb-count pressure and carrier deletion | 1-3 urgency plus missing-telemetry truth fixture | Required |
| Silvershard Mines | Active cart control, delay, route abandonment | Cart delay/recovery fixture | Required |
| Deephaul Ravine | Escort our cart, turn theirs, conditional Crystal value | Enemy-cart turn plus missing-telemetry truth fixture | Required |
| Seething Shore | Spawn timing, channel denial, exhausted-node exit | Next-spawn recovery fixture | Required |

Build-time rule references retained for Alpha 12:

- https://warcraft.wiki.gg/wiki/Arathi_Basin_(original)
- https://warcraft.wiki.gg/wiki/Eye_of_the_Storm
- https://warcraft.wiki.gg/wiki/Battleground_Blitz

These references define deterministic fixtures, not live truth. Blizzard's
public in-game score and objective widgets remain authoritative during a match.

## Global element checks

- Assigned team: the player's scoreboard roster determines friendly side;
  native faction is never used to guess an active cross-faction match.
- Score: changes within one runtime pulse and never remains frozen at zero when
  Blizzard's public score widget is present.
- Bracket: `/kwr verify` reports STANDARD or BLITZ and the prediction uses the
  matching scoring/capture model.
- Objectives: exactly one row per objective, with current owner/state and map position.
- Widget discovery: `/kwr verify` records the score and objective widget IDs
  actually observed in that match; changed IDs must not silently become zero state.
- Reporter map: objective markers update live. Instanced player coordinates are
  restricted by Blizzard and must not be fabricated.
- Team roster: observed specializations persist for the group session after
  another player is inspected.
- Formation verification: safe inspect results replace historical estimates,
  and no player receives a job incompatible with their effective role.
- Enemy roster: teammates never enter the enemy bucket while team assignment is pending.
- Carrier intelligence: colored orb/flag events identify the carrier; exposed
  health bars, stacks, and map markers update without converting hidden values.
- Reassessment: `REASSESS` publishes an explicit old-to-new assignment delta
  and does not silently distribute or execute the change.
- AAR: selected choices remain highlighted, saved choices restore, and the
  recorded result follows the assigned team's final score.
- Quick Calls: each left-click sends exactly one fixed phrase to Instance Chat,
  right-click opens the compact fallback, and no attribute changes in combat.
- Midnight safety: no combat-log subscription, automatic communication,
  unreviewed protected action, or in-combat secure-layout mutation.
