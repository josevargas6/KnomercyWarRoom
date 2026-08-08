# Sentinel Transport Spec

## Purpose

Define the only approved communication and bridge path between `KnomercyWarRoom`
(`KWR`) and `KWRSentinel`.

This document is the implementation gate for any multiplayer Sentinel sync work.
No comms code should be added until this spec is accepted and the validator,
README, and runtime owners are updated to match it.

## Problem

Players will keep installing external battleground addons unless Sentinel
replaces their practical value. Local-only UI relay is not enough for the full
Rated Battleground product vision. The team needs:

- one commander brain;
- ten player clients supplying bounded observations;
- compact player-specific outputs relayed back to each Sentinel;
- no second strategist, no second Store, no fake certainty.

WoW addons do not share a live common file across clients. Cross-client sync
must use addon messages, not SavedVariables.

## Scope

This spec covers:

- Commander/Sentinel transport policy;
- message schema and ownership;
- authority and merge rules;
- rate limits and safety rules;
- validation gates;
- completion criteria.

This spec does not itself approve implementation. It defines what implementation
must satisfy.

## Non-Negotiable Rules

1. `KWR` remains the only strategic brain.
2. `KWR.Store` remains the only published authoritative battlefield state.
3. Sentinels may send observations, not strategy.
4. Unknown stays unknown.
5. Lower-authority remote observations may enrich local truth, but may not
   silently overwrite stronger local truth.
6. No chat-visible communication path is allowed.
7. No secure action, target swap, focus swap, macro execution, or protected
   action may be triggered by incoming comms.
8. Every message family must be bounded, versioned, and rate-limited.
9. The system must degrade safely when zero, partial, or stale Sentinels are
   present.

## Required Policy Changes Before Code

The current repo posture blocks this feature:

- `README.md` states that KWR never sends addon-channel messages automatically.
- `tools/validate.ps1` currently treats `SendAddonMessage` usage as forbidden.

Before transport implementation:

1. `README.md` must be amended to allow reviewed, bounded KWR/Sentinel addon
   communication in battleground group contexts only.
2. `tools/validate.ps1` must stop blanket-forbidding reviewed comm owners and
   instead:
   - forbid comm APIs everywhere by default;
   - whitelist them only in the reviewed comm modules;
   - forbid unapproved prefixes;
   - forbid visible chat fallbacks.
3. release docs must describe what data is transmitted and what is not.

## Blizzard API Surface

Approved transport must use the standard addon communication channel:

- `C_ChatInfo.RegisterAddonMessagePrefix`
- `C_ChatInfo.SendAddonMessage`
- `CHAT_MSG_ADDON`

Reference behavior:

- prefix registration is required and does not persist through `/reload`;
- `INSTANCE_CHAT` is valid in instanced group content including battlegrounds;
- `RAID` is valid for raid groups and may be needed for pre-match staging.

## Product Architecture

### Overview

```text
KWRSentinel (10 clients)
    -> observe bounded local truth
    -> send normalized packets

KWR Commander (1+ client, authoritative owner)
    -> receive and validate packets
    -> aggregate per-player observations
    -> merge observations into existing runtime owners
    -> publish one authoritative Store
    -> relay compact player-specific outputs

KWRSentinel (10 clients)
    -> receive compact relay packets
    -> render compact player tools
```

### Single Brain Rule

Remote Sentinel data feeds the existing KWR owners:

- `EnemyIntel`
- `ObjectiveIntel`
- `Reporter`
- `CombatIntel`
- `Assignments`
- `Strategist`

Remote data does not create:

- a second Store;
- a second prediction model;
- a second assignment engine;
- a second commander output object.

## Module Ownership

### KWR Modules To Add

- `Runtime/CommanderComm.lua`
  - owns prefix registration, receive path, sender validation, dedupe,
    aggregation table, and relay send path.
- `Runtime/SentinelIngress.lua`
  - converts validated remote packets into normalized observation records.
- `Runtime/SentinelMerge.lua`
  - merges observation records into existing runtime owners using authority
    rules.
- `Runtime/SentinelRelay.lua`
  - produces compact player relay payloads from the authoritative Store.

