# KWR Commander overhaul audit and implementation plan

Audit date: **2026-09-04**. Scope: Retail Commander, the embedded Sentinel
package, installed runtime differences, tactical decision quality, performance,
player experience, verification, and distribution.

This is the sole active overhaul backlog. It replaces the earlier Season 2
execution order, fixed 5,000-case target, and competing delivery phases in this
document. The product vision is retained. Release decisions remain exclusively
in [RELEASE_READINESS.md](RELEASE_READINESS.md); engineering rules remain in
[AGENTS.md](AGENTS.md). This audit is complete as a planning deliverable.
**The implementation tasks below are open; the addon is not certified by this audit.**

## Release-first priority — owner direction 2026-09-04

**September 8 execution clarification:** finish all offline implementation,
migration, benchmark/replay, review and package work before asking the owner for
field testing. [RELEASE_READINESS.md](RELEASE_READINESS.md) supplies the current
per-OVR implementation/test/end-state recipes, nine pending source-recovery work
packages, and the OFFLINE COMPLETE — READY FOR FIELD TESTING gate. These execute
the requirements below; they do not replace the vision or clear any acceptance
criterion. Live-only evidence is a later promotion dependency, not a coding
dependency. KWR-281 does not wait for KWR-280's final WSG session.

The owner prioritizes a stable, distributable addon and controlling further
development cost. The owner's latest instruction requires the full audited
overhaul, including all tactical enhancements, before the field-test handoff.
This supersedes minimum-stable-first sequencing. Implement every offline OVR
requirement; comparative leadership and real-client safety still require field
evidence afterward. Do not repeat the audit or discard the existing architecture.

Freeze the candidate's advertised features, maps, brackets and client support in
OVR-01. Every advertised capability still needs its correctness, compatibility,
performance and field evidence. This priority does not clear any gate, reduce
the existing field sample requirements, authorize feature removal, or certify
the current Alpha 12 package.

The release path is:

1. Recover the reproducible source/package baseline and establish real performance
   measurements (OVR-01/09). Prepare the packaging checks in OVR-22 early.
2. Close the reproduced defects and command lifecycle failures with permanent
   regressions (OVR-02 through OVR-08 and OVR-12).
3. Close correctness, performance, compatibility, public-roster, learning and
   usability failures in the features being shipped (relevant parts of OVR-10/11
   and OVR-13 through OVR-19). Measure before choosing a larger refactor. An
   enhancement task must satisfy its audited offline acceptance criteria before
   handoff; unsupported advice cannot remain enabled while its replacement is
   unfinished.
4. Run fresh candidate and extracted-package tests, complete the existing live
   safety/tactical/performance matrix, then verify clean installation, upgrade,
   package contents and rollback (OVR-20/21/22). Comparative superiority remains
   necessary for a "leading" claim, rather than a new prerequisite for an honest
   stable release with verified advertised capabilities.

Control implementation cost with bounded fixes, focused regression runs and one
full certification per final candidate unless changes require it again. Record
closed gates, remaining blockers and evidence after each work package. Do not
claim a dollar estimate before observing actual implementation usage, or count
a model's confidence as release evidence. Complete the full audited offline
scope before field handoff, and field and distribution gates before stable release.

## Judgment and intended end state

KWR has a substantial foundation: one MatchRuntime/Store pipeline, public
objective sensors, assigned-team resolution, an existing Strategist and Commander,
role assignments, a compact HUD, secure roster rows, native-map coexistence,
reviewed knowledge gates, bounded history, and optional Sentinel transport.
Retain these systems and overhaul their contracts and expensive paths in stages.

It is not yet defensible to call this the leading rated battleground commander.
Eight defects reproduce against both the installed addon and the development
checkout. The current tests miss those cases, the offline timing receipt uses a
simulated clock, and current-package tactical effectiveness has not been proven.
Adding more generated scenarios or panels will not close these gaps.

The intended experience is:

- Before gates: identify the correct bracket, verify the roster, show an opening
  with named jobs, minimum defense, first contact, and a recovery option.
- In combat: show the win condition, one current team call, my job and location,
  a deadline when justified, and one local target/control instruction.
- When facts change: state why the old call stopped, who changes job, what stays
  covered, and the fallback. A neutral observation must not masquerade as a kill window.
- After combat: review what was recommended, what the leader accepted or changed,
  what execution was actually observed, and the objective result.
- In poor visibility: give conservative objective guidance, explicit uncertainty,
  and useful manual assignment control. Never invent hidden opponents or cooldowns.

Ten-player organized RBG leadership is the primary product. Blitz must have a
separate verified ruleset and assignment size if advertised. Arena, random BG,
training, unknown maps, and experimental companions do not silently inherit
10v10 assumptions.

## Audit boundary and evidence

Development checkout inspected:
`C:/Users/josev/source/repos/KnomercyWarRoom`, branch
`codex/kwr-278-alpha11-field-blockers`, base commit `bcce7f5`.
It already had uncommitted Alpha 11/12 work, including KWR-280.
Installed addon inspected:
`D:/Program Files/World of Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom`.

Both declare `6.1.1-alpha.12`. The following was the September 4 raw audit
snapshot: source had 131 TOC entries, installed Commander had 123, and the raw
comparison found 25 changed loaded files and three installed-only files. It is
not the current reconciliation receipt.

The current September 8 Retail-active receipt is
`artifacts/source-install-reconciliation-20260908-live-session.json`: source
has 132 Commander TOC entries, installed Commander has 123, and the Commander
comparison has 47 changed shared files, 11 source-only entries and two
installed-only generated projections (`ScenarioRuntimeKnowledge.lua` and
`StrategistNexusRuntimeIndex.lua`). Sentinel has two changed shared files. All
62 non-matches remain `review_required`; the hash-bound work packet records zero
completed dispositions. Raw source/package differences can be intentional, but
they need an evidence-backed source-of-truth decision and a reproducible build
path before reproducibility can be claimed. Do not overwrite installed
improvements with this checkout.

Installed Sentinel and load-on-demand KWR_DevTools also declare Alpha 12.
KWR_Maps, KWR_ScoreCard, and KWRBeacon are absent from their supplied installed
paths. Their absence is not a Commander release blocker. Their implementation
was not audited as though it were present. The separate Beacon/bot repositories,
live GitHub protection, CurseForge downloads, Discord, and Render deployment were
not certified in this pass.

Read: README, PRODUCT_ROADMAP, DESIGN_CONTRACT, ARCHITECTURE, PROJECT_HANDOFF,
RELEASE_READINESS, QA_CHECKLIST, BATTLEGROUND_VERIFICATION, META_SOURCES,
DATA_GOVERNANCE, PROTOCOL, release/security notes, current task briefs and
selected evidence, plus code across every runtime domain. This is a broad static
audit with targeted executable reproductions, not an in-client gameplay session
or a claim that every possible defect has been enumerated.

### Checks actually run

