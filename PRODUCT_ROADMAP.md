# KWR 10/10 Product Roadmap

## Roadmap context

`PROJECT_HANDOFF.md` is historical context only. This roadmap is the sole
authority for future priorities; release decisions remain in
`RELEASE_READINESS.md`. The work remains an additive combat-clarity and
decision-quality program, not an architecture rewrite.

The active execution order is the Season 2 workflow below. Earlier feature
lists remain design context, but they do not create separate backlogs or task
authorities.

The seventeen-feature suggestion package is dispositioned in the handoff.
Concept names do not authorize seventeen new runtime engines or UI surfaces.

## Active Season 2 enhancement workflow

```yaml
id: KWR-S2-001
title: Season 2 decision quality and tactical marker convergence
owner: project maintainer
priority: critical
risk: high
dependencies:
  - Retail 12.1 public API behavior
  - reviewed Season 2 doctrine
  - live battleground evidence
affected_modules:
  - knowledge
  - Data
  - Intelligence
  - Runtime
  - Features/CursorRing.lua
  - UI/Options.lua
  - tests
  - tools
```

### Objective

Deliver one fast, evidence-bounded Season 2 command system that can select,
explain, switch, and review specific RBG plans while presenting friendly,
objective, and target identity through one clean nameplate marker stack.

This section is the only active Season 2 implementation plan. Do not create a
new roadmap, marker plan, corpus plan, launch checklist, or task-list Markdown
file. Durable release truth remains in `RELEASE_READINESS.md`; completed user-
visible work is summarized in `CHANGELOG.md`. Machine evidence belongs in the
existing `knowledge/`, `artifacts/`, test, or CI outputs rather than new status
documents.

### Current baseline and interpretation

The repository currently declares:

- ten supported RBG map profiles;
- 2,003 replay fixtures, 2,001 golden labels, 2,000 replay results, 2,000
  outcome reviews, and 201 adversarial cases in the corpus manifest;
- 5,000 Season 2 deterministic simulation cases: 500 per map and 100 per phase
  for `OPENING`, `STABILIZE`, `PRESSURE`, `RECOVERY`, and `ENDGAME`;
- those 5,000 Season 2 cases as `SIMULATION_ONLY` and
  `OFFLINE_COVERAGE_AND_REGRESSION_ONLY`.

The 5,000 cases are an existing coverage target, not 5,000 independent proofs
that a tactic wins. They must not affect live plan scoring merely because they
exist. One normalized scenario case is the truth record; the scenario matrix,
coverage totals, calibration tables, compact Lua data, and audit reports are
derived views of those records. No mirrored hand-maintained corpus and matrix
copies are allowed.

### User outcome

During a match the leader should receive one legal, map-specific command that
states `NOW`, `WHO`, `WHERE`, `WHEN`, `WHY`, `SWITCH IF`, and `DO NOT`, plus one
fallback. The marker under the current-target crosshair should identify the
player or public objective instantly without competing panels, duplicate icons,
or unsupported claims.

Outside a match the same knowledge should help form a team, preview openings,
review alternatives, and turn AAR evidence into bounded future improvements.

### Non-goals

- No automatic target, focus, chat, movement, spell, macro, or protected action.
- No arithmetic, comparison, persistence, or inference from secret values.
- No claim that simulated, meta, or stale doctrine is live observation.
- No giant list of prose strategies selected by keyword.
- No second fact store, decision engine, nameplate tracker, or marker state.
- No bundled copy or unreviewed reuse of third-party addon code or artwork.
- No dependency on, bridge to, detection of, or private hook into another
  nameplate addon. KWR owns its complete native marker stack.

### One scenario truth model

Each canonical scenario record must contain or explicitly mark unknown:

```text
caseId and deterministic contentHash
schemaVersion, gamePatch, season, doctrineVersion
mapKey, mapFamily, phase, scoreBand, clockBand
public objective state and legal transition
our composition capability vector
enemy composition capability vector
available players, deaths, disconnects, and role ambiguity
observed pressure, travel, resurrection, and timing evidence
candidate plan, required capabilities, and rejected alternatives
NOW / WHO / WHERE / WHEN / WHY
success condition, switch trigger, stop rule, and fallbackPlanId
expected assignments and target/CC posture
uncertainty and contradiction cases
provenance, reviewer status, review notes, and expiry
outcome window, observed result, override reason, and AAR label
activationStatus and invalidatedBy
```

The minimum deduplication identity is the normalized combination of map,
phase, public state, our capability vector, enemy capability vector, candidate
plan version, and evidence boundary. Records that differ only in wording are
duplicates. Records that intentionally test a different uncertainty,
counter-response, timing, or outcome branch must name that dimension.

### Ideal 5,000-case coverage matrix

