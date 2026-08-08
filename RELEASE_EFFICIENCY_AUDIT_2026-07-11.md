# KWR Release Efficiency Audit

Date: 2026-07-11  
Scope: repo-wide field-release efficiency audit focused on purpose clarity, runtime cost, persistence cost, duplication, and release cleanliness.

## Audit Standard

Target release quality:
- one owner per concern
- no debug/developer payloads in the field build
- bounded persistence with explicit retention value
- minimal copy/churn between runtime, command, review, and UI
- thin presentation surfaces over stable runtime DTOs

Scoring:
- `9-10`: release-clean and efficient
- `7-8.9`: keep with targeted cleanup
- `5-6.9`: rewrite in place
- `<5`: remove from field build or split out

Decision labels:
- `KEEP`: subsystem is worth keeping as a core part of the product
- `REWRITE`: subsystem purpose is valid but implementation is too mixed/heavy
- `REMOVE`: do not ship in the field-release build as-is

## Executive Findings

### 1. Diagnostics is shipping inside the addon and should not be in the field build
Evidence:
- [KnomercyWarRoom.toc](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/KnomercyWarRoom.toc:57) includes [Core/Diagnostics.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Core/Diagnostics.lua:1)
- [Core/Diagnostics.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Core/Diagnostics.lua:1) is `1781` lines and carries extensive fixture, audit, and validation logic
- release packaging is now driven by [tools/release-manifest.ps1](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/tools/release-manifest.ps1:1), and both [tools/build.ps1](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/tools/build.ps1:1) and [tools/package-audit.ps1](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/tools/package-audit.ps1:1) consume the same exclusion list for `Core/Diagnostics.lua` and `Runtime/Preview.lua`
- progress 2026-07-12: the default live [KnomercyWarRoom.toc](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/KnomercyWarRoom.toc:1) no longer loads `Core/Diagnostics.lua` or `Runtime/Preview.lua`, and [tools/validate.ps1](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/tools/validate.ps1:1) now respects the same release exclusion manifest

Impact:
- unnecessary static memory in the field build
- increased maintenance surface
- release package is not cleanly separated from developer tooling

Decision:
- `REMOVE` from field-release package

### 2. The core runtime duplicates data across too many layers
Primary duplication path:
- [Core/Store.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Core/Store.lua:13) holds full live snapshot state
- [Runtime/Commander.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/Commander.lua:260) copies strategy, truth, knowledge, opportunity, trust, execution, response, integrity, and reassessment into `command`
- [Runtime/AAR.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/AAR.lua:345) copies command payloads again into review history
- progress 2026-07-12: shared compact review serialization now lives in [Core/CommandReview.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Core/CommandReview.lua:1); the live `command.reviewRecord` duplicate payload has been removed and AAR review capture now derives from the shared helper instead
- progress 2026-07-12: command presentation text now lives in [Core/CommandView.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Core/CommandView.lua:1); the live command DTO no longer stores pre-rendered `line1`, `line2`, `line3`, `spokenCall`, or call-routing strings

Impact:
- copy churn during live play
- harder reasoning about source-of-truth ownership
- “patchy” architecture where each downstream layer defensively snapshots large tables

Decision:
- `REWRITE` command/review DTO flow

### 3. MainWindow and CombatRoster are oversized mixed-responsibility UI owners
Evidence:
- [UI/MainWindow.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/MainWindow.lua:1) is now `1462` lines after page-render, report/export, shell, launcher, and slash extraction
- [UI/MainWindowPages.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/MainWindowPages.lua:1) owns the tactical, objectives, team, enemies, assignments, and intel page render bodies
- [UI/MainWindowReports.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/MainWindowReports.lua:1) now owns decision/setup/performance export text builders
- [UI/MainWindowShell.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/MainWindowShell.lua:1) now owns header refresh, compact-surface suppression/restore, launcher visuals, and launcher-menu summary helpers
- [UI/MainWindowLauncher.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/MainWindowLauncher.lua:1) now owns launcher button construction and launcher-menu construction/toggling
- [UI/MainWindowCommands.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/MainWindowCommands.lua:1) now owns slash-command registration and routing
- [UI/CombatRoster.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/CombatRoster.lua:1) is now `787` lines after visual/state extraction
- [UI/CombatRosterVisuals.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/CombatRosterVisuals.lua:1) now owns spotlight, row-visual, roster-normalization, and binding rendering helpers
- [UI/CombatRosterState.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/CombatRosterState.lua:1) now owns state-driven update and layout orchestration

Impact:
- layout, formatting, interaction, and data interpretation are mixed together
- visual changes are expensive
- runtime/UI coupling makes optimization harder

