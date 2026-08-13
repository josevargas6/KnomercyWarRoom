# Performance Audit

**Audit date:** 2026-07-13  
**Scope:** Static analysis, deterministic Fengari tests, package validation, and isolated reproductions. No live Retail profiling was available.

## Executive Assessment

The runtime is deliberately bounded in several important places: `MatchRuntime` has a 0.4-second minimum full-refresh interval, most histories have caps, and optional visual systems have explicit rates. Those controls prevent an obvious runaway loop, but they do not prove acceptable combat performance. The current soak test now injects a deterministic cost pattern and records nontrivial timings (`avgMs=0.22166666667108`, `p95Ms=0.79999999998836`, `maxMs=3.2000000000116`), which is enough to prove percentile retention and sample buffering. It is still a synthetic bounded benchmark, not live Retail profiling.

The highest-leverage performance work is to reduce unnecessary full-pipeline publications and prevent expensive observer work before deduplication. Correctness blockers must be repaired first because stale Reporter rows, lossy Store equality, and synthetic coordinates invalidate any optimization baseline.

The new local teamfight command slice is presently event/snapshot driven and presenter-only: it adds no ticker, no `OnUpdate`, no combat-log subscription, and no secure action path. Its cost is included in the normal `MatchRuntime` refresh path and is bounded by roster/enemy problem counts. Live Retail profiling still needs to prove its actual frame-time effect once real local enemy facts are available.

## Existing Budgets And Decision Gate

The repository contains conflicting targets:

| Source | Average | p95 | Maximum | Other |
|---|---:|---:|---:|---|
| `docs/audits/historical-plans/ALPHA_S_TIER_MASTER_PLAN.md` and `docs/audits/historical-plans/S_TIER_EXECUTION_SCORECARD.md` | <=1.5 ms | <=4 ms | fail >6 ms | CPU average <=1%, repeated peak <=3%; memory 25/28/32 MB |
| `PRODUCT_ROADMAP.md`, `PROJECT_HANDOFF.md`, and `QA_CHECKLIST.md` | Not stated | <2 ms | routine <4 ms | <1 MB growth over 30 minutes; median FPS loss <1%; 1% low loss <3% |

**Owner decision required:** adopt one authoritative release budget. For controlled external testing, this audit recommends p95 <=2 ms, routine maximum <4 ms, warning for any refresh >6 ms, hard stop for any refresh >10 ms, less than 1 MB retained growth over 30 minutes, median FPS loss <1%, and 1% low FPS loss <3% relative to the addon-disabled baseline.

## Hot Paths

