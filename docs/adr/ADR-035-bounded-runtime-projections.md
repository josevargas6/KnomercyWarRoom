# ADR-035: Bounded runtime projections

Status: Accepted
Date: 2026-09-20

## Context

Alpha26 NODE/CART captures failed CPU and sampled peak-memory budgets despite
correct clock ownership. Host attribution found redundant full-state copying,
per-refresh history sorting and repeated derivation from unchanged inputs.

## Decision

Store reconciles producer values directly against immutable published branches.
Changed producer tables are copied; unchanged published branches are shared.
Observers must not mutate published state. The optional publication finalizer
records duration after projection but before diagnostics publication/notification.
UI listeners, communication and audio are not included in that metric.

Roster summaries use a four-entry defensive-copy cache keyed by capabilities and
provenance, invalidated by patch identity. Formation caches use actual composition
inputs, not unused death/connectivity state. Actor profiles and movement estimates
are reused only within one evaluation. History aging runs at most five seconds
apart, while new identities trigger immediate capacity enforcement. Composition
ranking retains original tie-breaks and constructs only its winning result.

## Verification and consequences

Regression fixtures cover ownership isolation, finalizer ordering, summary
invalidation/eviction, independent composition ranking, actor/movement work counts
and history capacity/aging. Sequential instrumented host comparisons use the
archived alpha26 developer source and identical NODE/CART traces:

| Workload | Alpha26 ms | Alpha27 ms | Copied tables before / after |
| --- | ---: | ---: | ---: |
| NODE | 11288.277 | 6377.207 | 90656 / 37777 |
| CART | 10505.668 | 6071.009 | 88037 / 36953 |

Each workload has 20 outer ticks, including strategic/tactical refreshes and mock
timer followups. All 20 action/plan/assignment records match for each pair.
Logs are `artifacts/alpha27-{baseline,candidate}-live-{node,cart}.log`.
Host times and copied-table counts are comparative diagnostics, not Retail P95 or
MB measurements. No forced combat GC, budget relaxation or feature removal.
Saved-variable schemas and secure-frame behavior are unchanged. Rollback uses
the archived alpha26 packages and deployment backup.
