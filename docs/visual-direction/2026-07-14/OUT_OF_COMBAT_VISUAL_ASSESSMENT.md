# KWR Out-of-Combat Visual Assessment

Date: 2026-07-14  
Review roles: senior visual designer, addon developer, product QA, release reviewer  
Scope: town, RBG formation, Command Center pages, options, launcher, setup center,
target assist, and full-screen context  
Excluded: final live-combat readability verdict

## Executive Assessment

KWR already has a recognizable identity: serious, tactical, restrained, and clearly
separate from the default WoW interface. The black/charcoal base and command gold
communicate a war-room product effectively. The page architecture is also more
coherent than earlier builds: surfaces share a shell, tabs align, controls use one
visual family, and the addon no longer looks like unrelated windows.

The present visual execution is not yet distribution-grade. Nearly every item is
given the same one-pixel gold box, uppercase label, dark fill, and similar text
weight. This flattens hierarchy. The user sees containers before decisions. At the
reference 2560x1440 / 65% UI scale, body and metadata text are frequently below a
comfortable scan size, while large empty regions and dense side panels coexist on
the same page. State color is expressive but insufficiently disciplined: gold,
blue, green, red, purple, and yellow can all compete within one screen.

Visual-only readiness is `7.3 / 10`. The foundation is credible and worth
preserving; the gap is a shared design-system and information-hierarchy pass, not a
new theme or wholesale UI rewrite.

## Visual Scorecard

These scores assess screenshot presentation only. They do not rescore runtime logic,
truth handling, or addon safety.

| Category | Score | Assessment |
| --- | ---: | --- |
| Brand concept | 8.3 | Strong command-center identity with a clear tactical tone. |
| Brand execution | 7.2 | Gold-on-black is recognizable but currently generic and over-applied. |
| Information hierarchy | 6.8 | Cards, labels, and borders compete at nearly equal weight. |
| Typography and readability | 7.0 | Clean letterforms, but body and metadata are too small at 65% UI scale. |
| Layout and spacing | 7.3 | Shell is aligned; internal density and empty-space distribution are uneven. |
| Color semantics | 6.9 | Useful palette, but decorative and semantic color are mixed. |
| Surface consistency | 7.7 | Shared shell and controls are visible strengths. |
| Responsive/future-proof structure | 6.7 | Extensive fixed geometry creates scale and content-length risk. |
| Accessibility | 6.8 | Low-contrast muted text and color-only meaning remain concerns. |
| Marketing screenshot quality | 7.0 | Credible alpha product; not yet a premium product image. |
| Overall out-of-combat visual quality | **7.3** | Strong foundation requiring one disciplined system pass. |

Target after the specified out-of-combat pass: `9.2`.  
Target after live-combat certification and correction: `9.5+`.

## Brand and Marketing Evaluation

### What the current brand communicates

- command authority;
- seriousness and tactical focus;
- a tool designed for organized RBG leadership;
- compatibility with WoW rather than a web application placed over WoW.

### What weakens the brand

- black rectangles with thin gold outlines are used for almost every level of UI;
- the default game font is used without enough typographic role separation;
- the KWR launcher mark reads as a small boxed utility rather than a signature icon;
- the interface has no distinct visual motif beyond color and rectangular framing;
- large blank areas make some pages feel unfinished while adjacent panels feel busy;
- bright semantic colors sometimes look like debug output rather than polished state.

### Target direction: Midnight Command Table

Keep the KWR name, command gold, and dark tactical tone. Modernize the expression:

- use obsidian and midnight-navy layers instead of undifferentiated black;
- use warm command gold only for brand, active selection, and primary action;
- use cool slate separators for ordinary structure;
- use faction and state colors only for live meaning;
- introduce one restrained signature motif: a command-line/compass notch in major
  headers and the launcher, implemented with existing textures or simple geometry;
- make the interface feel machined and deliberate, not ornate or futuristic;
- avoid copying Blizzard expansion art or relying on expansion-specific assets.

