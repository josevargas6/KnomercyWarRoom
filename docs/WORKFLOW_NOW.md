# KWR Workflow Now

Date: 2026-07-29
Evidence baseline: `6.1.0-alpha.29`; current package: `6.1.0-alpha.30`

Release scope, component ownership, and repository recovery order are defined
by `../RELEASE_VISION.md`. The post-recovery expert-tier execution path is
defined by `../EXPERT_TIER_BATTLEFIELD_MASTER_PLAN.md`. This file is the
immediate Commander work log.

## Purpose

This is the current execution baseline after the audit-remediation pass.

Use it to answer:

- what is stable right now;
- what was just repaired;
- what is still open;
- what should happen next without drifting.

## 2026-07-29 expert-tier planning checkpoint

`KWR-036` establishes
`../EXPERT_TIER_BATTLEFIELD_MASTER_PLAN.md` as the forward guide from the
recovered alpha to an expert-tier battlefield release.

The plan does not promote the current candidate or bypass its field defects.
The order remains:

1. recover and review the exact alpha source;
2. close and live-reverify `KWR-032`, `KWR-033`, and `KWR-034`;
3. complete Retail proof for `KWR-035`;
4. build the Problem Signal Coverage Registry;
5. build the timeline replay, golden corpus, and competitive benchmark before
   tuning the planner;
6. repair macro/tactical authority and complete only legally sourced problem
   signals;
7. progress through shadow, commander, expert, and any separately evidenced
   2400-competitive validation.

## 2026-07-29 replay/corpus checkpoint

`KWR-038` establishes the first versioned replay and golden-label schema,
fixture templates, a sanitized sample replay, and `tools/corpus-audit.ps1`.
The replay executor itself is still pending ET-04.

## 2026-07-29 benchmark checkpoint

`KWR-040` adds machine-readable replay-run results, a first sample replay
result, and `tools/decision-benchmark.ps1` so replay outputs can be scored
against reviewed golden labels before broader corpus expansion.

## 2026-07-29 Decision Lab foundation checkpoint

`KWR-041` adds the corpus manifest, adversarial/outcome schemas and templates,
an Arathi Basin sample slice, and `tools/outcome-report.ps1` so the offline
system has enough structure to scale beyond a single-map proof of concept.

## 2026-07-29 all-RBG foundation checkpoint

`KWR-042` adds one authoritative all-RBG map-profile layer in
`Data/RBGMapProfiles.lua` plus the machine-readable
`knowledge/rbg-foundation.json` contract. Future doctrine, replay corpus,
benchmark, and outcome work should extend these profiles instead of inventing
new per-map structure while implementing.

## 2026-07-29 all-RBG corpus skeleton checkpoint

`KWR-043` extends the starter Decision Lab corpus from two maps to all ten
currently supported RBG maps. Every supported map now has one replay fixture,
one golden label, one replay result, and one outcome review so future work can
improve the same structure instead of building new map scaffolding.

## 2026-07-29 base scenario matrix checkpoint

`KWR-044` defines the next mandatory offline base: five common scenario
families per supported RBG map. The machine-readable
`knowledge/rbg-scenario-matrix.json` now states the minimum scenario coverage
that future corpus growth should satisfy before deeper expert-tuning claims.

## 2026-07-29 deliberate system progress checkpoint

`KWR-045` adds `tools/deliberate-system-report.ps1` plus a schema-backed
progress contract so the repository can state, in counts, the current gap
between the starter all-map corpus and the minimum deliberate-system target.

## 2026-07-29 full offline foundation-depth corpus checkpoint

`KWR-046` adds `tools/build-foundation-depth-corpus.ps1` to expand each
scenario to five reviewed offline cases plus one adversarial truth-degraded
case. This does not replace later expert review, but it does give the project a
complete offline coverage layer to build and test against.

## 2026-07-29 reviewed scenario calibration checkpoint