Maintain exactly 500 canonical Season 2 cases per supported map and exactly 100
per phase per map. The generator must balance, report, and fail on missing or
overrepresented dimensions rather than generating near-identical sentences.

Within every map and phase, cover all of the following axes:

- safe default, favorable, unfavorable, tied, and emergency score/clock states;
- balanced team fight, rot/attrition, melee collapse, ranged control,
  stealth/cross-cap, high-mobility rotation, bunker, anti-caster, anti-melee,
  and explicitly enabled off-meta composition archetypes;
- expected enemy response, unexpected counter, bait, failed opening, wipe,
  leaver/death, delayed reinforcement, impossible travel, and stale evidence;
- objective-specific success, partial success, failure, stop, switch, and
  fallback branches;
- live-known, observed, derived, meta-only, contradictory, expired, and unknown
  evidence states;
- legal assignment availability, healer/tank/carrier loss, reserve depletion,
  and reassignment pressure.

Map-family coverage must remain specific:

| Family | Required decision coverage |
| --- | --- |
| Node | stable shell, defender sufficiency, incoming response, cross-cap, ghosted node, capture/clock feasibility |
| Flag | carrier route, offense/defense split, return-and-cap, stack/public state, bunker break, reset and final-cap discipline |
| Hybrid | tower count, useful flag value, mid allocation, tower-versus-flag trade, impossible delivery rejection |
| Orb | carrier value, replacement pickup, center exposure, loose orb, carrier kill/protection, survival uncertainty |
| Cart | live/dead route, escort/delay, checkpoint or turn-in risk, secondary objective cost, reachable rotation |
| Resource | public spawn/channel state, arrival race, split safety, exhausted-node exit, regroup and denial |

The coverage matrix is generated from canonical records and reports counts and
gaps. It is not edited as an independent strategy source.

### Evidence and activation lifecycle

Every record advances through explicit states:

1. `SIMULATION_ONLY`: deterministic regression coverage; zero live scoring
   influence.
2. `DOCTRINE_REVIEWED`: legal and tactically coherent according to two expert
   reviews, or one expert review plus supporting reviewed match evidence;
   eligible as a curated baseline only.
3. `FIELD_OBSERVED`: exercised with matching public state in live play and
   linked to a sanitized AAR outcome; still bounded by sample safeguards.
4. `PROMOTED`: passes audit, replay, adversarial, calibration, expiry, and
   decision-quality gates; may influence live candidate scoring within the
   authority hierarchy.
5. `QUARANTINED` or `RETIRED`: tuning, API behavior, contradictory outcomes,
   unsafe evidence, or doctrine replacement prevents live use.

Activation is by versioned plan slice, never by bulk count. A promoted record
may adjust only a legal candidate whose required live facts are satisfied.
Meta, doctrine, and learned history remain tie breakers and may not override a
public score, objective state, timer, impossible route, or missing capability.

### Tactical nameplate and crosshair convergence

`Features/CursorRing.lua` remains the owner of the tactical marker model and
target reticle. Extend it or a narrow adapter behind it; do not create another
nameplate engine with separate target or assignment state.

The visual stack, back to front, is:

1. optional native friendly identifier marker: circular class icon;
2. public objective override: flag/orb carrier icon with a distinct gold ring;
3. compact role or KWR assignment badge: healer, tank, defend, strike, escort,
   rotate, or reserve;
4. current-target reticle: target, focus/kill, swap, carry, must-stop cast, or
   observed defensive state;
5. short text only when it changes the action; never duplicate full roster or
   command-card prose over a nameplate.

Marker truth priority is public objective, observed role/class identity,
authoritative KWR assignment, observed tactical state, and presentation-only
styling. Unknown identity uses a neutral marker. An unobserved enemy role,
location, cooldown, health state, assignment, or objective state is never
invented.

Rendering modes:

- `KWR_NATIVE` (default): KWR renders the base identifier, badge, and tactical
  reticle with no third-party dependency.
- `TACTICAL_ONLY`: KWR preserves its own base identifier setting and renders
  only the KWR reticle and explicitly enabled tactical accents.
- `OFF`: no KWR nameplate rendering.

The default must preserve existing health bars and names. Icon-only friendly
plates are an explicit setting. KWR must not silently alter another addon's
settings, hook its private implementation, or assume it is installed. If a
user wants KWR's standalone marker experience, they disable any other addon
that is separately replacing the same nameplate visual.

All marker frames are non-interactive, pooled or reused, bounded to visible
nameplates, and created/configured without protected combat mutations. Updates
are event-driven with a capped safety refresh. Plate removal, target loss,
instance exit, feature disable, UI reload, and addon compatibility changes must
restore or hide KWR visuals without leaving stale markers. The reticle and base
marker share one center anchor so the crosshair remains cleanly concentric at
all supported scales.