| ID | Location and path | Frequency and scaling | Allocation/API profile | Gameplay risk | Remediation and regression risk |
|---|---|---|---|---|---|
| PF-001 | `Runtime/MatchRuntime.lua:290-377` full `Refresh`; `Runtime/Sensors.lua` collection; Reporter, EnemyIntel, Strategist, Assignments, Commander | Baseline 1 Hz in PvP; event bursts are coalesced to a 0.4-second minimum, allowing 2.5 full refreshes/second. Sensors scan up to scoreboard 80, roster 40, POIs 30, vignettes 40, flags 8, and vehicles 12 before downstream work. | Rebuilds broad tables, calls many WoW APIs, sorts/copies state, and republishes multiple slices. | Frame-time spikes during roster, health, objective, and combat bursts; delayed calls if stages exceed the refresh budget. | Instrument each stage and reason first, then create domain-specific dirty revisions. Risk is stale cross-domain state if dependencies are incomplete. |
| PF-002 | `Runtime/Verification.lua:443-465`, `BuildEntry` before signature comparison | Every live Store publication, including publications later discarded as duplicate evidence | Calls `MemoryBudget:Summary`, formats strings, and copies broad state before dedupe. | Avoidable allocation and memory API work during combat refreshes. | Compute a cheap signature first and build the full entry only when retained. Low behavioral risk if signatures and retention semantics remain unchanged. |
| PF-003 | `Runtime/MatchRuntime.lua:564-583`, friendly health synchronization | Health event path can queue a full pipeline every 0.35 seconds, approximately 2.86 requests/second before the global refresh gate | A direct roster-bar update already occurs, then the complete sensor-to-commander pipeline is requested. | Redundant heavy work in the highest-frequency combat event family. | Add a health-only state path or defer strategic recomputation to the normal cadence. Medium risk because health thresholds may affect recommendations. |
| PF-004 | `Core/Store.lua:9-34`, `80-101`, `345-415` | Every selector comparison and publication; recursive with table depth and key count | Allocates tokens, sorts sampled keys, stringifies values, and currently samples only 24 arbitrary keys with shallow nested handling. | CPU/GC cost plus incorrect missed publications; optimization cannot be separated from correctness. | Replace with explicit immutable revisions or exact bounded comparisons per slice. High regression risk; repair and characterize first. |
| PF-005 | `Runtime/Reporter.lua` objective pressure, ETA, intent, snapshot paths | Each observation; approximately objectives multiplied by friendly/enemy tracks, plus sorting and copying | Repeated scans across tracked players and objectives; creates snapshot tables and strings. Stale tracks increase effective input size. | Increasing refresh cost and false pressure as group membership changes. | Prune lifecycle first, then index tracks by objective/role and reuse bounded scratch structures where safe. Medium regression risk to strategic calculations. |
| PF-006 | `Runtime/Strategist.lua`, `Runtime/Assignments.lua`, `Runtime/Commander.lua` | Every full refresh even when only a narrow domain changes | Repeated candidate lists, sorts, copied recommendation tables, formatting, and Commander composition. | Unnecessary work on health-only or cosmetic changes; GC churn during matches. | Add input revisions and preserve stable outputs; split composition from strategic computation. Medium-high risk because hidden dependencies exist. |
| PF-007 | `Features/CursorRing.lua:250-385`, `735-777` | Driver `OnUpdate` at 30 Hz while active; orb refresh every 0.12 seconds, about 8.33 Hz, scaled by visible nameplates and a linear orb lookup | Repeated nameplate API calls, list scans, anchor/layout updates, and frame work. | Optional but visible FPS loss in dense fights/nameplate bursts. | Measure enabled/disabled; replace linear lookup with indexed state and update on plate/orb changes. Risk is visual staleness. |
| PF-008 | Sentinel HUD and bridge update paths, including HUD `OnUpdate` and unresolved watch scans | HUD approximately 4 Hz; bridge scans group and up to 40 nameplates while resolving watches | Repeated unit/nameplate APIs and UI text/layout updates. | Additive cost when Sentinel is installed with War Room; current soak does not cover it. | Add dirty flags, bounded backoff, and combined-package profiling. Medium risk to watch responsiveness. |
| PF-009 | `Runtime/ObjectiveIntel.lua` carrier aura scanning | Carrier candidates multiplied by two aura filters and bounded group size; cache approximately 0.5 seconds | WoW aura API calls and temporary carrier records | Likely bounded, but can coincide with objective-message and roster bursts. | Preserve cache and instrument hit/miss rate before changing. Low priority unless live evidence exceeds budget. |
| PF-010 | Eager data loading from TOC, including `Data/BattlePlans.lua` and other static doctrine/map tables | Once at addon load; source data is material in aggregate, with `BattlePlans.lua` approximately 87 KB and loaded data source approximately 255 KB in the inspected checkout | Lua parsing and permanent table memory at startup | Login/reload latency and baseline memory, especially when features are disabled. | Measure first. Consider lazy bounded indexes only if startup or memory exceeds budget. Risk is init-order complexity. |
| PF-011 | Bounded histories using `table.remove(list, 1)` | On capped journal/evidence/history insertion | O(n) shift, but caps are small | No material current risk | Retain unless profiling identifies it. Micro-optimization is not justified. |
| PF-012 | Local teamfight planner: FactStore, problem detector, assignment scorer/optimizer, kill-target selector, presenter payloads | Once per full `MatchRuntime` refresh; scales by local enemies multiplied by friendlies for assignment candidates | Creates bounded candidate/problem/assignment tables; no ticker, no raw API calls outside adapters, no secure action mutation | Could add refresh cost in dense nameplate fights if local enemy data grows, but current path is bounded and deterministic | Keep in the main refresh path for now; profile in Retail. If it exceeds budget, add dirty revisions or skip planning when no local enemy/friendly facts changed. |

## Allocation Indicators

A static source count found approximately 88 table-copy patterns, 34 sort calls, 198 formatting calls, and 129 concatenation sites. These are orientation signals, not runtime allocation measurements. The dominant concern is repeated reconstruction of complete snapshots and formatted outputs in PF-001 through PF-006, not isolated string operations.

## Event And Burst Analysis

