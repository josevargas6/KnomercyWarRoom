# KWR Final Field Verification Checklist

Use this sheet during the next live session to clear the remaining field-verification blockers with one pass.

Status key:
- `PASS` = blocker cleared
- `FAIL` = blocker still active and needs repair
- `N/A` = scenario not reached this session

Audit gate mapping:
- `RG-025` secure UI / taint proof
- `RG-026` supported UI scale and resolution proof
- `RG-027` live transition cleanup proof
- `RG-028` leadership / role-change live proof
- `RG-029` complete-match live behavior proof
- `RG-034` live frame-time budget proof
- `RG-035` live FPS impact proof
- `RG-036` live memory-growth proof
- `RG-039` Cursor Ring live budget proof
- `RG-040` optional Sentinel package live budget proof
- `RG-053` exact external candidate install / upgrade proof
- `RG-054` full external stop-criteria proof

---

## Session Setup

- Date:
- Build/version shown in addon:
- Map/mode tested:
- UI scale:
- Resolution:
- Render scale:
- Instance type:
- Average FPS before queue:
- Average FPS in heavy combat:
- Addon memory before queue:
- Addon memory in heavy combat:
- Addon memory after match:
- Optional Sentinel package installed during test: `YES / NO`
- Exact candidate build under test: `developer / package / external zip`

---

## Live Proof Coverage Map

Use this row to confirm tonight's capture pack covers every remaining live gate.

| Gate | What must be proven | Covered by section |
| --- | --- | --- |
| `RG-025` | No taint / blocked-action behavior on secure surfaces | Gate 1, Gate 3, Gate 6, Gate 10 |
| `RG-026` | UI remains readable and reachable at the tested scale/resolution | Session Setup, Gates 2-9 |
| `RG-027` | Enter/leave/transition paths do not leave stale state | Gate 1, Gate 10 |
| `RG-028` | Leadership or role changes update correctly | Gate 1 notes, Gate 2, Gate 6 |
| `RG-029` | Full match produces coherent calls and safe cleanup | Gates 2-10 |
| `RG-034` | Real in-client frame-time stays within budget | Gate 8 |
| `RG-035` | FPS impact stays acceptable | Gate 8 |
| `RG-036` | Memory growth stays within budget over live play | Gate 8 |
| `RG-039` | Cursor / identifier layer does not overrun budget | Gate 5, Gate 8 |
| `RG-040` | Optional Sentinel package remains acceptable when intentionally installed | Session Setup, Gate 8 |
| `RG-053` | Exact candidate behaves on install / upgrade path | Session Setup, Gate 1, Gate 10 |
| `RG-054` | Final external stop-criteria matrix is satisfied | Final Blocker Decision |

---

## Gate 1: Entry / Transition Correctness

Goal: confirm the addon enters the battleground cleanly without stale roster, wrong team ownership, or reload-only fixes.

Capture:
- Queue pop / loading screen transition
- First 15 seconds after entering
- Scoreboard open once roster fills

Checks:
- [ ] Team ownership is correct on first load
- [ ] No duplicate self row appears in team roster
- [ ] No duplicate self row appears in compact roster
- [ ] Assignments populate without requiring `/reload`
- [ ] Match status/map name/mode are correct
- [ ] Blitz vs standard labeling is correct
- [ ] No blocked-action / taint warning appears on entry
- [ ] Leaving and re-entering staging or opening scoreboard does not stale the view
- [ ] No Lua errors on entry

Status:
- Entry correctness: `PASS / FAIL`

If fail, note exactly what was wrong:
- Team ownership issue:
- Duplicate row issue:
- Assignment hydration issue:
- Other:

---

## Gate 2: Command Center Readability In Match

Goal: verify the full command center is readable and useful under live battleground use.

Capture one screenshot each:
- Tactical Map tab
- Objectives tab
- Team tab
- Enemies tab
- Assignments tab
- Review / AAR tab