The marketable promise is: **KWR turns battlefield complexity into one readable
command plan.** The visuals must demonstrate that promise before the copy explains
it.

## System-Level Findings

### P1: typography is too small for the reference environment

Evidence: setup board, positioning keys, side-panel descriptions, enemy help,
assignment plan breakdown, and launcher summary. Current UI code uses many 8-10
point roles, including 120 calls to `Theme:Font` and several 8-point operational
labels. At 65% UI scale, this forces close reading.

Required correction:

- establish minimum body, action, metadata, and table roles;
- stop using 8-point text for information required during play;
- reserve 9-10 point text for secondary metadata only;
- test contrast and physical readability on the reference setup.

### P1: hierarchy is flattened by border repetition

Evidence: every major panel, nested card, button, badge, and table area uses a gold
or brown border. The screen reads as a matrix of boxes before the primary call.

Required correction:

- only shell, active selection, primary call, and urgent state receive command gold;
- standard panels use quiet slate dividers or no complete border;
- nested cards use surface contrast and spacing before outline;
- one visual focal point per surface.

### P1: content density and empty space are poorly balanced

Evidence: Team, Enemies, Assignments, and Objectives dedicate most of the frame to
empty tables or maps while dense explanatory text is confined to narrow right rails.
The setup page combines a very large composition field with small, dense side cards.

Required correction:

- use intentional empty states that explain the next action;
- allow detail rails to widen or collapse based on content;
- use selected-row detail rather than permanent explanatory walls;
- show help on demand instead of consuming the live layout;
- apply content-length and empty-state variants.

### P1: semantic colors are not governed tightly enough

Evidence: gold, blue, green, red, and purple appear simultaneously as content text,
links, status, selection, assignment, and emphasis.

Required correction:

- gold = KWR brand, selected navigation, primary command;
- green = confirmed favorable/ready/success;
- yellow = caution/needs attention;
- orange = inferred/limited/preview;
- red = urgent hostile/failure only;
- blue = friendly/assignment/location;
- purple = secondary control/learned profile only, never general emphasis;
- every colored label must also contain a word or icon conveying the state.

### P1: fixed geometry creates future content and scale risk

Evidence: 65 explicit `SetSize` calls across UI modules, fixed 1240x760 MainWindow,
fixed 740x860 Options, fixed 194-wide tabs, and many hard-positioned card columns.
The current screenshots fit, but assignment and setup text already approaches its
allocated boundaries.

Required correction:

- keep stable default sizes but add shared responsive layout contracts;
- define minimum/comfortable/expanded modes;
- calculate fluid center widths from available shell width;
- make overflow behavior explicit for every text and list region;
- never rely on ellipsis for the only copy of actionable information.

## Surface Findings

### Command Center shell

Strengths:

- strong title and recognizably tactical frame;
- consistent six-tab navigation;
- clear setup/live context and score position;
- centered window is appropriate for planning in town.

Gaps:

- title rail is taller and more dominant than the actual command state;
- top badges are too small to carry primary state;
- tabs and page borders add a second heavy horizontal frame;
- background is almost pure black, reducing depth between shell and cards;
- the window covers a large portion of play space without an intentional focus or
  background-dim policy.

Direction:

- preserve the centered 1240x760 planning footprint;
- convert the header to one brand zone plus one status zone;
- reduce passive chrome, increase primary state readability;
- use layered navy/obsidian surfaces with a subtle shell-to-card difference;
- apply a very light game-world dim only while the full Command Center is open.

### Tactical / setup board

Strengths:

- composition title and roster need are immediately visible;
- Prev/Auto/Next offers clear setup control;
- recruit and positioning columns support actual group formation.

Gaps:

- composition name, summary, meta target list, best-fit recruits, positioning keys,
  side cards, and footer repeat the same setup story;