- `MatchRuntime` provides useful global coalescing, but request sources can continuously hold the runtime at its maximum 2.5 full refreshes/second.
- Friendly health events have an additional 0.35-second queue threshold that is faster than the global full-refresh limit and should not be used as a separate performance guarantee.
- Roster, zone, objective, scoreboard, unit-state, and UI callbacks converge on shared mutable state. Reason counts are not currently sufficient to attribute refresh cost to a source.
- Finite settle refreshes after zone, roster, and match-end transitions are defensible, but live measurement must prove they do not overlap into sustained bursts.
- Cursor Ring and Sentinel are independent update loops, so full-package testing must measure additive cost rather than validating each system alone.

## Memory And Cache Risks

- `Sensors` specialization aliases can accumulate by GUID and name for the process lifetime without an explicit bound.
- Assignment override records can retain tombstones and have no documented cap or migration contract.
- MemoryBudget does not currently observe its intended current-state bucket due to the callback signature defect, so existing budget summaries cannot be treated as enforcement evidence.
- Most persistent learning, journal, evidence, and profile collections have explicit caps. Those bounds should be preserved and asserted in tests.
- Current retained-memory growth is unmeasured; Fengari cannot represent Retail Lua/UI allocation behavior.

## Measurement Plan

1. Add opt-in stage timing around Sensors, Reporter, EnemyIntel, Strategist, Assignments, Commander, Verification, UI dispatch, Cursor Ring, and Sentinel. Record count, average, p50, p95, p99, maximum, and refresh reason without storing player-identifying payloads.
2. Record request count, coalesced count, executed count, and maximum queue delay by reason. A high coalescing ratio is useful; a sustained 2.5 Hz execution rate is a warning.
3. Sample `collectgarbage("count")` before activation, after warm-up, and every minute for 30 minutes. Force no collection in production; observe natural high-water and post-GC retained values in a controlled profile.
4. Compare addon disabled, base War Room, all commander surfaces visible, Cursor Ring enabled, and War Room plus Sentinel.
5. Test 1-player, 10-player, and 40-player groups; 0, 20, and 40 visible nameplates; idle staging, opening clash, sustained team fight, roster churn, objective burst, reconnect, and match end.
6. Capture Retail frame timings/FPS with identical graphics, combat-log, nameplate, UI scale, and encounter conditions. Use multiple runs because battleground load is variable.
7. Validate stale-state correction before baseline collection so workload and recommendations represent real membership.

## Required Benchmarks

| Benchmark | Duration/input | Pass threshold | Failure action |
|---|---|---|---|
| Full pipeline stage benchmark | At least 10,000 synthetic bounded refreshes with advancing timer | p95 <=2 ms; no refresh >10 ms; output deterministic | Block external build and profile the dominant stage |
| Live 10-player match | Complete rated battleground or representative equivalent | Median FPS loss <1%; 1% low loss <3%; no sustained >4 ms stage | Disable optional hotspot or repair before expansion |
| Worst-case burst | Full group, 40 nameplates, health/roster/objective burst | Queue remains bounded; no error; no refresh >10 ms | Stop test and retain trace/reason counts |
| Thirty-minute memory | Active match-equivalent workload | Retained growth <1 MB after warm-up; caches remain within declared caps | Identify owner and add cap/invalidation |
| Optional visual systems | Cursor Ring and Sentinel separately and together | Each remains within aggregate budget; no layout storm | Default offending module off pending repair |
| Recovery benchmark | Reconnect, `/reload`, group leave/rejoin | No duplicate ticker/callback; rate returns to baseline | Treat as lifecycle blocker |

## Optimization Order

1. Repair Store correctness, Reporter pruning, coordinate provenance, and MemoryBudget observation so measurements are trustworthy.
2. Move Verification dedupe before expensive evidence construction.
3. Separate friendly-health visual synchronization from full strategic refreshes.
4. Introduce domain revisions and stage instrumentation before cache-heavy refactors.
5. Optimize Cursor Ring and Sentinel only with enabled/disabled live evidence.
6. Defer startup lazy-loading and bounded-history micro-optimizations unless measured budgets fail.

## Current Evidence And Limits

- `tests/soak.lua` completed 500 refreshes, retained bounded Commander/evidence histories, and now proves that the runtime preserves injected percentile and peak timing instead of collapsing to all-zero samples.
- `tools/validate.ps1`, knowledge audit, smoke, soak, and an out-of-tree package build all completed successfully. These checks validate structural and deterministic contracts, not live frame time.
- No Retail profiler capture, FPS comparison, garbage-collection trace, full-group run, nameplate stress test, or Sentinel combined-package benchmark was completed.
- Performance readiness is therefore **not demonstrated**. External testing must remain controlled until Phase 0 correctness repairs and the Phase 3 measurement baseline are complete.
