# KWR Sentinel Product Contract

Status: approved direction draft for scope lock

Last updated: 2026-07-17

## Product definition

KWR Sentinel is the non-commander player client for Knomercy War Room.

Its job is simple:

- collect bounded local battlefield observations from the player client;
- send that evidence to the commander-side KWR runtime;
- render one compact execution card for that player;
- confirm whether the player's current target matches commander intent.

Sentinel is not a second KWR client, not a second strategist, and not a
replacement for broad battleground UI suites.

Sentinel also cannot be a required dependency for KWR commander value.

Commander KWR must remain fully usable with:

- zero Sentinels;
- partial Sentinel adoption;
- stale or disconnected Sentinels;
- mixed addon adoption across a battleground.

## Core purpose

Sentinel must answer only these questions for a non-commander player:

1. What is my job right now?
2. Where should I be, or should I stay put?
3. Who is my local kill, kick, CC, or peel target?
4. Are we winning or losing, and what must be maintained or changed?
5. Am I on the correct target?

Everything else belongs in commander KWR or in optional third-party addons.

## Product pillars

### 1. Data collector

Sentinel exists first as a bounded observation client.

It should legally collect and relay:

- sender presence and compatibility;
- alive/dead and connected state;
- local healer reachability;
- local assignment reachability;
- visible enemy presence;
- observed visible casts and channels;
- visible carrier and orb state;
- local fight pressure shape;
- other reviewed, legal, non-secret observations approved by the transport spec.

It must never invent truth, infer secrets, or claim commander authority.

### 2. Player execution card

Sentinel exists second as a compact player guidance surface.

The player card should show only:

- my assignment;
- my movement authority;
- my current personal control or kill target;
- current match state;
- the one thing we must hold to preserve a lead, or the one thing we must do to recover.

This is not a freeform analyst panel. It is a compact execution card.

When multiple players run Sentinel, each execution card is a personalized view
of one shared commander operation. Sentinel clients do not generate independent
assignment logic.

### 3. Local target confirmation

Sentinel exists third as a target confirmation aid.

The local crosshair feature should:

- reflect the player's current commander-assigned target intent;
- support kill or control target states;
- show white when the player is on the correct target;
- show red when the player is on the wrong target;
- remain visual only, with no target swap, focus swap, cast, or automation.

## In-scope features

The Sentinel feature set is intentionally narrow.

### Required

- bounded observation transport to commander;
- safe partial-adoption behavior;
- compact execution card;
- current win/loss state summary;
- maintain-lead or recover-to-win instruction line;
- personal assignment display;
- personal movement authority display;
- personal control target display;
- current commander operation visibility through a player-specific slice;
- local crosshair target confirmation;
- commander connection indicator;
- native battleground utility toggles if they remain safe and low-noise.

### Allowed but secondary

- healer-range status;
- local death-zone or collapse warning if sourced from commander;
- carrier or objective exception cue if it changes this player's job;
- compact countdown or expiry on the current action.

## Out of scope

Sentinel must not grow into any of the following:

- full Reporter map;
- Enemy Tracker replacement;
- broad enemy roster addon;
- second commander dashboard;
- second tactical board;
- second assignment engine;
- player-side strategic recommendations;
- open-ended prose analysis;
- battlefield overlay clutter beyond the reviewed target cue;
- automatic target, focus, cast, macro, or movement behavior;
- chat-based transport fallback;
- visible-chat command relay.

If a player wants full enemy overlays or reporter tools, that is intentionally a
different addon choice.

## Partial-adoption rule

Sentinel must help commander truth when present and do nothing harmful when
absent.

### Non-negotiable behavior

- commander logic must never require Sentinel participation to function;
- strategic decisions must still work when only one, some, or no players run
  Sentinel;
- remote observations may enrich local truth but must not be treated as
  mandatory truth;
- missing Sentinel data must degrade to unknown, not failure;
- no commander order may assume every player has received Sentinel relay.

### Product interpretation

If all 10 players run Sentinel, KWR gains a coordinated execution layer.

If only some players run Sentinel, KWR gains better live evidence from those
players and optional personalized cards for them, while the commander still
runs normally for everyone else.

## Team operation model

Sentinel assignment changes should be coordinated at the commander-operation
level, not as ten unrelated personal retargets.

Commander should publish one shared operation package and each Sentinel should
render only that player's slice.

### Shared operation fields

- `operationId`
- `issuedAt`
- `minimumHoldUntil`
- `trigger`
- `teamObjective`
- `winState`
- `moverGroup`
- `holderGroup`
- `supersedesOperationId`