- the center card is simultaneously sparse at the top and dense at the bottom;
- `S+` and `Commander` naming read as model taxonomy, not immediate player action;
- the command timeline is visually present but does not carry enough value in setup.

Direction:

- top: selected composition, roster fit, and next recruit;
- middle: two balanced columns for required roles and positioning;
- bottom: optional rationale/details disclosure;
- replace repeated footer text with one next-step command;
- keep composition taxonomy available, but make the actionable build state dominant.

### Objectives

Strengths:

- score, map status, objective field, quick calls, and map info are logically grouped;
- empty state correctly avoids fabricating battleground data.

Gaps:

- the empty objective field dominates the screen without offering useful setup value;
- quick calls compete with the page's objective-information purpose;
- side-rail metadata is smaller than required for a glance read;
- `NO DATA`, `UNKNOWN`, `WORLD`, and `NO SCORE` repeat the same absence state.

Direction:

- one intentional setup empty state with a concise reason and next action;
- collapse duplicate absence labels into one top-level status;
- hide or demote live-only quick calls outside a battleground;
- reserve the center for objective state once authoritative data exists.

### Team

Strengths:

- roster table, role, state, and assignment columns are appropriate;
- the 1/10 summary is clear;
- setup plan and status provide useful formation context.

Gaps:

- one roster row floats in a very large empty table;
- the right plan card is dense and reads like documentation;
- table text is small relative to the available space;
- health, state, and assignment hierarchy is visually weak.

Direction:

- increase row and primary-name readability;
- use a roster-empty/partial roster state that explains open slots;
- turn setup doctrine into concise role and positioning bullets;
- reveal detailed doctrine on selection or help, not permanently.

### Enemies

Strengths:

- column organization is clear;
- live/recent/last-seen/note summary is useful;
- honest no-feed state protects trust.

Gaps:

- three permanent help cards consume a full rail while the enemy table is empty;
- column explanation is documentation, not active intelligence;
- priority colors are visually louder than the empty-state action;
- the page does not yet look valuable outside a live scoreboard feed.

Direction:

- keep a compact help affordance, not three permanent tutorial cards;
- use the right rail for selected-enemy details, note tags, learned traits, and
  commander takeaway when a row exists;
- in setup/no-feed state, show one concise explanation and how the page activates;
- retain truth limits in a tooltip/help drawer.

### Assignments

Strengths:

- one-player/one-job/one-location is a strong product rule;
- personal assignment card is visually distinct;
- full plan breakdown is available and scrollable.

Gaps:

- the primary action headline and setup row repeat the same information;
- plan breakdown is narrow, dense, and visibly clipped at the bottom;
- large empty main area and compressed right rail feel unfinished;
- color is being used for text hierarchy where size/weight should do more work.

Direction:

- make assignment rows the primary content and personal job the first side card;
- show a short plan summary by default and full reasoning on demand;
- remove duplicated action text;
- guarantee visible overflow affordance and no ellipsis for unique command detail.

### Review / AAR

Strengths:

- strongest current page;
- match history table has clear columns and stable row rhythm;
- result, review, and export status are understandable;
- map doctrine and AAR cards support the page purpose.

Gaps:

- last-command values truncate without an obvious selected-row detail path;
- insights block is text-heavy and visually static;
- multiple result/status badges compete with the main 8-match summary;
- `UNKNOWN` most-played map reads as a data defect without explanation.

Direction:

- selecting a history row should expose the full command and review summary;
- convert insights into two or three scannable metrics plus one lesson;
- use one result state and one review state hierarchy;
- explain unavailable aggregate data rather than showing a bare unknown.

### Setup Center

Strengths:

- setup goal, recruiting plan, queue check, and next step follow a useful sequence;
- far more glanceable than the full Command Center for formation work.

Gaps:

- every section has the same height and border treatment;
- the recruiting plan and next step repeat the same need;
- the compact window still reads as a vertical stack of boxes.

Direction:

- primary next step first;
- compact roster need and queue checklist second;
- personal assignment third;
- use separators and surface contrast instead of full borders around every block.

