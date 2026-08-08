# KWR Sentinel Design Handoff

Status: scope-locked design handoff

Audience: product designer, UI designer, UX contractor

Date: 2026-07-17

## Project summary

KWR Sentinel is the non-commander player client for Knomercy War Room.

It is not a second commander UI, not a second strategist, and not a broad PvP
utility suite.

Sentinel has one job:

- collect bounded local player-side battlefield observations for the commander;
- render one compact player execution card;
- confirm whether the player is on the correct assigned target;
- show one reviewed readiness alert before the battle starts.

## Product intent

Sentinel should feel like:

- a disciplined player execution client;
- quiet, clean, and trustworthy;
- coordinated with the commander;
- low-noise during live combat.

Sentinel should not feel like:

- a mini command center;
- a reporter map clone;
- an enemy tracker addon;
- a battleground overlay suite;
- a theorycraft or build planner.

## User model

Primary user:

- non-commander RBG player following team assignments.

Secondary use:

- optional same-client testing by the commander during development;
- staging/readiness checking before gates open.

Live assumption:

- some or all teammates may run Sentinel;
- commander may run only KWR and no Sentinel;
- Sentinel must still help when adoption is partial.

## Core product pillars

### 1. Data collector

Sentinel collects bounded player-local observations and sends them to the
commander addon.

This is invisible to the designer except where trust state is shown.

### 2. Execution card

Sentinel shows one compact card answering:

- what is my job;
- where do I move or stay;
- who is my current kill, kick, CC, peel, or watch target;
- are we winning or losing;
- what must we hold or do next.

### 3. Target confirmation

Sentinel shows a small visual cue that tells the player whether their current
target matches commander intent.

### 4. Readiness check

Sentinel performs a pre-match readiness check and may show one single alert
before the battle starts.

## The commander relationship

Commander does not need Sentinel.

Intended live setup:

- commander runs KWR;
- players run Sentinel.

Sentinel must display whether it is connected to the correct current commander.

## Required surfaces

Designer should scope Sentinel to these surfaces only.

### A. Main compact execution card

This is the primary and nearly always the only Sentinel surface.

Content:

- match header;
- commander sync badge;
- my job;
- movement authority;
- target responsibility;
- match state;
- hold/win instruction;
- small supporting alert line.

### B. Target confirmation cue

This is a very small battlefield-facing cue.

States:

- white: correct target;
- red: wrong target;
- muted: no current reviewed target instruction.

### C. One-shot readiness alert

This is a staging-only compact alert.

It should fire once at roughly 60 seconds before battle start, then stop unless
gear or talents change again before the match begins.

## Primary execution card content

The designer should treat these as required slots.

### Header

- battleground short name;
- score or compact pace state;
- win/loss state badge:
  - `WINNING`
  - `LOSING`
  - `EVEN`
  - `SETUP`
- commander sync badge:
  - `RAID CMD ONLINE`
  - `LOCAL KWR`
  - `NO COMMANDER`
  - `STALE`
  - `MISMATCH`

### Main body

- `MY JOB`
  - examples: `BS HOLD`, `LH FLOAT`, `FC HEAL`, `EFC KILL`
- `MOVE`
  - examples: `STAY`, `MOVE`, `FLOAT`, `ESCORT`, `RETURN`, `COLLAPSE`, `RESET`
- `TARGET`
  - examples: `KILL Maldraxxus`, `KICK Toxicmage`, `CC Deathwish`, `PEEL Kickadin`
- `MATCH STATE`
  - one plain-language line
- `TO HOLD`
  - one short line when ahead
- `TO WIN`
  - one short line when behind or even

### Supporting footer

- optional small exception state:
  - `HEALER OUT OF RANGE`
  - `FC VISIBLE`
  - `CARD LIVE 4s`
  - similar reviewed compact signals

## Team coordination model

Sentinel cards are personalized views of one shared commander operation.

The player should understand that:

- this is my role in a team move;
- others are moving or holding too;
- my instruction is coordinated, not random.

The UI does not need to show the whole team plan in detail, but it should feel
connected to one shared team order rather than a solo to-do list.

## Readiness alert scope

This is intentionally small.

### Hard readiness

Possible statuses:

- `READY`
- `PVP GEAR WARNING`
- `PVP TALENT WARNING`
- `UNKNOWN`

Use case:

- player may have entered from a PvE raid or wrong loadout.

