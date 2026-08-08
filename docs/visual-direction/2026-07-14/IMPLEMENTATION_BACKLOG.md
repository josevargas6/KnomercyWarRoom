# KWR Visual Implementation Backlog

Status: active; Battle for Gilneas combat evidence received, matrix certification pending

## Execution Rules

- complete work in the listed order;
- no surface-specific color or spacing patches before the token foundation;
- preserve existing feature behavior and saved positions;
- every slice must leave the addon loadable and all existing validators passing;
- do not merge final combat density decisions until combat evidence is reviewed;
- update the live scorecard only after evidence satisfies acceptance criteria.

## Phase 0 - Evidence and Baseline

### VIS-000 - Freeze visual baseline

Priority: P0 process gate  
Effort: 0.5 day  
Files: documentation and screenshot evidence only

Work:

- record build, resolution, UI scale, addon scale, page, and state for every image;
- preserve S01-S16 as the out-of-combat comparison set;
- add live-combat images using the protocol in this package;
- list any Lua errors, taint, frame-time spikes, or state changes seen during capture.

Acceptance:

- every supported surface has one identified formation/town image;
- every combat surface has one idle, active, urgent, death/respawn, and match-end
  image where applicable;
- no screenshot is accepted without environment metadata.

Independent: yes  
Rollback: documentation-only.

### VIS-001 - Confirm information ownership

Priority: P1  
Effort: 0.5-1 day  
Files: `UI/MainWindow.lua`, `UI/HUD.lua`, `UI/ReporterMap.lua`,
`UI/CombatRoster.lua`, `UI/Options.lua` review only

Work:

- identify the one primary answer on every surface;
- mark duplicate command, roster need, assignment, trust, and setup copy;
- decide keep, demote, disclose, or remove for each duplicate;
- preserve underlying logic and technical verification output.

Acceptance:

- one ownership table exists for every repeated player-facing fact;
- no unique actionable information is scheduled for removal;
- technical truth remains available in verification/AAR even when hidden from live UI.

Dependency: VIS-000  
Independent: yes.

## Phase 1 - Shared Visual Foundation

### VIS-100 - Theme token layer

Priority: P1  
Effort: 1-1.5 days  
Files: `UI/Theme.lua`, smoke tests

Work:

- add spacing, typography, surface, semantic-color, opacity, and border tokens;
- retain compatibility aliases for current color names during migration;
- add token lookup validation;
- prevent surface modules from inventing new raw visual constants where practical.

Acceptance:

- old surfaces render without behavior loss during migration;
- token inventory is deterministic and smoke-tested;
- gold, semantic color, and normal-divider ownership match the visual spec;
- no new runtime allocation path is introduced.

Dependency: VIS-001  
Rollback: compatibility aliases allow single-file rollback.

### VIS-101 - Shared typography roles

Priority: P1  
Effort: 1 day  
Files: `UI/Theme.lua`, all UI modules incrementally

Work:

- add named product-title, page-headline, section, action, body, table, metadata, and
  technical roles;
- migrate required player information away from 8-point text;
- normalize uppercase usage and line height;
- preserve WoW-provided fonts only.

Acceptance:

- no required command, assignment, objective, target, or readiness information uses
  the metadata role;
- no body sentence is full uppercase;
- reference environment is readable at normal viewing distance;
- no clipping appears at supported scales.

Dependency: VIS-100.

### VIS-102 - Shared panel, card, empty-state, and scroll primitives

Priority: P1  
Effort: 1.5-2 days  
Files: `UI/Theme.lua`, deterministic UI fixtures

Work:

- extend existing components with variant support;
- add explicit empty, unknown, disabled, and urgent treatments;
- add scroll clipping and visible overflow affordance;
- cap nested full-border depth at two.

Acceptance:

- primitives render each defined state without nil data;
- display text never shows edit-box chrome;
- scroll content clips correctly and exposes overflow;
- no component adds a ticker or per-frame script.

Dependency: VIS-100, VIS-101.

### VIS-103 - Responsive layout contract

Priority: P1  
Effort: 1.5-2 days  
Files: `UI/MainWindowShell.lua`, `UI/MainWindow.lua`, `UI/Options.lua`

Work:

- add minimum, comfortable, and expanded layout modes;
- centralize shell insets, rails, gaps, and bounded side widths;
- define overflow behavior for text, lists, tables, and details;
- preserve current saved position schema.

Acceptance:

- no overlap or clipping at matrix resolutions/scales;
- side rails never shrink below readable width;
- center content grows without creating excessive line lengths;
- no ordinary Store publish triggers full relayout.

Dependency: VIS-102.

## Phase 2 - Out-of-Combat Surface Migration

### VIS-200 - Command Center shell

Priority: P1  
Effort: 1-1.5 days  
Files: `UI/MainWindow.lua`, `UI/MainWindowShell.lua`

Work:

- consolidate title, context, score, and status hierarchy;
- reduce passive gold chrome;
- convert navigation to one clear active-state treatment;
- introduce layered shell/panel depth;
- add bounded world-dim behavior while the full window is open.