### Player slice fields

- `myRole`
- `myLocation`
- `myMovement`
- `myTargetMode`
- `myTargetName`
- `myHoldLine`
- `myWinLine`

### Result

All participating Sentinel clients remain synchronized to one team effort while
still showing only the information relevant to the local player.

## UX contract

Sentinel should feel clean, fast, and subordinate to gameplay.

### Visual hierarchy

1. Match state
2. My assignment
3. My target responsibility
4. Maintain or recover instruction
5. Small supporting exceptions only

### Attention budget

Sentinel should not ask the player to read more than one card during active
combat.

The player should understand the current instruction in under two seconds.

### Surface limit

Sentinel should prefer one primary HUD/card and one target cue.

Additional surfaces should be avoided unless they directly reduce player
friction without duplicating KWR.

## Execution card contract

The compact player card should contain these fields.

### Header

- map short name;
- live match score or objective pace state;
- win/loss state badge: `WINNING`, `LOSING`, `EVEN`, or `SETUP`.
- commander sync badge:
  - `RAID CMD ONLINE`
  - `LOCAL KWR`
  - `NO COMMANDER`
  - `STALE`
  - `MISMATCH`

### Card body

- `MY JOB`
  - role text such as `BS HOLD`, `FC HEAL`, `ROAD FLOAT`, `EFC KILL`
- `MOVE`
  - one of `STAY`, `MOVE`, `FLOAT`, `ESCORT`, `RETURN`, `COLLAPSE`, `RESET`
- `TARGET`
  - one of:
    - `KILL <name>`
    - `KICK <name>`
    - `CC <name>`
    - `PEEL <name>`
    - `WATCH <name>`
- `MATCH STATE`
  - one short plain-language line describing whether the team is ahead or behind
- `TO HOLD`
  - the one condition required to preserve the lead
- `TO WIN`
  - the one action required if behind or even

### Footer

- action expiry or refresh hint if useful;
- optional local exception such as `HEALER OUT OF RANGE` or `FC VISIBLE`.
- commander connection state if not already shown in the header.

## Crosshair contract

The crosshair must remain small, unambiguous, and player-safe.

### States

- `WHITE`
  - the player's current target matches the assigned kill or control target
- `RED`
  - the player is targeting the wrong enemy
- `MUTED`
  - no valid target instruction is currently active

### Rules

- kill and control assignments both use the same visual family;
- only one active target cue may be emphasized at a time;
- no permanent battlefield-wide crosshair grid;
- no enemy replacement layer;
- no action is taken automatically when the target is wrong.

## Commander authority contract

KWR commander remains the only authority for:

- assignments;
- strategic state;
- control target decisions;
- maintain-lead and recover-to-win guidance;
- merged battlefield truth.

Sentinel may contribute observations only. It may not publish strategy.

## Commander binding contract

Sentinel must talk only to the correct commander for the player's current team
and current battleground session.

This is mandatory because both factions may run KWR/Sentinel in the same match.

### Binding rules

Sentinel may bind to a commander only when all of the following are true:

- commander and Sentinel are in the same current group or raid context;
- commander and Sentinel share the same battleground session key;
- commander and Sentinel resolve to the same friendly team;
- commander identity maps to the live roster for the player's side;
- the packet protocol version is compatible.

If any of those checks fail, the packet must be ignored.

### Commander identity

The relay path should identify commander with reviewed fields such as:

- commander character identity;
- commander GUID when legally available;
- commander roster membership;
- commander team/faction side for the active match;
- commander session key;
- protocol version.

### Sentinel binding lifecycle

Sentinel should:

1. enter `UNBOUND` on load, reload, zone change, or battleground transition;
2. listen for reviewed commander handshake traffic;
3. bind only after one commander passes the binding rules;
4. reject other commanders for that session while bound;
5. unbind immediately on session mismatch, roster loss, or expiry;
6. return to `UNBOUND` on battleground end or commander timeout.

### Enemy-team safety

Sentinel must never accept commander relay merely because:

- the prefix matches;
- the battleground map matches;
- the player can hear or see the other team in the same match.

Shared battleground presence is not enough. Same-team roster and session binding
are required.

## Commander connection indicator

Sentinel should expose a small but explicit commander-link state so the player
knows whether the current card is tied to the live team commander.

### Indicator states

- `RAID CMD ONLINE`
  - bound to the current reviewed commander for this raid/team/session
- `LOCAL KWR`
  - using reviewed same-client bridge only
