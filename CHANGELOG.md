# Changelog

## 6.1.0-alpha.15

- Replaced abbreviated mover counts with complete spoken command rosters.
  Scout HUD objective calls now list every named mover and any named defenders
  by compact objective, without `+3` or other numeric shorthand.
- Enlarged the Scout HUD command area and separated the full call, personal
  assignment, mover roster, timing, confidence, and kill target into readable
  sections suitable for voice leadership.
- Made qualified execution responses bypass the short command-stability hold
  so an evidence-supported emergency pivot is displayed immediately.
- Added four bounded post-zone transition truth confirmations and three
  bounded group-roster confirmations. These are finite event responses and do
  not add a polling loop or permanent ticker.
- Added `UNIT_NAME_UPDATE` and `PLAYER_ROLES_ASSIGNED` refreshes so raid names,
  roles, health bindings, and secure roster rows converge after loading.
- Cross-checked raid unit identities against Blizzard's raid-roster records,
  suppressed duplicate identities, and withheld unstable unit bindings until
  the corresponding unit token resolves.
- Expanded deterministic diagnostics to 243 checks and added regression
  coverage for complete spoken commands and bounded transition settling.

## 6.1.0-alpha.14

- Replaced the lossy refresh flag with one bounded, preemptible dirty-state
  scheduler. Simultaneous score, roster, and transition events now produce one
  primary refresh plus at most one newest-truth follow-up.
- Added guaranteed settling refreshes after login, world/zone transitions,
  group roster changes, score-table changes, match activation, and public
  widget updates without adding another ticker.
- Made each map's reviewed score widget authoritative. Dynamically discovered
  widgets are validated fallbacks and cannot silently displace the configured
  source; within-match score regressions are rejected.
- Added widget authority, score-change age, regression state, queue
  coalescing, follow-up, preemption, and settle telemetry to `/kwr verify` and
  `/kwr perf`.
- Replaced duplicate `Team Engagement` location text with source-aware
  descriptions such as `ENGAGED WITH STRIKE -> LM`. Direct positions remain
  authoritative; assignment-derived destinations remain explicitly inferred.
- Kept enemy identities and safely numeric last-observed health visible after
  live tokens disappear, and retained the last local target spotlight for five
  clearly labeled seconds.
- Unified compact assignment terminology across Team, HUD, combat roster, and
  command copy surfaces.
- Corrected the Team table's eight-pixel header/row offset and widened its
  assignment column.
- Replaced the fixed 46-pixel square minimap launcher with a 32-pixel circular
  launcher positioned from the current minimap radius.
- Expanded deterministic diagnostics from 240 to 242 checks, added scheduler,
  score-authority, launcher, and table-alignment regression assertions, and
  retained the 500-refresh bounded-state soak.

## 6.1.0-alpha.13

- Added one normalized battlefield truth contract with source, observation
  time, expiration, confidence, verification state, and conservative gating.
- Added static map-route ETA fallback when exact legal coordinates are not
  available; observed movement remains higher confidence.
- Upgraded every assignment into a monitored contract with issue time,
  expected arrival, evidence source, success condition, abort condition,
  completion state, and value-aware replacement.
- Added an objective coverage ledger that identifies uncovered and
  overcommitted friendly objectives without stripping the sole defender from
  another node.
- Reworked the existing five candidate actions into objective-aware heuristic
  scores with named targets, opportunity cost, reversibility, evidence,
  success, and abort semantics. Scores are explicitly not statistical win
  probabilities.
- Added map-specific reviewed enemy counter and response doctrine to all ten
  supported battleground scenario families.
- Added immediate (5 second), engagement (15 second), and strategic (30 second)
  decision horizons to the existing execution assessment.
- Expanded `/kwr explain`, Commander, Verification, and AAR evidence without
  adding combat HUD lines or a parallel decision engine.
- Expanded deterministic diagnostics from 232 to 240 checks and retained the
  500-refresh bounded-state soak.

## 6.1.0-alpha.12

- Added one complete response package derived from the existing execution
  assessment: action, target, movers, stayers, success, abort, confidence, and
  evidence score.
- Allowed only high-confidence, score-85+ execution responses to arbitrate the
  existing Commander action. No parallel command owner was introduced.
- Made manual reassessment publish a compact changed-assignment summary and
  identify the affected players directly in the command.
- Added response-package agreement across Tactical, Assignments, `/kwr
  explain`, `/kwr verify`, and structured AAR export.