Acceptance:

- title and primary state scan separately;
- active tab is unambiguous without hover;
- no more than four top-rail badges;
- planning window remains centered, movable, clamped, and position-persistent;
- opening/closing adds no taint or frame-time spike.

Dependency: VIS-103.

### VIS-201 - Tactical/setup page

Priority: P1  
Effort: 1.5-2 days  
Files: `UI/MainWindow.lua`, `UI/MainWindowPages.lua`

Work:

- establish selected composition, roster fit, and next recruit as top hierarchy;
- rebalance recruit and positioning columns;
- move extended rationale behind learning/detail disclosure;
- remove repeated setup footer/action copy;
- make timeline conditional on useful content.

Acceptance:

- next setup action is readable in under two seconds;
- composition details fit without clipping at the reference environment;
- every repeated setup sentence has one visible owner;
- empty timeline space is not rendered as an unfinished panel.

Dependency: VIS-200.

### VIS-202 - Objectives page

Priority: P1  
Effort: 1 day  
Files: `UI/MainWindow.lua`, `UI/MainWindowPages.lua`, `UI/QuickCalls.lua`

Work:

- replace repeated world/no-data labels with one empty-state contract;
- demote live-only quick calls during setup;
- enlarge objective and win-condition operational text;
- keep data-source detail available through help/verification.

Acceptance:

- setup state has one absence message and one next action;
- live objective data remains the center focus;
- quick calls never compete with the win-condition call;
- unknown truth is explicit and not visually alarming.

Dependency: VIS-200.

### VIS-203 - Team page

Priority: P1  
Effort: 1-1.5 days  
Files: `UI/MainWindow.lua`, roster page helpers

Work:

- increase row hierarchy and stable row rhythm;
- add partial-roster empty-space treatment;
- compress plan copy into scannable roles/positioning;
- clarify state and assignment columns.

Acceptance:

- player, role, readiness, and assignment scan in one pass;
- 1/10 and 10/10 layouts both look intentional;
- plan detail never requires an undersized paragraph;
- updates do not change row height or column alignment.

Dependency: VIS-200.

### VIS-204 - Enemies and note-detail page

Priority: P1  
Effort: 1.5-2 days  
Files: `UI/MainWindow.lua`, enemy-note editor UI

Work:

- replace permanent help rail with selected-enemy detail;
- define no-feed/partial/full variants;
- retain note tags, learned traits, takeaway, and truth separation;
- move data-limit documentation to help/verification.

Acceptance:

- no-feed state is useful without looking empty or broken;
- selected enemy detail shows live truth, manual note, and learned model distinctly;
- note editor fits at reference scale and all text wraps/clips correctly;
- colors follow the semantic contract.

Dependency: VIS-200.

### VIS-205 - Assignments page

Priority: P1  
Effort: 1.5-2 days  
Files: `UI/MainWindow.lua`, assignment page helpers

Work:

- make assignment rows the dominant content;
- remove duplicated action headline text;
- shorten default plan breakdown and disclose full reasoning;
- guarantee visible scroll state and text clipping.

Acceptance:

- player, job, location, state, and timing are readable without side-panel parsing;
- personal assignment remains the first side card;
- no unique command line is ellipsized without a full-detail path;
- plan breakdown never draws outside its panel.

Dependency: VIS-200.

### VIS-206 - Review/AAR page

Priority: P2  
Effort: 1-1.5 days  
Files: `UI/MainWindow.lua`, `UI/AARWindow.lua`

Work:

- add selected-match detail for full command text;
- reduce metric/badge duplication;
- convert insights to scannable metrics plus one lesson;
- explain unavailable aggregates.

Acceptance:

- full last command is available from every row;
- one result and one review state dominate;
- insights are readable in under three seconds;
- copy/export actions remain clear and functional.

Dependency: VIS-200.

### VIS-207 - Options

Priority: P1  
Effort: 1-1.5 days  
Files: `UI/Options.lua`, `UI/Theme.lua`, smoke layout audit

Work:

- migrate to responsive two/one-column card grid;
- add visible scroll affordance;
- normalize card heights and footer ownership;
- replace repeated orange dependency warnings with disabled-state hierarchy;
- retain current functional option inventory and position behavior.

Acceptance:

- zero overlap at supported sizes;
- every description wraps inside its card;
- every dependency can be understood without trial and error;
- scroll state is visible;
- `Options:LayoutAudit()` passes all matrix fixtures.

Dependency: VIS-102, VIS-103.

### VIS-208 - Launcher and menu

Priority: P2  
Effort: 1-1.5 days  
Files: `UI/MainWindowLauncher.lua`, `UI/MainWindowShell.lua`

Work:

- create a centered circular/compass KWR mark with existing lightweight assets;
- use one perimeter/status indicator;
- group menu actions and establish one contextual primary action;
- raise menu opacity and simplify badge hierarchy.

Acceptance:

- launcher is centered on the minimap ring at all minimap sizes;
- state is readable without tiny text;
- menu groups are visually distinct;
- underlying game UI does not compete with labels;
- drag, hover, click, and saved angle remain correct.

Dependency: VIS-100, VIS-102.

### VIS-209 - Setup Center

Priority: P2  
Effort: 1 day  
Files: `UI/HUD.lua` setup-state branch

Work:

- promote next setup action;
- combine repeated recruiting need;
- reduce full-border stacking;
- preserve movement, lock, and setup visibility behavior.

Acceptance:

- next step, roster need, queue check, and personal assignment scan in order;
- no repeated setup sentence appears twice;
- compact surface uses no undersized action text;
- setup and live modes remain visibly different.

Dependency: VIS-102.

## Phase 3 - Combat Surface Migration

Do not estimate final geometry until VIS-000 combat evidence is complete.

### VIS-300 - Compact HUD live mode

Priority: P1  
Provisional effort: 1.5-2 days  
Files: `UI/HUD.lua`

Acceptance focus:

- primary call readable in one second;
- no paragraph text during active combat;
- stable layout through updates;
- no obstruction of core player UI;
- opacity works against bright and dark scenes.

### VIS-301 - CombatRoster and spotlight

Priority: P1  
Provisional effort: 1.5-2 days  
Files: `UI/CombatRoster.lua`, `UI/CombatRosterVisuals.lua`,
`UI/CombatRosterState.lua`

Acceptance focus:

- local target and personal/team assignment are immediately visible;
- rows remain stable;
- marker, spotlight, and target status do not duplicate or overlap;
- stale/dead/unavailable states are readable without excessive dimming.

### VIS-302 - ReporterMap / battlefield support view

Priority: P1  
Provisional effort: 2-3 days  
Files: `UI/ReporterMap.lua`, `UI/TacticalMap.lua`

Acceptance focus:

- map remains square and proportionally correct;
- current call outranks technical trust detail;
- pressure, route, and objective markers remain readable at combat density;
- no analyst jargon is required to understand the next action.

### VIS-303 - Target assist / reticle / crosshair

Priority: P1  
Provisional effort: 1.5-2 days  
Files: `UI/TargetAssistFrame.lua`, `UI/CrosshairPresenter.lua`,
`Features/CursorRing.lua`

Status: compact identifier baseline complete offline; live visual certification pending

Acceptance focus:

- friendlies render role icon plus short name only by default;
- enemies render class icon plus short name only by default;
- confirmed flag/orb carrier art replaces the normal role/class icon and preserves color;
- health renders only on the current enemy target;
- cast progress renders only for an active visible priority cast;
- target name/health are not redundantly obscured by KWR panels;
- job, target match, and countdown are visible;
- background is transparent outside useful content;
- no non-player target treatment;
- no protected action or automatic targeting.

Offline evidence:

- identifier refresh cadence reduced from 8.3 Hz to 4 Hz;
- health APIs are queried only for the current enemy target;
- deterministic smoke fixtures cover role, class, carrier, UNKNOWN, target-health,
  active-cast, and expired-cast behavior;
- validate, smoke, and soak pass. Live bright/dark-scene and carrier screenshots remain.

### VIS-304 - Alerts and transient feedback

Priority: P2  
Provisional effort: 1 day  
Files: `UI/QuickCalls.lua`, HUD alert helpers, status feedback

Acceptance focus:

- urgent, caution, confirmed, and blocked states use fixed semantics;
- one alert owns the user's attention at a time;
- transient feedback clears safely;
- no continuous animation or layout churn.

## Phase 4 - Certification and Release Evidence

### VIS-400 - Automated layout diagnostics

Priority: P1  
Effort: 1-1.5 days  
Files: smoke fixtures, existing layout audits

Work:

- assert card and control bounds;
- assert unique option inventory and dependency state;
- assert text regions have explicit overflow contracts;
- assert hidden surfaces do not relayout or refresh unnecessarily.

Acceptance:

- deterministic fixtures cover supported layout modes;
- zero overlap/bounds failures;
- soak remains within existing performance budgets.

### VIS-401 - Screenshot matrix certification

Priority: P1 release gate  
Effort: 1-2 days field capture/review

Acceptance:

- every required matrix cell is captured or explicitly not applicable;
- no P0/P1 visual finding remains open;
- every surface meets its glance-time target;
- owner approves out-of-combat and combat comparison sets.

### VIS-402 - Marketing capture set

Priority: P2  
Effort: 0.5-1 day

Acceptance:

- one formation/setup image;
- one live objective command image;
- one local teamfight assignment image;
- one after-action review image;
- no debug, verification, unknown, clipped, or stale state in marketing captures;
- images clearly communicate KWR's product promise without explanatory captions.

## Required Validation Per Slice

Run the repository commands after every implementation slice:

```powershell
./tools/validate.ps1
./tools/knowledge-audit.ps1
fengari tests/smoke.lua
fengari tests/soak.lua
./tools/build.ps1
```

Also run the visual matrix checks specified in `VISUAL_VALIDATION_PROTOCOL.md`.