Decision:
- `REWRITE` into smaller surface modules with shared view-model helpers

### 4. Persistence is now bounded, but the boundaries are implementation-driven rather than design-driven
Evidence:
- AAR, encounter history, opponent models, learning, enemy notes now all have caps
- those caps live in multiple subsystems and reflect memory control more than product doctrine
- progress 2026-07-12: additional live caps for commander history, objective events, and runtime duration samples now route through [Runtime/MemoryBudget.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/MemoryBudget.lua:1) instead of living only as isolated constants
- progress 2026-07-12: cap application is now centralized through [Runtime/MemoryBudget.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/MemoryBudget.lua:1) `ApplyCaps`, reducing one-off retention wiring across AAR, EncounterHistory, OpponentModels, EnemyIntel, Learning, Reporter, ObjectiveIntel, Commander, MatchRuntime, and Verification
- progress 2026-07-12: [Runtime/MemoryBudget.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/MemoryBudget.lua:1) now owns an explicit named retention contract with priorities, purposes, cap bindings, prune order, and contract reporting for persistent and live memory domains

Impact:
- safer than before, but still fragmented
- release behavior depends on many local pruning rules instead of one data-retention policy

Decision:
- `REWRITE` persistence policy into one explicit retention layer

### 5. Static data is large, but that is mostly acceptable product weight
Evidence:
- `Data/` contains the doctrine/meta/catalog layer
- biggest files include [Data/BattlePlans.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Data/BattlePlans.lua:1) `1032` lines and multiple `300+` line reviewed tables

Impact:
- static memory footprint is real
- but this is mostly intentional product intelligence, not accidental waste

Decision:
- `KEEP`, normalize only after runtime/data-flow cleanup

## Scorecard