### Options

Strengths:

- sections are now separated and descriptions wrap;
- options map to real systems;
- scroll behavior supports the complete inventory;
- safety policy is visible.

Gaps:

- the window is very tall and visually dense;
- columns have unequal card heights and a weak shared baseline;
- dependency warnings use orange text repeatedly, creating warning fatigue;
- scrolling is not visually obvious until the user interacts;
- policy and utilities are visually equivalent to configuration sections.

Direction:

- preserve the two-column structure at comfortable width;
- add a clear scroll track or top/bottom fade indicator;
- use disabled-state styling plus one dependency line, not warning-colored repetition;
- make utilities and policy subordinate footer sections;
- keep minimum body text readable at 65% scale.

### Launcher and launcher menu

Strengths:

- menu labels are now clear and aligned with Command Center ownership;
- primary, compact, team, support, enemy, review, and verification paths are present;
- small footprint is appropriate.

Gaps:

- the minimap launcher reads as a boxed debug icon;
- launcher ring and inner mark lack a strong centered silhouette;
- menu is one undifferentiated stack of nine buttons;
- translucent menu background allows underlying UI text to compete;
- setup state badges consume space without strongly helping navigation.

Direction:

- use a circular or compass-disc KWR launcher with a centered monogram;
- communicate live/urgent state through one perimeter arc or status dot;
- group menu actions into `Command`, `Battlefield`, and `Review/Tools`;
- use one primary button and quieter secondary rows;
- increase menu background opacity enough to isolate it from the game scene.

### Target assist

Strengths:

- target identity and assignment intent are available near the target;
- the addon does not automate targeting;
- target match can remain a valuable confirmation.

Gaps:

- the small floating card competes with the nameplate and duplicates identity;
- microtext and tiny markers are not readable at combat glance distance;
- the close/marker icon does not communicate a clear action;
- status and intent need a stronger relationship to the actual nameplate.

Direction pending combat evidence:

- one compact personal-job plate, not a second miniature window;
- target name stays on the Blizzard/player nameplate;
- KWR adds job, countdown, and match state only;
- no opaque background larger than the useful content;
- final scale, alpha, and placement wait for live-combat screenshots.

## Screenshot Evidence Inventory

| ID | File suffix | Size | Primary evidence |
| --- | --- | ---: | --- |
| S01 | `bf795942...png` | 510x315 | Target-assist/nameplate relationship. |
| S02 | `06c2e555...png` | 1531x938 | Tactical setup page. |
| S03 | `14cb26eb...png` | 1511x932 | Objectives page. |
| S04 | `f9e5a646...png` | 1517x926 | Team page. |
| S05 | `721cfde2...png` | 1521x942 | Enemies page. |
| S06 | `fa8e402a...png` | 1515x932 | Assignments top state. |
| S07 | `bc38adf5...png` | 1513x926 | Assignments scrolled detail. |
| S08 | `1f441b5d...png` | 1503x942 | Review/AAR page. |
| S09 | `b365d7a4...png` | 537x797 | Compact setup center. |
| S10 | `6d2b6fa7...png` | 940x1065 | Options upper state. |
| S11 | `3ee7555d...png` | 921x1071 | Options full upper layout. |
| S12 | `19a5d721...png` | 937x1066 | Options lower state and policy. |
| S13 | `6e4c1e08...png` | 51x56 | Minimap launcher. |
| S14 | `d004d3eb...png` | 295x512 | Launcher menu. |
| S15 | `0cb53457...png` | 2557x1437 | Full-screen town context. |
| S16 | `71a718a0...png` | 1531x938 | Full Command Center crop. |

## Release Position

Out-of-combat visuals are suitable for continued internal alpha use. They are not
yet suitable as final marketing or broad external-test screenshots. There are no
confirmed visual P0 defects in this set. The shared P1 issues above should be
resolved as one system pass after the live-combat evidence is added.

