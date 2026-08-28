# ADR: Runtime work lanes and strategic truth ownership

## Status

Accepted for KWR-274 field-candidate implementation.

## Context

A live rated battleground can generate hundreds of thousands of health, aura,
target, and cast events. Those signals are useful to local presentation, but
they do not independently prove score, objective ownership, carrier state, or
match phase. Sharing one refresh queue made local combat noise compete with
the complete Sensors-to-Commander decision pipeline and concealed the source
of refresh pressure.

## Decision

MatchRuntime remains the single event and publication owner, with three work
lanes:

- Direct UI work updates bounded health/aura presentation without Store
  publication or strategic scheduling.
- Tactical work projects current EnemyIntel and CombatIntel into a copy of the
  published snapshot. It reuses the current prediction, assignments, command,
  and active play. A bounded tactical truth signature may escalate a material
  enemy location, engagement, carrier, death, or priority-cast change to one
  coalesced strategic refresh; repeated equivalent traffic cannot.
- Strategic work is the existing authoritative capture and decision pipeline.
  Score, objective, roster, match-phase, and battleground-system evidence can
  schedule it. A slow recovery heartbeat protects against a missed Retail
  event, but periodic combat presentation does not own strategic truth.

The tactical and strategic queues have independent tokens, coalescing,
durations, and reason attribution. A pending strategic refresh absorbs
tactical work because its capture supersedes the tactical projection.

## Consequences

- Local fight surfaces may be refreshed more often than macro calls without
  producing command churn.
- Strategic calls may remain unchanged through heavy casts and health traffic,
  which is intentional unless authoritative battlefield truth changes.
- Field performance is judged by lane. Routine tactical P95 must satisfy the
  2 ms goal; strategic cost and frequency remain explicit release evidence.
- A missed Retail truth event can remain stale only until the bounded recovery
  heartbeat.
- No saved-variable migration, second Store, second decision engine, or
  doctrine fork is introduced.