`KWR-037` adds `tools/build-scenario-calibration.ps1`, the generated
`knowledge/scenario-calibration.json` artifact, and the runtime
`Data/ScenarioCalibration.lua` module. The strategist can now attach reviewed
sample count, win rate, dominant break pattern, and one discipline rule to the
selected battlefield scenario before field testing.

## 2026-07-29 adversarial scenario calibration checkpoint

`KWR-047` adds `tools/build-scenario-adversarial-calibration.ps1`, the
generated `knowledge/scenario-adversarial-calibration.json` artifact, and the
runtime `Data/ScenarioAdversarialCalibration.lua` module. The strategist can
now attach fail-closed uncertainty discipline per scenario: safe action,
fallback action, forbidden commit, must-stay coverage, and escalation rule
when battlefield truth is degraded.

## 2026-07-29 field-readiness pack checkpoint

`KWR-048` adds `tools/field-readiness-report.ps1`, the generated
`knowledge/field-test-readiness.json` report, and one unified field-readiness
document pack for live Retail testing. The repository now states, in one
place, what is offline-complete, what remains live-required, which map proofs
still matter, and what blocks promotion immediately.

## 2026-07-29 candidate blocker-report checkpoint

`KWR-049` adds `tools/field-blocker-report.ps1`, the generated
`knowledge/field-blocker-report.json` artifact, and
`docs/CANDIDATE_FIELD_CAPTURE_MATRIX_2026-07-29.md`. The repository now states
the fastest live sessions for clearing the current P1/P2 candidate blockers
before broader map-family certification.

## 2026-07-29 Twin Peaks first-session operator checkpoint

The repository now also includes
`docs/KWR_TWIN_PEAKS_FIRST_SESSION_OPERATOR_SHEET_2026-07-29.md`, a
ready-to-run live operator sheet for the first Twin Peaks blocker-clearing
session against `KWR-032`, `KWR-033`, `KWR-034`, and `TP-D03`.

## 2026-07-29 offline completion audit checkpoint

`KWR-050` adds `tools/offline-completion-audit.ps1`, the generated
`knowledge/offline-completion-audit.json` artifact, and
`docs/OFFLINE_COMPLETION_AUDIT_2026-07-29.md`. The repository now states, in
one place, that offline work is prepared enough to begin field testing while
remaining honest about the live-only blockers that still prevent certification.

## 2026-07-30 daily Discord update checkpoint

`KWR-051` adds `tools/kwr-daily-discord-update.ps1` plus
`docs/KWR_DAILY_DISCORD_UPDATES.md` so the repo now has one guarded daily KWR
status-post path. The script builds concise `daily-progress` and `ops` Discord
messages from the current readiness, blocker, and `WORKFLOW_NOW` artifacts,
supports dry runs, keeps webhook credentials outside the repository, and is now
scheduled through `.github/workflows/kwr-daily-discord.yml`.

## 2026-07-28 recovery checkpoint

The live addon folder was recovered after an interrupted development session.
Alpha 28 remains the active field-test candidate.

Closed in this recovery pass:

1. Completed `KWR-029`
   - the live compact HUD keeps one permanent `LOCAL FIGHT` card;
   - kill and healer-control lanes render independently;
   - confirmed local healers persist between casts while remote scoreboard-only
     healers are rejected;
   - active free-casters outrank passive local healers;
   - expired local actors clear to explicit placeholders.

2. Repaired synchronized assignment precedence
   - protected defenders and carriers no longer receive a conflicting personal
     healer-control job;
   - Sentinel keeps the protected objective role and normalized map location.

3. Repaired package-test trust
   - package audit now requires `KWR_SMOKE_PASS` and `KWR_SOAK_PASS`;
   - a zero Fengari process code without the expected marker is a failed gate.

Offline proof:

- `tools/validate.ps1`: 118 Lua files, 0 errors, 0 warnings;
- `tools/knowledge-audit.ps1`: 0 errors;
- `tests/smoke.lua`: `KWR_SMOKE_PASS checks=275`;
- `tests/soak.lua`: `KWR_SOAK_PASS refreshes=500`, 0.234 ms synthetic
  average, 0.800 ms p95, and 3.200 ms maximum.