### KWRSentinel Modules To Add

- `Comm.lua`
  - prefix registration, sender/receiver path, rate limiting, sequence control.
- `Observer.lua`
  - extracts bounded local observation packets.
- `Relay.lua`
  - consumes commander relay packets and updates Sentinel view state.

### Existing Modules That Must Not Be Duplicated

- `Runtime/MatchRuntime.lua`
- `Runtime/Strategist.lua`
- `Runtime/Assignments.lua`
- `Runtime/Commander.lua`
- `Runtime/Reporter.lua`
- `Runtime/CombatIntel.lua`

## Prefix and Session Rules

### Approved Prefix

Use a single reviewed prefix:

- `KWRSync1`

Rules:

- maximum 16 bytes;
- all traffic uses this prefix;
- packet family is carried inside the envelope;
- no secondary hidden prefixes are allowed.

### Session Key

Every packet must carry the normalized battlefield session key:

- map key;
- live/preview mode;
- battleground/instance phase;
- optional battleground instance identifier if available.

Packets with missing or mismatched session keys must be ignored.

## Transport Channels

### Approved Distributions

- `RAID`
  - pre-match staging when the team is assembled as a raid outside the active
    battleground instance.
- `INSTANCE_CHAT`
  - active battleground communication path.
- `PARTY`
  - fallback only when testing in a small grouped environment.

### Rejected Distributions

- `SAY`
- `YELL`
- `CHANNEL`
- `GUILD`
- `OFFICER`
- `WHISPER`

Rationale:

- `WHISPER` creates unnecessary routing complexity and privacy risk.
- public or social channels are outside the bounded battleground product scope.

## Envelope Format

### Encoding Goals

- ASCII only;
- compact enough for frequent battleground use;
- no JSON parser requirement;
- easy deterministic testing;
- explicit versioning;
- field order stable.

### Canonical Envelope

```text
v=1|sid=<sessionKey>|seq=<senderSequence>|kind=<family>|ts=<epoch>|src=<unitKey>|body=<payload>
```

Rules:

- `v`: protocol version;
- `sid`: session key;
- `seq`: monotonically increasing sender-local integer;
- `kind`: message family identifier;
- `ts`: sender timestamp;
- `src`: sender identity key;
- `body`: family-specific payload.

Field separator:

- top-level: `|`
- family body fields: `;`
- list items inside body: `,`

All parsers must reject malformed envelopes.

## Identity Model

### Sender Identity

Sender identity must be normalized as:

- player name;
- realm if available;
- GUID if available;
- class token;
- role if known.

Commander must map messages to the active roster. Messages from names not in
the active battleground raid must be ignored.

### Enemy Identity

Remote enemy references may use:

- normalized short name;
- full name-realm when available;
- GUID only when legally exposed.

No packet may claim a private identifier that the sender could not legally
observe.

## Message Families

### `HELLO`

Purpose:

- announce addon presence and protocol compatibility.

Sentinel -> Commander fields:

- addon version;
- protocol version;
- class;
- current role;
- capabilities flags.

Rate:

- on join;
- on reload;
- at most once every 20 seconds otherwise.

### `STATE`

Purpose:

- sender liveness and compact personal state.

Fields:

- alive/dead;
- connected/disconnected;
- local assignment reachability;
- healer range state;
- current location token if legal and available.

Rate:

- every 2 seconds maximum;
- immediate on alive/dead change.

### `OBS_VISIBLE`

Purpose:

- bounded visible-unit truth.

Fields:

- enemy identity;
- visible yes/no;
- local range yes/no;
- local engaged yes/no;
- timestamp.

Rate:

- at most one update per enemy every 1 second;
- send only on state change or expiry refresh.

### `OBS_CAST`

Purpose:

- share legal visible cast truth.

Fields:

- enemy identity;
- spell id;
- spell name;
- cast start/end when available;
- interruptible yes/no;
- cast/channel state.

Rate:

- send on cast start;
- send on interrupt / stop / finish if observed;
- no polling spam.

### `OBS_CARRIER`

Purpose:

- share legal carrier truth.