- `NO COMMANDER`
  - no reviewed commander connection is currently active
- `STALE`
  - previous commander binding existed but relay timed out
- `MISMATCH`
  - received traffic failed roster/team/session validation

### UX rule

The indicator should be visible at a glance but quiet. It is a trust badge, not
an alarm panel.

### Commander timeout

Commander binding should expire quickly enough to avoid stale trust and slowly
enough to avoid flicker.

Initial target:

- stale after 6-10 seconds without valid relay refresh;
- unbound after a longer reviewed timeout window if the commander does not
  return.

## Data collection contract

Sentinel observations should stay within the transport families already defined
by the reviewed Sentinel transport direction:

- `HELLO`
- `STATE`
- `OBS_VISIBLE`
- `OBS_CAST`
- `OBS_CARRIER`
- `OBS_PRESSURE`

Commander relay back to Sentinel should stay within:

- `RELAY_ASSIGN`
- `RELAY_CONTROL`
- `RELAY_ACTION`
- `WELCOME` or equivalent reviewed commander-binding handshake

No additional families should be added unless they clearly strengthen the
player-card or commander-truth mission.

## Observation truth and weight contract

Sentinel data is not all equal.

Commander should evaluate each remote observation by:

- legality;
- freshness;
- sender identity validity;
- session/team match;
- observation family;
- corroboration count;
- conflict with stronger local truth.

### Top-level truth priority

Sentinel data must fit beneath the existing KWR truth ladder.

1. Local authoritative battleground widget or reviewed API truth
2. Local commander-client visible-unit truth
3. Remote Sentinel truth corroborated by multiple valid senders
4. Remote Sentinel truth from one valid sender
5. Historical, meta, and advisory knowledge

### Family priority and weight

Use these as initial merge weights for commander-side reasoning.

| Family | What it represents | Truth priority band | Initial weight | Primary consumers |
| --- | --- | --- | ---: | --- |
| `HELLO` | Presence and protocol compatibility | control plane only | 1.00 control | commander binding only |
| `STATE` | player liveness, connection, reachability, healer-range | low-medium | 0.30 | Assignments, Reporter, assignment integrity |
| `OBS_VISIBLE` | enemy seen / in local range / locally engaged | medium | 0.45 single / 0.70 corroborated | EnemyIntel, Reporter, CombatIntel |
| `OBS_CAST` | visible active cast or channel | medium-high | 0.60 single / 0.85 corroborated | CombatIntel, EnemyIntel |
| `OBS_CARRIER` | visible carrier/orb state | high when corroborated, never above widget truth | 0.65 single / 0.90 corroborated | ObjectiveIntel, Reporter, CombatIntel |
| `OBS_PRESSURE` | local fight shape and numbers estimate | medium advisory | 0.40 single / 0.65 corroborated | Reporter, Strategist, Assignments |

Rules:

- weights are additive evidence inputs, not permission to override stronger
  truth;
- `HELLO` is not gameplay evidence and should never affect strategy directly;
- `STATE` should influence assignment integrity and support confidence, not hard
  objective truth;
- `OBS_PRESSURE` is useful for shaping urgency and local support decisions but
  should never become hard position certainty;
- `OBS_CARRIER` may strongly raise confidence for carrier action, but reviewed
  widget/objective truth still outranks it.

### Expiry and decay

Remote evidence must decay fast.

Initial reviewed targets:

- `OBS_CAST`
  - full weight while active, then decay to zero within 2 seconds after end
- `OBS_VISIBLE`
  - full weight at receipt, decays toward zero across 3 seconds without refresh
- `OBS_CARRIER`
  - full weight at receipt, decays toward zero across 2 seconds unless stronger
    truth refreshes it
- `OBS_PRESSURE`
  - full weight at receipt, decays toward zero across 3 seconds
- `STATE`
  - operational for 4 seconds, then downgraded to stale

Expired remote data must become `UNKNOWN`, not sticky fact.

### Conflict rules

When remote observations disagree:

- multiple matching senders beat one sender;
- the most recent valid packet wins inside the same authority band;
- exact battleground widget or local commander visibility beats all remote
  claims;
- impossible claims are dropped, not averaged;
- a remote signal may raise confidence but may not invent unavailable values.

## Commander-side write path

Sentinel data must not write directly into `KWR.Store`.

That would create a second published truth path and break the existing runtime
architecture.

### Correct path