- Propagated reviewed enemy-composition counter directives to relevant
  individual assignments.
- Strengthened assignment audits with roster-identity, priority-range, and
  flag-carrier role validation.
- Added a one-second dirty-state cache for execution assessment and exposed its
  telemetry in `/kwr perf`.
- Throttled carrier-aura scans and added objective truth-quality provenance.
- Expanded deterministic diagnostics from 226 to 232 checks and retained the
  500-refresh bounded-state soak.

## 6.1.0-alpha.11

- Added an optional, always-precreated current-target spotlight to the existing
  compact combat roster. It displays direct target health without storing or
  comparing secret health values.
- Added a small reviewed priority-cast catalog and event-fed `STOP` accents for
  selected must-stop and advantage-swing casts. KWR never claims a cast is
  interruptible and never interrupts automatically.
- Added explicit advisory responses for observed immunity, absorb, and major
  defensive windows. Verified swap-class protection removes that enemy from
  automated kill-candidate ranking but never changes the player's target.
- Added priority-cast and defensive accents to existing enemy rows.
- Extended the optional Cursor Ring with one evidence-driven color state:
  danger, caution, rotation, recovery, uncertainty, or neutral.
- Added an Options toggle for target/cast combat visuals.
- Added priority-cast evidence to live verification and compact AAR state.
- Expanded deterministic diagnostics from 222 to 226 checks and retained the
  500-refresh bounded-state soak.

## 6.1.0-alpha.10

- Added one bounded execution-assessment layer inside the existing Strategist;
  no parallel command brain, timer, or combat window was introduced.
- Added objective commitment, reinforcement advantage, pressure forecast,
  rotation economy, fight-collapse, recovery-window, and organization-entropy
  assessments using already-sanitized Reporter, assignment, resource, and
  confidence evidence.
- Added one ranked action opportunity for explanation and review. It does not
  replace the live three-line command HUD or perform actions automatically.
- Expanded `/kwr explain`, `/kwr verify`, and manual AAR export with the
  assessment evidence so field decisions can be audited.
- Added seven deterministic assessment checks, bringing the suite to 222, and
  retained the 500-refresh bounded-state soak.
- Preserved Alpha 9 as the rollback baseline. Target spotlight, cast accents,
  Combat Clarity controls, and visual rings remain gated for live testing.

## 6.1.0-alpha.9

- Added a bounded manual match-evidence exporter to the existing AAR journal.
- Captures sanitized match metadata, friendly/enemy composition, KWR commands,
  objective transitions, assignment integrity, player locations, safely
  exposed scoreboard statistics, and factual enemy sightings.
- Added `/kwr aar`, `/kwr aar copy`, and `/kwr aar clear`.
- Added `COPY EXPORT` to the existing Command Center Intel/AAR page and the
  existing post-match review surface; both reuse KWR's manual copy dialog.
- Added an option to disable AAR evidence recording.
- Kept unknown information unknown and separated recommendations, supporting
  evidence, observed execution, and known outcomes in the export.
- Added safe optional scoreboard fields that are discarded when Retail marks
  them secret.
- Expanded deterministic diagnostics from 210 to 215 checks and retained the
  500-refresh bounded-state soak.

## 6.1.0-alpha.8

- Added a multi-source confidence budget with evidence, bounded risk, and
  conservative low-confidence behavior.
- Added friendly/enemy objective ETA estimates, enemy-intent prediction,
  battlefield momentum, and match-only rotation memory to Reporter.
- Added short-lived opportunity windows and honest resource-economy estimates
  from permitted observed evidence.
- Added lightweight HOLD, ROTATE, TRADE, TEAMFIGHT, and SPLIT outcome
  simulation without machine learning or a parallel decision engine.
- Added continuous assignment-integrity verification with abandoned,
  impossible, moving, and on-station states plus replacement recommendations.
- Expanded `/kwrwhy` with confidence evidence, candidate outcomes, ETA,
  intent, momentum, opportunity, resources, success/abort criteria, and
  assignment integrity while preserving the three-line combat HUD.
- Added developer-only counterfactual decision review records to AAR; they do
  not automatically modify live strategy.
- Added dirty-state decision caching and performance telemetry.
- Expanded deterministic diagnostics from 199 to 210 checks.

## 6.1.0-alpha.7