Fields:

- carrier identity;
- kind `FLAG` or `ORB`;
- objective label;
- visible health when legal;
- stacks;
- reviewed aura summary;
- location source `VISIBLE`, `LAST_SEEN`, `WIDGET`, `FLAG_MARKER`.

Rate:

- at most once per second per observed carrier;
- immediate on pickup / return / death / handoff changes.

### `OBS_PRESSURE`

Purpose:

- share local fight-shape truth, not strategy.

Fields:

- local friendly count estimate;
- local enemy count estimate;
- healer support yes/no;
- local bad-fight state `NONE`, `WATCH`, `ACTIVE`;
- target label if the local hotspot is mappable to an objective.

Rate:

- at most every 2 seconds;
- only while sender has meaningful local engagement evidence.

### `RELAY_ASSIGN`

Purpose:

- Commander -> player assignment relay.

Fields:

- assigned role;
- assigned location;
- backup role;
- movement authority `STAY`, `MOVE`, `FLOAT`, `ESCORT`, `RETURN`.

Rate:

- on change;
- heartbeat refresh every 8 seconds maximum.

### `RELAY_CONTROL`

Purpose:

- Commander -> player assigned control target relay.

Fields:

- target identity;
- control mode `KICK`, `CC`, `KICK_CC`, `WATCH`;
- priority label;
- hold/swap condition;
- fixed-match assignment flag.

Rate:

- pre-match lock;
- on explicit commander reassignment only.

### `RELAY_ACTION`

Purpose:

- Commander -> player compact action relay.

Fields:

- one-line action;
- death-zone state;
- carrier action;
- leave/stay authority;
- expiry timestamp.

Rate:

- on change;
- never more than once per second.

## Rate Limits

### Sender Limits

Per Sentinel:

- hard cap: 10 packets per second sustained;
- burst cap: 20 packets in any rolling 2-second window;
- lower-priority packets must be dropped before exceeding caps.

Priority order:

1. `HELLO`
2. `STATE`
3. `OBS_CAST`
4. `OBS_CARRIER`
5. `OBS_VISIBLE`
6. `OBS_PRESSURE`

### Commander Limits

- relay traffic must be player-specific where possible;
- Commander must not broadcast full strategic state every refresh;
- unchanged relay packets should be coalesced and suppressed.

## Dedupe and Expiry

### Sequence Rules

Each sender keeps a monotonically increasing `seq`.

Commander stores:

- latest accepted `seq` per sender;
- last envelope signature per sender and family.

Commander must drop:

- duplicate packets;
- out-of-order stale packets older than the accepted sequence window;
- malformed future-version packets.

### Expiry Rules

Default evidence expiry:

- cast truth: 2 seconds after end if no update;
- visible/local-range truth: 3 seconds;
- carrier truth: 2 seconds unless refreshed by authoritative widget/local view;
- pressure truth: 3 seconds;
- assignment relay: 10 seconds;
- action relay: 5 seconds.

Expired remote evidence must degrade to unknown, not remain sticky.

## Authority and Merge Rules

### Authority Ladder

1. Local authoritative widget/API truth
2. Local visible-unit observation on commander client
3. Remote Sentinel observation corroborated by multiple senders
4. Remote Sentinel observation from a single sender
5. Historical/meta/advisory data

### Merge Policy

Remote observations may:

- raise confidence when they corroborate existing truth;
- fill gaps when commander lacks local visibility;
- provide additional recent-local context for Reporter and CombatIntel.

Remote observations may not:

- override authoritative battleground score or objective widget values;
- invent health, aura, cooldown, or position state;
- claim certainty stronger than their source;
- directly change assignments or strategy without passing through existing KWR
  owners.

## Commander Aggregation Table

Commander must maintain one bounded in-memory ingress model:

```text
sentinelIngress = {
    byPlayer = {},
    byEnemy = {},
    byObjective = {},
    lastSeqBySender = {},
    diagnostics = {},
}
```

Requirements:

- bounded size;
- per-session reset;
- debug-readable;
- not persisted across matches except optional diagnostics.

## Sentinel Player Tools Backed By Relay