### Soft comp-fit

Possible statuses:

- `MATCHED`
- `CONSIDER SWAP`
- `NOT EVALUABLE`

Use case:

- player is in legal PvP setup but a current PvP talent may be low-fit into the
  observed enemy comp.

Important:

- soft comp-fit is not a failure state;
- it should not be styled like an error;
- it only appears when enemy-comp confidence is strong enough.

### Timing rule

- one alert only at about `T-60s` before battle;
- no repeated reminders;
- no combat nagging;
- if the player changes gear or talents after the alert, one more reviewed alert
  may be allowed before battle starts.

## Trust and connection states

These are important design responsibilities.

The player must be able to tell whether the current card is real, stale, local,
or unbound.

### Commander trust states

- `RAID CMD ONLINE`
  - correctly bound to the current raid/team commander
- `LOCAL KWR`
  - same-client bridge only
- `NO COMMANDER`
  - no reviewed commander binding active
- `STALE`
  - prior commander data timed out
- `MISMATCH`
  - received traffic failed team/session validation

### UX intent

- visible at a glance;
- small trust badge, not a screaming warning box;
- must not be hidden in a submenu.

## Interaction scope

Sentinel interaction should stay very small.

Allowed:

- show/hide main HUD;
- move the card;
- toggle safe native battleground map/scoreboard/raid frames if retained;
- inspect the card.

Avoid:

- multi-panel navigation;
- tabs;
- deep configuration inside the main live surface;
- dense staging setup flows;
- detailed report drawers.

## Out of scope

Designer should not build for any of the following:

- Reporter map;
- tactical board;
- enemy table;
- battlefield reporter panel;
- expanded notes system;
- composition analysis window;
- commander page;
- second roster suite;
- broad overlay language beyond the reviewed crosshair cue;
- in-combat build advisor;
- repeated pre-match coaching.

If a feature depends on “maybe Sentinel could also become...”, it is out of
scope unless explicitly approved.

## Visual direction

Sentinel should visually align with KWR but be simpler and cleaner.

Preserve:

- dark tactical shell;
- restrained cool-blue accent language;
- readable WoW-safe text;
- professional military-table tone.

Emphasize:

- one-card clarity;
- strong role and target readability;
- high contrast over real battleground backgrounds;
- small, meaningful state color.

Avoid:

- giant colored slabs;
- glowing arcade visuals;
- cluttered icon walls;
- multiple equal-priority panels;
- giant battlefield art treatments.

## Relative priority of information

The designer should preserve this order:

1. commander connection trust
2. win/loss state
3. my job
4. my target responsibility
5. hold/win line
6. small exceptions

If space is tight, lower-priority content should collapse first.

## Responsiveness and density

Sentinel is not a desktop dashboard.

Expect:

- compact footprint;
- fast combat readability;
- minimal text lines;
- no dense row stacks;
- no body paragraph longer than needed.

Target read time:

- under 2 seconds for the current instruction.

## States the designer must cover

Required visual states:

- setup, no commander
- setup, commander online
- winning, stable assignment
- losing, recovery instruction
- correct target
- wrong target
- no current target instruction
- stale commander connection
- mismatch / invalid commander traffic
- hard readiness warning
- soft comp-fit consider-swap warning

## Deliverables requested from design

The design handoff should include:

- primary execution card layout;
- trust badge states;
- crosshair cue states;
- one-shot readiness alert treatment;
- compact typography and spacing rules;
- color/state behavior on bright and dark battleground scenes;
- minimal interaction behavior notes.

Optional but useful:

- small motion notes for state changes;
- low-clutter icon suggestions for:
  - job
  - move
  - target
  - trust
  - readiness

## Engineering notes for designer awareness

These are not design tasks, but they constrain design:

- Sentinel must not require every player to install it.
- Commander remains fully functional without Sentinel.
- Sentinel only talks to the correct team commander for the current raid and
  battleground session.
- Sentinel data is bounded, short-lived, and merged into commander truth through
  the normal KWR runtime.
- The execution card is driven by commander relay or same-client bridge data,
  not independent player-side strategy.

## Final scope lock

The correct design sentence is:

`KWR Sentinel is a compact player execution client that collects bounded local data, shows one commander-linked action card, confirms target correctness, and stays quiet during combat.`

If a design concept does not reinforce that sentence, it should not be in this
project.