- Expanded all fourteen weighted capability categories to at least three
  semantic signals and three documented battlefield effects.
- Added map-family and strategic-state capability profiles so plan selection
  considers objective fit, team readiness, and enemy matchup instead of tags
  alone.
- Added at least three rating inputs to every assignment job family while
  preserving hard role compatibility and the proven semantic-tag model.
- Added explicit objective verb/target, success condition, abort condition,
  weighted focus, and three-step archetype counter sequences.
- Preserved current and last-seen enemy location, observation source, age, and
  coordinate confidence across Enemy Tracker, compact roster, HUD, Reporter,
  tactical map, and verification output.
- Retained coordinate-free observations as intelligence without fabricating
  map dots.
- Added immutable capability caching, reused Formation summaries, skipped
  unchanged HUD/roster rendering, and prevented ordinary friendly health/aura
  events from rebuilding the full strategy pipeline.
- Expanded `/kwr perf` with cache, render-skip, and lightweight-event telemetry.
- Updated the official patch review through Blizzard's 2026-06-22 hotfixes.
- Expanded deterministic diagnostics from 183 to 199 checks and passed the
  500-refresh bounded-state soak.

## 6.1.0-alpha.6

- Integrated a bounded fourteen-rating capability model and nine battlefield
  job preferences into the existing specialization repository.
- Added advisory Hero talent modifiers that refine copied capability results
  without mutating base specialization truth.
- Added centralized Retail 12.0.7 PvP tuning overlays reviewed against official
  Blizzard hotfix notes through 2026-06-17.
- Reclassified Smoke Bomb and added a small reviewed battlefield-ability
  catalog so observed kill, displacement, and capture-denial windows inform
  existing combat intelligence without a new scanner or event loop.
- Refined the existing assignment weights with capped capability preferences;
  role validation and the proven tag model remain authoritative.
- Added explicit confirmed, likely, estimated, and unknown capability coverage.
- Expanded deterministic diagnostics from 176 to 183 checks and passed the
  500-refresh bounded-state soak.

## 6.1.0-alpha.5

- Added the reviewed twenty-composition tier library supplied in the Midnight
  Commander handoff, including roster, tier, map fit, win condition, role
  package, and counterplan.
- Added multiset specialization matching for exact and likely full-roster
  composition detection; incomplete evidence remains labeled partial.
- Integrated qualified friendly composition matches into formation doctrine
  and map-plan scoring.
- Integrated qualified enemy composition matches into reviewed counterplay
  while preserving generic archetype fallback when enemy specs are incomplete.
- Added optional automatic compact combat-roster preparation on battleground
  entry without reopening it after the player manually closes it.
- Expanded deterministic diagnostics from 172 to 176 checks.

## 6.1.0-alpha.4

- Added `/kwr bug`, a single local field-defect bundle containing current
  authoritative truth, assignments, command reasoning, performance, source
  freshness, team/enemy live-unit coverage, the latest AAR state, and the
  bounded match evidence ledger.
- Added explicit friendly/enemy specialization, live-unit, and locally engaged
  coverage counts to `/kwr verify`.
- Expanded deterministic diagnostics from 171 to 172 checks.

## 6.1.0-alpha.3

- Fixed protected Team/Enemy health rendering so client-provided secret text is
  written directly to UI widgets and never read back or compared.
- Removed the retired `UNIT_HEALTH_FREQUENT` registration that blocked
  MatchRuntime startup on Retail 12.0.7.
- Added map-native objective abbreviations and grouped one-line assignment
  exports suitable for practical chat handoff.
- Added build-time guards against secret-backed health-text reads and removed
  Retail event registrations.
- Established Alpha 3 as the distinct field-testing baseline with 171
  deterministic checks and the 500-refresh bounded-state soak.

## 6.1.0-alpha.2

- Bound scoreboard enemy identities to safely observed live unit tokens using
  GUID, name, class, race, sex, and honor evidence without comparing secret values.
- Added direct Blizzard unit-token health rendering for compact and expanded
  Team/Enemy bars and event-driven health refreshes.
- Pre-bound enemy rows to player-click target/focus macros before combat and
  restricted automatic kill recommendations to visible local combatants.
- Corrected node recovery assignments so strike teams attack the missing or
  enemy-controlled objective while named defenders hold existing bases.
- Made manual reassessment publish a visible ten-second result, assignment
  changes, an explicit TAKE/HOLD command, and a local confirmation message.