```text
KWRSentinel client
    -> Comm.lua sends reviewed packet

KWR commander client
    -> Runtime/CommanderComm.lua validates envelope, team, commander binding,
       sender, sequence, and rate limits
    -> Runtime/SentinelIngress.lua converts packet into normalized observation
       records
    -> sentinelIngress in-memory session table stores bounded remote evidence
    -> Runtime/SentinelMerge.lua applies remote evidence into existing runtime
       owners
    -> Runtime/MatchRuntime.lua continues normal refresh pipeline
    -> Core/Store.lua publishes one authoritative state
```

### Where it is written

Remote Sentinel data should be written only to:

- a bounded in-memory `sentinelIngress` session table;
- reviewed in-memory owner caches inside existing runtime modules;
- the next ordinary published `snapshot` through the normal MatchRuntime cycle.

Remote Sentinel data should not be written directly to:

- `KWR.Store.state` outside `Store:Publish`;
- SavedVariables;
- ad hoc global tables;
- separate player-owned strategic stores.

### Session ingress table

Initial commander ingress shape:

```text
sentinelIngress = {
    sessionKey = "...",
    byPlayer = {},
    byEnemy = {},
    byObjective = {},
    lastSeqBySender = {},
    diagnostics = {},
}
```

This table is:

- in-memory only;
- bounded;
- reset per battleground session;
- debug-readable;
- not authoritative by itself.

### Owner merge targets

Remote evidence should merge into existing KWR runtime owners like this:

| Family | Merge target |
| --- | --- |
| `STATE` | `Assignments`, assignment integrity, limited Reporter support context |
| `OBS_VISIBLE` | `EnemyIntel`, `Reporter`, `CombatIntel` |
| `OBS_CAST` | `CombatIntel`, `EnemyIntel` |
| `OBS_CARRIER` | `ObjectiveIntel`, `Reporter`, `CombatIntel` |
| `OBS_PRESSURE` | `Reporter`, `Strategist`, assignment-integrity support context |

### Publish rule

`MatchRuntime` remains the only owner that produces a full battlefield snapshot
and calls `Store:Publish`.

Sentinel merge data should be consumed during the normal runtime refresh, then
appear in:

- `snapshot.enemies`
- `snapshot.objectives`
- `snapshot.reporter`
- `snapshot.combat`
- `snapshot.assignmentIntegrity`
- any reviewed truth/evidence summaries

That keeps one authoritative Store path, which matches the current architecture.

## Persistence contract

By default, raw Sentinel observation traffic should not be persisted.

### Allowed persistence

- bounded diagnostics counters;
- optional reviewed verification exports;
- optional AAR-level summarized evidence after match, if it is sanitized and
  useful.

### Not allowed persistence

- raw packet logs by default;
- unbounded per-player event history;
- hidden cross-match remote evidence carryover;
- persistent strategy side effects from stale Sentinel data.

## Player card relay contract

Commander relay should be normalized into a compact Sentinel view model like:

```text
playerView = {
    assignment = {
        role,
        location,
        movement,
        backup,
    },
    control = {
        mode,
        target,
        priority,
    },
    match = {
        state,
        scoreText,
        paceText,
    },
    requirement = {
        holdLine,
        winLine,
    },
    alerts = {
        healerRange,
        carrier,
        collapse,
        expiry,
    },
}
```

The exact Lua table can differ, but the information contract should stay this
tight.

## Fallback behavior

When commander relay is unavailable, Sentinel should degrade safely.

### Allowed standalone fallback

- healer-range status;
- current-target cast watch;
- local target confirmation only if a valid reviewed local target can be
  resolved.
- same-client `LOCAL KWR` bridge when KWR is installed on that client.

### Not allowed in fallback

- invented assignments;
- fake match state;
- fake target instructions;
- second-hand strategic guesses.

## Success criteria

Sentinel is successful when:

- commander gains useful extra local evidence from player clients;
- players receive one clear execution card instead of multiple noisy panels;
- coordinated team moves can be relayed as one shared operation when enough
  players run Sentinel;
- the player can verify target correctness instantly;
- the addon reduces reliance on voice repetition for personal tasks;
- the addon clearly indicates whether it is connected to the correct current
  commander;
- Sentinel does not become a cluttered second battleground interface.

## Failure modes

Sentinel has failed product direction if it becomes:

- a mini commander board;
- a generic PvP enemy package;
- a second Reporter;
- a broad overlay system;
- a transport path with weak safety boundaries;
- a feature bucket for anything that does not fit KWR proper.

## Explicit direction lock

From this point forward, Sentinel should be treated as:

`data collector + compact execution card + target confirmation`

Anything outside that box requires an explicit scope review.