### S-tier enhancement sequence

Implement in this order so strategy volume cannot hide correctness defects:

1. **Truth and safety:** consolidate schemas, authority, expiry, secret-value
   handling, combat safety, and duplicate rejection.
2. **Marker clarity:** converge KWR's identifier, assignment badge, objective
   icon, and crosshair on one anchor with native, tactical-only, and off modes.
3. **Corpus quality:** audit the 5,000 cases for unique decision branches,
   coverage balance, legal mechanics, provenance, and review state.
4. **Decision depth:** generate legal candidates, score composition/map/timing
   fit, apply counters, publish one call plus fallback, and explain rejected
   alternatives.
5. **Adaptive switching:** respond to public objective changes, player
   availability, enemy counterplay, failed success windows, and stop rules
   without oscillation.
6. **Performance:** domain invalidation, event-driven refresh, pooled visuals,
   bounded buffers, hidden-view suspension, and measured CPU/memory budgets.
7. **Learning and AAR:** record plan outcome and leader override, require review,
   apply minimum-sample limits, and quarantine patch-stale evidence.
8. **Release usability:** pre-gate opening brief, Command/Learning density,
   readable explanations, clean installation, compatibility tests, packaging,
   and rollback proof.

### Implementation workflow and exit gates

#### Gate 0: Baseline lock

- Record current validation, knowledge audit, smoke, soak, build, package hash,
  runtime performance, taint, and visual evidence.
- Confirm the current release remains recoverable before changing schemas or
  marker behavior.

Exit: reproducible baseline and rollback package exist; no unknown failing test
is reclassified as an enhancement.

#### Gate 1: Schema and generator convergence

- Establish the canonical scenario schema and lifecycle fields.
- Generate matrix coverage, compact Lua, calibration, manifest totals, and
  hashes from canonical cases.
- Reject duplicate IDs, duplicate normalized hashes, dangling plan links,
  contradictory activation states, stale patch data, and unreviewed promotion.
- Preserve schema migration for existing reviewed evidence.

Exit: one source produces all derived artifacts deterministically, two clean
builds have identical content hashes, and no hand-edited mirror remains.

#### Gate 2: Corpus quality pass

- Audit exactly 500 cases per map and 100 per phase.
- Replace wording variants with distinct counter, evidence, outcome, or timing
  branches.
- Review map mechanics, composition requirements, stop/switch conditions, and
  fallbacks.
- Keep all unreviewed Season 2 forecasts simulation-only.

Exit: coverage audit is green, all records explain their unique decision
dimension, and every promoted slice meets the evidence lifecycle.

#### Gate 3: Marker convergence

- Implement the shared plate anchor and render modes.
- Correct frame level, scale, offsets, overlap, stale cleanup, and target
  transition behavior.
- Add objective, role, assignment, and neutral-unknown visuals using existing
  KWR icon/theme assets or Blizzard-provided assets.
- Verify KWR's marker independently with Blizzard default plates and confirm
  that it neither detects nor modifies any third-party nameplate addon.

Exit: the class/objective marker remains readable beneath a concentric KWR
crosshair, no duplicate KWR marker appears, and disabling the feature restores
the prior plate presentation.

#### Gate 4: Decision integration

- Feed only eligible reviewed records into existing candidate generation and
  scoring.
- Prove that required facts, impossible travel, missing capabilities, expiry,
  and public objective truth filter candidates before scoring.
- Publish one primary call, one fallback, one switch trigger, and one stop rule.
- Record which live facts and reviewed records influenced the choice.

Exit: every supported map/phase returns a legal specific call or an explicit
`UNKNOWN`/safe fallback; no generic filler can be selected as a live command.

#### Gate 5: Deterministic and adversarial verification

- Replay all canonical cases through the same decision boundary used by live
  runtime.
- Test stale, missing, contradictory, secret, malformed, and out-of-order input.
- Test deaths, disconnects, role ambiguity, target changes, addon-message loss,
  and incompatible plate ownership.
- Compare selected plan, assignments, timing, fallback, switch behavior,
  explanation, and confidence against reviewed golden labels.

Exit: zero fabricated or illegal calls; zero promoted-case schema/audit errors;
all safety, smoke, soak, and benchmark thresholds pass.

#### Gate 6: Live field verification

- Test clean install and upgrade with fresh and migrated SavedVariables.
- Exercise native, tactical-only, and off marker modes at 1080p, 1440p, and 4K
  across common UI scales.
- Run each supported map with Commander only, Commander plus local Sentinel,
  Commander plus remote Sentinel, and relevant nameplate-addon combinations.
- Capture `/kwr verify`, `/kwr bug`, AAR, screenshots, CPU/memory samples, taint
  logs, and transport receipts where applicable.