| Subsystem | Primary Files | Score | Decision | Why | Required Action |
|---|---|---:|---|---|---|
| Bootstrap, DB defaults, module lifecycle | [Core/Addon.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Core/Addon.lua:1), [Core/Store.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Core/Store.lua:1), [Core/Util.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Core/Util.lua:1), [tools/validate.ps1](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/tools/validate.ps1:1) | 8.3 | KEEP | default live loadout is release-clean, validator/build/audit share one exclusion contract, and retention ownership is now centralized instead of scattered | keep; later reduce snapshot breadth and add typed view-model helpers |
| Diagnostics / dev harness | [Core/Diagnostics.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Core/Diagnostics.lua:1), [KnomercyWarRoom.toc](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/KnomercyWarRoom.toc:57) | 2.5 | REMOVE | field build carries dev-only fixture and audit code | split into dev-only TOC/build target |
| Static doctrine/data catalogs | `Data/*.lua` especially [Data/BattlePlans.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Data/BattlePlans.lua:1), [Data/Capabilities.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Data/Capabilities.lua:1), [Data/Compositions.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Data/Compositions.lua:1) | 7.4 | KEEP | large but intentional; this is the addon brain, not accidental runtime bloat | keep; later normalize repeated fields and compress repeated text patterns |
| Match runtime orchestrator | [Runtime/MatchRuntime.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/MatchRuntime.lua:1) | 7.0 | KEEP | single runtime owner is correct; queue/coalescing direction is strong | keep; later simplify transition sweeps and post-match fallback copies |
| Sensor ingestion / truth acquisition | [Runtime/Sensors.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/Sensors.lua:1), [Runtime/TeamResolver.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/TeamResolver.lua:1), [Runtime/RosterInspector.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/RosterInspector.lua:1), [Runtime/ObjectiveIntel.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/ObjectiveIntel.lua:1) | 7.3 | KEEP | correct core mission; bounded event/aura state; good legal-data discipline | keep; later tighten objective event DTOs and remove redundant row decoration work |
| Enemy observation and local combat intel | [Runtime/EnemyIntel.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/EnemyIntel.lua:1), [Runtime/CombatIntel.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/CombatIntel.lua:1) | 6.2 | REWRITE | strong feature value, but identity resolution, note persistence, location semantics, and local-target scoring are packed together | separate identity store, local observation layer, and combat scoring DTOs |
| Reporter / movement engine | [Runtime/Reporter.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/Reporter.lua:1) | 6.5 | REWRITE | valuable subsystem, but track memory, event generation, hotspot logic, and summary text are too fused | split movement model, event ledger, and surface summary formatter |
| Predictor | [Runtime/Predictor.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/Predictor.lua:1) | 7.6 | KEEP | focused purpose, moderate size, good candidate for stable DTO output | keep; later make prediction output thinner and more explicit |
| Strategist | [Runtime/Strategist.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/Strategist.lua:1) | 6.4 | REWRITE | central and valuable, but too many responsibilities: focus weighting, doctrine selection, confidence, execution assessment, and simulation payload building | split into doctrine selector, scoring engine, execution assessor, and export summarizer |
| Assignments and override engine | [Runtime/Assignments.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/Assignments.lua:1), [Runtime/AssignmentOverrides.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/AssignmentOverrides.lua:1) | 7.1 | KEEP | high gameplay value and mostly correct place in architecture | keep; later split integrity audit from assignment generation |
| Commander output builder | [Runtime/Commander.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/Commander.lua:1), [Core/CommandReview.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Core/CommandReview.lua:1), [Core/CommandView.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Core/CommandView.lua:1) | 7.5 | REWRITE | compact review serialization is shared and presentation lines are no longer stored on the live command DTO, but the runtime command still carries more report/export fields than an ideal thin contract | continue toward a thinner command DTO plus separate review/export payload builder |
| Persistence and learning | [Runtime/AAR.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/AAR.lua:1), [Runtime/EncounterHistory.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/EncounterHistory.lua:1), [Runtime/OpponentModels.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/OpponentModels.lua:1), [Runtime/Learning.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/Learning.lua:1), [Runtime/MemoryBudget.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/MemoryBudget.lua:1), [Core/CommandReview.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Core/CommandReview.lua:1) | 7.8 | KEEP | persistence still uses bounded caps, but those caps and prune order now live behind one explicit retention contract with named priorities and one owner | keep; next improvement is doctrine-level tuning of the contract instead of structural cleanup |
| Verification and field export | [Runtime/Verification.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/Verification.lua:1), [Runtime/SentinelBridge.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/SentinelBridge.lua:1) | 6.3 | REWRITE | useful, but mixes operator verification, debug evidence, and player-facing bridge output | separate operator verification from field relay output |
| Preview / non-live demo path | [Runtime/Preview.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/Preview.lua:1), [UI/Options.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/Options.lua:265), [UI/MainWindow.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/MainWindow.lua:2666) | 4.7 | REMOVE | useful for development and mockups, not a field-release necessity | move to dev build or explicit designer mode package only |
| Main tactical board | [UI/MainWindow.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/MainWindow.lua:1), [UI/MainWindowPages.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/MainWindowPages.lua:1), [UI/MainWindowReports.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/MainWindowReports.lua:1), [UI/MainWindowShell.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/MainWindowShell.lua:1), [UI/MainWindowLauncher.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/MainWindowLauncher.lua:1), [UI/MainWindowCommands.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/MainWindowCommands.lua:1) | 7.8 | REWRITE | page rendering, export builders, shell state, launcher/menu construction, and slash routing are now split out, but page construction and a few high-level toggles still live in the board owner | finish page-construction extraction or stop here and shift the next rewrite pass to CombatRoster |
| Combat roster | [UI/CombatRoster.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/CombatRoster.lua:1), [UI/CombatRosterVisuals.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/CombatRosterVisuals.lua:1), [UI/CombatRosterState.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/CombatRosterState.lua:1) | 7.1 | REWRITE | spotlight rendering, row visuals, normalization, and layout/update ownership are now extracted, but frame construction and lifecycle still live in the root owner | finish pane/frame construction split only if it materially improves maintainability |
| Compact HUD | [UI/HUD.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/HUD.lua:1) | 7.8 | KEEP | compact, purposeful, and increasingly clean after visibility/terminology pass | keep; later consume a thinner command DTO |
| Tactical map / reporter map | [UI/TacticalMap.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/TacticalMap.lua:1), [UI/ReporterMap.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/ReporterMap.lua:1) | 7.2 | KEEP | good mission fit, bounded surface size, clear user value | keep; later push more text formatting out of the surface modules |
| AAR window | [UI/AARWindow.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/AARWindow.lua:1) | 6.7 | KEEP | good feature, but depends on oversized persisted entry shape | keep after AAR schema rewrite |
| Options and presentation control | [UI/Options.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/Options.lua:1), [UI/Presentation.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/Presentation.lua:1) | 6.0 | REWRITE | functional, but still contains legacy explanation burden and build-mode behavior that should not exist in field release | reduce to live functional settings only; remove dev-only controls |
| Quick calls / copy dialog / theme | [UI/QuickCalls.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/QuickCalls.lua:1), [UI/CopyDialog.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/CopyDialog.lua:1), [UI/Theme.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/Theme.lua:1) | 7.5 | KEEP | relatively clean utility/surface support layer | keep; later ensure theme primitives are never mistaken for interactive controls |
| Cursor ring / reticle overlay | [Features/CursorRing.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Features/CursorRing.lua:1) | 7.0 | KEEP | self-contained optional feature with clear battleground-only utility | keep; later split visual layer from battleground target-state logic |

