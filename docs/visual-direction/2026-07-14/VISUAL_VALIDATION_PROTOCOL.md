# KWR Visual Validation Protocol

Status: out-of-combat baseline and first Battle for Gilneas combat set recorded; full matrix pending

## Pass Philosophy

A surface passes only when it is understandable, readable, stable, and correctly
scoped in the state where the player uses it. Presence of text is not proof of
readability. Presence of a scrollbar is not proof that overflow works. A clean town
screenshot is not proof of combat usability.

## Environment Record

Record for every capture:

- KWR build and revision;
- WoW client build;
- resolution and display mode;
- WoW UI scale;
- KWR/addon surface scale if configurable;
- map and queue type;
- player role/spec;
- page/surface;
- match state;
- whether the player is moving, in combat, dead, or spectating;
- observed Lua errors, taint, FPS, CPU, and addon memory concerns.

Primary owner reference environment:

- resolution: 2560x1440;
- WoW UI scale: 65%;
- display mode: fullscreen windowed unless otherwise recorded.

## Resolution and Scale Matrix

| ID | Resolution | WoW UI scale | Addon scale | Purpose |
| --- | --- | ---: | ---: | --- |
| M1 | 1280x720 | default/supported | 0.80 | Minimum-space failure detection. |
| M2 | 1920x1080 | default/supported | 1.00 | Common baseline. |
| M3 | 2560x1440 | 65% | 1.00 | Owner reference and primary sign-off. |
| M4 | 2560x1440 | 65% | 1.15 | Large-scale clipping detection. |
| M5 | 3440x1440 if available | recorded | 1.00 | Ultrawide anchoring and line-length check. |

If WoW rejects a specific scale combination, record the nearest valid value instead
of silently skipping the cell.

## State Matrix

| State | Main | Setup HUD | HUD | Roster | Reporter | Target assist | Options | Review |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Town / solo | required | hidden unless allowed | policy check | hidden | hidden | hidden | required | required |
| RBG group building | required | required | setup mode | policy check | policy check | hidden | required | optional |
| Queue accepted/loading | transition | transition | transition | hidden/transition | hidden/transition | hidden | closed | closed |
| Gate closed | required | live setup | required | required | required | idle | optional | closed |
| Active combat | optional/closed | no | required | required | required if used | required | closed | closed |
| Death/respawn | closed/optional | no | required | required | required if used | cleared | closed | closed |
| Match complete | optional | transition | summary/transition | clear/summary | clear/summary | cleared | closed | required if enabled |
| Back in world | required | setup if grouping | setup/hidden | hidden | hidden | hidden | required | required |
| Arena | hidden | hidden | hidden | hidden | hidden | hidden | manual settings only | manual only |
| PvE instance | hidden | hidden | hidden | hidden | hidden | hidden | manual settings only | manual only |

## Screenshot Naming

Use:

`KWR_<build>_<surface>_<state>_<map>_<resolution>_<uiscale>_<sequence>.png`

Example:

`KWR_a25_CombatRoster_Active_WSG_2560x1440_65_01.png`

Do not overwrite the previous baseline. Keep before and after pairs.

## Global Pass Gates

### Readability

- primary call readable in one second on compact combat surfaces;
- primary page answer readable in two seconds on full planning surfaces;
- body copy readable at normal viewing distance in the owner reference environment;
- no required information uses 8-point metadata styling;
- no text depends on the game scene being dark;
- no long saturated-color paragraph;
- no clipped glyph, word, line, or descender.

### Hierarchy

- one obvious focal point per surface;
- primary action is stronger than explanation;
- active navigation is visible without hover;
- no more than four top-rail badges;
- no more than two nested full-border levels;
- unknown/inactive state does not visually resemble urgent failure.

### Layout

- zero overlapping frames, labels, buttons, scrollbars, or textures;
- zero content outside its panel or clipping region;
- no unexplained empty rectangle;
- no unique actionable text lost to ellipsis;
- rows do not change height or shift columns during refresh;
- window remains clamped and movable when unlocked;
- saved position survives `/reload` and relog.

### Color and state

- same state uses the same color everywhere;
- color always has a text/icon companion;
- gold indicates brand, selection, or primary command only;
- red is reserved for urgent hostile/failure state;
- inferred/preview data is not styled as confirmed;
- stale/dead state remains readable and is not merely reduced to near invisibility.

### Interaction

- every visible button has an obvious purpose;
- hover, selected, disabled, and pressed states are distinct;
- dependency-disabled options cannot appear active;
- scroll affordance is visible before the user discovers overflow accidentally;
- close, minimize, and back behavior are consistent;
- no click target is smaller than 24 high unless attached to a Blizzard-owned control.

### Scope and safety