Checks:
- [ ] Header state is readable at a glance
- [ ] Top-line call is short enough to read quickly
- [ ] Left column does not feel cramped or clipped
- [ ] Right column does not repeat the same information unnecessarily
- [ ] Win condition is understandable in plain player language
- [ ] Team assignments are readable without squinting
- [ ] Enemy tracker table remains readable when populated
- [ ] No obvious overlap, clipping, or cut-off text

Status:
- Command center readability: `PASS / FAIL`

Most distracting panel, if any:
- 

Most useful panel, if any:
- 

---

## Gate 3: Compact Command HUD

Goal: confirm the compact HUD is readable and stable in live play.

Capture:
- Out of combat in battleground
- In first fight
- Mid-match rotation
- End of match

Checks:
- [ ] Compact HUD stays readable on live background
- [ ] Current call is short enough to parse quickly
- [ ] Assignment block is readable
- [ ] No stale text remains after state change
- [ ] Buttons shown are meaningful and functional
- [ ] Window position feels correct and non-obstructive
- [ ] No overlap with player UI during active combat
- [ ] No blocked-action / taint warning appears when interacting with compact HUD

Status:
- Compact HUD: `PASS / FAIL`

If fail, what is wrong:
- Density:
- Contrast:
- Stale text:
- Position:
- Other:

---

## Gate 4: Support View

Goal: confirm the support/reporter surface is readable and useful instead of noisy.

Capture:
- Support view out of combat
- Support view during active rotation
- Support view during objective pressure
- Support view with the drawer collapsed and expanded

Checks:
- [ ] Summary line is understandable immediately
- [ ] Current call text is short and actionable
- [ ] Map is readable and not visually crushed
- [ ] ETA / marker information is understandable
- [ ] READ / NEXT / FEED drawer is readable when opened
- [ ] Support view still works as a quick map when the drawer is closed
- [ ] No analyst jargon feels unnecessary
- [ ] Support view helps rather than distracts

Status:
- Support view: `PASS / FAIL`

If fail, what still feels wrong:
- 

---

## Gate 5: Battlefield Identifiers / Nameplate Layer

Goal: verify the battlefield overlay is not cluttering fights.

Capture:
- Friendly stack before opener
- Live teamfight with many units visible
- Current target with crosshair active
- Free-casting enemy target if seen
- Carrier/orb holder if seen
- Identifiers with the optional Sentinel package installed too, if applicable

Target rule set to verify:
- Friendlies: icon + short name only by default
- Enemies: no persistent health bar unless current target / focus state requires it
- Cast info: only for meaningful free-cast / must-stop targets
- Objective carriers: special badge only

Checks:
- [ ] Friendly identifiers are minimal enough
- [ ] Enemy identifiers are not cluttering the battlefield
- [ ] Health bars only appear when they truly need to
- [ ] Cast presentation appears only when tactically useful
- [ ] Crosshair target is clear and readable
- [ ] Current target presentation stands out cleanly
- [ ] Non-target enemy clutter is acceptably low
- [ ] The battlefield looks more like a command overlay than a stack of boxes

Status:
- Identifier layer: `PASS / FAIL`

If fail, which clutter is the worst:
- Friendly overlay clutter:
- Enemy overlay clutter:
- Target/crosshair clutter:
- Cast clutter:

---

## Gate 6: Combat Roster

Goal: confirm the compact roster is readable and useful in live combat.

Capture:
- Pre-fight
- Mid-fight
- Post-fight / regroup

Checks:
- [ ] Team rows are readable at combat glance
- [ ] Assignment labels are useful
- [ ] Markers/icons are clean, not cheap-looking
- [ ] Spotlight row is readable
- [ ] No overlap with center combat space
- [ ] No stale row state after deaths / regroup / transitions
- [ ] Expand/team/enemy/both controls render correctly
- [ ] No blocked-action / taint warning appears when showing/hiding roster surfaces

Status:
- Combat roster: `PASS / FAIL`

If fail:
- Visual issue:
- State issue:
- Position issue:

---

## Gate 7: Enemy Tracker / Notes

