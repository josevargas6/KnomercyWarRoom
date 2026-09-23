# P07 — Real measurements, responsive scheduling and measured optimization

Parent: [KWR-297](../KWR-297-s-tier-completion-packages.md).
Read [execution standard](execution-standard.md). OVR-09/10;
REC-01/02/03/05/06. Medium builds measurement fixtures; High owns scheduler,
cache invalidation and publication ownership. Start instrumentation after P00;
integrate optimized behavior after P01/P05 contracts stabilize.

## What is already present, and what remains

`tests/host-performance.lua` now measures 30 real host refreshes after five
warmups. `tools/performance-benchmark.ps1` labels that mocked-preview workload
honestly. Extend it; do not revert to injected soak durations. A single aggregate
host measurement is not the required stage, queue, allocation or client evidence.

Existing owners are `Runtime/MatchRuntime.lua`, `Core/Store.lua`, `Core/Util.lua`,
Strategist caches, `Runtime/EncounterHistory.lua`, `FormationAdvisor.lua`, UI
subscribers, `tests/soak.lua`, host performance and the Lua test runner.

## In-progress implementation evidence (2026-09-11)

`MatchRuntime` now retains and publishes bounded P50, P95, P99 and maximum
duration metrics for both strategic refreshes and the separately coalesced
tactical lane. The 500-refresh soak asserts the tactical percentile surface and
the strategic percentile ordering while preserving the existing injected-clock
provenance label. This improves the offline measurement contract; it does not
make a Retail CPU/FPS claim or close the required real-client measurement work.

The host benchmark receipt now also records nearest-rank P50/P95/P99/max over
30 real host refreshes after warmup, plus source revision, Lua runtime command
and host environment. The generated receipt is
`knowledge/offline-performance-benchmark.json`; it remains explicitly scoped to
the mocked preview workload and marks the client budget as requiring Retail
measurement. This closes neither stage-level instrumentation nor the required
before/after optimization and live-client evidence.

Regenerated 2026-09-12 evidence records 30 real host samples after warmup
(P50 216.05 ms, P95 253.41 ms, P99/max 265.73 ms) in
`knowledge/offline-performance-benchmark.json`. These are mocked-preview host
measurements, not Retail budget compliance; its client timing remains explicitly
`REQUIRES_RETAIL_MEASUREMENT`.

## P07-M: measurement contract first

1. Record REAL_HOST, REAL_CLIENT or SIMULATED_CLOCK explicitly. Include candidate/
   source hashes, runtime version/path, hardware/environment, clock type, warmup,
   workload, seeds, sample count and exclusions. Missing timings are unavailable,
   not zero. Keep mock costs only for deterministic scheduler assertions.
2. Instrument capture, objective/prediction, strategy, assignments, Commander,
   Store reconciliation, visible subscribers and render tail separately. Record
   event reception -> enqueue -> eligible execution -> publication -> displayed
   revision, retaining critical versus ordinary events and match transitions.
3. Use a monotonic high-resolution host clock supported by the pinned runtime;
   document whether it measures CPU or elapsed time. Do not assume `os.clock`
   has identical semantics across native Lua and Fengari. Never call CPU time
   event-to-display latency. Expose timing provenance per metric.
4. Report P50/P95/P99/max and sample counts, not averages alone. Keep transition
   outliers separately but visible. Measure allocations/retention with supported
   host tooling or mark unavailable; infer neither from a single memory snapshot.
5. Expand workloads: world idle, preview, hydrated 10/8-player rosters, busy
   objectives/teamfight, mixed event bursts, hidden/shown panels, teardown/reload,
   DevTools off/on. Run repeated matched workloads before and after an optimization
   with fixed seeds/order and equivalent public decisions.

## P07-H: optimize only measured work

1. Create an event-to-domain invalidation table using existing strategic/tactical
   lanes. Every relevant score/objective/roster/spec/target/countdown/end event
   increments the appropriate revision. Cache keys include the required evidence,
   match, bracket and profile revisions; display labels are not truth signatures.
2. Coalesce bursts to latest state without dropping the final event. Cancel
   obsolete timer generations; bounded followups must not starve a final capture,
   disconnect or match end. Critical invalidation clears stale cues immediately,
   even if full strategy recomputation is deferred.
3. Preserve Store-owned immutable published branches and deterministic listener
   order. Reuse a branch only when equal and owned. A shallow copy is permitted
   only for a measured consumer with nested-write tests. No producer may mutate
   state A after B is published; hidden subscribers may skip rendering, not truth.
4. Finish REC-05/06 measured cache decisions: profile-selection invalidation,
   actual reuse, allocation and encounter capture cost. Preserve idempotent
   identity/migration logic; a faster wrong cache is a regression.
5. Avoid expensive full strategy in idle/world contexts and unchanged domains.
   Bound retries, pending queues and subscriber work. Explain the chosen
   invalidation contract before adjusting intervals; no global slower ticker
   that merely hides stalls by delaying important calls.

## Verification and budgets

Use controlled clocks for scheduling correctness: 100 mixed events ending in a
cap/target loss, a new generation during callback execution, a listener requesting
refresh, slow subscriber, hidden view reopening and same-map rematch. Every last
material event reaches the correct next eligible projection. Compare semantic
output against an uncached/full-work reference on the same public inputs.

Use actual host time for optimization comparisons. Record all repeated runs,
variance and any regression, not only the best run. No hard Retail speed claim
can be derived from Fengari CPU milliseconds. Existing client targets remain:

- Strategic P95 <2 ms; no routine refresh >4 ms, with transitions reported.
- Tactical and Store plus visible subscribers: each P95 <=1.5 ms.
- Critical fact-to-display invalidation P95 <=250 ms; ordinary update <=750 ms.
- Routine full strategy <=4/second without losing critical corrections.

These are FIELD acceptance targets; instrumentation paths themselves are CODE
tests. P12 measures actual FPS/client memory and the end-to-display budgets.

## Acceptance criteria

- [ ] Reports separate CPU/elapsed and host/client/simulated provenance correctly.
- [ ] Stage, queue, publication and display measurements have valid sample counts.
- [ ] Each optimization has repeated before/after evidence and semantic equality.
- [ ] Final burst events, immutable Store ownership and cache invalidation tests pass.
- [ ] REC-01/02/03/05/06 get tested dispositions; missing client evidence stays open.

## Rollback and handoff

Retain an uncached/reference path in tests, not a duplicate live pipeline. Roll
back an optimization independently while preserving truthful instrumentation.
Handoff a ranked bottleneck report, event-domain matrix, workload fixtures,
before/after samples, semantic differences (must be justified) and residual risks.
