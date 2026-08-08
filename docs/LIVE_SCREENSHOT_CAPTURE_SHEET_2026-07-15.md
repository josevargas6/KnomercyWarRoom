# KWR Live Screenshot Capture Sheet

Use this single page for the immediate field test. Capture screenshots in order when possible. If a scenario does not happen, mark it `N/A` instead of forcing it.

Build under test: `6.1.0-alpha.25`  
Primary environment to record: resolution, UI scale, map, queue type, FPS, CPU, addon memory, Lua errors.

## Session Header

- Date / time:
- Map / mode:
- Standard or Blitz:
- Resolution:
- WoW UI scale:
- Addon memory before queue:
- Addon memory in heavy fight:
- Addon memory after match:
- Average FPS before queue:
- Lowest FPS in heavy fight:
- Lua errors: `YES / NO`
- Taint / blocked-action warnings: `YES / NO`

## Required Screenshot Set

| # | Capture | Purpose | Pass / Fail Notes |
| --- | --- | --- | --- |
| 1 | Town / world with KWR closed or only allowed setup HUD | Proves PvE/world visibility policy is not noisy | |
| 2 | Group-building setup HUD | Proves setup command center is useful before queue | |
| 3 | Queue pop / first 15 seconds inside BG | Proves no stale roster/team ownership/reload-only fix | |
| 4 | Scoreboard open during staging | Proves enemy/team roster truth and duplicate-row behavior | |
| 5 | Command Center: Tactical Map | Proves live map, markers, command summary, and readable objective plan | |
| 6 | Command Center: Objectives | Proves score/objective ownership/source/confidence are readable | |
| 7 | Command Center: Team | Proves friendly roster, roles, assignments, and readiness alignment | |
| 8 | Command Center: Enemies | Proves enemy intelligence rows, notes, and priority controls are readable | |
| 9 | Command Center: Assignments | Proves one-player/one-job/one-location and personal assignment clarity | |
| 10 | Compact Command Center in active combat | Proves the combat HUD is readable, short, and non-obstructive | |
| 11 | Support / Reporter view during objective pressure | Proves reporter map is square/readable and bottom-line guidance is clear | |
| 12 | Battlefield identifiers in friendly stack | Proves friendly identifiers are minimal: role icon + short name only | |
| 13 | Battlefield identifiers in heavy teamfight | Proves non-target clutter is controlled and health bars are not spammed | |
| 14 | Current kill target / crosshair target | Proves target-assist is obvious without auto-targeting | |
| 15 | Free-casting enemy if seen | Proves cast info appears only when tactically useful | |
| 16 | Flag/orb/carrier if seen | Proves carrier badge/icon overrides normal role/class icon cleanly | |
| 17 | Game menu performance overlay during heavy fight | Proves FPS, CPU, and addon memory under load | |
| 18 | Death / respawn state if it happens | Proves stale target/crosshair/assignment cleanup | |
| 19 | Match end with Blizzard scoreboard | Proves cleanup and post-match state do not fight Blizzard UI | |
| 20 | Review / AAR page | Proves result, history, AAR summary, and export controls are readable | |
| 21 | AAR review popup | Proves review fields are readable and no thin edit-box artifact appears | |
| 22 | Copy/export window | Proves export text is readable/selectable and does not overflow | |
| 23 | Back in world after BG | Proves RBG-only windows hide or return to setup policy correctly | |
| 24 | Options window after match | Proves no overlap, dependency locks, wrapping, and scrollbar behavior | |
| 25 | Verification window | Proves technical report scrolls and stays inside the panel | |

## High-Value Failure Captures

Take an immediate screenshot if any of these happen:

- Lua error popup or BugSack/Lua error text.
- Taint, blocked action, or protected-action warning.
- Addon memory above expected range or rising fast after match.
- FPS tanking when KWR surfaces are open.
- Wrong team/faction, wrong map mode, wrong Blitz/standard label.
- Duplicate player rows, especially duplicate self.
- Stale roster after someone joins/leaves/reloads.
- KWR visible in arena or PvE instance.
- Reporter, roster, or minimized windows visible outside RBG when they should be hidden.
- Crosshair background becomes opaque or blocks view.
- Enemy/friendly identifier clutter blocks the fight.
- Health bars shown on many non-targets.
- Text overlap, clipped text, invisible red text, or unreadable tiny text.
- Buttons shown that do nothing or do not explain what they do.

## Fast Pass Criteria

The field pass is cleared when:

- No Lua errors.
- No taint / blocked-action warnings.
- No reload required to fix team/roster/assignment state.
- KWR stays silent in arena/PvE and only shows allowed setup surfaces in world/group-building.
- Compact combat HUD gives one clear call, one assignment, and one next step.
- Full Command Center pages are readable at your 2560x1440 / 65% UI scale.
- Reporter map is readable and square enough to understand locations.
- Battlefield identifiers reduce clutter compared to prior tests.
- Target assist guides visually but never targets/focuses/casts for the player.
- Addon memory and FPS remain acceptable through full match and post-match cleanup.

## Final Session Decision

- Field status: `PASS / FAIL / PARTIAL`
- Biggest live blocker:
- Biggest visual blocker:
- Biggest strategy/truth blocker:
- Biggest performance blocker:
- Next repair slice:

## Session Log

Pre-game capture assessment is tracked in:

- `docs/LIVE_FIELD_TEST_LOG_2026-07-15.md`