Goal: confirm the enemy tracker is readable and the note/profile workflow is useful.

Capture:
- Tracker with roster only
- Tracker after visible enemies are observed
- Any note/profile interaction used in match

Checks:
- [ ] Column labels are understandable
- [ ] Rows remain readable when populated
- [ ] `ADD / NOTE / PROFILE` language makes sense
- [ ] Tracked enemies show useful last-seen/location info
- [ ] Notes feel useful rather than noisy
- [ ] No clipped CTA buttons

Status:
- Enemy tracker / notes: `PASS / FAIL`

If fail:
- 

---

## Gate 8: Performance / Load

Goal: verify the addon does not create visible gameplay drag.

Capture:
- Escape menu performance panel before combat
- Escape menu performance panel during heaviest combat
- Escape menu performance panel after match

Checks:
- [ ] FPS remains stable enough for live play
- [ ] CPU usage does not spike unreasonably in combat
- [ ] Addon memory remains acceptable during match
- [ ] Addon memory settles acceptably after the match
- [ ] No obvious hitching when windows update
- [ ] No obvious hitching on transitions, scoreboard open, or AAR open
- [ ] Cursor / reticle / identifier usage does not cause obvious frame drops
- [ ] If the optional Sentinel package is installed, combined runtime still feels acceptable

Status:
- Performance: `PASS / FAIL`

Numbers:
- Before combat FPS / CPU / memory:
- Heavy combat FPS / CPU / memory:
- Post-match FPS / CPU / memory:
- 20+ minute memory trend, if captured:

Observed hitching:
- None / Light / Moderate / Severe

---

## Gate 9: Post-Match Review / AAR

Goal: confirm the end-of-match surfaces are readable and complete.

Capture:
- Review / AAR page
- AAR modal
- Export window

Checks:
- [ ] Match history is readable
- [ ] Result badge and review state are clear
- [ ] AAR modal is readable on live background
- [ ] Choice groups are usable
- [ ] Snapshot / command review / evidence blocks are readable
- [ ] Export window is readable and selectable
- [ ] No clipping, overlap, or washed-out text
- [ ] Match-end cleanup does not produce stale combat or assignment state

Status:
- Post-match review / AAR: `PASS / FAIL`

If fail:
- 

---

## Gate 10: Error-Free Session

Goal: confirm the run is clean enough to move past the field-verification block.

Checks:
- [ ] No Lua errors on load
- [ ] No Lua errors on battleground entry
- [ ] No Lua errors during combat
- [ ] No Lua errors on match end
- [ ] No Lua errors on review/export open
- [ ] No blocked-action / taint errors in combat or on combat exit
- [ ] No reload required to restore correctness

Status:
- Error-free session: `PASS / FAIL`

Errors seen:
- 

---

## Final Blocker Decision

Mark each remaining blocker:

- Entry / transition correctness: `PASS / FAIL`
- Command center readability: `PASS / FAIL`
- Compact HUD readability: `PASS / FAIL`
- Support view readability: `PASS / FAIL`
- Identifier/nameplate clutter: `PASS / FAIL`
- Combat roster readability: `PASS / FAIL`
- Enemy tracker / notes: `PASS / FAIL`
- Performance/load: `PASS / FAIL`
- Post-match review / AAR: `PASS / FAIL`
- Error-free session: `PASS / FAIL`

Field-verification block overall:
- `CLEARED`
- `NOT CLEARED`

If not cleared, top 3 fixes needed next:
1.
2.
3.

## Screenshot Inventory

Attach or save:
- [ ] UI scale / graphics settings screenshot
- [ ] Entry transition
- [ ] Scoreboard hydration
- [ ] Full command center tabs
- [ ] Compact HUD
- [ ] Support view (collapsed and drawer open)
- [ ] Combat roster
- [ ] Identifier/nameplate examples
- [ ] Heavy combat performance panel
- [ ] Post-match performance panel
- [ ] Post-match review page
- [ ] AAR modal
- [ ] Export dialog
- [ ] Taint / error log evidence if any problem appears
