# KWR Comprehensive Battleground Visual Audit

Date: 2026-07-15  
Scope: before BG, queue/setup, live BG, combat-density, post-match, AAR, export,
options, support view, reporter, identifiers  
Source set: screenshot evidence supplied across 2026-07-14 and 2026-07-15 review threads

## Executive summary

KWR now has a coherent product shell. The addon no longer reads like unrelated
PvP widgets glued together. The brand is visible, the page architecture is
stable, and the command-center identity is strong enough to preserve.

The visual system is still not finished. The remaining issues are no longer
"build a theme" problems. They are now concentrated in four areas:

1. live-combat clutter and priority competition;
2. support/reporter readability under density;
3. post-match and AAR information hierarchy;
4. lingering control-surface inconsistencies on utility windows.

The right next step is not a redesign. It is a strict finalization pass against
the existing shell.

Current visual readiness:

- out-of-combat planning/readability: `8.9`
- live commander combat readability: `8.4`
- post-match review/export readability: `8.5`
- overall visual release readiness: `8.7`

Target after the next implementation pass and live verification:

- overall visual release readiness: `9.2+`

## Review coverage

The screenshot set now covers the major lifecycle stages:

- before BG / town / queue setup
- full command center in setup mode
- options and launcher/menu
- compact setup center
- live BG command center pages
- live BG support view
- live identifiers and local-target/crosshair overlays
- live compact HUD plus roster pressure
- after-match command center and review surfaces
- AAR review modal
- export modal

This is sufficient to issue a consolidated visual recommendation pack.

## Global assessment

### What is working

- KWR has a real brand and not a placeholder look.
- The black-and-gold command shell feels appropriate for a WoW RBG commander addon.
- Navigation is consistent across the major command-center pages.
- The split between command center, compact center, support view, and review is understandable.
- The battleground pages preserve truth-first presentation better than earlier builds.
- The live identifier direction is moving toward a cleaner battlefield language.

### What is not working

- Too many panels still compete at equal visual weight.
- Live combat views are trying to show too much at once.
- Dense side rails remain harder to read than their importance justifies.
- Red emergency text is still visually noisy and often less legible than it should be.
- AAR/review/export surfaces still feel like technical review tools, not polished commander review tools.
- Some controls remain semantically unclear because button labels describe implementation state instead of player purpose.

## Brand and theme evaluation

### Brand status

KWR's identity is now credible:

- tactical
- serious
- commander-led
- WoW-native
- premium-leaning rather than novelty-leaning

### Brand weaknesses

- the shell is stronger than the internals;
- thin gold borders are still overused as the main structuring device;
- content blocks often feel framed but not directed;
- some surfaces still look like alpha debug presentation inside a premium shell.

### Recommendation

Keep the current brand family.

Do not change:

- the KWR naming;
- the black / obsidian base;
- command gold as the main accent;
- the centered main-window war-room composition.

Change:

- reduce decorative border repetition;
- create stronger contrast between shell, card, and data regions;
- reserve gold for brand, selection, and top-priority command emphasis;
- use calmer slate separators for ordinary structure;
- treat purple/orange/red as semantic accents only, not general copy emphasis.

## Visual findings by phase

## Before BG / queue / town

### Command Center setup board

Current state:

- structurally strong;
- center board reads as the primary planning surface;
- side rails still feel text-dense;
- "composition plan", "leadership setup", and "ready check" read more like notes than action zones.

Problems:

- setup guidance is spread across too many boxes;
- roster action and recruit priority are readable but visually under-ranked;
- the center board carries both taxonomy and action, which weakens immediate next-step clarity.

Recommendation:

- make `next recruit` and `queue blockers` the strongest side-rail items;
- demote long-form composition explanation beneath the primary formation call;
- keep one setup thesis at the top and move supporting rationale lower;
- make the command timeline either meaningful in setup or hidden in setup.

Verification criteria:

- a new user can identify the next recruiting action in under 2 seconds;
- no setup-critical text falls below readable size at 2560x1440 / 65% scale;
- the setup board reads as one command plan, not five related notes.

### Compact setup center

Current state:

- much clearer than older HUD variants;
- good role as a queue/build helper;
- still slightly document-like in how it presents information.

Problems:

- several panels carry full-sentence text where short imperative copy would scan faster;
- "queue check" and "next step" are useful but still read like notes instead of gates;
- the top state line is good, but the body still feels too uniform.

Recommendation:

- tighten the copy into `Goal`, `Need`, `Blockers`, `Next`;
- use badges or short status chips for readiness gates;
- keep this surface decisively compact and procedural.

Verification criteria:

- compact setup center is readable without opening the full command center;
- each section answers one question only;
- no section duplicates full-board prose.

## Live BG

### Main command center live pages

Current state:

- command center pages are stable enough to serve as the truth authority;
- objectives, team, enemies, assignments, and review pages each have a clear purpose;
- top status line is improved and generally useful.

Problems:

- left rail, center board, and right rail still overcompete on some pages;
- the most important sentence is not always the visually strongest sentence;
- command text and explanation text still sit too close in weight;
- some pages have excessive empty black space paired with dense sidebars.

Recommendation:

- always prioritize the `current call` above explanation;
- reduce right-rail prose blocks by 20-35%;
- turn long supporting paragraphs into short bullets or state lines;
- keep empty-center states intentional and helpful, not merely blank.

Verification criteria:

- on any live page, the commander can identify `state`, `call`, and `assignment` instantly;
- side rails never contain the only readable version of the plan;
- the center board remains the main focus.

### Tactical map / objectives

Current state:

- map visuals are directionally correct and trustworthy;
- objective rows and score state read more cleanly than older builds;
- map call footer is useful.

Problems:

- map canvas still loses some hierarchy because the surrounding rails and badges are visually similar;
- setup/live state chips above the map are still somewhat dense;
- quick calls remain visually heavy for how often they matter relative to objective truth.

Recommendation:

- keep the map as the dominant element on tactical/objective surfaces;
- reduce chrome above the map by one level;
- let the footer handle context, and let the side rail handle consequences.

Verification criteria:

- map is the first read on tactical surfaces;
- objective markers, call state, and assignment pressure coexist without noise;
- player can answer `where`, `why`, and `what next` from one glance.

### Team page

Current state:

- roster table is clean and understandable;
- assignments in the rightmost column work well;
- summary row is strong.

Problems:

- health column is visually weak and may not justify the space when values are absent;
- right-side doctrine block remains too text-heavy;
- low roster count states produce a visually sparse table with little explanation.

Recommendation:

- increase emphasis on player name plus assignment;
- convert right-side doctrine to shorter tactical bullets;
- improve partial-roster empty state messaging.

Verification criteria:

- row scanning remains strong with 1, 5, or 10 players;
- assignment is always easier to read than doctrine notes;
- no doctrine paragraph is needed to understand the current setup state.

### Enemies page

Current state:

- structure is solid;
- no fabricated certainty is shown;
- note actions are visible.

Problems:

- note buttons still dominate the row more than the actual enemy read;
- repeated `UNKNOWN` and `NOT VISIBLE` states flatten the page visually;
- the right help rail is still useful but oversized relative to the table.

Recommendation:

- let row identity and last-seen context dominate;
- reduce the visual weight of `ADD NOTE`;
- treat unknowns as neutral state, not alarm state;
- shorten or collapse the right explanation rail once learned.

Verification criteria:

- the page answers `who matters`, `where last seen`, and `what we know` before note affordances;
- manual notes are clearly secondary to live truth;
- repeated rows remain scannable at full 8-10 enemy density.

### Assignments page

Current state:

- one-player-one-job-one-location concept is strong;
- assignment table is readable;
- personal assignment panel is good in principle.

Problems:

- plan breakdown card is overloaded and reads like an internal strategist dump;
- the command sentence across the top is too long in live pressure;
- support/primary/high markers are useful but still not visually optimized.

Recommendation:

- compress plan breakdown into short tactical bullets;
- hide technical doctrine tokens from the default player-facing surface;
- make player job, location, and urgency the dominant read;
- keep detailed planner rationale behind review/verify, not in the live surface.

Verification criteria:

- a player can identify their job/location/priority in one glance;
- no internal planner text is required to execute the assignment;
- assignment surface remains readable under both setup and live pressure.

### Compact command HUD

Current state:

- major improvement over earlier overlapping variants;
- state, score, current call, and assignment are now structurally coherent;
- better separation between title rail and content.

Problems:

- still too tall for how much screen real estate is claimed in combat;
- some copy remains too explanatory under pressure;
- alert and command phrasing can still feel crowded when many systems are active.

Recommendation:

- reduce vertical footprint;
- make the default read:
  `state -> score -> current call -> my assignment -> next action`;
- move secondary rationale behind hover, expansion, or review surfaces.