- Deferred protected expanded/compact visibility changes until combat ends.
- Captured match-complete state so time-limit victories and defeats resolve
  correctly from the final assigned-team score.
- Added `/kwr field` to arm the complete formation-to-AAR test workflow.
- Expanded deterministic diagnostics from 167 to 169 checks.

## 6.1.0-alpha.1

- Added a 400-state scenario matrix: forty deterministic situations for each supported battleground.
- Added explicit opening, stabilization, pressure, recovery, and endgame phases.
- Added manual `REASSESS` command with assignment-change publication.
- Added GUID-based assignment identity and strict role compatibility; non-healers can no longer inherit healer jobs.
- Added bounded current-season encounter history with clearly labeled historical specialization evidence.
- Added safe pre-match group inspection sequencing to verify friendly specializations when inspect data is available.
- Added colored orb and flag-carrier event state, carrier promotion, observable aura stacks, and node assault timers.
- Added carrier-aware map markers, combat-roster state, assignment overrides, and flag-stack strategy.
- Added direct friendly health-bar rendering when numerical health is protected but a safe unit token exists.
- Expanded deterministic diagnostics from 149 to 167 checks.

## 6.0.0-beta.13

- Added reviewed opening doctrines and valid opening assignments for all ten supported battlegrounds.
- Added weighted defense, spin, team-fight, assault, carry, healing, and rotation valuation.
- Added explicit EOTS two-tower sitters, four-player mid control, and four-player tower strike.
- Added AB spinner/defender handoffs, mobile defense floaters, and a six-player minimum decisive-fight core.
- Added safe scoreboard refreshes, event-fed enemy unit observation, observed hostile cooldowns, and live direct health bars.
- Added public POI/vignette/fallback map positions, combat movement pressure, and stronger Reporter coverage.
- Added map art fallbacks, assignment counterplay context, and 149 deterministic diagnostics.
- Reduced enemy polling from all possible raid/nameplate targets to active event-fed unit tokens.

## 6.0.0-beta.12

- Routed the Tactical COPY control and `/kwr copy` through the compact
  single-line dialog while preserving the large dialog for multiline reports.
- Clamped copy, AAR, and Options dialogs to the visible screen.
- Added lead, deficit, tie, assignment-family, location-validity, and
  map-specific node-priority fixtures across all ten supported battlegrounds.
- Added reusable assignment audits for complete coverage, one job per player,
  valid map locations, and prevention of Formation leakage into active PvP.
- Added five-second freshness gates for authoritative score and objective
  evidence so stale values cannot drive a live recommendation.
- Expanded `/kwr verify` with map ID, assigned score faction, source ages,
  command age/TTL, complete assignments, Reporter coverage, and transition
  performance.
- Restricted Quick Calls to an exact six-phrase allowlist and added secure,
  combat-fallback, and rejected-call regression assertions.
- Added explicit impossible-recovery handling instead of recommending an
  objective count that cannot beat the enemy scoring clock.
- Corrected Arathi Basin and Deepwind Gorge standard and Blitz resource rates,
  and replaced the retired Eye of the Storm Blitz scoring model with Midnight's
  restored standard four-base model.
- Expanded deterministic diagnostics from 96 to 138 checks.

## 6.0.0-beta.11

- Replaced the six-step Quick Call copy workflow with fixed secure Instance
  Chat buttons activated by one explicit player click.
- Added immediate CALL ACTIVATED / NOT SENT status feedback and right-click compact-copy
  fallback behavior.
- Kept multiline reports in the full export dialog while giving one-line
  fallbacks a correctly sized single-line field.
- Centralized reviewed communication actions in `UI/QuickCalls.lua`, assigned
  attributes only outside combat, and added deterministic secure-action checks.
- Retained 96 deterministic diagnostics and added secure Quick Call smoke
  assertions.

## 6.0.0-beta.10

- Replaced proportional-font, space-padded headers with anchored columns on
  Objectives, Enemy Intelligence, Assignments, and Match History.
- Preserved specialization and effective role in every assignment record and
  changed the assignment identity column to `Spec Class / Role`.
- Replaced raw numeric assignment priority with PRIMARY, HIGH, SUPPORT, and
  FORMING decision labels.
- Replaced non-actionable Team map coordinates with battlefield assignment
  locations.
- Replaced primary-view widget IDs and source strings with VERIFIED, MAP ONLY,
  or UNKNOWN confidence; raw evidence remains available through `/kwr verify`.