| Check | Result on the inspected working tree | What it establishes |
| --- | --- | --- |
| tools/validate.ps1 | PASS; zero warnings/errors | Existing static, TOC, document, and control-surface rules |
| tools/test-lua.ps1 -Suite All | PASS; smoke marker reports 276 checks | Existing mocked regression suite; the number is not a quality score |
| Sentinel transport test | PASS; accepted=10, rejected=14, hud=10 | Existing mock transport cases, not ten physical clients |
| Soak | PASS; 500 refreshes, 60 retained duration samples | Bounded state and scheduling under the test driver |
| Default replay | PASS by fallback; primary=false | One Twin Peaks replay, not full-corpus current-code correctness |
| tools/knowledge-audit.ps1 | PASS; 100,000 cases, 10 maps, 5 phases, 2,000 exact branches | Generated coverage and internal knowledge consistency |
| Additional audit probes | Eight defects reproduced in source AND installed modules | Ordinary-value contract failures independent of WoW secrets |
| Live CPU/FPS/taint, secure combat cycle, complete current-build matches | NOT RUN | Required before promotion |
| Clean tagged rebuild, extracted install parity, public download receipts | NOT RUN | Required before promotion |

Local reproduction script and output are in
`artifacts/overhaul-audit-20260904/` (`probes.lua`, `source-probes.txt`,
`installed-probes.txt`). They are development evidence, excluded from player
packages. A probe's `AUDIT_REPRODUCED` marker means the defect is still present.
Preserve these cases as permanent regressions when fixing them.

### Current WoW constraints checked