Verification criteria:

- compact HUD is readable in combat without becoming the focal point over gameplay;
- player can see `my assignment` faster than `why`;
- no section wraps into visual clutter at normal live text lengths.

## Live combat density

### Battlefield clutter

Current state:

- improved from older nameplate-heavy builds;
- command center and roster now coexist more predictably;
- identifier direction is clearly trending toward less noise.

Problems:

- live combat still has too many simultaneous visible layers:
  crosshair, target plate, local target card, compact roster, compact HUD, support view,
  enemy roster, map feed, floating identifiers, base game combat text, and external addons;
- not all of this is KWR-owned, but KWR still needs a policy for what it adds.

Recommendation:

- KWR default live battlefield policy should be:
  minimal identifier, minimal local-target card, compact HUD, compact roster;
- any support/map/reporter surface should be opt-in during live combat, not persistent by default;
- KWR should aggressively prefer glanceable symbols over framed text during combat;
- current crosshair target can show temporary health/cast emphasis; non-targets should stay light.

Verification criteria:

- in a dense fight, the player can still track their character, target, and assignment;
- KWR overlays never become the most visually chaotic element on screen;
- the addon adds guidance without replacing the battlefield.

### Support view

Current state:

- useful conceptually;
- map and read/check/feed split is good for an analyst/commander workflow.

Problems:

- current implementation is too dark, too dense, and too paragraph-heavy for live use;
- "current read", "next check", and "map feed" are valid categories but still too text-heavy;
- the map remains helpful, but surrounding chrome and blocks reduce focus.

Recommendation:

- treat support view as a commander verification surface, not a combat-primary surface;
- use shorter statements and one-line truth summaries;
- make the feed a sparse event ledger, not a prose box;
- brighten body text slightly and reduce decorative darkness.

Verification criteria:

- support view can be opened live without becoming unreadable;
- it helps verify the plan rather than competing with action execution;
- each block has a distinct purpose and no block becomes a text wall.

### Crosshair / local target / identifiers

Current state:

- concept is correct;
- local-target split from global command is valuable;
- newer identifier direction is cleaner than the old full-healthbar clutter.

Problems:

- crosshair and local-target support are still visually strong enough to compete with gameplay if not tightly bounded;
- health and cast emphasis must remain target-only or high-priority-only;
- some identifier boxes still look more like floating widgets than battlefield marks.

Recommendation:

- treat identifiers as battlefield tags, not micro-panels;
- keep current-target emphasis and free-cast emphasis only;
- friendlies: role symbol + short name;
- enemies: class/spec mark + short name;
- carriers: carrier icon and color override;
- no persistent KWR health bars except current target.

Verification criteria:

- battlefield identifiers remain useful when 8-10 units are stacked;
- no non-target enemy gets a persistent KWR health bar by default;
- current target remains the only strong health anchor created by KWR.

## After BG / review

### Post-match command center

Current state:

- structurally coherent;
- interruption/defeat/victory states are recognized;
- AAR entry points are visible.

Problems:

- post-match pages still feel too close to live pages and not enough like review mode;
- the commander shell remains heavy while the review hierarchy is not yet strong enough;
- interrupted results are currently presented correctly but not elegantly.

Recommendation:

- give post-match pages a distinct review-state treatment;
- reduce live urgency treatment once the match is over;
- promote outcome, top lesson, and review actions over raw page chrome.

Verification criteria:

- user can immediately tell the match is over and what the next review action is;
- interrupted outcomes feel intentional, not broken;
- review mode is calmer than live mode.

### AAR page

Current state:

- match history table is good;
- AAR insight side card is useful;
- export and review actions are present.

Problems:

- AAR insights still read as a dark info block instead of a prioritized review card;
- top match-summary strip is fine, but the doctrinal text below remains visually under-ranked;
- some labels feel too internal for a polished end-user review flow.

Recommendation:

- promote `result`, `review status`, and `next lesson`;
- tighten the insight card into shorter, stronger claims;
- keep doctrine copy but reduce its visual dominance over reviewed lessons.

Verification criteria:

- user can answer `what happened`, `what mattered`, and `what to review next`;
- history rows remain readable at full width;
- export/review actions feel like the natural next step.

### After Action Review modal

Current state:

- the modal has good conceptual sections;
- the review questions are reasonable.

Problems:

- overlay layering feels unfinished;
- text is readable but the screen still looks visually busy underneath;
- "decision review" and "evidence check" feel more diagnostic than polished.