Package certification is complete and focused Retail testing has begun. Next
execution order: preserve and review the `alpha.28` GitHub recovery diff,
repair and reverify `KWR-032` in a bounded follow-up, repeat the full gate from
that Git checkout, finish the open Sentinel polish verification, then continue
the map-family field matrix.

## 2026-07-28 Fight-Now combat clarity checkpoint

`KWR-035` is complete in the live addon folder and packaged as the current
`alpha.28` field-test candidate.

Closed in this pass:

1. Rebuilt the compact live card around immediate combat direction
   - score and projected result share the top line;
   - the battleground win path and next objective are stated in short PvP
     terms;
   - both current and next calls show WHAT, WHO, WHERE, and WHEN;
   - defense, offense, KILL/PRESS, and healer CC remain independent;
   - live trust, source, revision, refresh, and reassessment copy is hidden.

2. Synchronized health-row direction
   - each friendly row promotes the current execution job over its static map
     assignment;
   - clearing the packet restores the static assignment without a stale frame;
   - enemy rows show KILL, PRESS, or CC only from the reviewed local-fight
     packet.

3. One crosshair combat palette
   - HUD calls, roster jobs, target reticle, and battlefield identifiers share
     the same movement, kill, stop/CC, recovery, carrier, unknown, and stale
     colors;
   - STOP is now the same orange across the reticle and identifier rings.

Offline proof:

- `tools/validate.ps1`: 118 Lua files, 0 errors, 0 warnings;
- `tools/knowledge-audit.ps1`: 0 errors;
- `tests/smoke.lua`: `KWR_SMOKE_PASS checks=275`;
- `tests/soak.lua`: `KWR_SOAK_PASS refreshes=500`, 0.234 ms synthetic
  average, 0.800 ms p95, and 3.200 ms maximum;
- reproducibility and extracted distribution/developer package audit: passed.

The remaining gate is direct Retail battleground verification of legibility,
assignment repaint timing, unknown enemy health, secure targeting, and combat
lockdown/taint behavior.

## 2026-07-28 Twin Peaks field checkpoint

Nine supplied screenshots are preserved at
`docs/field-evidence/2026-07-28-twin-peaks/`.

Visible passes:

- Horde-relative score moves from `0-0` to `0-1` with the Blizzard score;
- native `Shift-M` map coexists with KWR compact surfaces;
- friendly/enemy rosters, assignments, seen/last-seen aging, and dead-state
  repaint are functioning in the captured states;
- unavailable enemy, objective, and local-fight facts stay unknown.

New P1 repair gates:

- `docs/KWR_TEAM_TRUTH_FIELD_FIX_TASK_2026-07-28.md`
  - expanded Team health is not meaningfully visible;
  - expanded Team specialization labels disagree with compact `(HIST)`
    provenance.
- `docs/KWR_COMMAND_STABILITY_FIELD_FIX_TASK_2026-07-28.md`
  - the final AAR reports 58 command replacements, `STABILITY REVIEW`, and
    `AVG LIFE 0:00`;
  - AAR labels confuse bounded command records and ActivePlay switches with
    total/manual concepts.
- `docs/KWR_FLAG_COMMAND_TARGET_FIX_TASK_2026-07-28.md`
  - raw flag-event prose became a `REINFORCE` target instead of remaining
    evidence.

Twin Peaks is partial, not certified. Final `0-3` result/AAR agreement and flag
events are now captured. Taint, Lua errors, performance, exact carrier/stacks
truth, exactly-one AAR history entry, exit cleanup, and Sentinel still require
direct evidence.

## 2026-07-15 visual verification closeout

The highest-priority offline visual/readability blockers were repaired and
revalidated on 2026-07-15.

Closed in this pass:

1. Support view readability
   - stronger panel contrast;
   - simpler headings;
   - plainer player-facing battlefield summary language;
   - less analyst jargon in the visible readout.

2. Assignments page density and clarity
   - command card now wraps correctly;
   - the main action line is shorter and easier to scan;
   - the right-side reasoning panel now explains `WHY THIS PLAN` in player terms
     instead of overexposing internal planner language.

3. Review / export readability
   - AAR cards were rebalanced for clearer text hierarchy while preserving
     required review terminology;
   - copy/export dialogs no longer show the thin template edit-box artifact
     behind the text body;
   - verification/export note spacing is cleaner.

4. MainWindow side-card hierarchy
   - review summaries and assignment side cards now have more usable text space
     and less clipping pressure.

Proof from this pass:

- `./tools/validate.ps1` passed
- `./tools/knowledge-audit.ps1` passed
- `npx --yes --package=fengari-node-cli fengari tests/smoke.lua` passed with
  `KWR_SMOKE_PASS checks=277`
- `npx --yes --package=fengari-node-cli fengari tests/soak.lua` passed with
  `KWR_SOAK_PASS refreshes=500 durationSamples=120 avgMs=0.15083333333605 p95Ms=0.79999999998836 maxMs=3.2000000000116 commanderHistory=3 evidence=2`

This closes the offline field-verification blocker for those repaired surfaces.
Remaining visual work is now live follow-up only if new battleground screenshots
expose a real unresolved edge case.

## 2026-07-15 commander gap-closure implementation

The implementation pass for
`docs/KWR_COMMANDER_GAP_CLOSURE_DESIGN_PATH_2026-07-15.md` is now part of the
stable offline baseline.

Closed in this pass:

1. BoardState compatibility contract
   - added read-only BoardState types, builder, and query facade;
   - BoardState normalizes context, score, objectives, enemies, friendlies,
     evidence IDs, and bounded summaries without becoming a second truth owner.

2. Enemy-problem depth
   - expanded the problem taxonomy beyond the original healer/killable pair;
   - detection now emits future-proof problem types such as carrier exposure,
     base pressure, stealth threat, healer pressure, cooldown window, and
     objective threat when safe fields exist.

3. Counterplay and scoring
   - added a data-driven CounterplayMatrix for job intent and capability fit;
   - scoring now considers objective value, local-vs-map confidence, inferred
     penalties, and current assignment context.

4. Assignment optimizer
   - replaced the greedy picker with a bounded deterministic search;
   - the optimizer caps problems, candidates per problem, and search nodes and
     exposes diagnostics for verification.

5. Kill target context
   - kill selection now accounts for resolved support-control coverage so the
     team kill target is evaluated after subdue/disrupt assignments are known.

6. DR, reasons, and ruleset policy
   - DR state now degrades through CONFIRMED / INFERRED / UNKNOWN instead of
     being a permanent stub;
   - assignment scoring penalizes immune/diminished/unknown control state and
     rewards confirmed-ready control windows;
   - debug reasons expose DR state and unknown defensive state explicitly;
   - Retail, PTR, and Strict Future rulesets now own decision-policy and
     optimizer-limit values consumed by the tactical optimizer.

Proof from this pass:

- `./tools/validate.ps1` passed with `Lua files: 115`, `Errors: 0`,
  `Warnings: 0`
- `./tools/knowledge-audit.ps1` passed
- `npm exec --yes --package=fengari-node-cli -- fengari tests/smoke.lua`
  passed with `KWR_SMOKE_PASS checks=277`
- `npm exec --yes --package=fengari-node-cli -- fengari tests/soak.lua`
  passed with `KWR_SOAK_PASS refreshes=500 durationSamples=120 avgMs=0.22166666667108 p95Ms=0.79999999998836 maxMs=3.2000000000116 commanderHistory=3 evidence=2`
- `./tools/build.ps1` passed with `KWR PACKAGE AUDIT PASSED`

## Current lane

Work in this order:

1. Live validation of the repaired audit blockers
2. Retail proof for the new local teamfight command-assignment slice
3. Retail lifecycle, taint, and field-performance proof
4. Visual/readability cleanup only when it does not reopen truth, safety, or performance risk

Immediate field-test capture sheet:

- `docs/LIVE_SCREENSHOT_CAPTURE_SHEET_2026-07-15.md`

### Visual direction package

The visual direction baseline is now split across two authoritative packages:

- `docs/visual-direction/2026-07-14/README.md`
- `docs/visual-direction/2026-07-15/COMPREHENSIVE_BATTLEGROUND_VISUAL_AUDIT.md`

The first package defines the out-of-combat design-system direction. The second
adds the consolidated before/during/after battleground audit. Visual work is no
longer blocked on missing direction; it is now blocked only on implementation
and live re-verification.

## Stable right now

These areas are now the current stable repo baseline:

1. Exact Store publication semantics
   - nested state changes now publish correctly without lossy token reuse.

2. Objective authority resolution
   - widget objective truth now uses canonical `ui_widget` provenance and no longer loses authority to weaker POI state.

3. Enemy truthfulness
   - enemy coordinate truth no longer piggybacks teammate or assignment positions.
   - inferred engagement stays semantic instead of becoming a fake map dot.

4. Canonical identity path
   - enemy truth, roster truth, and assignment overrides no longer merge distinct players by short name.
   - ambiguous short-name commander queries now fail safely instead of guessing.

5. Secure compact-surface suppression hardening
   - compact roster and command-center suppression paths no longer recurse or directly re-enter their own layout flow.
   - combat-safe hide queuing is back on the stable path.

6. Deterministic and packaging evidence
   - `./tools/validate.ps1` passed.
   - `./tools/knowledge-audit.ps1` passed.
   - `npx --yes --package fengari-node-cli fengari tests/smoke.lua` passed with `KWR_SMOKE_PASS checks=277`.
- `npx --yes --package fengari-node-cli fengari tests/soak.lua` passed with deterministic injected-cost timing proof: `KWR_SOAK_PASS refreshes=500 durationSamples=120 avgMs=0.15083333333605 p95Ms=0.79999999998836 maxMs=3.2000000000116 commanderHistory=3 evidence=2`.
   - `./tools/build.ps1` passed and `KWR PACKAGE AUDIT PASSED`.

7. Phase 1 correctness tranche one
   - Reporter now removes absent friendly contributors when the battleground roster changes.
   - MemoryBudget now evaluates the current Store state instead of the previous one.
   - MatchRuntime now re-evaluates strategy after assignment integrity exists, then rebuilds assignments against that refined result.
   - response-package recovery text no longer emits fake urgent gaps when coverage is already satisfied.

8. Release packaging and metadata trust
   - extracted distribution smoke and soak now run during package audit instead of certifying only the developer archive.
   - release workflow now rejects tags that do not exactly match the addon TOC version.
   - active release metadata and field-test template now reference `6.1.0-alpha.25` and the current `277` deterministic checks.

9. Runtime efficiency tranche one
   - Verification now rejects duplicate live states before building the heavy report entry.
   - ordinary friendly health and aura churn now updates roster bars without queuing a full strategic refresh.
   - Commander stability certification now separates raw evaluations from actually published command changes.

10. SavedVariables and lifecycle tranche one
   - bootstrap now performs typed field normalization instead of preserving malformed scalar values in defaulted tables.
   - persisted roots for journal, learning, encounters, overrides, and opponent models are normalized before modules consume them.
   - future-schema SavedVariables now run in explicit read-only compatibility mode instead of being downgraded on write.
   - active AAR journals now checkpoint during play and commit a single explicit `INTERRUPTED` record on reload/relog/disable-style teardown.

11. Objective carrier message tranche one
   - named flag return/capture battleground messages now clear only the affected flag carrier.
   - explicit full-reset wording uses a separate global carrier reset path instead of piggybacking on any message containing `flag`.