- Label incorrect, late, generic, oscillating, or ignored calls; never convert a
  smooth run into proof of strategic correctness without the corresponding AAR.

Exit: no Lua errors, blocked actions, taint, stale markers, overlapping tactical
surfaces, transport safety defect, or unbounded resource growth; field evidence
meets the human acceptance and performance budgets below.

#### Gate 7: Promotion and release

- Promote only reviewed plan slices supported by their evidence.
- Regenerate manifests, compact data, hashes, changelog, release readiness, and
  certified Commander/Sentinel packages from the same commit.
- Verify clean package roots, TOC loading, version parity, GitHub artifact,
  CurseForge artifact, Discord release text, and rollback package.

Exit: CI and certification are green for the release commit; public artifacts
match certified hashes; `RELEASE_READINESS.md` records remaining refinement as
non-blocking or identifies an actual release blocker. No obsolete TODO,
historical hold, or duplicate roadmap remains active.

### Automated verification commands

Run the focused generators and audits during development, then the complete
gate from a clean checkout:

```powershell
./tools/build-season2-rbg-simulation-corpus.ps1 -CasesPerMap 500
./tools/corpus-audit.ps1
./tools/knowledge-audit.ps1
./tools/decision-benchmark.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1
./tools/validate.ps1
./tools/build.ps1
```

The final automation must additionally assert:

- 10 maps, 500 canonical cases per map, 100 per phase, and 5,000 total;
- zero duplicate IDs and zero duplicate normalized content hashes;
- zero dangling plan, fallback, counter, assignment, or source references;
- zero `SIMULATION_ONLY`, expired, unreviewed, or quarantined records compiled
  into live scoring data;
- deterministic generation and package hashes from identical inputs;
- standalone marker mode defaults, cleanup, and target-state transitions;
- zero secret-value arithmetic/comparison and zero protected-frame mutation;
- bounded refresh counts, buffers, addon-message packets, and SavedVariables.

### Live proof matrix

Completion requires retained evidence for these observable cases:

| Area | Required proof |
| --- | --- |
| Identity marker | friendly class, healer, tank, unknown, and objective carrier render correctly |
| Crosshair | target acquire/loss/swap, kill/focus, carry, cast-stop, defensive, and neutral states stay centered |
| Standalone ownership | KWR works with Blizzard plates alone and neither detects nor changes any other nameplate addon |
| Cleanup | plate removal, death, target loss, instance exit, reload, and disable leave no stale visual |
| Strategy | opening, stable lead, pressure, recovery, endgame, countered plan, failed plan, and fallback are map-specific |
| Truth | missing, stale, contradictory, secret, and impossible inputs fail closed without invented advice |
| Sentinel | authorized assignment/action relay and observation receipt match the Commander session and expire safely |
| Performance | visible and hidden UI, 10-player combat, marker churn, 30-minute match, and repeated matches remain within budget |
| Packaging | clean install loads every TOC file; Commander/Sentinel versions and public archive hashes match |

### Completion thresholds

Season 2 enhancement is complete only when all of the following are true:

- automated gates are green from a clean checkout and clean SavedVariables;
- the 5,000-case matrix is balanced, unique by decision dimension, and generated
  from one canonical corpus;
- every live-active plan is reviewed, versioned, sourced, unexpired, linked to a
  legal fallback, and traceable in explanations/AAR;
- every supported map has deterministic opening, tied, winning, losing,
  emergency, counter, stop, and fallback coverage;
- expert reviewers judge at least 90% of sampled calls legal and reasonable;
- a leader can identify the call and reason within five seconds;
- zero impossible, fabricated, or generic filler calls appear in the acceptance
  sample;
- marker/crosshair behavior passes the full live proof matrix without overlap,
  stale state, duplicate ownership, taint, or blocked actions;
- strategic refresh p95 is below 2 ms with no routine refresh above 4 ms,
  median FPS loss is below 1%, 1% low FPS loss is below 3%, and post-GC memory
  growth is below 1 MB over a 30-minute match;
- a minimum of 20 complete reviewed beta matches per map is accumulated before
  stable strategic certification for that map; smaller samples remain beta or
  refinement evidence and cannot be relabeled as complete;
- the certified package, public distribution artifact, release announcement,
  changelog, and `RELEASE_READINESS.md` all identify the same commit and hashes.

### Rollback

Marker rendering is reversible through its mode setting and feature flag.
Knowledge activation is reversible by quarantining the affected plan/doctrine
version and regenerating compact live data without deleting source evidence.
Schema changes retain the previous reader until the migration and clean-install
matrix passes. A release rollback restores the last certified Commander and
Sentinel archives together; partial component rollback is not allowed when the
transport or shared command contract changed.

## Command experience doctrine

KWR should present information in three layers:

1. **Always visible:** the current win path, the one action required now, the
   player's own job/location, and an urgent local kill or peel target.