Blizzard distinguishes display of restricted combat values from addon reasoning
over those values. Publicly displayable data must not automatically become a
decision input. Design API fallbacks around that distinction.
[Blizzard addon philosophy](https://worldofwarcraft.blizzard.com/en-us/news/24246290/combat-philosophy-and-addon-disarmament-in-midnight).

The official hotfix ledger now includes changes through September 3, while the
local pack's `officialHotfixReviewed` stops at August 27. For example, the ledger
includes September 2 PvP fixes and September 3 healing fixes; that is a review
gap, not permission to invent new numeric capability weights.
[Official hotfix ledger](https://worldofwarcraft.blizzard.com/en-us/news/24296142).

Blizzard's generated API documentation, mirrored in the UI source, places the
casting spell ID in UnitCastingInfo's ninth return and UnitChannelInfo's eighth.
Treat the live branch as a moving reference; pin the exact client build when
implementing adapter tests.
[Generated Unit API source](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua).

The shipped June 27 Murlok snapshot is patch 12.0.7 and correctly excluded from
12.1 meta influence. No new specialization tier list or external competitor
ranking is asserted by this audit. Current ranked-map availability and exact API
availability must be recorded from the target client and reviewed patch sources.

### Current comparison baseline

These are developer-published feature references checked on September 4, not
an in-client ranking or a claim that KWR should copy their code. Pin versions
again when running the OVR-21 comparison.

| Reference | Advertised capability / audit-date listing | What KWR must prove |
| --- | --- | --- |
| [Capping Battleground Timers](https://www.curseforge.com/wow/addons/capping-bg-timers) | Node/flag timers and score estimates; Retail 12.1.0 listing | At least comparable public-objective timing, then a feasible named response and fallback |
| [BattleGroundEnemiesFixed](https://www.curseforge.com/wow/addons/battlegroundenemiesfixed) | Battleground roster presentation; 12.1.0 listing, with explicit restricted health/role limitations | Equally trustworthy readable identity/click behavior; no claims of hidden role/health knowledge |
| [Battleground Win Conditions](https://www.curseforge.com/wow/addons/battleground-win-conditions) | Win-condition banner/text; retrieved listing advertises 12.0.7 | Clear correct winning-clock explanation; verify current build compatibility before comparison |

The intended differentiation is the complete leader workflow: objective truth,
feasible assignments, stable calls, explicit recovery and reviewed execution.
This is a product hypothesis until measured. More overlays or a larger corpus
alone do not establish an advantage over focused tools.

## Findings and implementation ownership

Evidence paths/line numbers below refer to the inspected source before this
documentation update. Resolve the named function if later edits move a line.
R = executable reproduction; C = directly observed code/document behavior;
V = live or release verification gap; E = product enhancement.

| ID | Evidence and shortcoming | Impact | Fix task |
| --- | --- | --- | --- |
| F01 C/V | Source/install TOC and runtime differences above; Alpha 12 TOCs coexist with Alpha 10/11 receipts and release checkboxes | Cannot bind a tested source, package, and deployment | OVR-01, OVR-22 |
| F02 R | State/BoardStateBuilder.lua:53 iterates snapshot.objectives; Sensors.lua:1272 publishes objectives.rows | Local BoardState sees zero objectives despite a populated sensor snapshot | OVR-02 |
| F03 R | State/FactStore.lua:24,34 stamps Now() on unchanged observations; friendly records are blanket CONFIRMED | Freshness/provenance can be upgraded by rebuilding a view | OVR-02 |
| F04 R | Runtime/CombatIntel.lua:573,575 sets the highest-scoring candidate killable=true even with unknown health/support; EnemyProblemDetector consumes that flag | Preference becomes claimed vulnerability and a kill recommendation | OVR-03 |
| F05 R | AssignmentScorer.lua:41 applies -200 for unavailable players; AssignmentOptimizer.lua:123 accepts any remaining positive score | A dead Knomercy receives a control job with score 26 in the probe | OVR-04 |
| F06 C | Data/PlayerControlProfiles.lua:6 hardcodes knomercy/stan bonuses; LocalTeamfightState includes the full friendly board | Public distribution has name-based bias; remote defenders can enter local job selection | OVR-04, OVR-17 |
| F07 C | TeamfightCommandPlanner.lua:13 builds a new five-second countdown; AssignmentOptimizer.lua:57 and KillTargetSelector.lua:47 say Go in 5; ExecutionCommandBuilder.lua:609 publishes it | There is no stable start/deadline establishing when GO actually occurs | OVR-05 |
| F08 R | TeamResolver.lua:379 infers Blitz solely from 8+8 rows; Sensors.lua:1227 latches that evidence | A partly loaded standard roster can activate different scoring rules for the session | OVR-06 |
| F09 R | CommanderComm.lua:104 dereferences absent seq before validating its presence; Receive decodes before roster authorization | A malformed eight-field payload can throw when transport is enabled | OVR-08 |
| F10 R | KWRSentinel/Observer.lua:60 reads cast return 8 as spell ID | Ordinary casts fail to produce OBS_CAST; channel layout happens to differ | OVR-07, OVR-08 |
| F11 R | CursorRing.lua:1247 returns before downstream retry accumulators; line 1279 adds only the final frame's elapsed | At 30/60/144 FPS, ten-second probe produces 37/18/8 orb refreshes; higher FPS makes retry updates slower | OVR-12 |
| F12 C/V | tests/soak.lua:8 replaces debugprofilestop; lines 90-96 inject 3.2/1.6/0.8/0.1 ms; performance JSON calls the result PASS | Reported 0.8 ms P95 is simulated and cannot establish Retail speed | OVR-09 |
| F13 C/V | MatchRuntime.lua:990 measures before Store.Publish at 1020; Store.lua:450 recursively reconciles and batches subscribers later | Refresh timing omits publication/render tail; lower frequency can hide latency | OVR-09, OVR-10 |
| F14 C/E | Maps.lua:279 uses normalized straight-line distance and shared movement constants for all maps | Estimates omit roads, elevation, crossings, spawn routes and actual player availability | OVR-14 |
| F15 C/E | Learning.lua:7 buckets only map+plan; RecordReviewed credits a whole win/loss to primaryPlanID and any feedback; Adjustment uses five samples | Composition/bracket/team/plan-version effects and actual delivery are conflated | OVR-18 |
| F16 C/V | KnowledgeManifest.lua:70 compares two bundled patch strings; freshness tolerates missing dates; reviewed hotfix cutoff is old | Static agreement is not client-build compatibility; stale slices can remain apparently reviewed | OVR-07, OVR-16 |
| F17 C/V | tools/decision-benchmark.ps1 reads existing .run.json evaluation flags; default test-lua replay runs one fixture | A benchmark PASS need not mean current runtime generated all results | OVR-20 |
| F18 C/V | KWR-278 historical field brief records 35.072 ms strategic P95, 50.295 ms max, 47,974 KB peak; KWR-280 is still in progress | Severe past field cost and churn remain regression targets, not proof Alpha 12 has the same measured values | OVR-05, OVR-09, OVR-21 |
| F19 C/V | README/QA/map/design notes still cite Alpha 25/28/29 or only live-proof gaps; roadmap said 5,000 cases and 30-match retention | Engineer and player instructions disagree with current code and evidence | OVR-01, OVR-19, OVR-22 |
| F20 C/E | Byte-based text clipping in Core/Util.lua:51; English command/UI strings throughout UI and Runtime | Distribution needs UTF-8-safe clipping, explicit locale support, and readability verification | OVR-19 |
| F21 C/E | Runtime/Commander.lua exceeds 2,600 lines; hot paths build multiple fact/board/command views; caches/queues already exist | Refactor measured responsibilities, avoid introducing another engine or a broad blind rewrite | OVR-10, OVR-15 |
| F22 V/E | No candidate-bound comparative commander benchmark or complete live acceptance matrix established in this audit | “Meta leading” remains an aspiration until usefulness beats the baseline | OVR-20, OVR-21 |

## Architecture to preserve and tighten

```text
Blizzard permitted API/event values
    -> Adapters + Sensors + TeamResolver
    -> one snapshot, field provenance, freshness, typed objective IDs
    -> Predictor + Strategist candidate evaluation
    -> Assignments feasibility + existing local-fight planner
    -> Commander-owned play lifecycle + synchronized ExecutionCommand
    -> Store publication with revision and changed-domain mask
    -> HUD / tactical board / secure roster / audio / optional Sentinel / AAR
```

FactStore and BoardState become read-only projections of the same observed facts.
They do not create new observations. Local-fight selection must consume one
adjudicated target intent; it cannot independently upgrade the roster spotlight.
Keep manual priority and observed vulnerability as separate fields.

Secure click bindings are prepared out of combat. Display-only restricted health
may flow directly to a Blizzard-supported visual sink, never into numeric
scoring, signatures, serialization, saved variables, or addon messages.
The native Shift-M map remains the battlefield map. Reporter is background
intelligence with detail on the existing board; do not revive another support map.

Use the existing root-level module layout. Extract narrow pure functions from
large files only where ownership/testability or profiling justifies it. New
generation tools and replay machinery stay outside the player runtime. No
network fetching, automatic movement, spell use, targeting, focus, macro
execution, or visible-chat sending is added. Retain reviewed hardware-click
quick calls and secure targeting. Sentinel remains an optional recipient,
not another strategic brain.

## Ordered work register

P0 blocks promotion because it affects correctness, safety, reproducibility, or
proof. P1 is required for the requested overhaul outcome. Parallel work may start
after shared contracts are agreed; completion must respect dependencies.
OVR-01 is **IN_PROGRESS**, owned by Codex in
[KWR-281](docs/tasks/KWR-281-release-source-reconciliation.md). OVR-08 and OVR-12
are **IN_PROGRESS**, owned by Codex for the bounded parser/cast/cadence fixes in
[KWR-282](docs/tasks/completed/KWR-282-runtime-boundary-regressions.md); their broader field
and integration gates remain open. OVR-02/03/04 are **IN_PROGRESS** under Codex's
[KWR-283](docs/tasks/completed/KWR-283-tactical-truth-regressions.md) for the objective,
target-preference and known-unavailable actor regressions. Their broader typed
truth and feasibility criteria remain open. The unknown-friendly availability
and role boundary continues in [KWR-287](docs/tasks/completed/KWR-287-friendly-availability-truth.md).
OVR-06 is **IN_PROGRESS** under
[KWR-284](docs/tasks/completed/KWR-284-observation-and-bracket-truth.md), which also preserves
OVR-02 observation timestamps. The bounded KWR-282/283/284 tasks passed the
`audited-regressions-20260905-02` extracted-package audit and are completed;
their broader OVR work packages remain in progress. OVR-09/10 are **IN_PROGRESS**
under [KWR-285](docs/tasks/completed/KWR-285-memory-sampling-provenance.md), starting with
accurate, bounded memory sampling; that bounded task passed
`memory-sampling-20260905-package` extraction. OVR-11 is **IN_PROGRESS** under
[KWR-286](docs/tasks/completed/KWR-286-scenario-generator-parity.md), first preserving
scenario generator/runtime parity before projection changes. Other rows remain **OPEN**, with owner
**unassigned** until claimed.
These OVR IDs are work packages, not claims that existing KWR task IDs are closed.

OVR-05 is **IN_PROGRESS**, owned by Codex under
[KWR-288](docs/tasks/completed/KWR-288-explicit-countdown.md) for explicit local start/deadline
and stale-cue rejection. Canonical lifecycle, relay revision and live gates remain open.
KWR-287/288 passed the `explicit-countdown-20260906-package` extraction gate.
OVR-02 continues after [KWR-289](docs/tasks/completed/KWR-289-evidence-freshness.md),
which closes shared evidence-time validation with an extracted dirty-package
checkpoint. Full typed field projection remains required.
OVR-03 continues after [KWR-290](docs/tasks/completed/KWR-290-observed-kill-intent.md),
which closes observed target intent and kill-commit gating with an extracted
dirty-package checkpoint. Full target evidence and feasibility requirements
remain open.
OVR-03/04 continue after [KWR-291](docs/tasks/completed/KWR-291-local-support-availability.md),
which closes known local-support proof with an extracted dirty-package checkpoint.

| Order / ID | Priority | Risk | Depends on | Deliverable |
| --- | --- | --- | --- | --- |
| OVR-01 | P0 | High | None | Reconciled source and honest baseline |
| OVR-02 | P0 | High | 01 | Correct typed facts and objective projection |
| OVR-03 | P0 | High | 02 | Truthful target intent and confidence |
| OVR-04 | P0 | High | 02,03 | Feasible local control and protected assignments |
| OVR-05 | P0 | High | 02,03,04 | Stable play and real execution deadlines |
| OVR-06 | P0 | High | 01,02 | Verified bracket, map and lifecycle context |
| OVR-07 | P0 | High | 01,02,06 | Build-aware, secret-safe API contracts |
| OVR-08 | P0 for shipped transport | High | 01,07 | Defensive optional Sentinel transport |
| OVR-09 | P0 proof | Medium | 01 | Real cost and responsiveness measurements |
| OVR-10 | P1 | High | 02,05,09 | Reduced computation and publication cost |
| OVR-11 | P1 | Medium | 01,09,10 | Small player runtime and bounded memory |
| OVR-12 | P1 | High | 02,05,09 | Correct marker cadence and secure identity |
| OVR-13 | P1 | High | 02,05,06,07 | Complete map objective engines |
| OVR-14 | P1 | Medium | 02,06,13 | Honest route and reinforcement feasibility |
| OVR-15 | P1 | High | 03,04,05,13,14 | Map-specific candidate/counter decisions |
| OVR-16 | P1 | Medium | 06,07 | Reviewed current-patch knowledge |
| OVR-17 | P1 | Medium | 04,06,16 | General-purpose roster formation and job presets |
| OVR-18 | P1 | High | 02,05,15,16 | Decision-level AAR and conservative local learning |
| OVR-19 | P1 | Medium | 05,12,13,17 | Commander UX, accessibility and supported locales |
| OVR-20 | P0 proof | High | 02-08,13-18 | Current-code replay and tactical benchmark |
| OVR-21 | P0 proof | High | 09-20 | Live competitive and performance evidence |
| OVR-22 | P0 release | High | All required rows | Certified, installable distribution and rollback |

### OVR-01 — Reconcile source, preserve fixes, freeze a reviewable baseline

**Current / outcome:** the installed DevTools split and runtime projections are
not reproducible from the inspected checkout. The leader needs an identifiable
build before any overhaul result can be trusted.

**Implementation:** preserve a hash manifest and backup of Commander, Sentinel
and DevTools plus current dirty source. Inventory available branches/worktrees
and package receipts; recover installed-only improvements into the canonical
repository through reviewed, bounded diffs. Preserve KWR-278/279 and finish
KWR-280's already-written fixes instead of rebuilding them. Document which
differences are source changes versus deterministic packaging transforms.
Correct stale main/develop and “no git metadata” instructions using the actual
repository policy. Do not reset dirty source, move old tags, or install older code.

**Acceptance / verification:**

- [ ] A clean candidate commit can generate all three intended runtime identities.
- [ ] Exact TOC/runtime/version/hash receipt explains every installed-file difference.
- [ ] Source and extracted-package tests run against that candidate.
- [ ] KWR-280 remains awaiting its WSG live regression until captured.

**Rollback:** preserved source diffs and the exact pre-overhaul addon/SavedVariables
snapshot; restore components together when shared contracts change.

### OVR-02 — One fact contract with correct objective shape and observation age

**Implementation:** repair BoardStateBuilder to read `snapshot.objectives.rows`.
Give each objective a canonical map/ruleset/objective ID, independent of its
localized label. Carry original `observedAt`, source, TTL, expiry, observation ID
and verification level into FactStore/BoardState. Keep `projectedAt` separate.
Represent known/unknown/conflicting values explicitly; an evidence ID proves
traceability, not confidence. Reuse the existing truth-contract owner; no new
mutable fact store.

**Acceptance / verification:**

- [ ] Populated sensor rows produce the same IDs/counts in board, predictor and UI.
- [ ] Rebuilding a t=10 observation at t=100/200 never refreshes its observation time.
- [ ] Unknown friendly role/connection remains unknown; scoreboard identity is not visibility.
- [ ] Permuting input order does not change identity, evidence IDs or call selection.
- [ ] Expiry and contradictory sources suppress only dependent decisions.

**Rollback:** retain the old reader only for versioned fixtures; live code uses
one schema after migration. Reject malformed rows instead of silently coercing them.

### OVR-03 — Separate preferred target, observed vulnerability, and kill commit

**Implementation:** in CombatIntel remove the promotion from “best candidate” to
`killable`. Publish distinct target intents such as manual focus, pressure,
observed opportunity, and swap/avoid, each with evidence requirements. Let
EnemyProblemDetector and KillTargetSelector consume that intent through the
existing planner. Apply the same defensive/carrier/role constraints to every
surface. Confidence reflects input support and contradictions, not assignment
count or a high heuristic score.

**Acceptance / verification:**

- [ ] Unknown-health/no-support candidate can be a pressure target but never a
  confirmed kill window merely because it ranks first.
- [ ] No legal candidate yields a calm “no confirmed local target” state.
- [ ] Immunity/defensive evidence suppresses an incompatible commit across HUD,
  spotlight, execution packet, audio and Sentinel.
- [ ] Manual priority remains visibly manual; HIST spec does not become live certainty.
- [ ] Removing supporting facts cannot increase commitment confidence.

**Rollback:** feature flag advanced target commits off; retain permitted visual
target identity and manual priority.

### OVR-04 — Hard assignment feasibility before scoring

**Implementation:** filter dead/disconnected actors before candidate scoring.
For unknown availability, remote location, unknown reach or unsupported control
capability, use an unassigned/watch state rather than an executable local job.
Pass the authoritative assignment coverage ledger into the optimizer.
Exclude carriers, committed sitters, essential healers and last defenders unless
a legal handoff exists. The existing late `preserveProtectedAssignments` pass
is a final invariant check, not a substitute for generating feasible candidates.
Remove shipped short-name bonuses; explicit leader overrides belong to a
versioned, opt-in local profile keyed by stable identity.

**Acceptance / verification:**

- [ ] The dead-player score-26 reproduction produces no assignment.
- [ ] Remote rogue, last defender, carrier, ambiguous name and missing healer
  cases preserve coverage or explicitly expose an unfilled job.
- [ ] Each actor has one compatible objective job and at most one feasible
  local control responsibility; conflicting/immune control is rejected.
- [ ] Search-node budget exhaustion returns a feasible deterministic incumbent
  and diagnostics, never a partly valid assignment.
- [ ] Renaming an otherwise identical character does not change default scoring.

**Rollback:** disable local job optimization while keeping objective assignments
and explicit manual choices.

### OVR-05 — Stable commands with genuine start, deadline, and retirement

**Implementation:** extend Commander's existing ActivePlay lifecycle with one
command ID/revision, issued/start time, optional deadline, success/abort/fallback
and termination reason. Replace fixed `Go in 5` with a leader-started local
countdown or a qualified public event deadline. Without either, say “prepare”
or “on leader call.” Project remaining time; do not restart on refresh.
Keep existing KWR-280 terminal-reissue suppression and refine it with material
fact revisions, emergency invalidation and time-bounded retry rules.

**Acceptance / verification:**

- [ ] A countdown started at t=100 for five seconds shows 5,4,1,0 at t=100,101,104,105;
  a repaint/target event cannot reset it.
- [ ] Terminal play is recorded once and cannot reappear from unchanged failed facts.
- [ ] Score/capture/carrier invalidation cancels a stale play promptly even during dwell.
- [ ] Equivalent calls do not churn from ordering, timestamps or text-only changes.
- [ ] HUD, copy text, local audio, AAR and optional relay identify the same play
  revision; no GO call survives target loss or match completion.

**Rollback:** disable scheduled execution cues and keep stable untimed objective calls.

### OVR-06 — Explicit bracket and match state

**Implementation:** put bracket evidence and uncertainty in Sensors/TeamResolver:
STANDARD_RBG, BLITZ, UNRATED, TRAINING, UNKNOWN. Prefer a permitted explicit
client indicator. An observed 8+8 subset may be a hint, never a latched ruleset
decision without corroboration. Invalidate on contradictory evidence and use a
unique match/session generation through reload, map hydration and repeat queues.
Derive roster size, scoring, capture and assignment parameters from that context.

**Acceptance / verification:**

- [x] 8+8 then 10+10 standard roster never latches Blitz (KWR-284 source capture
  regression and interim extracted package, September 5; physical-client proof remains).
- [ ] Actual Blitz uses eight-player jobs and its own verified mechanics.
- [ ] Late joins, mercenary/cross-faction sides, reload, back-to-back same-map
  matches, unsupported map and interrupted match cannot reuse stale team truth.
- [ ] Unknown bracket does not authorize a bracket-specific winning clock.
- [ ] Publish a current supported-map/bracket manifest before advertising support.

**Rollback:** unknown/conservative mode if classification cannot be established;
never force standard or Blitz from roster size alone.

### OVR-07 — Client-build compatibility and field-level secret boundaries

**Implementation:** route volatile API calls through existing adapters; fix
Sentinel cast/channel tuple decoding separately. Validate presence, return shape,
secret status and permission before any comparison or formatting. Audit unit
existence/visibility/name, casts, aura instances, scoreboard/widget fields,
positions and message payloads. Fix Util:Call to preserve sparse multi-returns
with explicit result count, and return a bounded failure reason for diagnostics.
Bind active ruleset to sanitized GetBuildInfo/interface capability evidence;
bundled patch-string agreement alone is insufficient.

**Acceptance / verification:**

- [ ] Ordinary cast return 9 and channel return 8 resolve the right spell ID;
  protected fields yield no derived observation.
- [ ] Nil holes, absent APIs, errors, secret booleans/strings/numbers and partial
  rows cannot escape the adapter or become zero-score/ready facts.
- [ ] Unknown/new client build visibly degrades advanced inference.
- [ ] Existing direct StatusBar display remains legal and unpersisted.
- [ ] In-client taint/blocked-action checks pass; mock secret proxies alone do
  not constitute proof of Blizzard's actual restrictions.

**Rollback:** safe unknown-only adapter/ruleset fallback for affected fields.

### OVR-08 — Sentinel protocol correctness and optional promotion

**Implementation:** validate exact field set and types before `:match`, numeric
conversion or unescaping. Reject missing/extra/duplicate fields, malformed
percent sequences, control characters, invalid UTF-8, oversize payloads and
non-finite numeric values. Bound ingress work before session/roster processing;
preserve actual sender authorization, leader authority, sequence/epoch rules,
expiry and aggregate traffic limits. Fix the observer tuple bug from OVR-07.
Separate availability, observed control, assignment and acknowledged intent.

**Acceptance / verification:**

- [ ] Missing seq/ts in an eight-field packet returns a reject reason without
  throwing; rejection counters stay bounded under a flood.
- [ ] Round-trip both encoders/decoders with long cross-realm/localized names.
- [ ] Packet reordering, stale epoch, duplicate sender names, leader handoff,
  reload and same-map rematch never revive an old job.
- [ ] Blocked addon communication gives a visible local-only state and never a
  visible-chat workaround.
- [ ] Keep transport off by default. Ten physical-client proof is required only
  before promoting its remote capability, not for Commander-only value.

**Rollback:** transport disabled; keep a useful local execution card.

### OVR-09 — Measure real cost and call latency

**Implementation:** retain simulated-clock tests for accounting/backpressure and
label them explicitly. Add real host-time benchmarks with a pinned Lua runtime,
and client profiling from sanitized event arrival through publication and visible
HUD update. Measure Sensors, truth, combat, strategy, assignments, Store
reconciliation, subscribers, rendering, audio and transport separately.
Keep queue dwell distinct from CPU execution cost.

**Acceptance / verification:**

- [ ] Timing receipts state REAL_CLIENT, REAL_HOST or SIMULATED_CLOCK and never
  compare simulated values to Retail CPU/FPS gates.
- [ ] Report P50/P95/P99/max, queue depth/coalescing, deadline misses and sample count
  with candidate hashes, machine, client build, map/bracket and UI mode.
- [ ] Reproduce historical high-cost event patterns before optimizing.
- [ ] Include DevTools on/off overhead and whole-pipeline publication/render tail.
- [ ] No performance pass is achieved only by delaying needed calls.

**Rollback:** disable detailed profiling; keep low-cost operational error/age counters.

### OVR-10 — Reduce measured runtime work

**Implementation:** use OVR-09 profiles to prioritize hot paths. Build stable
identity indexes and domain revisions for objective, roster, combat, knowledge
and assignments. Replace blanket deep reconciliation with changed-domain
publication and explicit mutation ownership where benchmarks justify it.
Reuse unchanged formation, ruleset, capability, board and candidate projections.
Make subscriber delivery deterministic, skip hidden expensive renders, and
cancel stale scheduled generations. Preserve immediate critical-event handling.
Keep one lifecycle scheduler and one command decision owner.

**Acceptance / verification:**

- [ ] Burst tests execute at most the intended coalesced jobs; a relevant final
  event is never dropped.
- [ ] Tactical refresh preserves immutable strategic branches; UI subscribers
  cannot mutate prior snapshots.
- [ ] Idle/hidden/world states perform no full battleground strategy work.
- [ ] Optimized output matches baseline golden decisions, except approved fixes.
- [ ] Real measurements meet the budgets below without starving updates.

**Rollback:** bounded per-domain flags restore the previous pipeline; avoid
unreviewable all-at-once file rewrites.

### OVR-11 — Small runtime, explicit memory and persistence contracts

**Implementation:** preserve the recovered DevTools split in the authoritative
build. The installed-only hardcoded runtime projections were rejected during
KWR-281; generate any replacement compact indexes from canonical data with
consumer/API and semantic parity, rather than importing those files. Package
only what the player TOC actually uses, plus explicitly allowed assets/docs.
The installed folder still contains about 1.54 MB of full scenario/calibration/
Nexus corpus Lua outside the compact path; unused files cost package size, not
necessarily loaded Lua memory. Measure these separately. Use bounded ring buffers
for high-churn history; trim derived caches before essential live truth.
Version saved schemas and quarantine unknown future versions read-only.

**Acceptance / verification:**

- [ ] Commander works without DevTools; enabling it out of combat loads matching
  tooling; turning it off stops capture, and reload releases its code.
- [ ] Full corpus is excluded from player archives and compact projection parity
  is proved against the same source records.
- [ ] Player memory plateaus; default journal, notes and learned buckets meet
  documented count/byte caps without deleting the active match.
- [ ] Fresh install, Alpha 10/12 upgrade, malformed DB and future-schema downgrade
  preserve settings/history or show an explicit recovery path.

**Rollback:** previous schema reader and saved-variable backup; never repair a DB
by indiscriminately clearing it.

### OVR-12 — Marker timing, secure roster identity and visual cleanup

**Implementation:** accumulate the full elapsed interval before throttling
CursorRing work, or use absolute deadlines and retain remainder. Share one center
anchor for class/objective marker, badge and reticle. Preserve names/native health
by default; icon-only presentation is explicit. Secure row bindings and displayed
identity must remain coherent through combat, with changes queued and visibly
unavailable when binding cannot safely change. Keep plate pools bounded and
restore owned visual state on disable/removal/exit.

**Acceptance / verification:**

- [x] Retry cadence is within one update across 30/60/144 FPS over ten seconds
  (KWR-282 source and interim extracted smoke, September 5; live checks remain).
- [ ] Target acquire/loss/swap and plate-token reuse show the correct person,
  including friendly carriers, duplicate short names and role changes.
- [ ] Left/right clicks act on exactly the identity displayed; all attribute or
  secure layout mutations wait for combat end.
- [ ] No stale marker, duplicate KWR icon or stranded frame after repeated
  queues, reload, disable or resolution changes.
- [ ] Test Blizzard plates plus coexistence with installed UI addons; do not
  inspect or change third-party private state.

**Rollback:** marker OFF/tactical-only and ordinary secure roster presentation.

### OVR-13 — Finish each objective family as a state machine

**Implementation:** extend ObjectiveIntel/ObjectiveRules/Predictor in the existing
pipeline. Each objective has legal transitions, observation authority, freshness,
optional deadline, score contribution and completion state. Reconcile widget,
POI, permitted system-message and carrier evidence by field; localized text
is a fallback parser with fixtures, not the canonical key. Unknown/missing input
stays unknown. Use the map matrix below as the acceptance contract.

**Acceptance / verification:**

- [ ] Each supported map/bracket passes opening, lead, deficit, tie, transition,
  late-game, stale/conflicting input and match-end fixtures.
- [ ] Correct score race changes the plan before a capture becomes irreversible.
- [ ] Cart/resource/orb plans depend on their own mechanics, not generic node prose.
- [ ] Map sensors, objective UI, call, assignments and AAR agree at every checkpoint.
- [ ] Current queue membership and supported modes are documented separately
  from implemented historical map profiles.

**Rollback:** disable only the affected advanced map rule; retain authoritative
score/objective display and conservative manual assignments.

### OVR-14 — Route, reinforcement and resurrection feasibility

**Implementation:** replace shared straight-line travel constants with reviewed
per-map route edges, legal crossings, estimated time ranges, mounting/combat
assumptions and confidence. Consume observed location only when legally
available; otherwise use explicitly labeled map-route assumptions. Distinguish
fresh observed speed, estimated route and unknown reach. Couple arrival windows
to objective capture/cart deadlines and confirmed deaths/respawn observations.
Unknown resurrection-wave phase is not an exact countdown.

**Acceptance / verification:**

- [ ] River/elevation/long-route cases do not promise impossible arrivals.
- [ ] A candidate requiring unknown arrival certainty cannot beat a safe hold
  solely on guessed seconds.
- [ ] Estimates show a range/source; verified arrival may tighten the range.
- [ ] Carrier escort, wipe regroup and last-second rotations respect legal travel.
- [ ] Record actual arrival errors in qualified field reviews without inferring
  unobserved movement.

**Rollback:** coarse “near/rotation/unknown” estimates; no exact deadline promises.

### OVR-15 — Tactical depth through feasible alternatives

**Implementation:** extend existing Strategist candidate generation, Nexus policy
and Assignments response package. Filter illegal actions first; compare objective
value, time-to-score, protected defense, role availability, reserve, rotation cost
and reversibility. Add map-specific counter branches for mirror, overcommit,
stealth pressure, bait, wipe recovery and missed deadline. Preserve one primary
call, one fallback, one switch condition and a brief reason for rejecting the
next-best alternative. Simulation coverage does not add a win-probability bonus.

**Acceptance / verification:**

- [ ] Winning clock protects minimum control unless public evidence demands a change.
- [ ] Named movers/stayers, objective, success, abort and fallback exist for every
  selected tactical play.
- [ ] Missing facts reduce specificity; generic empty advice cannot pass as a
  complete map tactic.
- [ ] Role loss or failed opening yields a feasible recovery rather than reissuing
  the same failed attack.
- [ ] Different public states produce meaningfully different actions in held-out
  fixtures; prose variants are not counted as extra tactical depth.

**Rollback:** reviewed fundamental hold/defend/regroup policy remains available.

### OVR-16 — Current-patch knowledge that can be trusted

**Implementation:** review official changes since August 27; record applicability
to PvP, affected spell/spec/map and whether any tactical assumption actually
changes. Update SourceRegistry/PatchData/KnowledgeManifest with client build,
review date, reviewer, expiry and affected plan slices. Refresh an advisory RBG
snapshot only through the existing development review process. Version
capabilities, control profiles and composition shells separately from patch
compatibility. Missing/invalid freshness is ineligible, not a positive score.
Never import web text or infer individual talents from a population ranking.

**Acceptance / verification:**

- [ ] Every activated change has a source, reviewer, bounded rationale and regression.
- [ ] Unreviewed hotfixes flag affected slices; unrelated foundational rules
  remain usable without claiming new review.
- [ ] Historical spec, hero talent and meta assumptions remain labeled.
- [ ] Old patch/season/unknown-build data cannot silently affect advanced commits.
- [ ] Expert doctrine and observed outcomes remain separate from synthetic cases.

**Rollback:** quarantine affected slice and regenerate compact data; retain evidence.

### OVR-17 — Formation and roster jobs suitable for all leaders

**Implementation:** derive team size and role constraints from bracket. Extend
FormationAdvisor/Assignments/AssignmentOverrides with roster lock, target caller,
carrier/backup, healer anchors, defense minimum and reserve choices using existing
pages. Explain shortages and substitutions by capability, not character name.
Use existing composition shells as editable advisory templates; no guessed
talent availability or mandatory named-spec roster.

**Acceptance / verification:**

- [ ] Ten-player and supported eight-player rosters produce valid slot counts.
- [ ] Leaver, spec change, missing tank/healer and cross-realm duplicates produce
  clear shortages and reassignment options.
- [ ] Overrides persist only at their documented scope and cannot bypass dead/
  disconnected actors or create contradictory jobs.
- [ ] Pregame opening is usable with partial/unknown enemy compositions.

**Rollback:** generic capability formation and manual jobs remain available.

### OVR-18 — AAR that measures execution and learns conservatively

**Implementation:** append bounded decision episodes to existing AAR: command
ID/version, phase, bracket, doctrine version, public evidence, alternatives,
accepted/overridden status, observed execution and outcome window. Separate
“recommended,” “delivered,” “observed,” and “unknown.” A match win alone is not
proof a plan caused it. Restrict local adjustment to eligible comparable episodes;
include team/bracket/plan-version context, sample safeguards, bounded influence,
expiry and reset. Correct records must not count twice after review/reload.
Manual exports offer anonymized stable aliases with relationships preserved.

**Acceptance / verification:**

- [ ] Undelivered/unobserved recommendations and interrupted matches do not
  train execution quality.
- [ ] Patches, team changes, role composition and plan revisions do not pool
  incompatible outcomes.
- [ ] Small or contradictory samples do not override public objective feasibility.
- [ ] Player AAR remains compact; full diagnostics require DevTools opt-in.
- [ ] Export preview discloses scope, redacts identifiers by default when sharing,
  preserves links between facts/actors, and sends nothing automatically.

**Rollback:** learning adjustment zero; retain local review history read-only.

### OVR-19 — Calm command UX, accessibility and localization

**Implementation:** reuse Command Focus, Commander and Review modes. Prioritize
NOW / MY JOB / WHERE with a compact reason and explicit trust state. Put full
alternatives, evidence and diagnostics behind the existing explain/review views.
Provide one short first-run setup for role, UI scale, audio choice and movement/
lock/reset. Make audio cancellable/deduplicated by play revision and test native
combat-audio coexistence. Replace raw English protocol identity and byte clipping
with stable codes, localizable text and UTF-8-safe display truncation.

**Acceptance / verification:**

- [ ] Leaders identify next call and personal responsibility in at most five
  seconds in timed usability trials.
- [ ] 1080p, 1440p, 4K and UI scales 0.65/0.8/1.0 have no meaningful clipping,
  hidden buttons, overlap or unreadable essential text.
- [ ] High contrast and shape/text cues carry all critical states without color alone.
- [ ] Supported locales have tested parsers; unsupported ones visibly fall back
  to public widget/manual guidance instead of silently misreading messages.
- [ ] Player package instructions contain only working commands; developer-only
  commands explain the required companion.

**Rollback:** restore prior layout/profile preset; keep schema-compatible settings.

### OVR-20 — Replay and benchmark the code that will ship

**Current checkpoint (2026-09-07):** KWR-294 completed a fresh, hash-bound run
of all 2,003 fixtures on the dirty current source. The run has no forbidden
outputs but fails its decision contract (0 primary, 578 allowed fallback and
1,425 unmatched results). Treat this as an audit result, never as a passing
benchmark. KWR-295 must classify every discrepancy as an evaluator-normalization
defect, stale/incorrect fixture contract, or real planner behavior defect before
the clean-candidate and extracted-package runs are attempted.

**Current adjudication checkpoint (2026-09-08):** the contract queue contains
2,003 rows with zero named, evidence-backed adjudications. The 69 exact
navigation clusters identify 15 fallback-only and 54 unmatched contract patterns.
The observed concrete plans and their catalog tags are retained beside each
generic label token. This permits reviewer triage but does not authorize a
taxonomy equivalence, a fallback-only pass, a bulk relabel, or a benchmark score
change. KWR-295 remains in progress: engineering must trace representative
failures, repair proven evaluator/planner/label defects, test every affected
member and persist honest technical reviews. Independent tactical review remains
required quality evidence; it does not prevent offline diagnosis or coding.
Final verification requires clean source and extracted player package execution.

**Implementation:** run the actual decision boundary for every release acceptance
fixture from a clean candidate and the extracted production package. Generate
results afresh with source/package/input/label/engine hashes. The benchmark
must reject cached flags or incomplete sets. Use one canonical corpus; report
unique branches, evidence dimensions and adversarial coverage, not just 100,000
cases. Separate doctrine training/calibration from held-out labels. Add mutation
and metamorphic checks for roster order, missing facts, secret fields, stale
observations and supported bracket changes. Port all eight audit probes into
appropriate permanent tests.

**Acceptance / verification:**

- [ ] A one-line intentional regression in objective projection, cast index,
  unavailable-player exclusion or killable semantics fails the release gate.
- [ ] Fresh result count equals expected fixture set; missing/duplicate/stale
  hashes fail even if remaining results pass.
- [ ] Every advertised map/bracket/phase has legal, impossible, unknown,
  countered-plan and recovery cases with independently reviewed labels.
- [ ] No fabricated/illegal recommendation; no undocumented fallback-only “pass.”
- [ ] Source and extracted production decisions agree for all accepted inputs.

**Rollback:** block promotion and retain the prior certified fixture/package pair.

### OVR-21 — Prove field quality and comparative usefulness

**Implementation:** execute QA_CHECKLIST and the map matrix on candidate-bound
packages. Include commander-only, optional Sentinel, new leader and experienced
leader sessions. Compare against current KWR baseline and permitted native UI/
relevant current tools on equivalent scenarios; verify comparison-tool versions
at test time. Have two RBG reviewers label calls blind where practical.
Stratify by map/bracket, team composition, lead/deficit and observation coverage.

**Acceptance / verification:**

- [ ] Zero fabricated/impossible calls, Lua errors or KWR-attributable taint/
  blocked actions in the accepted sample.
- [ ] At least 90% of sampled calls are legal and tactically reasonable by review;
  disagreements are adjudicated with the underlying public facts.
- [ ] Report correct-action rate, harmful overrides, missed objective deadlines,
  unsupported reversals, useful warning lead time, five-second comprehension and
  live CPU/FPS/memory, including denominators and uncertainty.
- [ ] Retain the existing target of at least 20 complete reviewed matches per
  advertised map before claiming stable strategic certification for that map.
  Stratify bracket evidence; do not pool Blitz and standard into one certificate.
- [ ] Comparative tests show meaningful decision/clarity improvement without
  performance regression. Win rate alone cannot establish causality.
- [ ] No map family lacks both lead/win and deficit/loss evidence.

**Rollback:** keep uncertified maps/features explicitly prerelease; withhold
“leading” claims when comparison evidence is inconclusive.

### OVR-22 — Distribution and release end state

**Implementation:** use the canonical build/release tools after OVR-01, from a
clean reviewed commit. Pin Lua/Fengari and build dependencies (CI currently
installs an unversioned fengari-node-cli). Generate correct addon roots,
deterministic TOCs, interface support, versions, MIT/license/asset provenance,
public install guide, changelog and SHA-256 manifest. Exclude corpus, probes,
tests, internal reports and developer tooling from player archives. Repair
relative links to files that are intentionally absent from packages.
Ship Sentinel from the same source authority; DevTools is an optional matching
development artifact. Beacon/Maps/ScoreCard/bot remain separately versioned
and outside this release unless expressly added to the manifest.

**Acceptance / verification:**

- [ ] Two clean builds give identical archive hashes and pass extracted-runtime tests.
- [ ] Fresh install and upgrades from preserved baselines work with no missing
  TOC entries, double folder nesting, duplicate development addon or extra files.
- [ ] Exact install manifest, SavedVariables migration and rollback rehearsal pass.
- [ ] Version/channel, commit, checksums, supported client build and advertised
  map capabilities agree across all public assets.
- [ ] Actual public GitHub/CurseForge downloads resolve to the approved artifacts;
  announcement follows those receipts under RELEASE_POLICY.
- [ ] All required rows and field gates have evidence; no checklist is cleared
  because a previous alpha or generated corpus passed.

**Rollback:** restore the previous certified runtime packages and compatible
SavedVariables backup; issue a new version for repairs, never replace an old tag.

## Map-specific tactical acceptance matrix

These are the ten maps currently declared by the addon, not a verified current
rated queue pool. OVR-06 must decide which map/bracket combinations can be
advertised for the target release.

| Map | Specific command behavior to implement/verify | Required counter and end-state cases |
| --- | --- | --- |
| Arathi Basin | Minimum-base winning race, capture deadlines, anchor defenders, reserve and reachable cross-cap | 3-2 hold vs needed extra node; inc-cap tick flip; ghosted node; standard/Blitz rule separation |
| Battle for Gilneas | Two-base hold, named defense, pressure at the third node only when the clock demands it | Enemy overload, reserve reinforcement, defender death, losing-clock all-in with abort |
| Deepwind Gorge | Wide-rotation travel cost, split coverage and score-race breakpoints | Impossible long rotation, defend-before-cross-cap, partial widget loss; separate Blitz evidence |
| Eye of the Storm | Tower count vs actual flag value and delivery feasibility | Mid-fight trap, tower trade, flag turn-in changes; standard/Blitz active-objective differences |
| Warsong Gulch | Flag possession state, return-and-cap synchronization, offense/defense split | Both flags out, dropped/returned/captured, unknown carrier, final-cap discipline and tie/time rules |
| Twin Peaks | Same flag contract with map-specific routes and carrier support | River/elevation route choice, wipe regroup, countered carrier path, canonical carrier target text |
| Temple of Kotmogu | Orb possession/zone value, qualified carrier pressure, replacement pickup | Loose orb, center overcommit, multiple carriers, protected/unknown-health carrier; no invented survival timer |
| Silvershard Mines | Cart control/progress/route deadlines, named escort and reachable denial | Abandon exhausted route, contest before delivery, cart split, turnover and unknown progress |
| Deephaul Ravine | Own-cart escort vs enemy-cart conversion and conditional crystal value | Crystal distraction, simultaneous objectives, unreachable interception and cart reset |
| Seething Shore | Spawn/channel/collection/exhaustion cycle, arrival race and denial | Failed spawn play retires, exhausted node exits, message reorder/locales and ambiguous spawn location |

For each row: test public transition truth first, then prediction, assignment,
command, display and AAR agreement. All exact timers require a verified source
and appropriate bracket rule. Unknown position cannot create an enemy map dot.

## Performance and responsiveness release budgets

These are engineering acceptance targets, not measurements from this audit.
Retain the existing strategic/FPS/memory objectives; add tactical and delivery
metrics so backpressure cannot create a misleading performance pass.

| Metric / scope | Acceptance target | Measurement rule |
| --- | --- | --- |
| Strategic computation | P95 <2 ms; no routine refresh >4 ms | Real client stage timing; record loading/transition outliers separately, never delete them |
| Tactical computation | P95 <=1.5 ms | Proposed added budget; benchmark actual local-fight workload before tuning |
| Store + visible subscriber work | P95 <=1.5 ms per scheduled batch | Include reconciliation and frame work; record total end-to-end time as well |
| Critical public fact to displayed call invalidation | P95 <=250 ms | Event timestamp through publication/render under event storms |
| Ordinary tactical update | P95 <=750 ms | Include queue wait; no stale target/control after invalidation |
| Normal full strategy frequency | <=4 per second; idle much lower | Critical correctness cannot be dropped to meet frequency cap |
| FPS impact | Median loss <1%; 1% low loss <3% | Repeated matched native/KWR runs, same settings/addons/hardware; report variance |
| Player-addon memory | Current soft/warn/hard 25/28/32 MB; plateau | Report loaded player code and retained data separately from DevTools and disk bytes |
| Growth | <1 MB over 30 minutes after comparable GC/warm-up | No forced full collection in combat to manufacture a pass |
| Default SavedVariables | <=1 MB serialized | Current bounded 8-match default, not the obsolete 30-match claim |
| Lifecycle | No BG strategic ticker outside BG; bounded pools/queues | Ten queue/exit/reload cycles plus 30-minute combat |
| Safety | Zero KWR-attributable taint/blocked actions/errors | Current client, clean and representative addon profiles |

Do not relax a budget to make old evidence green. If a requirement is infeasible,
record a measured proposal and product tradeoff before changing this table.

## Tactical quality benchmark

Use the following scorecard for each supported map/bracket, with per-case labels.
Safety and feasibility are hard gates; aggregate scores cannot compensate for
a fabricated fact or assigning a dead actor.

| Dimension | Evidence to retain | Pass rule |
| --- | --- | --- |
| Truth | Source, observed age, conflict/unknown fields | No authority upgrade from selection, formatting or refresh |
| Feasibility | Who is available, minimum defense, route/capability requirements | No impossible action or abandoned mandatory objective |
| Decision value | Primary, rejected alternative, objective payoff and fallback | At least 90% reviewer-acceptable sample; zero fabricated/impossible cases |
| Timing | Issue, delivery, actual start/deadline, abort | Critical changes meet latency; no artificial five-second restart |
| Stability | Semantic switches, reasons, reversals, time-to-first-move | Zero switches/reissues on invariant truth fixtures; real emergencies allowed |
| Communication | Timed comprehension, personal role accuracy, audio usefulness | Call and personal job understood within five seconds |
| Learning | Delivered/observed outcome and review provenance | Only eligible comparable evidence changes bounded local bias |

Review at least 30 distinct held-out decisions per advertised map/bracket
across all five phases before the field gate. This is a minimum test design,
not evidence of statistical superiority. Record confidence intervals and
reviewer disagreements for comparative claims. Do not use generated outcomes
as actual wins, simulated case counts as confidence, or self-generated labels
as independent expert validation.

## Execution, verification and completion rules

Start **OVR-01 and OVR-09**, then fix **OVR-02 through OVR-07** before tactical
expansion. OVR-08 can proceed independently once adapter contracts settle.
Prepare packaging checks early; then close the remaining failures in the frozen
release scope, following the release-first priority above. Complete benchmark,
live validation and final package certification before the stable milestone.
All audited tactical depth is implemented before field handoff. One overhaul is delivered as
bounded, reviewable changes within this single backlog.

For each task, use the existing docs/tasks contract format when implementation
starts: owner, priority, risk, dependencies, affected modules, objective/user
outcome, current/required behavior, non-goals, constraints, acceptance,
verification and rollback. Link the OVR row and relevant findings instead of
creating another roadmap. Existing KWR-280 work feeds OVR-01/05/09/10/18.

Task status lifecycle: OPEN -> IN_PROGRESS -> IMPLEMENTED_OFFLINE ->
FIELD_VERIFIED (when applicable) -> RELEASE_VERIFIED. An implementation checkbox
cannot clear a live or distribution gate. Store evidence in existing
knowledge/artifacts/CI paths with candidate hashes and exact command results.

Run focused regressions after each change. The final candidate must run the
existing full certification path from the recovered canonical source:

```powershell
./tools/validate.ps1
./tools/knowledge-audit.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./tools/test-lua.ps1 -Suite All
./tools/security-audit.ps1
./tools/test-automation.ps1
./tools/certify-offline.ps1 -OutputDirectory <fresh-candidate-output>
./tools/build.ps1 -IncludeSentinel -OutputDirectory <fresh-build-output>
```

Use actual unique output paths in place of placeholders. Pin runtimes before
certification. OVR-20 adds fresh complete-replay and extracted-runtime result
binding to these existing tools; the current commands alone do not cover the
new audit defects or prove live speed. Avoid duplicate builds when certification
already produced the exact artifacts needed.

The overhaul is complete only when all P0 and required P1 outcomes are evidenced,
every advertised feature/map has the stated proof, documentation and packages
agree, and rollback works. Publication follows the existing release policy.
Writing this plan, passing mocks, or distributing another alpha is not that end state.