- KWR remains silent in arena and PvE instances per policy;
- compact battleground surfaces do not persist in world content unless explicitly
  allowed for group formation;
- target assist never automates target/focus/action;
- visual changes introduce no protected-action mutation;
- no visual state fabricates certainty.

### Performance

- no new `OnUpdate` loop;
- no layout calculation on ordinary unchanged Store publishes;
- no texture/font allocation during normal refresh;
- no visible stutter when opening, closing, switching pages, or receiving rapid data;
- existing smoke and soak budgets remain green;
- record FPS/CPU before and after the combat capture sequence.

## Surface Acceptance Sheets

### Full Command Center

- product title, state, and score do not compete;
- tabs align and active tab is obvious;
- each page has one dominant answer;
- side rails support rather than duplicate the center;
- empty states state why and what happens next;
- window does not visually swallow the game world more than needed for planning.

### Tactical/setup

- selected composition, roster need, and next recruit are visible first;
- detailed rationale is secondary;
- no repeated next-step sentence;
- 1-player and 10-player states both look intentional;
- timeline is useful or absent.

### Objectives

- current score/win condition is first;
- objective owner/state/confidence rows are readable;
- no repeated no-data language;
- setup state does not render live-only controls as primary;
- no source label implies truth that is not available.

### Team

- name, spec/role, readiness, health, and assignment remain aligned;
- partial roster uses intentional empty state;
- full roster fits without row compression;
- setup doctrine is scannable;
- stale/unavailable players remain readable.

### Enemies

- feed state is explicit;
- row identity and priority are readable in under one second;
- selected enemy detail separates live truth, manual note, and learned model;
- help does not consume the permanent live detail rail;
- no note or profile text clips.

### Assignments

- player, job, location, state, and timing are primary;
- personal assignment is obvious;
- plan detail has visible overflow behavior;
- no duplicate action headline;
- lock state and manual handoff remain clear.

### Review/AAR

- result, review state, and next lesson scan in order;
- full command is accessible from a selected row;
- unknown aggregate data is explained;
- open review and copy export remain obvious;
- no editable-looking field appears behind display text.

### Setup Center

- next step is first;
- roster need and queue check do not repeat;
- personal assignment is readable;
- no equal-weight border stack;
- setup mode cannot be mistaken for live combat.

### Options

- all cards stay within the scroll child;
- summaries and descriptions wrap;
- dependency state is clear and not warning-noisy;
- lower policy/footer content remains reachable;
- scrollbar/fade indicates additional content;
- reset action is visually separate from normal toggles.

### Launcher/menu

- logo/ring are centered;
- icon reads at minimap size;
- status is visible without tiny tag text;
- menu groups are distinct;
- primary action reflects context;
- game-world text does not show through enough to compete.

### HUD, roster, reporter, target assist

The first Battle for Gilneas combat set confirms excessive simultaneous nameplate,
spotlight, roster, and target-assist density. Target-assist certification now requires:

- friendly identifiers show role icon plus short name only by default;
- enemy identifiers show class icon plus short name only by default;
- carrier icon/color replaces role/class identity while the carrier fact is confirmed;
- no KWR health strip appears except on the current enemy target;
- no KWR cast strip appears except during an active priority cast;
- UNKNOWN identity uses a neutral fallback and never guesses;
- KWR identifier background remains transparent in bright and dark scenes;
- base Blizzard/third-party nameplate behavior remains user-owned and unmodified;
- no protected action, target change, focus change, macro, or taint is introduced.

## Required Combat Capture Set

Capture these before releasing the implementation hold:

1. gate closed, all intended compact surfaces visible;
2. first teamfight with ordinary pressure;
3. urgent win-condition state;
4. local target acquired and target matched;
5. assigned target not matched;
6. multiple friendly/enemy compact identifiers with reticle enabled;
7. confirmed flag carrier and orb carrier identifier replacement;
8. ReporterMap at highest observed marker density;
9. CombatRoster with team/enemy/both modes;
10. player dead at graveyard;
11. match complete and transition back to world;
12. one bright outdoor scene and one dark indoor/tunnel scene;
13. `/kwr verify` and performance panel after the match.

For each combat capture, note whether the surface changed position, size, alpha,
content height, or row order during the preceding five seconds.

## Release Decision

Visual release status is exactly one of:

- `NO-GO`: any P0, unreadable command, overlap, taint, or unsafe scope behavior;
- `CONDITIONAL`: no P0, but one or more P1 readability/hierarchy defects remain;
- `LIMITED`: matrix passes for controlled owner hardware only;
- `GO`: full matrix passes, no P0/P1 remains, performance gates pass, and owner signs
  off the before/after evidence.

Current visual decision: `CONDITIONAL - FIRST COMBAT SET RECEIVED; FULL MATRIX OPEN`.