12. Phase 1 offline closure
   - the SavedVariables upgrade path now has deterministic schema-boundary proof, not only one legacy migration and one future-schema case.
   - AAR disable/reload interruption behavior now has a direct offline lifecycle fixture.
   - ObjectiveIntel now has an explicit locale policy: reviewed `enUS` plus reviewed `deDE` battleground message grammar, with safe fallback when no reviewed grammar exists.

13. Release provenance and reproducibility tranche one
   - build output now emits explicit source manifests, tool provenance, and reproducibility reports alongside hashes.
   - two clean builds now prove matching staged payload digests for distribution, developer, and Sentinel outputs.
   - PowerShell `Compress-Archive` still produces non-identical distribution/developer ZIP container bytes across clean builds, so the release baseline now records that as a documented container exception instead of pretending artifact hashes alone prove reproducibility.

14. Local teamfight multi-assignment command slice
   - new compliance/ruleset/adapters/state/intelligence pipeline converts safe facts into a local teamfight plan without auto-targeting, auto-casting, macros, focus changes, or secure combat mutation.
   - Knomercy/Stan/Priest-V/Priest-M/Warrior-Z replay is now deterministic in smoke: Knomercy subdues Priest-V, Stan subdues Priest-M, Team kills Warrior-Z in 5, debug reasons are present, target-match state is display-only, and UNKNOWN UI paths are safe.
   - `tools/validate.ps1` now scans the new architecture directories, blocks broader protected-action APIs, enforces adapter-only aura/combat-log reads, and rejects spell-specific commander-call phrasing.

15. Commander gap-closure intelligence baseline
   - BoardState now provides one normalized tactical read model over existing
     snapshot truth without replacing Sensors, Reporter, Strategist, Assignments,
     or Commander.
   - enemy problems are structured through the expanded taxonomy and
     CounterplayMatrix, with evidence IDs and explicit UNKNOWN/INFERRED handling.
   - tactical assignments now use bounded deterministic optimization instead of
     a single greedy sorted pass.
   - kill-target selection now receives support-control assignment coverage.
   - DR state and assignment policy now flow from safe facts and rulesets rather
     than hard-coded feature assumptions.

16. Compact battlefield identifier slice
   - friendly player plates now add only a role icon and short name by default;
   - enemy player plates now add only a class icon and short name by default;
   - confirmed flag/orb carrier state replaces the normal icon with Blizzard carrier art and objective color;
   - KWR health is target-only, priority-cast progress is active-cast-only, and UNKNOWN identity degrades without guessing;
   - the existing nameplate presenter was simplified rather than duplicated, refresh cadence was reduced to 4 Hz, and non-target health reads were removed.

## Ready to work right now

1. Retail combat-lockdown proof
   - verify no taint or blocked actions when roster, HUD, and command-center suppression occurs in combat.

2. Retail lifecycle proof
   - verify battleground entry, queue setup, `/reload`, death/rez, match end, battleground exit, arena suppression, and PvE suppression.
   - confirm the new interrupted-AAR path behaves once per teardown and does not duplicate records on real client reload/relog.

3. Local teamfight field proof
   - verify the new assignment optimizer with real nameplate/scoreboard truth in a battleground.
   - verify crosshair/target-assist guidance remains display-only and does not create taint, targeting, focus, macros, or protected-action side effects.

4. Performance proof refinement
   - the soak timer is now monotonic and nonzero, but deeper slowdown/failure-mode proof is still open if we want the performance gate to be stronger than a bounded-health signal.
   - archive reproducibility is now reduced to a container-level PowerShell ZIP exception rather than a payload-drift question.

5. Visual verification matrix
   - options, verification, setup center, support view, assignments, enemy tracker, and AAR readability across supported scales.
   - compact identifiers still need bright/dark, multi-plate, flag-carrier, and orb-carrier screenshots; Blizzard or third-party base nameplates remain user-controlled.
   - use `docs/visual-direction/2026-07-15/COMPREHENSIVE_BATTLEGROUND_VISUAL_AUDIT.md` as the active implementation brief for the next visual pass.