2. **Visible when changed:** objective transitions, clock flips, incoming
   captures, assignment failures, resurrection/flag/capture timers, and the
   short reason the command changed.
3. **Available on demand:** complete rosters, raw evidence, alternatives,
   doctrine, history, meta context, diagnostics, and learning detail.

Primary surfaces must answer:

- **Scout HUD:** What wins, what do we do now, what do I do, and who is the
  urgent local target? Do not repeat the same call in multiple cards.
- **Reporter mini map:** Which objective is changing, how long remains, where
  is the observed pressure, and what is my assigned area? Movement paths are
  shown only when public, recent, and decision-relevant.
- **Tactical board:** What changed, what is the projected outcome, which plan
  is active, who moves, when must they arrive, and what causes the next switch?
- **Objectives:** Ownership, active transitions, scoring clocks, minimum
  control required, and mechanic-specific timers. Widget IDs and raw API
  source names remain in verification exports.
- **Team:** Player, specialization, effective role, health/state, battlefield
  job, and assignment location. Raw map coordinates are not commander data.
- **Enemies:** Healers, tank/carrier, locally actionable target, visible
  health, last observation, and only proven defensive/trinket use. Meta rank
  and unobserved readiness must not dominate live decisions.
- **Assignments:** One player, one battlefield job, one location, readable
  priority words, and a visible backup/reassignment need when someone is dead
  or unavailable.
- **Intel/AAR:** Pregame preparation and postgame learning. It should not
  compete with live combat attention.

The next high-value mechanic work is public-data timing: node capture windows,
flag debuff/return state, resurrection waves, cart progress/turn-in pressure,
orb carrier value, and Seething Shore spawn/channel state. Each must remain
unknown when Blizzard does not safely expose it.

## Product target

Knomercy War Room should be a lightweight, trustworthy RBG decision assistant
that helps a new leader answer four questions:

1. What is the current win condition?
2. What should the team do next?
3. Who should do it, and when?
4. What evidence would make us change the call?

The addon must feel intelligent because it evaluates alternatives, explains its
choice, recognizes counters, and learns from reviewed outcomes. It must never
pretend to know protected information or imply that an uncertain inference is a
live fact.

## Non-negotiable boundaries

- No network access from the addon.
- No automatic chat, targeting, focus, casting, keybinding, or macro execution.
- Secure target/focus and fixed quick-call actions remain explicit hardware-click
  actions prepared out of combat.
- Secret combat values may be displayed only through permitted Blizzard widgets;
  they never enter arithmetic, comparisons, persistence, or decisions.
- Every fact carries source, observation time, confidence, and expiry.
- Live authoritative facts outrank predictions, meta, and learned preferences.
- Missing evidence produces UNKNOWN or a conservative fallback, never invented truth.
- External data is acquired during development, reviewed, versioned, and compiled
  into a small release data pack.

Blizzard's Midnight addon policy explicitly distinguishes information that can
be displayed from information an addon may computationally know:

https://worldofwarcraft.blizzard.com/news/24246290/combat-philosophy-and-addon-disarmament-in-midnight

## Target architecture

### 1. Fact layer

Maintain one compact fact registry keyed by domain:

- match phase and timer;
- public score and objective ownership;
- incoming, contested, carrier, cart, orb, and resource state when public;
- friendly roster, role, death, connection, and safe position;
- enemy scoreboard identity;
- safe visible/last-seen enemy evidence;
- observed combat-log spell events;
- manual leader marks and notes.

Each fact uses:

```text
value
source
observedAt
expiresAt
confidence
authority = LIVE | OBSERVED | DERIVED | META | LEARNED
```

No lower authority may overwrite a higher authority.

### 2. Capability knowledge base

Create a generated repository for every specialization:

- role and battlefield archetypes;
- mobility, stealth, spin, flag-carry, peel, burst, sustain, and disruption tags;
- dispel, purge, mortal-wound, immunity, external-defense, knockback, and control tags;
- important observed cooldown IDs and baseline windows;
- map-role suitability;
- known strengths, weaknesses, and counter categories;
- patch, season, provenance, and review status.

This repository describes specialization capabilities. It must not claim that a
particular player selected a talent or owns an item unless that fact was safely
observed.

### 3. Composition repository

Represent a team composition as capabilities rather than a tier-list string:

```text
roles: tank/healer/damage counts
specCounts
melee/ranged balance
stealth count
rot pressure
team-fight pressure
single-target burst
anti-heal
purges/dispels
peel and crowd-control coverage
immunity and external-defense coverage
flag-carry strength
base-defense strength
mobility and rotation speed
```

Store reusable archetypes:

- standard balanced team fight;
- rot/attrition;
- melee collapse;
- ranged control;
- stealth/cross-cap;
- high-mobility rotation;
- flag-carry bunker;
- anti-caster;
- anti-melee;
- off-meta compositions with explicit enabling conditions.

Every archetype includes advantages, liabilities, favorable maps, unfavorable
maps, required capabilities, counters, and confidence.

### 4. Battle-plan repository

Plans are executable doctrine records, not paragraphs:

```text
planID
map and objective family
our composition requirements
enemy composition triggers
score/phase prerequisites
assignment slots
opening
next action
success condition
switch trigger
stop rule
fallback plan
counter-plan links
source and review version
```

Each map needs:

- two or more meta plans;
- at least one safe default plan;
- viable off-meta plans;
- counter-plans against each major composition archetype;
- opening, winning, tied, losing, and emergency branches;
- explicit stop rules that prevent low-value fighting.

### 5. Decision engine

Use a deterministic candidate-and-score engine:

1. Generate legal plans for the current map and phase.
2. Remove plans whose required facts or team capabilities are absent.
3. Score remaining plans using win-path impact, travel feasibility, local
   numbers, resurrection timing, composition fit, counter risk, and confidence.
4. Apply observed enemy counterplay.
5. Select one call and one fallback.
6. Publish NOW / WHO / WHEN / WHY / SWITCH IF / DO NOT.

Suggested score:

```text
planScore =
    winPathImpact
  + objectiveUrgency
  + ourCompositionFit
  + enemyWeaknessFit
  + localNumbers
  + timingFeasibility
  + reviewedLocalSuccess
  - travelRisk
  - counterRisk
  - uncertaintyPenalty
```

Meta and learned history are tie breakers. They never override an authoritative
score, objective, timer, or impossible travel constraint.

### 6. Counter engine

Produce counterplay at three levels:

- Composition: what our team should emphasize against their archetype.
- Map: where that advantage should be converted into score.
- Local fight: which safely observed target or defensive window is actionable.

Examples of valid reasoning:

- "They lack stealth coverage; protect three and float early to the exposed side."
- "Their composition wins long team fights; avoid the sustain node and create a
  rotation race."
- "Their carrier bunker has two externals observed on cooldown; collapse during
  this window."

Invalid reasoning:

- inferring an unobserved talent from the current meta;
- comparing secret enemy health;
- claiming an unseen player is at a location;
- treating a baseline cooldown expiry as proof that the spell is ready.

## Map-engine completion plan

### Node maps

Arathi Basin, Battle for Gilneas, and Deepwind Gorge:

- exact tick curves and capture durations;
- owned, incoming, assaulted, and contested states;
- projected clocks for plausible control transitions;
- minimum-control requirement;
- defender coverage and nearest safe rotation;
- ghosted-node and over-rotation warnings;
- resurrection-wave and travel-time feasibility.

### Eye of the Storm

- combine tower tick rates and flag value;
- model flag value at each tower count;
- compare tower capture versus flag-delivery paths;
- account for flag possession and plausible delivery timing;
- never recommend a flag play that cannot alter the projected result.

### Flag maps

Warsong Gulch and Twin Peaks:

- match time, score, final-cap tiebreak, carrier state, and public stack state;
- offense/defense split recommendations;
- return-and-cap synchronization;
- carrier route and resurrection-wave timing when safely observable;
- bunker-break windows from observed externals, immunities, and trinkets.

### Temple of Kotmogu

- orb ownership and public scoring state;
- replacement pickup, center-value, and carrier survival plans;
- target priority among safely observed carriers;
- avoid fabricated carrier health or hidden position.

### Cart maps

Silvershard Mines and Deephaul Ravine:

- active route, ownership, progress, turn-in risk, and next rotation;
- distinguish recoverable carts from dead routes;
- escort, delay, and secondary-objective opportunity costs.

### Seething Shore

- active and upcoming public spawn state;
- channel protection and denial;
- arrival feasibility and exhausted-node abandonment;
- safe split versus required regroup.

## Lightweight runtime plan

### Split the pipeline by cost

Fast lane:

- permitted public event routing;
- update only the affected public domain and visible row;
- no blocked combat-log subscription.

Medium lane:

- visible unit evidence and compact health presentation;
- hard cap of four evaluations per second;
- skip hidden detailed surfaces.

Slow lane:

- scoreboard, full roster, map state, assignments, prediction, and AAR;
- event-driven with a one-second safety pulse;
- recompute only invalidated domains.

### Remove allocation hotspots

- Do not subscribe to Retail 12's blocked combat-log event.
- Replace deep snapshot copies with small immutable domain revisions.
- Use fixed ring buffers for movement and events.
- Store AAR features and transitions, not the complete live snapshot.
- Do not set secure attributes when the desired value is unchanged.
- Do not update hidden roster rows or hidden HUD text.
- Pool tactical-map markers and line segments.
- Expire inactive enemy tracks and temporary combat records.

