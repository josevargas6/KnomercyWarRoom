# KWR Live Visual Scrub Worksheet

Date: __________  
Tester: __________  
Build / Rev: __________  
Character / Spec: __________  
Map / Queue Type: __________  
Resolution: __________  
UI Scale: __________  
Graphics Preset: __________  

## Pass Rules

- Test one surface at a time.
- Take one clean screenshot before changing anything.
- Record only what the player can actually see, read, click, drag, or understand.
- Do not score hidden logic. Score presentation, clarity, and usability.
- If text is smart but not useful to the player, mark it as noise.
- If the same information appears in multiple places, mark the weakest copy as duplicate.
- If a problem appears only during movement, combat, zoning, scaling, or reload, write that trigger down.

## Severity

- `P0`: blocks play, causes confusion in combat, overlaps critical gameplay, unreadable, broken click/drag behavior
- `P1`: harms fast decision-making, weak hierarchy, bad spacing, stale data, duplicated or noisy wording
- `P2`: polish issue, alignment issue, minor density problem, low-value visual inconsistency

## Global Gate

- [ ] KWR is hidden in arena
- [ ] KWR is hidden in PvE instances
- [ ] Reporter, roster, and minimized windows appear only in RBG-allowed contexts
- [ ] Command HUD is available in formation / queue-building and live RBGs only
- [ ] No surface shows clipped text
- [ ] No surface shows overlapping controls
- [ ] No surface shows invented jargon or analyst-only wording
- [ ] No surface shows stale battleground data after zoning, reload, or match end
- [ ] No unexplained squares, missing glyphs, or placeholder marks appear
- [ ] Dragging works where expected and locked surfaces stay locked
- [ ] Scale remains usable at this exact resolution and UI scale

## Screenshot Matrix

Capture each surface in these states when possible.

- [ ] Formation / world state
- [ ] Queue-building / pre-match
- [ ] Battleground gate open
- [ ] Live combat
- [ ] Death / graveyard / respawn
- [ ] Match end
- [ ] Post-match world state
- [ ] After `/reload`

## Surface Scorecard

Use 1-10 for each category.

| Surface | Clarity | Readability | Layout | Terminology | Signal/Noise | Drag/Click | Combat Use | Overall |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Command HUD |  |  |  |  |  |  |  |  |
| Combat Roster |  |  |  |  |  |  |  |  |
| Reporter Map |  |  |  |  |  |  |  |  |
| Main Window |  |  |  |  |  |  |  |  |
| Tactical Map |  |  |  |  |  |  |  |  |
| Cursor / Reticle / Spotlight |  |  |  |  |  |  |  |  |
| Options |  |  |  |  |  |  |  |  |
| Launcher / Minimap Ring |  |  |  |  |  |  |  |  |

## Questions To Ask On Every Surface

1. What is this surface supposed to help me decide in the next 2 seconds?
2. Is the most important message visually obvious without reading the whole window?
3. What is the one line or block that feels like noise?
4. Is any wording internal/dev/analyst language instead of real battleground language?
5. Is any information duplicated somewhere else more clearly?
6. Can I read this while moving or in combat?
7. Is anything too dim, too compressed, too small, or too low-contrast?
8. Are any buttons present that do not clearly do something useful?
9. Does this surface feel anchored and intentional, or floaty and patchy?
10. If I hid 30% of this surface, what would I remove first?

## Surface-by-Surface Worksheet

---

## 1. Command HUD

Purpose:
- bottom-line command
- assignment
- next move
- win condition

Checks:
- [ ] The top status line is immediately understandable
- [ ] The main call is short, plain, and useful
- [ ] The assignment block uses real battleground terms only
- [ ] The next move block is readable at combat glance speed
- [ ] No analyst/confidence jargon is exposed unless the player truly needs it
- [ ] Buttons are meaningful and visibly interactive
- [ ] The frame is movable when unlocked
- [ ] The frame does not appear in disallowed PvE/arena contexts

Questions:
- Can I understand the bottom line without interpreting hidden system language?
- Is there any sentence here that should be rewritten into plain PvP language?
- Is any block repeating the same idea as another block?

Issues:

| Severity | Screenshot | Problem | Trigger | Expected | Suggested Fix |
|---|---|---|---|---|---|
|  |  |  |  |  |  |

---

## 2. Combat Roster

Purpose:
- local kill target
- fast team/enemy scan
- assignment reference

Checks:
- [ ] Header is readable and not stale
- [ ] Rows do not duplicate or persist incorrectly after roster changes
- [ ] Class/name/spec/assignment hierarchy is visually clear
- [ ] Marker icons look intentional, not tiny/cramped/crude
- [ ] Spotlight area does not overlap or hide critical row content
- [ ] Red warning/status text is readable against the background
- [ ] Expand, team, enemy, both, and close controls are aligned and legible
- [ ] Local target state is obvious even when no target exists

Questions:
- Can I identify the right row in less than one second?
- Are markers/icons helping or just decorating?
- Does the spotlight strengthen target understanding or create clutter?

Issues:

| Severity | Screenshot | Problem | Trigger | Expected | Suggested Fix |
|---|---|---|---|---|---|
|  |  |  |  |  |  |

---

## 3. Reporter Map

Purpose:
- simple battlefield picture
- pressure, route, objective, and flag context