6. Bot or workflow handoff for daily progress reporting
   - keep the scheduled GitHub workflow secrets current, or hand the same repo
     script to the external Sentinel bot if scheduling moves out of Actions.

## Recently completed

1. `Core/Util.lua`
   - added canonical identity helpers and exact deep-equality support for authoritative state reconciliation.

2. `Core/Store.lua`
   - removed lossy sampled publication reuse and replaced it with exact branch reconciliation.

3. `Runtime/Sensors.lua`
   - canonicalized objective widget provenance to `ui_widget` for authority resolution.

4. `Runtime/EnemyIntel.lua`
   - removed unsafe short-name merges across live truth paths.
   - removed enemy coordinate fabrication from teammate/source-unit context.

5. `Runtime/Reporter.lua`
   - fallback positions now apply only to friendly tracks, not enemies.
   - absent friendly tracks are now pruned when the live roster changes.

6. `Runtime/AssignmentOverrides.lua`
   - moved override resolution to canonical identities with safe legacy fallback.
   - ambiguous short-name queries now fail closed.

7. `UI/CombatRosterVisuals.lua`
   - compact roster normalization no longer collapses same-short-name friendlies.

8. `UI/CombatRoster.lua` and `UI/CombatRosterState.lua`
   - compact roster suppression and auto-show flow were hardened after the audit pass and recursion regression.

9. `Runtime/Strategist.lua`
   - objective conflict truth now invalidates cached clean strategies and properly suppresses hard commit authorization.

10. `Runtime/MemoryBudget.lua`, `Runtime/MatchRuntime.lua`, and `Runtime/Assignments.lua`
   - current-state memory sampling is fixed.
   - strategy now gets a post-integrity re-evaluation pass before final command publication.
   - zero-deficit recovery text no longer creates fake urgent coverage gaps.

11. Release trust surfaces
   - `CHANGELOG.md`, `README.md`, `CURSEFORGE_DESCRIPTION.md`, `BATTLEGROUND_VERIFICATION.md`, `META_SOURCES.md`, `THIRD_PARTY_NOTICES.md`, and the battleground issue template were aligned to the current alpha.25 baseline.
   - package audit now certifies the stripped distribution archive with extracted runtime smoke/soak, not just the developer package.

12. `Runtime/Verification.lua`, `Runtime/MatchRuntime.lua`, and `Runtime/Commander.lua`
   - duplicate verification updates are now filtered before expensive entry construction.
   - ordinary friendly health churn no longer drives full pipeline refreshes.
   - command-stability certification now counts published command transitions separately from repeated evaluations.

11. `tests/smoke.lua`
   - added deterministic coverage for exact Store nested publication, same-short-name roster separation, ambiguous override rejection, engagement-only enemy truth storage, Reporter roster pruning, current-state memory sampling, post-integrity strategy output, and zero-deficit recovery summaries.

12. Packaging
   - rebuilt distribution, developer, and Sentinel archives with verified hashes from the repaired baseline.
   - build output now also writes `*_SOURCE_MANIFEST.json`, `*_BUILD_PROVENANCE.json`, and `*_REPRODUCIBILITY.json`.

13. Commander local teamfight architecture
   - added `Rulesets`, `Compliance`, `Adapters`, `State`, and `Intelligence` modules for safe fact ingestion, normalized teamfight state, enemy problem detection, friendly capability scoring, assignment optimization, kill-target selection, countdown generation, and debug reasoning.
   - added presenter contracts for teamfight command cards, personal assignment cards, crosshair markers, target assist, countdown, and debug reasons.
   - wired `snapshot.teamfight` into `MatchRuntime` and `Store` so future UI can consume one authoritative plan branch.
   - added `tools/forbidden-api-rules.json` and `tools/replay-test-runner.lua`.