### Performance acceptance budget

Release is blocked unless live profiling demonstrates:

- no full strategic refresh above four per second;
- public event dispatch p99 below 0.03 ms on the test machine;
- strategic refresh p95 below 2 ms and no routine refresh above 4 ms;
- median FPS difference below 1% versus addon disabled;
- 1% low FPS difference below 3%;
- memory reaches a plateau after warm-up;
- less than 1 MB growth over a 30-minute match after garbage collection;
- SavedVariables below 1 MB for the default 30-match history;
- zero active match ticker outside a battleground;
- zero taint or blocked-action warnings.

Record results by map, UI visibility mode, raid size, and other installed addons.

## Learning system

### What KWR should learn

- which plan was selected;
- map, score band, phase, and composition feature vector;
- enemy composition feature vector;
- whether the plan achieved its objective within its evaluation window;
- whether the leader accepted, overrode, or abandoned it;
- match result;
- structured AAR labels and notes.

### What KWR should not learn

- hidden talents or gear;
- opponent identity profiles;
- secret health or aura values;
- causal claims from one match;
- recommendations from unreviewed preview data.

### Small-footprint model

Use bounded aggregate statistics:

- success/failure counts by map + plan + composition archetype;
- recency-weighted success estimate;
- Bayesian shrinkage toward the curated baseline;
- minimum sample size before learned results affect scoring;
- confidence interval and sample count shown to the user.

Suggested safeguards:

- fewer than 5 reviewed samples: display only, no scoring effect;
- 5-19 samples: maximum learned adjustment of 3%;
- 20 or more samples: maximum learned adjustment of 8%;
- patch change: decay or quarantine old samples;
- doctrine changes: start a new plan version;
- user can reset, export, or disable learning.

This creates genuine adaptation without shipping a model runtime or allowing
small noisy samples to corrupt doctrine.

## Data acquisition and provenance

### Tier A: Blizzard in-game APIs

Purpose:

- live match, score, objective, roster, scoreboard, map, and safely observed
  combat facts.

Rules:

- respect Midnight secret-value restrictions;
- field-test every source in active PvP;
- fail closed when a value becomes secret or unavailable.

### Tier B: Battle.net Game Data and Profile APIs

Official documentation:

- https://community.developer.battle.net/documentation/world-of-warcraft/game-data-apis
- https://community.developer.battle.net/documentation/world-of-warcraft/profile-apis

Build-time uses:

- specialization, spell, item, media, talent, season, and leaderboard reference;
- public profile snapshots for aggregate meta research where permitted;
- never place credentials in the addon.

Create a separate developer ETL tool with OAuth credentials supplied through
environment variables. Cache responses, respect rate limits, retain provenance,
and publish only reviewed aggregate facts.

### Tier C: Murlok

Current RBG pages:

- https://murlok.io/meta/healer/rbg
- https://murlok.io/meta/tank/rbg
- https://murlok.io/meta/dps/rbg

Murlok states that these pages refresh every eight hours from active top-rated
players. Use them as a secondary meta cross-check and build-time snapshot only.

Before automating collection:

- obtain permission or confirm applicable terms;
- do not bypass access controls or scrape aggressively;
- store aggregate specialization/build frequencies, not copied page content;
- include capture time, patch, region coverage, sample description, and expiry;
- disable meta scoring when the snapshot is stale.

### Tier D: Warcraft Logs

Official API documentation:

- https://www.warcraftlogs.com/api/docs

Warcraft Logs provides an OAuth-protected GraphQL API. It should be treated as
an optional research source only if the API exposes relevant, representative
PvP reports and its terms permit the intended aggregation. It is not a substitute
for RBG match-state truth.

### Tier E: KWR opt-in match corpus

This is the most valuable composition and counterplay source:

- capture a sanitized post-match record after restrictions lift;
- include both compositions, map, score transitions, selected plans, outcomes,
  and reviewed AAR labels;
- export manually or through an optional out-of-game developer importer;
- require contributor consent;
- remove account identifiers and hash or discard character names;
- never transmit from the addon during play.

Start local-only. A shared community corpus requires a privacy policy, consent,
data-retention policy, schema version, moderation, and quality controls.

### Tier F: Expert doctrine panel

Use experienced RBG leaders to label:

- composition archetypes;
- meta and off-meta plans;
- counter-plans;
- switch conditions;
- stop rules;
- expected calls for sanitized replay fixtures.

Every doctrine record requires at least two reviews or one review plus supporting
match evidence before release.

## Data pipeline deliverables

Create a developer-only `knowledge/` workspace:

```text
knowledge/
  schemas/
  raw/
  normalized/
  reviewed/
  fixtures/
  provenance/
  generators/
```

Generated addon files:

```text
Data/Capabilities.lua
Data/Compositions.lua
Data/BattlePlans.lua
Data/Counters.lua
Data/MetaSnapshot.lua
Data/KnowledgeManifest.lua
```

The generator must:

- validate every ID and reference;
- reject duplicate or contradictory records;
- attach source, patch, season, review status, and expiry;
- create compact numeric lookup tables;
- generate deterministic hashes;
- report unreviewed or stale records;
- produce no runtime JSON parser or external library dependency.

## New-leader experience

Provide two information levels:

### Command mode

Show only:

- NOW;
- WHO;
- WHEN;
- WHY;
- SWITCH IF;
- DO NOT.

### Learning mode

Expand into:

- win-path calculation;
- composition matchup;
- counterplay explanation;
- rejected alternatives;
- evidence confidence;
- relevant map doctrine;
- post-match review.

Add:

- first-run guided preview;
- map-specific opening card before gates open;
- plain-language glossary;
- confidence and UNKNOWN explanations;
- color plus icon/text accessibility;
- scalable typography and density presets;
- one-click "why this call?" explanation;
- leader override that becomes an AAR learning signal.

## Validation program

### Deterministic tests

- every map phase and score edge;
- every composition archetype;
- every plan/counter/fallback link;
- stale, unknown, and contradictory evidence;
- secret-value safety;
- cross-faction teams;
- player death, leaver, reconnect, and role ambiguity;
- patch-data expiry;
- learning minimum-sample safeguards.

### Sanitized replay harness

Record fact transitions, not protected raw values. Replay them offline through
the decision engine and compare:

- selected plan;
- call timing;
- assignments;
- switch behavior;
- explanation;
- confidence.

Build a reviewed golden corpus for all supported maps.

### Human acceptance

For each map:

- at least 20 complete beta matches;
- novice leader can state the call and reason within five seconds;
- expert reviewers agree the call is legal and reasonable at least 90% of the time;
- zero impossible or fabricated calls;
- every override can be explained and categorized;
- visual review at 1080p, 1440p, 4K, and common UI scales.

## Delivery phases

### Phase 0: Measurement and safety lock

- add performance telemetry and a repeatable baseline protocol;
- record refresh frequency, p50/p95/max time, allocation proxy, and memory;
- add secret/taint regression fixtures;
- freeze new surface features until budgets pass.

Exit: measured Beta 4 baseline and zero unresolved safety defects.

### Phase 1: Runtime efficiency

- split fast/medium/slow lanes;
- eliminate event-dispatch allocation and snapshot deep copies;
- implement domain invalidation and hidden-view suspension;
- compact AAR storage and ring buffers.

Exit: all performance acceptance budgets pass in live matches.

### Phase 2: Knowledge foundation

- define schemas and provenance manifest;
- build capability, composition, plan, and counter repositories;
- create the generator and stale-data gates;
- establish expert review workflow.

Exit: every shipped knowledge record is validated, sourced, and versioned.

### Phase 3: Complete map engines

- implement map-specific state machines and win-path models;
- add timer, transition, travel, and resurrection feasibility where public;
- build golden replay fixtures.

Exit: all ten maps pass deterministic and expert-reviewed scenarios.

### Phase 4: Composition and counter assistant

- detect our and enemy composition features;
- choose meta/off-meta plan families;
- generate counterplay and fallback calls;
- expose rejected alternatives and switch conditions.

Exit: no plan is selected without requirements, evidence, and a fallback.

### Phase 5: Learning loop

- record compact plan outcomes and leader overrides;
- add reviewed AAR labels;
- implement bounded Bayesian/recency adjustments;
- add reset/export/disable controls.

Exit: learning improves tie breaks without overriding authoritative live truth.

### Phase 6: 10/10 UX

- progressive Command/Learning modes;
- typography scaling and density presets;
- onboarding and pre-gate opening brief;
- accessibility and clutter testing;
- final visual comparison against approved mockups.

Exit: novice and expert acceptance targets pass.

### Phase 7: Release validation

- multi-machine, multi-resolution, multi-addon field matrix;
- 20-match-per-map corpus target;
- performance, taint, correctness, and usability sign-off;
- refresh meta snapshot and knowledge manifest;
- produce release candidate, developer package, hashes, and evidence report.

Exit: stable promotion, not merely another beta ZIP.

## Recommended next execution order

1. Implement Phase 0 telemetry.
2. Complete the Phase 1 performance pass.
3. Create the knowledge schemas and generator.
4. Build one vertical slice: Arathi Basin plus three composition archetypes,
   their counters, replay fixtures, and new-leader explanations.
5. Field-test that slice before expanding to the remaining maps.

This order proves performance, truth handling, strategy depth, learning inputs,
and usability without multiplying an unverified design across ten maps.