Checks:
- [ ] The map is square or otherwise correctly proportioned
- [ ] The map is not visually smushed or stretched
- [ ] Objective markers are clear at a glance
- [ ] Labels are readable and not overcrowded
- [ ] The top summary uses plain player language
- [ ] Trust/risk/analyst language does not overwhelm the actual call
- [ ] The most important action is visually obvious
- [ ] The panel remains readable during active match movement

Questions:
- Does the map itself communicate more than the text?
- Is the player learning something actionable from this panel in under 2 seconds?
- What text belongs behind the scenes instead of on the window?

Issues:

| Severity | Screenshot | Problem | Trigger | Expected | Suggested Fix |
|---|---|---|---|---|---|
|  |  |  |  |  |  |

---

## 4. Main Window

Purpose:
- deep command board
- review, team, enemy, objectives, assignments, AAR

Checks:
- [ ] Title/header area is aligned
- [ ] Tabs are evenly spaced and readable
- [ ] No tab page has clipping, overlap, or crushed density
- [ ] Each page has a clear top takeaway
- [ ] Sidebars do not compete with the main content area
- [ ] Status badges are readable and consistently styled
- [ ] Empty states look intentional, not broken
- [ ] Real battleground wording is used consistently

Questions:
- Is the page hierarchy obvious from far view?
- What panel feels overloaded first?
- What panel is saying too much without adding more value?

Issues:

| Severity | Screenshot | Problem | Trigger | Expected | Suggested Fix |
|---|---|---|---|---|---|
|  |  |  |  |  |  |

---

## 5. Tactical Map

Purpose:
- strategic map-centered command view

Checks:
- [ ] Map is centered and proportioned correctly
- [ ] Icons align with intended positions
- [ ] Friendly/enemy/objective ownership is clear
- [ ] Supporting text does not overpower the map
- [ ] Visual density remains usable in combat

Questions:
- Is the map the focus, or is text stealing attention from it?
- Are icons understandable without decoding?

Issues:

| Severity | Screenshot | Problem | Trigger | Expected | Suggested Fix |
|---|---|---|---|---|---|
|  |  |  |  |  |  |

---

## 6. Cursor / Reticle / Spotlight

Purpose:
- fast target confirmation
- local priority emphasis

Checks:
- [ ] Reticle is centered
- [ ] Crosshair lines do not feel oversized or distracting
- [ ] Target name/health remains readable over the effect
- [ ] Spotlight does not cover gameplay-critical information
- [ ] The visual reads as premium, not noisy
- [ ] The system shows only in intended battleground contexts

Questions:
- Does this help me secure the right target faster?
- Is any part of the effect too bright, too thick, or too theatrical?

Issues:

| Severity | Screenshot | Problem | Trigger | Expected | Suggested Fix |
|---|---|---|---|---|---|
|  |  |  |  |  |  |

---

## 7. Options

Purpose:
- functional, trustworthy controls only

Checks:
- [ ] No section header overlaps controls
- [ ] Toggle descriptions fit cleanly
- [ ] Dependency text is readable
- [ ] Only real live features are exposed
- [ ] The window is movable if intended
- [ ] The layout works at this UI scale

Questions:
- Does every toggle clearly map to a real system?
- What should be removed instead of explained better?

Issues:

| Severity | Screenshot | Problem | Trigger | Expected | Suggested Fix |
|---|---|---|---|---|---|
|  |  |  |  |  |  |

---

## 8. Launcher / Minimap Ring

Purpose:
- compact entry point

Checks:
- [ ] Ring is centered on the logo
- [ ] The button does not collide with the minimap frame
- [ ] Hover/click state feels intentional
- [ ] It remains readable at the current scale

Questions:
- Does this look like a polished addon launcher or a debug remnant?

Issues:

| Severity | Screenshot | Problem | Trigger | Expected | Suggested Fix |
|---|---|---|---|---|---|
|  |  |  |  |  |  |

## Duplicate / Noise Audit

List anything shown in more than one place. Keep the best version. Simplify or remove the weaker version.

| Information | Surfaces Where It Appears | Best Version | Remove / Simplify From |
|---|---|---|---|
|  |  |  |  |

## Terminology Audit

Mark any wording that is not real battleground/player language.

| Screenshot | Current Wording | Why It Fails | Correct PvP Term / Rewrite |
|---|---|---|---|
|  |  |  |  |

## Readability Audit

Use this when text technically exists but fails in play.

| Screenshot | Text / Element | Problem | Cause | Fix Needed |
|---|---|---|---|---|
|  |  |  |  |  |

## Movement / Combat Audit

Watch the same surface while mounting, jumping, strafing, targeting, fighting, dying, and respawning.

| Surface | Stable? | Readable? | Stale? | Overlaps gameplay? | Notes |
|---|---|---|---|---|---|
|  |  |  |  |  |  |

## Final Triage

### P0 Fixes Before Broader Testing

1. ________________________
2. ________________________
3. ________________________

### P1 Fixes For Next Code Pass

1. ________________________
2. ________________________
3. ________________________

### P2 Polish Queue

1. ________________________
2. ________________________
3. ________________________

## Done Definition For Visual Scrub

- [ ] Every surface answers its purpose in under 2 seconds
- [ ] No critical overlap or clipping remains
- [ ] No unexplained analyst/dev wording remains on player-facing windows
- [ ] No duplicate information remains unless it serves a different use case
- [ ] The addon looks intentional at the tested UI scale and resolution
- [ ] The battleground-only visibility policy behaves correctly
- [ ] Screenshots from the full matrix are clean enough to use in a test package