14. Enemy intelligence, Reporter readout, and Options discipline
   - opponent models now expose structured learned traits, trait summaries, and commander takeaways instead of only long profile text.
   - enemy notes now support local structured tags such as `Kill`, `Subdue`, `Peel`, `Spinner`, `Carrier`, and `Avoid Tunnel`; tagged notes survive pruning.
   - assignment scoring consumes learned opponent traits only as bounded advisory modifiers, preserving live truth as the authority.
   - Reporter now publishes a plain `battlefieldRead` with status, confidence, headline, action, and source.
   - Options now exposes an auditable toggle inventory and layout audit so dead-toggle and overlap regressions can be caught offline.

15. Visual readability closeout tranche one
   - Support View, Assignments, Review/AAR summaries, and copy/export dialogs were cleaned up for stronger contrast, less jargon, better wrapping, and fewer layout artifacts.
   - the verification/export thin text-box artifact was removed from the copy dialog path.
   - smoke and soak were rerun after the visual pass to prove the UI cleanup did not reopen runtime regressions.

16. `Runtime/ObjectiveIntel.lua`, `tests/smoke.lua`, and `tests/soak.lua`
   - added reviewed locale grammar support for battleground objective messages with deterministic `deDE` coverage and safe fallback behavior.
   - added schema-boundary matrix coverage for supported SavedVariables upgrades.
   - added direct disable/reload interruption proof for the AAR lifecycle path.
   - reran validate, smoke, and soak from the repaired runtime baseline.

17. Daily Discord update path
   - added `docs/KWR_DAILY_DISCORD_UPDATES_TASK_2026-07-30.md` to define the
     bounded accountability outcome and verification steps.
   - added `docs/KWR_DAILY_DISCORD_UPDATES.md` as the repo-owned operator
     playbook for daily KWR progress posts.
   - added `tools/kwr-daily-discord-update.ps1` to generate guarded
     `daily-progress` and `ops` webhook posts from the current machine-readable
     readiness, blocker, and workflow artifacts plus operator-supplied deltas.
   - added `.github/workflows/kwr-daily-discord.yml` to schedule one daily
     post and optional ops post through GitHub Actions when Discord webhook
     secrets are present.

## Newly discovered / still needs attention

1. Live-only proof is still missing for combat-safe secure-surface suppression
   - offline paths are repaired, but Retail taint proof is still required.

2. Visual polish remains open on several commander surfaces
   - especially remaining live-combat clutter choices, full scale-matrix proof,
     and any new screenshot-driven edge cases.

3. Local teamfight UI is architecturally present but not yet field-proven
   - offline replay proves the command planner and presenter contracts.
   - live validation still needs to confirm real battleground enemy facts are rich enough to drive the plan consistently without clutter or unsafe behavior.

4. Visual verification remains required for the newly deepened enemy/note/options surfaces
   - verify the expanded enemy note editor tag/takeaway layout in-game at the userâ€™s 2560x1440 / 65% UI scale.
   - verify Options scroll behavior and card readability after the new inventory/layout audit-backed cleanup.
   - verify support-view readability and live-combat declutter against the comprehensive battleground visual audit.

5. GitHub sync could not be verified from this shell
   - `git` is not available in the current environment, so repo-to-GitHub parity still needs to be checked in a shell with Git installed.

6. Daily posting depends on GitHub Actions or bot secret configuration
   - the repository schedule now exists, but daily Discord delivery still
     depends on valid `DISCORD_WEBHOOK_DAILY_PROGRESS` and optionally
     `DISCORD_WEBHOOK_OPS` secrets.

## If you only have a few minutes

- run `./tools/validate.ps1`;
- run `npx --yes --package fengari-node-cli fengari tests/smoke.lua`;
- verify one real battleground combat/suppression cycle for taint-free behavior;
- update the release-gate artifacts with any live failure immediately.

## Session close rule

After each work session, update:

1. `Recently completed`
2. `Newly discovered / still needs attention`
3. `Ready to work right now`
