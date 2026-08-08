# KWR Live Field Test Log

Build observed: `6.1.0-alpha.25`  
Session state: pre-game / world setup captures received  
Primary resolution/UI scale: owner live environment, previously recorded as `2560x1440` at `65%` UI scale

## Pre-Game Capture Result

Status: `PARTIAL PASS`

The pre-game surfaces are stable enough to continue into live battleground testing. No screenshot shows a hard visual blocker, Lua error, taint warning, or unusable out-of-combat layout. The remaining issues are cleanup and readability items, not stop-the-test blockers.

## Captures Reviewed

| Area | Result | Notes |
| --- | --- | --- |
| Login / load banner | PASS | Load text is readable. Keep watching for typo/noise in the startup message, but it is not blocking. |
| Command Center / Tactical Map setup | PASS | Strongest pre-game page. Composition selector, recruit need, assignment preview, and controls are readable. |
| Objectives setup page | PASS WITH NOTE | Empty state is clear. Quick-call footer clips `NO INSTANCE CHAT OUTSIDE BATTLEG...`; this should wrap or shorten. |
| Team page | PASS | Roster row is aligned, status rail is readable, no overlap visible. |
| Enemy page empty state | PASS | Empty state and data-limit rail are readable. No clutter while feed is unavailable. |
| Assignments page | PARTIAL | Layout is stable, but `WHY THIS PLAN` still exposes technical/internal phrasing such as `READ: NONE`, score, and enemy-plan logic. Needs user-facing wording pass. |
| Review / AAR page | PASS | Match list, insights, and action buttons are readable. |
| AAR review popup | PASS | Review layout is much cleaner and no obvious edit-box artifact is visible in this capture. |
| Match evidence export | PARTIAL | Export is readable, but duplicate player rows and `source unknown/source historical/source cache` language are noisy for user-facing export. |
| Options window | PASS WITH NOTE | No major overlap visible. Dependency text is readable. Continue verifying that dependent toggles can be unchecked or clearly explain why they are locked. |
| Verification window | PARTIAL | Scrolling works and text remains inside the window. It is still technical by design, but performance line shows a high memory value that must be cross-checked with the WoW game-menu memory panel during live play. |

## Pre-Game Blockers

No hard blockers found from the pre-game screenshots.

## Pre-Game Repair Backlog

| Priority | Issue | Surface | Acceptance Criteria |
| --- | --- | --- | --- |
| P2 | Quick-call footer clips outside battleground context text | Objectives / Quick Calls | Footer uses a short phrase such as `Chat disabled outside battlegrounds` with no ellipsis/clipping. |
| P2 | Assignment reasoning still shows internal terms | Assignments | Player-facing panel uses plain language: `Why this plan`, `What to hold`, `When to switch`, and hides raw score/read fields unless debug mode is open. |
| P2 | AAR export includes duplicate player rows and source jargon | AAR / Export | Export dedupes player identities where safe and uses clearer terms like `observed`, `remembered`, or `unknown` only when useful. |
| P3 | Verification performance line may confuse memory interpretation | Verification | Verification labels memory as addon/runtime estimate and is compared against the WoW game-menu AddOn Memory panel in the same session. |
| P3 | Options dependency toggles need final behavior proof | Options | Dependent toggles either toggle off normally or show a clear disabled/locked state when parent is off. |

## Continue Testing

Proceed into live battleground validation and capture:

1. First 15 seconds after entering the BG.
2. Scoreboard during staging.
3. Full Command Center pages after roster fills.
4. Compact HUD in first fight.
5. Support / reporter view during objective pressure.
6. Battlefield identifiers in friendly stack and heavy fight.
7. Current target / crosshair behavior.
8. Game-menu performance overlay during heavy fight.
9. Match-end scoreboard and post-match cleanup.
10. Review/AAR and export after the match.

## Live Stop Conditions

Stop and send screenshots/errors immediately if any occur:

- Lua error;
- taint or blocked-action warning;
- reload required to fix roster/team/assignment state;
- KWR visible in arena or PvE instance against policy;
- FPS tanks specifically when KWR surfaces are shown;
- addon memory continues rising after match end;
- battlefield identifiers block target visibility;
- crosshair or target cards become opaque/cluttered;
- support/reporter view becomes unreadable in combat.