Recommendation:

- strengthen modal isolation from the background;
- improve section hierarchy and spacing;
- separate user-entered review from system evidence more clearly.

Verification criteria:

- modal feels like one complete review flow;
- background no longer visually competes;
- manual review action is unmistakable.

### Export modal

Current state:

- functional;
- copy stays local and safe.

Problems:

- raw export text is too stark and too technically dense for comfortable scan;
- the framing is utility-grade, not polished;
- export content needs stronger structured grouping for human review.

Recommendation:

- improve monospace export layout with stronger section breaks;
- highlight the key top-line fields;
- keep it plain-text safe but visually calmer.

Verification criteria:

- user can quickly inspect exported evidence before copying;
- sections are visually grouped without harming copy integrity;
- the utility window no longer feels unfinished.

## Options and utility surfaces

### Options window

Current state:

- much improved over earlier overlap failures;
- grouping is now coherent;
- toggle inventory is credible.

Problems:

- still visually long and slightly heavy;
- too much equal-weight card framing;
- some dependency text remains small.

Recommendation:

- keep the current grouping;
- trim vertical density slightly;
- treat dependency copy as secondary but readable.

Verification criteria:

- no overlap at supported scales;
- dependencies are understandable;
- all visible toggles appear purposeful and live.

### Launcher / menu / minimap presence

Current state:

- functionally understandable;
- menu list is cleaner than earlier builds.

Problems:

- launcher button still reads more like a utility square than a premium icon;
- menu is serviceable but not yet branded enough;
- some menu item names still feel implementation-oriented.

Recommendation:

- simplify launcher mark and center its identity;
- use consistent product naming across menu items;
- make the menu feel like a command index rather than a dev tool list.

Verification criteria:

- launcher is recognizable at a glance on the minimap;
- menu terminology matches the product vocabulary;
- there is no ambiguity between "command center", "compact center", "support view", and "review".

## Required changes by priority

### P1

- reduce live combat clutter by enforcing a stronger default visibility policy for nonessential support surfaces;
- rewrite support view for shorter, brighter, calmer live-read blocks;
- compress assignments plan breakdown to player-facing language only;
- improve post-match and AAR hierarchy so outcome and next lesson dominate;
- reduce border repetition and equal-weight chrome across all major surfaces.

### P2

- tighten setup-board hierarchy around next recruit and queue blockers;
- improve export modal grouping and presentation;
- refine options visual density and dependency text readability;
- strengthen launcher/menu brand execution.

### P3

- polish remaining empty states;
- further normalize chip/badge vocabulary;
- reduce rare decorative inconsistencies across review surfaces.

## Verification matrix

| Surface | Before BG | Live BG | After BG | Status |
| --- | --- | --- | --- | --- |
| Main command center | reviewed | reviewed | reviewed | actionable findings complete |
| Compact setup center | reviewed | n/a | n/a | actionable findings complete |
| Tactical map | reviewed | reviewed | reviewed | actionable findings complete |
| Objectives | reviewed | reviewed | reviewed | actionable findings complete |
| Team | reviewed | reviewed | reviewed | actionable findings complete |
| Enemies | reviewed | reviewed | reviewed | actionable findings complete |
| Assignments | reviewed | reviewed | reviewed | actionable findings complete |
| Compact HUD | reviewed | reviewed | partial | actionable findings complete |
| Support view | n/a | reviewed | n/a | actionable findings complete |
| Options | reviewed | n/a | n/a | actionable findings complete |
| Launcher/menu | reviewed | reviewed | reviewed | actionable findings complete |
| Local target/crosshair/identifiers | reviewed | reviewed | reviewed | actionable findings complete |
| AAR page | n/a | n/a | reviewed | actionable findings complete |
| AAR modal | n/a | n/a | reviewed | actionable findings complete |
| Export modal | n/a | n/a | reviewed | actionable findings complete |

## Final recommendation

Visual direction is now clear enough to implement without guessing.

Do not redesign the addon.

Implement one final visual completion pass with these priorities:

1. live combat declutter policy;
2. support view readability rewrite;
3. assignments/player-facing language cleanup;
4. post-match/AAR/export hierarchy pass;
5. border/hierarchy discipline pass across all major surfaces.

If those are completed cleanly and then re-verified with one more live screenshot
matrix, KWR's visual layer should be able to move from `8.7` to `9.2+` without
reopening the underlying product identity.