- Added a command-experience doctrine defining always-visible, changed-only,
  and on-demand information for every surface.
- Expanded offline diagnostics to 96 checks.

## 6.0.0-beta.9

- Resolved the player character's specialization and combat role directly from
  the player specialization API instead of depending on inspection.
- Added specialization source metadata while retaining session-cached specs
  for teammates.
- Coordinated expanded and compact workflows: opening the War Room temporarily
  suppresses HUD, combat roster, and Reporter surfaces and restores them on close.
- Routed minimize controls through one surface coordinator so compact windows
  do not open through the expanded dashboard.
- Established explicit frame hierarchy: compact `HIGH`, expanded `FULLSCREEN`,
  and modal editors/reports `FULLSCREEN_DIALOG`.
- Added top-level raise behavior and removed pre-hide calls that prevented
  compact-surface restoration after expansion.
- Expanded offline diagnostics to 95 checks and added expanded/compact
  coordination assertions to the smoke suite.

## 6.0.0-beta.8

- Removed the complete six-page dashboard, tactical maps, compact roster,
  AAR, options, copy dialog, launcher menu, and other optional frames from
  synchronous addon-load initialization.
- Deferred the default HUD and first runtime refresh until the world has
  settled, while coalescing login and world-entry events.
- Stopped requesting group map positions outside PvP when formation mode
  cannot safely use them.
- Added per-module boot timing, world-transition refresh timing, and slowest
  initialization reporting to `/kwr perf`.
- Added a regression gate proving heavy optional UI stays off the
  addon-load critical path.
- Expanded offline diagnostics to 94 checks.

## 6.0.0-beta.7

- Rebuilt compact Team/Enemy rows as readable two-line health bars with
  specialization, role, health, assignment or observation state, and richer tooltips.
- Added persistent TEAM, ENEMY, and BOTH mode selection styling plus clear
  target, focus, local kill target, defensive, trinket, dead, offline, and
  critical-health presentation.
- Enlarged the compact roster while retaining combat-safe frozen secure bindings.
- Added tactical marker badges for friendly, enemy, healer, tank, dead, flag,
  incoming objective, priority objective, and local kill target states.
- Added live command, risk, track coverage, and objective-source overlays to
  both tactical and compact Reporter maps.
- Fixed map tiles and movement paths so they correctly re-layout after resizing.
- Preserved role and observed health context in Reporter tracks and expanded
  preview health coverage.
- Expanded offline diagnostics to 93 checks.

## 6.0.0-beta.6

- Added runtime performance telemetry, a four-refresh-per-second strategic cap,
  allocation-conscious event dispatch, compact AAR features, hidden-view
  suspension, secure-attribute diffing, and a 30 Hz cursor cap.
- Added 40 specialization capability profiles, seven composition archetypes,
  22 map battle plans, counter doctrine, patch overlays, and a knowledge manifest.
- Added contextual plan selection with requirements, alternatives, counterplay,
  switch conditions, stop rules, and explanations.
- Added bounded reviewed learning with patch isolation, Bayesian shrinkage, and
  minimum-sample safeguards.
- Added `/kwr explain`, `/kwr perf`, `/kwr mode`, and Learning-mode guidance.
- Added a pre-match Formation Advisor with 10-player role targets, archetype
  detection, meta/capability-aware recruit recommendations, leadership setup,
  ready checks, and positioning doctrine.
- Replaced the irrelevant city map in formation mode with a central Formation
  Briefing board; the Reporter map returns automatically in battlegrounds.
- Added source authority tiers for Blizzard, Battle.net, Murlok, PvP Basics,
  Wowhead, Warcraft Logs, KWR match evidence, and community signals.
- Added a developer knowledge-update workflow and automated knowledge audit.
- Replaced unsupported Unicode UI symbols with safe ASCII labels, switched to
  Blizzard's locale-safe standard font, and added a glyph validation gate.
- Registered runtime events once at initialization and gated inactive event
  handling, preventing protected event-subscription changes during PvP lifecycle
  transitions.
- Replaced native-faction score assumptions with roster-validated battlefield
  team assignment so cross-faction and mercenary matches normalize scores,
  objectives, enemies, strategy, and AAR results consistently.
- Retained safely observed teammate specializations across inspection changes.
- Added persistent selected styling and saved-value restoration to AAR choices.
- Removed Midnight-blocked combat-log registration and added a release gate
  preventing it from returning.
