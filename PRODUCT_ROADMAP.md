# KWR 10/10 Product Roadmap

## Current handoff and next release

`PROJECT_HANDOFF.md` is the authoritative no-drift plan following
6.1.0-alpha.9. Alpha 9 remains the certified rollback baseline. Alpha 14 is
the current additive trust and decision-quality candidate, not an architecture
rewrite. It retains target/cast clarity and complete response packages while
adding evidence contracts, coverage integrity, route estimates, and
objective-aware action comparison. The three-line combat HUD remains unchanged.

The immediate order is:

1. live-test Alpha 14 truth, assignment, response, transition, and decision contracts;
2. reversible Combat Clarity controls;
3. kill-zone `FORMING`/`ACTIVE`/`RECOVERY`;
4. Contain-and-Trade counterplay;
5. refine the single bounded player advisory from field evidence.

The seventeen-feature suggestion package is dispositioned in the handoff.
Concept names do not authorize seventeen new runtime engines or UI surfaces.

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