The relay path exists to power player execution tools, not a second command UI.

Primary relay outputs:

- my assignment;
- my control target;
- my leave/stay authority;
- my death-zone state;
- carrier action;
- compact score pace.

These outputs should feed Sentinel surfaces, not open-ended prose.

## Security and Safety Rules

1. No message may carry secrets or protected values.
2. No message may request a target/focus change.
3. No message may request a spell cast.
4. No message may mutate secure button attributes in combat.
5. No incoming comm may directly call protected APIs.
6. No visible chat output may be used as transport or fallback.
7. Comm diagnostics must never spam player chat during live matches.

## Failure Modes

### Zero Sentinels

Commander runs exactly as today.

### Partial Adoption

Commander uses local truth first and supplements with remote observations from
only participating players.

### Version Mismatch

- older or newer packets are ignored if incompatible;
- `HELLO` may record compatibility diagnostics;
- no downgrade hacks in live runtime.

### Flooding

- sender queue drops low-priority packets first;
- commander ignores excess packets from a sender for a cooldown window;
- diagnostics record throttling.

## Validation Gates

### Gate 1: Policy

Must prove:

- README and release docs explicitly authorize only the reviewed KWR/Sentinel
  addon comm path.

### Gate 2: Validator

Must prove:

- comm APIs are still forbidden everywhere except reviewed comm owners;
- unapproved prefixes fail validation;
- visible chat transport fails validation.

### Gate 3: Protocol

Must prove:

- every family parses deterministically;
- malformed packets are rejected;
- version mismatch handling is deterministic.

### Gate 4: Runtime Safety

Must prove:

- no taint;
- no protected action regressions;
- commander still works with no Sentinels;
- stale remote evidence ages out correctly.

### Gate 5: Soak

Must prove:

- 10 Sentinel senders remain bounded in CPU and memory;
- commander does not rebuild strategic state for every trivial packet;
- packet storms are throttled.

### Gate 6: Truth Quality

Must prove:

- remote observations improve commander truth in real cases;
- remote observations never override stronger authoritative truth incorrectly;
- Reporter, EnemyIntel, and CombatIntel tell the same story after merge.

### Gate 7: Product Value

Must prove:

- Sentinel can replace the practical need for external battleground enemy,
  healer-priority, and battleground map addons for the intended workflow;
- player attention is reduced, not fragmented.

## Required Tests

### Deterministic

- packet encode/decode fixtures;
- sequence and dedupe tests;
- session mismatch drop tests;
- expiry tests;
- authority merge tests;
- relay payload tests.

### Soak

- simulated 10-sender battleground packet load;
- burst throttling tests;
- reconnect tests;
- late-join tests.

### Live RBG

- pre-match handshake;
- gate open;
- first objective split;
- local healer out-of-range state;
- enemy cast observation from non-commander clients;
- carrier pickup and stack updates;
- death-zone escalation and recovery;
- match end teardown.

## Completion Criteria

### Transport Module Complete

Complete only when:

- protocol is implemented exactly as reviewed;
- validator gates pass;
- deterministic and soak tests pass;
- live RBG proof shows bounded stable behavior.

### Product Complete

Complete only when:

- KWR remains the only brain;
- Sentinel receives useful compact player outputs;
- pooled Sentinel observations measurably improve commander truth;
- no unsafe, wrong, or broken communication issue remains open.

## Initial Implementation Order

1. approve this spec;
2. amend README and validator policy;
3. implement prefix registration and `HELLO`;
4. implement `STATE`;
5. implement `OBS_VISIBLE` and `OBS_CAST`;
6. implement `OBS_CARRIER`;
7. add Commander ingress table and merge rules;
8. implement `RELAY_ASSIGN`, `RELAY_CONTROL`, and `RELAY_ACTION`;
9. run deterministic, soak, and live-field validation.

## Explicit Non-Goals

- no shared-file transport;
- no Sentinel-to-Sentinel strategy mesh;
- no arbitrary remote execution;
- no chat-based transport fallback;
- no second command UI in Sentinel;
- no hidden auto-targeting, auto-focus, or auto-casting behavior.