## Concrete Remove / Rewrite / Keep Program

### Remove From Field Build
1. `Core/Diagnostics.lua`
2. `Runtime/Preview.lua`
3. preview toggles and dev-preview messaging from release options

### Rewrite First
1. Command payload pipeline
   - goal: `Store snapshot -> thin command DTO -> thin UI DTO -> optional review payload`
   - remove the current multi-copy chain across [Runtime/Commander.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/Commander.lua:260) and [Runtime/AAR.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/AAR.lua:345)
   - progress 2026-07-12: shared review serialization moved into [Core/CommandReview.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Core/CommandReview.lua:1) and redundant `command.reviewRecord` storage was removed from the live command payload
   - progress 2026-07-12: command presentation lines and spoken-call text now derive from [Core/CommandView.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Core/CommandView.lua:1) instead of living inside the runtime command DTO
2. MainWindow decomposition
   - split into page modules:
   - tactical page
   - objectives page
   - team page
   - enemies page
   - assignments page
   - intel/aar page
   - separate launcher/menu shell from board pages
   - progress 2026-07-12: all six page render bodies live in [UI/MainWindowPages.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/MainWindowPages.lua:1), export/performance builders live in [UI/MainWindowReports.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/MainWindowReports.lua:1), header/compact-surface helpers live in [UI/MainWindowShell.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/MainWindowShell.lua:1), launcher/menu construction lives in [UI/MainWindowLauncher.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/MainWindowLauncher.lua:1), and slash routing lives in [UI/MainWindowCommands.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/MainWindowCommands.lua:1); remaining work is page-construction extraction only if worth the extra complexity
3. Persistence policy
   - one retention contract for:
   - AAR history
   - encounter history
   - opponent profiles
   - processed matches
   - enemy notes
   - learning buckets
   - progress 2026-07-12: implemented in [Runtime/MemoryBudget.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/MemoryBudget.lua:1) as named persistent/live contracts with priorities, purposes, cap bindings, shared module binding, prune order, and contract reporting
4. Enemy/Reporter model boundaries
   - move identity resolution, observation capture, and surface copy text into separate layers

### Keep And Harden
1. MatchRuntime as single runtime owner
2. Predictor as separate state projection stage
3. Assignments as dedicated plan-to-player translation stage
4. HUD as primary compact field surface
5. Tactical/Reporter map surfaces as commander-first information displays

## Priority Backlog

### P0
1. Remove diagnostics from release TOC/build.
   - progress 2026-07-12: release exclusions are centralized in [tools/release-manifest.ps1](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/tools/release-manifest.ps1:1) and enforced by both build and package audit
   - progress 2026-07-12: the default live [KnomercyWarRoom.toc](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/KnomercyWarRoom.toc:1) no longer loads diagnostics
2. Move preview out of release build or hard-disable it in field package.
   - progress 2026-07-12: release exclusions are centralized in [tools/release-manifest.ps1](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/tools/release-manifest.ps1:1) and enforced by both build and package audit
   - progress 2026-07-12: the default live [KnomercyWarRoom.toc](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/KnomercyWarRoom.toc:1) no longer loads preview
3. Replace fat command object with thin release DTO.

### P1
1. Split MainWindow into page modules.
2. Split CombatRoster into pane manager, row renderer, spotlight renderer.
3. Redesign AAR entry schema around compact review records instead of copied runtime payloads.

### P2
1. Normalize static data tables for repeated shape/text compression.
2. Add explicit release build flags for dev-only surfaces and commands.
3. Add an in-game memory/retention report for field verification.

## If This Were My Release Build

I would not ship the final field-release package until these are true:
- diagnostics and preview are out of the shipped TOC
- command/review payload duplication is redesigned, not just trimmed
- MainWindow is split into smaller page owners
- persistence has one documented retention policy
- every user-facing surface consumes deliberate release DTOs instead of mining runtime internals directly

## Recommended Execution Order

1. Create `dev` vs `release` package boundary.
2. Redesign command DTO and AAR review DTO.
3. Decompose MainWindow.
   - progress 2026-07-12: page rendering, report/export text, and shell-helper extraction completed and validated through `validate`, smoke, soak, and package audit
4. Decompose CombatRoster.
   - progress 2026-07-12: visual/state extraction completed and validated through `validate`, smoke, soak, and package audit; [UI/CombatRoster.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/CombatRoster.lua:1) is reduced to `787` lines with [UI/CombatRosterVisuals.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/CombatRosterVisuals.lua:1) and [UI/CombatRosterState.lua](/D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/CombatRosterState.lua:1)
5. Simplify enemy/reporter observation models.
6. Re-run memory/CPU/live readability audit after each stage.