- Canonicalized live objective labels so POI positions inherit current widget
  ownership while restricted player coordinates remain explicitly unknown.
- Added map-specific prediction fixtures and a live evidence matrix for all ten
  supported battlegrounds.
- Added `/kwr verify` and `/kwr evidence` for reproducible live truth,
  decision, transition, and performance capture.
- Corrected faction-specific home-objective assignments and distinguished open
  formation slots from role replacements.
- Added legacy-database migration coverage and a 500-refresh bounded-state soak.
- Added an automated round-trip package structure, legacy-exclusion, extracted
  validation, knowledge, and SHA-256 audit.
- Added explicit Blitz detection with separate verified node rates, capture
  timing, EOTS tower rates, and flag values.
- Added incoming-objective clock simulation that detects captures which flip
  the projected result and changes the live call accordingly.
- Added score-delta tracking for WSG/Twin Peaks last-capture tiebreak logic.
- Added a hard decision gate preventing incomplete battlefield truth from
  becoming a live strategy call.
- Required qualified assigned-team and score evidence before an AAR can enter
  the learning model.
- Expanded offline diagnostics to 91 checks, including missing orb/cart
  telemetry truth handling.

## 6.0.0-beta.5

- Added the knowledge, contextual strategy, formation-advisor, performance,
  safe-glyph, and bounded-learning foundation used by Beta 6.
- Expanded the initial offline diagnostics to 69 checks.

## 6.0.0-beta.4

- Added one compact Team/Enemy combat roster with class-colored live health
  bars, tank/healer role symbols, and combined/team/enemy modes.
- Added combat-safe secure rows: left-click targets and right-click focuses;
  enemy name macros are prepared out of combat and never changed during combat.
- Added observed defensive and PvP-trinket tracking from the combat log.
- Added a local kill-target model that requires safe visibility and local-range
  evidence, then weighs role, available health, observed trinket/defensive use,
  manual priority, and a modest RBG-meta tie breaker.
- Corrected Retail 12.0.7 defensive cooldown baselines against the field-tested
  reference addons and removed unsupported racial-as-trinket assumptions.
- Added cross-faction scoreboard team detection from actual group-name matches.
- Added the dated Murlok RBG specialization snapshot and explicit provenance.
- Kept Team, Enemy, Reporter, and combat processing active while detailed pages
  are closed; detailed tables now render only when opened.
- Expanded deterministic diagnostics to 54 checks.

## 6.0.0-beta.3

- Reframed Reporter as the always-running battlefield movement-intelligence domain.
- Added friendly and safe enemy movement tracks with bounded path history.
- Added objective-pressure analysis, hotspot detection, movement risk, and call hints.
- Fed Reporter evidence into Predictor urgency/action and Commander reasoning.
- Added a clean minimized Reporter dot map that expands into the primary Tactical Command Board.
- Added movement paths and Reporter status to the expanded tactical map.
- Added Reporter events to the After Action Review timeline.
- Kept all Reporter processing independent of whether either Reporter view is visible.
- Expanded deterministic diagnostics and smoke coverage from 40 to 45 checks.

## 6.0.0-beta.2

- Restored the endgame commander-dashboard direction from the approved mockups.
- Replaced the four austere test pages with one integrated Tactical Command Board: Tactical Map, Objectives, Team, Enemies, Assignments, and Intel/AAR.
- Rebuilt the compact HUD as the live Scout command window.
- Added reusable Blizzard map-art rendering with objective, friendly, enemy, and flag overlays.
- Added a sanitized enemy-intelligence repository using scoreboard and visible-unit evidence.
- Added manual enemy priorities and persistent field notes.
- Added a persistent match journal, command/event timeline, learning summary, and After Action Review form.
- Added an explicitly labeled preview mode for reviewing the complete interface outside PvP.
- Kept the single Store, single runtime ticker, one command pipeline, and display-only safety boundary.
- Added Beta 1 database migration for the new navigation and HUD placement.
- Expanded deterministic diagnostics and smoke coverage from 31 to 40 checks.

## 6.0.0-beta.1

- Rebuilt KWR around one authoritative Store and one match lifecycle.
- Added map-specific predictors and deterministic assignments.
- Removed automatic communication, targeting, keybinding writes, and protected actions.
- Added validation, packaging, hashes, and release documentation.
