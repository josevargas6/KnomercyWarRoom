# Remediation Work Plan

**Recommendation basis:** `LIMITED GO - suitable only for controlled testers under stated restrictions`  
**Ordering rule:** Complete Phase 0 in order, rerun the full gate suite, then permit only controlled external testing. Later items may be parallelized only where their dependency field allows it.
## Execution Update - 2026-07-14

Completed offline in this execution pass:

- `R0-001` Exact Store publication semantics
- `R0-002` Objective source authority
- `R0-003` Coordinate provenance and truthfulness
- `R0-004` Combat-suppression request-path hardening (Retail proof still required)
- `R0-005` Canonical player identity and legacy-safe override resolution
- `R1-005` Typed SavedVariables normalization and malformed-field recovery
- `RA-LIFE-017` Explicit interrupted-AAR lifecycle persistence
- `R1-006` Objective-message carrier scoping for named flag return/capture events
- `R5-002` Artifact provenance and reproducibility manifests, with documented PowerShell ZIP-container exception
- `TF-001` Local teamfight multi-assignment command slice with safe adapters, compliance/ruleset gates, normalized FactStore/teamfight state, assignment optimizer, kill-target selector, countdown, display-only target assist, and debug reasons

Fresh evidence:

- `./tools/validate.ps1` passed
- `./tools/knowledge-audit.ps1` passed
- `tests/smoke.lua` passed
- `tools/replay-test-runner.lua tests/smoke.lua` passed
- `tests/soak.lua` passed
- `./tools/build.ps1` passed and package audit succeeded

Current next execution order:

1. Retail-proof `R0-004` and the remaining live release gates.
2. Retail-proof `TF-001` with real battleground facts, display-only target assist, and no protected-action side effects.
3. Finish the remaining schema/lifecycle matrix items that still need Retail or broader fixture coverage.
4. Strengthen the remaining live performance-proof gaps, especially Retail budget validation and worst-case profiling.
5. Keep package, workflow, and scorecard artifacts aligned to the repaired baseline.

Also completed after the original audit report:

- `R4-003` distribution-package runtime certification path
- `R5-001` release metadata/version drift cleanup
- tag-versus-TOC release guard in GitHub workflow
- `R3-001` duplicate verification-entry work reduction
- `R3-002` ordinary friendly health churn refresh suppression
- `R3-003` truthful command-stability certification counters

## Phase 0: Blockers And Safety

### R0-001 — Exact Store Publication Semantics

**Priority:** P1  
**Objective:** Eliminate lossy equality/token behavior that suppresses legitimate nested-state publications.  
**Rationale:** `Core/Store.lua` samples only 24 keys and reduces deeper tables to array length; a changed nested value was reproduced as unchanged. Every downstream selector depends on this authority.  
**Files/modules:** `Core/Store.lua`; Store selector consumers; new focused Store tests.  
**Dependencies:** None. Must precede performance baselining and domain revision work.  
**Implementation steps:** Characterize current selector contracts; replace sampling with exact bounded comparison or explicit immutable revisions; retain callback ordering and API signatures; document equality semantics.  
**Tests:** Deep map value change, key 25+ change, same-length array content change, alias mutation, unchanged reuse, owner unsubscribe, callback error isolation.  
**Commands:** Smoke, soak, validation, knowledge audit, build; isolated Store regression suite under Fengari.  
**Acceptance:** Every semantic change publishes exactly once, unchanged state reuses safely, no callback API break, all existing tests pass.  
**Rollback:** Revert only the Store comparison implementation and its tests; do not revert unrelated state producers.  
**Risk:** High because Store semantics are cross-cutting; mitigate with characterization tests and a small implementation diff.  
**Independent?:** Yes for implementation; no for final integration.  
**High-reasoning?:** Yes.

### R0-002 — Objective Source Authority

**Priority:** P1  
**Objective:** Prevent lower-confidence POI observations from downgrading fresh widget objective ownership.  
**Rationale:** `Runtime/Sensors.lua` assigns authority 400 only to source `ui_widget`, while widget rows use source `widget`; a same-label POI then wins and changes `FRIENDLY/CONTROLLED` to `UNKNOWN/MAP`.  
**Files/modules:** `Runtime/Sensors.lua`; objective sensor fixtures/tests.  
**Dependencies:** None; integrate after R0-001 to observe state reliably.  
**Implementation steps:** Define canonical source enum and priority table; normalize widget provenance; specify tie/freshness rules; reject lower-authority overwrite while preserving complementary metadata.  
**Tests:** Widget versus POI conflict in both orders, stale widget fallback, duplicate labels, missing owner, map transition, deterministic iteration order.  
**Commands:** Focused sensor test, smoke, soak, validation, knowledge audit, build.  
**Acceptance:** Fresh widget owner/state remains authoritative; lower-confidence data can fill absent fields but cannot downgrade; no map fixture regression.  
**Rollback:** Restore the previous merge policy behind one localized priority function.  
**Risk:** Medium; overly strong authority could retain stale ownership, so freshness tests are mandatory.  
**Independent?:** Yes.  
**High-reasoning?:** Yes.

### R0-003 — Coordinate Provenance And Truthfulness

**Priority:** P1  
**Objective:** Ensure enemy map positions are rendered only from observed enemy coordinates and never inferred from teammates or semantic assignments.  
**Rationale:** `Runtime/EnemyIntel.lua` substitutes friendly/assignment coordinates, and `Runtime/Reporter.lua` converts semantic locations to coordinates; the isolated reproduction marked an unobserved enemy as located. This contradicts architecture and release truthfulness policy.  
**Files/modules:** `Runtime/EnemyIntel.lua`, `Runtime/Reporter.lua`, commander/map consumers, evidence schemas, tests.  
**Dependencies:** Owner confirmation that approximate semantic presence may remain text-only; R0-001 for reliable publication.  
**Implementation steps:** Add coordinate provenance; permit map dots only for direct supported observations; keep semantic objective association separate; expire stale observations; prevent legacy records without provenance from rendering as observed.  
**Tests:** Direct observation, teammate-only inference, assignment-only inference, stale coordinate, map change, missing coordinate, evidence serialization, UI map marker visibility.  
**Commands:** Focused provenance tests, smoke, soak, validation, knowledge audit, build; Retail map verification.  
**Acceptance:** No enemy dot is produced without supported direct provenance; semantic recommendations remain available without false precision.  
**Rollback:** Disable enemy positional rendering while retaining semantic roster intelligence; do not restore fabricated coordinates.  
**Risk:** Medium product impact because fewer dots will appear; correctness and user trust take precedence.  
**Independent?:** Mostly; UI verification depends on affected consumers.  
**High-reasoning?:** Yes.

### R0-004 — Combat-Lockdown-Safe Visibility

**Priority:** P1  
**Objective:** Route all visibility/layout changes involving secure frames through a single combat-safe queue.  
**Rationale:** `UI/CombatRoster.lua` creates `SecureUnitButtonTemplate` rows and `UI/QuickCalls.lua` creates secure action buttons, but Store/context paths in CombatRoster and `UI/MainWindow.lua` can call `Hide` directly before combat checks. Static evidence is strong; exact Retail taint behavior requires live proof.  
**Files/modules:** `UI/CombatRoster.lua`, `UI/MainWindow.lua`, `UI/QuickCalls.lua`, secure UI tests/manual scripts.  
**Dependencies:** Retail client verification; no architectural dependency.  
**Implementation steps:** Inventory every Show/Hide/layout/attribute path; centralize requested versus applied visibility; defer protected changes during lockdown; flush once after `PLAYER_REGEN_ENABLED`; preserve rejected-state feedback.  
**Tests:** Enter combat while visible/hidden, Store-driven context changes, repeated toggles, reload into combat if reproducible, regen flush, no duplicate queue, secure click remains functional.  
**Commands:** Static validator, smoke, build; `/console taintLog 1` and Retail combat matrix.  
**Acceptance:** No blocked-action/taint errors; protected state is unchanged during lockdown; final requested state applies once after combat.  
**Rollback:** Default affected secure surface hidden and disable its toggle pending repair.  
**Risk:** High because taint can be nonlocal and client-version sensitive.  
**Independent?:** Yes.  
**High-reasoning?:** Yes.

### R0-005 — Canonical Player Identity And Legacy Migration

**Priority:** P2, elevated to Phase 0  
**Objective:** Use GUID/full normalized identity internally while preserving existing short-name SavedVariables through explicit migration.  
**Rationale:** `Runtime/AssignmentOverrides.lua` keys by short name and `Runtime/EnemyIntel.lua` can merge records sharing a short name; two distinct GUIDs were reproduced as one record. Deferring this creates external-test data that is harder to migrate safely.  
**Files/modules:** `Runtime/AssignmentOverrides.lua`, `Runtime/EnemyIntel.lua`, Sensors/Reporter identity helpers, UI lookup consumers, SavedVariables migration in bootstrap, fixtures.  
**Dependencies:** Owner decision for conflict behavior when one legacy short name maps to multiple identities; backup/rollback schema.  
**Implementation steps:** Define canonical ID and display-name contracts; isolate short-name fallback; migrate legacy keys without deletion; quarantine ambiguous records; update lookups; retain display compatibility.  
**Tests:** Same short name/different realm and GUID, missing GUID, reconnect identity enrichment, cross-faction names, legacy override migration, ambiguous migration, idempotent reload, rollback fixture.  
**Commands:** Migration tests, smoke, soak, validation, knowledge audit, build; fresh/upgrade Retail checks.  
**Acceptance:** Distinct GUIDs never merge; legacy unambiguous settings survive; ambiguous data is preserved and surfaced safely; migration is idempotent.  
**Rollback:** Read both old and new keys for one compatibility window; restore from backed-up SavedVariables if migration validation fails.  
**Risk:** High data-compatibility risk; requires fixture-based migration proof.  
**Independent?:** No; coordinate and Reporter records share identity assumptions.  
**High-reasoning?:** Yes.

## Phase 1: Correctness And Recovery

### R1-001 — Reporter Membership Lifecycle

**Priority:** P2  
**Objective:** Remove or age friendly tracks that disappear from the current roster.  
**Rationale:** `Runtime/Reporter.lua` ages records only when retracked and snapshots all stored tracks; removal was reproduced with coverage remaining at one instead of zero.  
**Files/modules:** `Runtime/Reporter.lua`, `Runtime/MatchRuntime.lua`, roster transition tests.  
**Dependencies:** R0-005 identity contract.  
**Implementation steps:** Pass an authoritative roster generation; mark seen records; prune or terminally age unseen friendlies after each complete observation; preserve temporary API-missing grace.  
**Tests:** Group leave, role swap, reconnect, transient missing roster, map transition, full disband, no mutation-during-iteration defect.  
**Commands:** Focused Reporter tests, smoke, soak, validation, build.  
**Acceptance:** Absent players stop contributing to coverage/pressure within the documented grace period and can rejoin cleanly.  
**Rollback:** Increase grace or disable stale records from calculations without deleting them.  
**Risk:** Medium; aggressive pruning can flicker during API gaps.  
**Independent?:** No; depends on identity.  
**High-reasoning?:** Yes.

### R1-002 — MemoryBudget Subscription Contract

**Priority:** P2  
**Objective:** Make MemoryBudget evaluate current Store state and add a contract test for subscriber argument order.  
**Rationale:** Store calls `(owner, nextState, previousState)`, but `MemoryBudget:Update(_, state)` receives previous state; the reproduction made zero memory measurements when one was expected.  
**Files/modules:** `Runtime/MemoryBudget.lua`, `Core/Store.lua` contract tests.  
**Dependencies:** R0-001 Store contract characterization.  
**Implementation steps:** Correct the callback signature; assert revision/bucket transitions; avoid duplicate measurements; retain threshold behavior.  
**Tests:** First publication, bucket crossing, unchanged revision, previous/current distinction, missing memory API, warning/recovery transitions.  
**Commands:** Focused test, smoke, soak, validation, build.  
**Acceptance:** Exactly one measurement occurs at each intended current-state threshold and summaries reflect the current revision.  
**Rollback:** Disable automatic sampling and retain explicit `/kwr perf` sampling.  
**Risk:** Low-medium; corrected sampling can expose previously hidden threshold warnings.  
**Independent?:** Mostly.  
**High-reasoning?:** No.

### R1-003 — Strategy And Assignment Sequencing

**Priority:** P2  
**Objective:** Remove the one-cycle/empty assignment-integrity dependency from Strategist evaluation.  
**Rationale:** `Runtime/MatchRuntime.lua` evaluates Strategist before Assignments integrity exists, while Strategist reads integrity-derived doctrine flags.  
**Files/modules:** `Runtime/MatchRuntime.lua`, `Runtime/Strategist.lua`, `Runtime/Assignments.lua`, contract tests.  
**Dependencies:** R0-001; owner choice between two-stage strategy or previous-cycle semantics.  
**Implementation steps:** Define stage inputs; compute base strategy, assignments/integrity, then bounded refinement, or explicitly use tagged previous-cycle integrity; prohibit implicit partially built state.  
**Tests:** Only-defender, friendly-wave, missing assignment, first refresh, unchanged refresh, oscillation prevention.  
**Commands:** Pipeline tests, smoke, soak, validation, build.  
**Acceptance:** Integrity-dependent flags appear in the intended cycle and outputs converge deterministically without extra unbounded passes.  
**Rollback:** Disable integrity-derived flags while retaining base strategy.  
**Risk:** Medium-high due to recommendation behavior changes.  
**Independent?:** No; central pipeline.  
**High-reasoning?:** Yes.

### R1-004 — Recovery Gap Semantics

**Priority:** P3  
**Objective:** Prevent a fully covered objective from being emitted as an urgent recovery gap.  
**Rationale:** `Runtime/Assignments.lua` selects the first coverage row as `criticalGap`; reproduction returned urgent with “needs 0 more.”  
**Files/modules:** `Runtime/Assignments.lua`, Commander response tests.  
**Dependencies:** R1-003 sequencing contract.  
**Implementation steps:** Select only positive deficits; define stable no-gap output; preserve ordering among actual deficits.  
**Tests:** All covered, one deficit, tied deficits, empty ledger, stale assignments.  
**Commands:** Focused tests, smoke, validation, build.  
**Acceptance:** No urgent recovery call exists when all deficits are zero; real highest-priority gaps remain deterministic.  
**Rollback:** Suppress recovery output when deficit is nonpositive.  
**Risk:** Low.  
**Independent?:** Mostly.  
**High-reasoning?:** No.

### R1-005 — SavedVariables Validation And Migration Framework

**Priority:** P2  
**Objective:** Validate root and nested types, migrate by version, and recover malformed data without deleting valid user state.  
**Rationale:** Bootstrap merge defaults preserve incompatible scalar types, migration coverage stops at an older version, and current schema assignment is unconditional.  
**Files/modules:** addon bootstrap, SavedVariables defaults/migrations, `Runtime/OpponentModels.lua`, Sentinel SavedVariables, fixtures.  
**Dependencies:** R0-005 identity migration; owner decisions for corrupt-field recovery and Sentinel schema ownership.  
**Implementation steps:** Add typed schema normalization; sequence idempotent migrations; copy invalid branches to bounded recovery storage or log; add explicit current version; test forward-version safety.  
**Tests:** Fresh install, each supported prior fixture, malformed root/nested/list, missing fields, future schema, reload/relog idempotence, partial write recovery.  
**Commands:** Migration suite, smoke, soak, validation, build; Retail upgrade matrix.  
**Acceptance:** Valid settings and learned data survive; malformed fields fall back safely; no migration repeats or silent wholesale reset.  
**Rollback:** Read-only compatibility mode plus restore from pre-migration backup.  
**Risk:** High due to user data.  
**Independent?:** No.  
**High-reasoning?:** Yes.

### R1-006 — Objective Message And Carrier Policy

**Priority:** P2  
**Objective:** Define supported locales and correct carrier-clearing semantics.  
**Rationale:** `Runtime/ObjectiveIntel.lua` parses English messages/aura names and clears all flag carriers on a returned/captured message. Live semantics and localization coverage are unproven.  
**Files/modules:** `Runtime/ObjectiveIntel.lua`, locale data, objective fixtures, release docs.  
**Dependencies:** Product decision: English-only controlled alpha or localized parser support.  
**Implementation steps:** Separate localized patterns from logic; scope carrier removal by flag/team when data permits; define fallback to authoritative APIs; gate unsupported locales explicitly.  
**Tests:** Each message family, multiple carriers, returned/captured flag specificity, unsupported locale, missing globals, duplicate/out-of-order messages.  
**Commands:** Parser tests, smoke, validation, build; live locale verification.  
**Acceptance:** Supported locales parse deterministically; one event cannot erase unrelated carriers; unsupported locales degrade without false claims.  
**Rollback:** Disable message-derived carrier state and use authoritative API/aura sources only.  
**Risk:** Medium-high because live strings vary by client locale and battleground.  
**Independent?:** Yes.  
**High-reasoning?:** Yes.

## Phase 2: Architecture Stabilization

### R2-001 — Domain Revisions And Dirty Contracts

**Priority:** P2  
**Objective:** Replace broad implicit equality dependencies with explicit revisions for roster, objectives, health, enemies, strategy, and UI.  
**Rationale:** Full Store snapshots and hidden cross-domain reads make both correctness and performance fragile.  
**Files/modules:** `Core/Store.lua`, `Runtime/MatchRuntime.lua`, domain producers/consumers.  
**Dependencies:** R0-001, R1-003, R3-005 instrumentation design.  
**Implementation steps:** Map reads/writes; define revision ownership; publish immutable slice contracts; retain legacy aggregate state during transition; migrate one domain at a time.  
**Tests:** Revision changes only on semantic change, cross-domain dependency matrix, unchanged output reuse, compatibility selectors.  
**Commands:** Full suite and new contract tests.  
**Acceptance:** Each stage declares inputs; narrow changes do not recompute unrelated domains; existing public state remains compatible.  
**Rollback:** Keep aggregate refresh as fallback behind an internal flag.  
**Risk:** High; bounded subsystem refactor, not architecture rebuild.  
**Independent?:** No.  
**High-reasoning?:** Yes.

### R2-002 — Reporter/UI Boundary

**Priority:** P3  
**Objective:** Remove UI-specific assumptions from Reporter state and expose stable domain snapshots.  
**Rationale:** Reporter combines tracking, strategic calculations, formatting, and consumer-facing snapshot construction.  
**Files/modules:** `Runtime/Reporter.lua`, `UI/ReporterMap.lua`, Commander/Strategist consumers.  
**Dependencies:** R1-001 and R2-001.  
**Implementation steps:** Define domain DTOs; move presentation formatting to UI/Commander adapters; preserve old snapshot shape through compatibility adapter.  
**Tests:** Snapshot parity, no UI dependency in runtime, stale lifecycle, consumer contract fixtures.  
**Commands:** Full suite, validation, build.  
**Acceptance:** Reporter owns observed domain truth only; consumers receive documented immutable views.  
**Rollback:** Retain adapter and route consumers to legacy snapshot.  
**Risk:** Medium.  
**Independent?:** No.  
**High-reasoning?:** Yes.

### R2-003 — Bootstrap Health And Capability Status

**Priority:** P3  
**Objective:** Prevent partial module initialization from reporting the addon fully ready.  
**Rationale:** Bootstrap catches module failures and can continue to a ready state without a clear required/optional capability contract.  
**Files/modules:** addon bootstrap, Diagnostics, slash status, module initializers.  
**Dependencies:** Owner definition of required versus optional modules.  
**Implementation steps:** Classify modules; record init result and cause; block runtime activation on required failures; expose degraded optional state; make teardown idempotent.  
**Tests:** Inject each init failure, partial teardown, reload, optional module absent, required module absent.  
**Commands:** Fault-injection tests, smoke, validation, build.  
**Acceptance:** Ready means all required capabilities initialized; degraded mode is explicit and actionable.  
**Rollback:** Fail closed with runtime disabled and diagnostics available.  
**Risk:** Medium; stricter startup may reveal latent failures.  
**Independent?:** Yes.  
**High-reasoning?:** Yes.

### R2-004 — Retention Contract Unification

**Priority:** P3  
**Objective:** Centralize and test limits for journals, evidence, learning, profiles, encounters, caches, and overrides.  
**Rationale:** Most caps exist, but documentation disagrees and some caches/overrides are unbounded or absent from MemoryBudget.  
**Files/modules:** retention-owning runtime modules, MemoryBudget, policy/docs after code agreement.  
**Dependencies:** R1-002, R1-005.  
**Implementation steps:** Inventory owner/cap/eviction; define constants; bound or justify caches; include all persistent classes in summaries; preserve oldest/newest semantics.  
**Tests:** Cap+1 eviction, reload persistence, tombstone cleanup, memory summary completeness.  
**Commands:** Soak, focused retention tests, validation, build.  
**Acceptance:** Every collection has an owner, cap, eviction rule, and assertion; docs match code.  
**Rollback:** Restore prior caps while retaining observability.  
**Risk:** Medium due to learned-data retention changes.  
**Independent?:** Mostly.  
**High-reasoning?:** No.

### R2-005 — Active AAR Interruption Policy

**Priority:** P3  
**Objective:** Define what happens to an active match record on reload, relog, disable, or disconnect.  
**Rationale:** `Runtime/AAR.lua` persists on normal finish; disable unsubscribes without an explicit interrupted-record contract.  
**Files/modules:** `Runtime/AAR.lua`, bootstrap lifecycle, SavedVariables schema, UI history.  
**Dependencies:** R1-005 migration framework and product decision to persist or discard partial records.  
**Implementation steps:** Mark interrupted sessions; persist a bounded resumable or diagnostic summary; prevent duplicate completion after reconnect; disclose partial status.  
**Tests:** Reload/relog/disconnect/disable mid-match, resume, normal finish, duplicate finish.  
**Commands:** Lifecycle tests, smoke, build; Retail matrix.  
**Acceptance:** No silent ambiguous record loss or duplicate completed AAR; policy is visible to users.  
**Rollback:** Explicitly discard partial records with one diagnostic reason.  
**Risk:** Medium data semantics.  
**Independent?:** No.  
**High-reasoning?:** Yes.

## Phase 3: Performance

### R3-001 — Verification Cheap Dedupe

**Priority:** P2  
**Objective:** Avoid building full evidence entries and memory summaries for duplicate publications.  
**Rationale:** `Runtime/Verification.lua` performs expensive work before signature rejection.  
**Files/modules:** `Runtime/Verification.lua`, MemoryBudget integration.  
**Dependencies:** R0-001 and R1-002.  
**Implementation steps:** Compute a stable cheap signature from revisions; return on duplicate; build/copy/format only retained evidence.  
**Tests:** Duplicate versus changed evidence, memory sample count, retained payload parity, signature collision cases.  
**Commands:** Benchmark, smoke, soak, validation, build.  
**Acceptance:** Duplicate publications perform no full evidence construction; retained evidence is unchanged.  
**Rollback:** Restore old builder order.  
**Risk:** Low-medium if signature inputs are incomplete.  
**Independent?:** Yes after dependencies.  
**High-reasoning?:** No.

### R3-002 — Friendly Health Fast Lane

**Priority:** P2  
**Objective:** Keep responsive health UI without triggering unnecessary complete strategic refreshes.  
**Rationale:** The current 0.35-second health synchronization duplicates a direct UI update and queues the full pipeline.  
**Files/modules:** `Runtime/MatchRuntime.lua`, Sensors health slice, CombatRoster/Commander consumers.  
**Dependencies:** R2-001 domain revisions and R3-005 timing.  
**Implementation steps:** Define health-only state; update bars immediately; mark strategic health dependency for normal cadence; coalesce burst changes.  
**Tests:** Health thresholds, deaths/resurrections, missing units, burst events, strategy freshness bound.  
**Commands:** Burst benchmark, smoke, soak, live profile.  
**Acceptance:** UI health remains responsive; full refresh execution rate does not increase with health-event rate; strategic delay stays within documented bound.  
**Rollback:** Return to full refresh behind a diagnostic flag.  
**Risk:** Medium.  
**Independent?:** No.  
**High-reasoning?:** Yes.

### R3-003 — Cursor Ring Event-Driven Updates

**Priority:** P3  
**Objective:** Reduce 30 Hz and 8.33 Hz work when visual state is unchanged.  
**Rationale:** Cursor Ring repeatedly scans and reanchors in dense nameplate conditions.  
**Files/modules:** `Features/CursorRing.lua`.  
**Dependencies:** R3-005 live baseline.  
**Implementation steps:** Index orbs; update on nameplate/orb/config changes; retain a low-rate safety reconcile; suspend fully when hidden.  
**Tests:** Plate add/remove, target changes, cursor movement, config changes, disable, combat burst.  
**Commands:** Optional-module benchmark, smoke, validation, build.  
**Acceptance:** Same visual behavior; inactive cost is zero-equivalent; enabled aggregate budget passes.  
**Rollback:** Restore prior cadence or default feature off.  
**Risk:** Medium visual staleness.  
**Independent?:** Yes after measurement.  
**High-reasoning?:** No.

### R3-004 — Sentinel Watch Backoff

**Priority:** P3  
**Objective:** Bound additive HUD and unresolved-watch scans in the combined package.  
**Rationale:** Sentinel runs independent 4 Hz HUD work and group/nameplate resolution not covered by current soak tests.  
**Files/modules:** Sentinel HUD/Bridge modules and package integration tests.  
**Dependencies:** R3-005 combined-package baseline.  
**Implementation steps:** Add dirty triggers and exponential bounded backoff; stop scanning resolved/expired watches; avoid duplicate layout.  
**Tests:** 0/20/40 nameplates, full group, unresolved/resolved/expired watch, addon disable, reconnect.  
**Commands:** Combined live benchmark, package build/audit.  
**Acceptance:** Watch latency remains within policy and combined package passes frame/memory budgets.  
**Rollback:** Disable Sentinel integration/default HUD while retaining War Room.  
**Risk:** Medium responsiveness.  
**Independent?:** Yes after measurement.  
**High-reasoning?:** No.

### R3-005 — Runtime Performance Telemetry

**Priority:** P2  
**Objective:** Produce trustworthy, privacy-safe stage and burst measurements.  
**Rationale:** Current soak timing is always zero and no live baseline exists.  
**Files/modules:** `Runtime/MatchRuntime.lua`, stage modules, Diagnostics/perf command, test timer mocks.  
**Dependencies:** Owner adoption of one performance budget; R0/R1 correctness for final baseline.  
**Implementation steps:** Add opt-in stage histograms, reason/coalescing counters, queue delay, memory high-water, bounded reset/export; use advancing deterministic test clock.  
**Tests:** Histogram math, timer unavailable, reset, cap/privacy, nonzero synthetic durations, overhead benchmark.  
**Commands:** New benchmark suite, smoke, soak, live 10/40-player matrix.  
**Acceptance:** Nonzero p50/p95/p99/max are reproducible; telemetry overhead is below 0.1 ms p95 and exports no names/GUIDs/chat.  
**Rollback:** Disable telemetry collection by default and retain minimal counters.  
**Risk:** Medium observer effect.  
**Independent?:** Can be designed early; final thresholds depend on fixes.  
**High-reasoning?:** Yes.

## Phase 4: Tests And Observability

### R4-001 — Realistic Benchmark Harness

**Priority:** P2  
**Objective:** Replace zero-time soak claims with deterministic work and live-compatible benchmarks.  
**Rationale:** Existing soak proves bounds only.  
**Files/modules:** `tests/soak.lua`, new benchmark fixtures/scripts, mock clock.  
**Dependencies:** R3-005.  
**Implementation steps:** Advance profile time by staged work; add burst/full-roster fixtures; report percentiles and allocation proxies; retain boundedness checks.  
**Tests:** Self-test percentile math and intentional threshold failure.  
**Commands:** Fengari benchmark and full suite.  
**Acceptance:** Benchmark detects an injected slowdown and publishes machine-readable results.  
**Rollback:** Keep old soak as functional test while benchmark is repaired.  
**Risk:** Low.  
**Independent?:** No.  
**High-reasoning?:** No.

### R4-002 — Lifecycle And Persistence Matrix

**Priority:** P2  
**Objective:** Automate fresh, upgrade, reload-equivalent, relog-equivalent, enable/disable, reconnect, and transition behavior.  
**Rationale:** Current deterministic coverage does not prove lifecycle recovery or migration.  
**Files/modules:** tests, SavedVariables fixtures, bootstrap/runtime test seams.  
**Dependencies:** R1-005, R2-003, R2-005.  
**Implementation steps:** Build isolated sessions with serialized DB handoff; inject events and partial APIs; assert registration/ticker counts and state recovery.  
**Tests:** Entire external lifecycle matrix.  
**Commands:** New lifecycle suite, smoke, soak, build.  
**Acceptance:** All supported transitions are deterministic and no duplicate callback/ticker remains.  
**Rollback:** Retain fixtures and mark unsupported scenarios as explicit blockers.  
**Risk:** Low implementation, high discovery potential.  
**Independent?:** No.  
**High-reasoning?:** Yes.

### R4-003 — Distribution Artifact Runtime Test

**Priority:** P2  
**Objective:** Execute smoke/runtime load against the release-pruned distribution archive, not only developer extraction.  
**Rationale:** `tools/package-audit.ps1` runs extracted tests from the developer package; distribution wiring is checked structurally but not executed.  
**Files/modules:** `tools/build.ps1`, `tools/package-audit.ps1`, package fixture loader.  
**Dependencies:** None.  
**Implementation steps:** Extract distribution to temp; run TOC-order load with production exclusions; verify no dev-only dependency; compare manifest.  
**Tests:** Intentionally remove a required distribution file and assert failure.  
**Commands:** Build/package audit in clean temp directory.  
**Acceptance:** Release-pruned artifact loads and deterministic core tests pass from extracted content.  
**Rollback:** Keep distribution blocked and ship only after manual clean-client proof.  
**Risk:** Low.  
**Independent?:** Yes.  
**High-reasoning?:** No.

### R4-004 — Evidence Metric Integrity

**Priority:** P3  
**Objective:** Ensure stability/readiness metrics represent distinct decisions rather than refresh count.  
**Rationale:** Commander increments issued metrics on each composition and can become “ready” from repeated identical refreshes.  
**Files/modules:** `Runtime/Commander.lua`, Verification/evidence, Diagnostics.  
**Dependencies:** R2-001 revisions and product definition of a distinct issued call.  
**Implementation steps:** Define decision identity; count new/changed recommendations only; record suppression reason; migrate/reset incompatible aggregate metrics.  
**Tests:** Identical refreshes, changed call, withdrawn call, reload, evidence export.  
**Commands:** Focused metrics tests, smoke, soak, build.  
**Acceptance:** Repeated identical state cannot satisfy readiness; metrics are reproducible from retained evidence.  
**Rollback:** Label metric diagnostic-only and remove it from release gating.  
**Risk:** Medium because historical metrics may no longer compare.  
**Independent?:** No.  
**High-reasoning?:** Yes.

## Phase 5: Packaging And External Readiness

### R5-001 — Version And Documentation Authority

**Priority:** P3  
**Objective:** Align TOCs, changelog, metadata, check counts, retention limits, and performance targets.  
**Rationale:** Code identifies alpha 25 and 277 smoke checks while multiple release documents remain alpha 23/254 and budgets disagree.  
**Files/modules:** TOCs, changelog, metadata, release/QA/roadmap documents, issue template.  
**Dependencies:** Owner-approved release version and performance budget; code fixes complete.  
**Implementation steps:** Select authoritative version and budget; update all references in one bounded documentation change; add validator assertions.  
**Tests:** Repository search for stale versions/counts; validation and build.  
**Commands:** `rg`, validation, knowledge audit, build.  
**Acceptance:** One version/check count/budget appears across release surfaces and validator detects drift.  
**Rollback:** Revert documentation-only change.  
**Risk:** Low.  
**Independent?:** No owner decision.  
**High-reasoning?:** No.

### R5-002 — Artifact Provenance And Reproducibility

**Priority:** P3  
**Objective:** Produce traceable artifacts with deterministic manifests and release-source identity.  
**Rationale:** Hashes alone are insufficient release evidence. The build needs explicit source/tool provenance and a clean-build comparison, while the workflow already enforces tag-versus-TOC identity.  
**Files/modules:** build/release scripts, workflow, package metadata.  
**Dependencies:** R5-001 and source-control release environment.  
**Implementation steps:** Emit source-manifest, build-provenance, and reproducibility reports; normalize archive order/timestamps where feasible; retain the tag-versus-TOC guard; generate checksums and tool versions; fall back to source-digest provenance when Git metadata is unavailable in the checkout.  
**Tests:** Two clean builds compare payload manifests/content hashes; mismatched tag fails.  
**Commands:** Clean build twice, package audit, workflow dry run.  
**Acceptance:** Artifact provenance is inspectable, staged payload reproducibility is proven or its container exception is documented, and a mismatched release identity cannot publish.  
**Rollback:** Retain current hashed build but block automated publication.  
**Risk:** Low-medium CI portability.  
**Independent?:** No.  
**High-reasoning?:** No.

### R5-003 — Controlled External Candidate Certification

**Priority:** P1 release gate  
**Objective:** Certify one exact artifact against the external test matrix.  
**Rationale:** Source tests cannot replace clean-client, combat, lifecycle, and worst-case validation.  
**Files/modules:** built artifact, release checklist, test evidence only.  
**Dependencies:** All Phase 0; mandatory Phase 1 P2 items; R3-005; R4-003; owner decisions.  
**Implementation steps:** Freeze artifact hash; install on clean and upgrade profiles; run `EXTERNAL_TEST_PLAN.md`; collect privacy-reviewed evidence; triage every stop condition; sign gates.  
**Tests:** All required external scenarios and performance baselines.  
**Commands:** Full offline suite plus documented Retail commands.  
**Acceptance:** No open P0/P1, approved P2 disposition, all mandatory gates pass, exact artifact hash recorded.  
**Rollback:** Withdraw candidate, revert testers to prior package, restore SavedVariables backup.  
**Risk:** Medium operational.  
**Independent?:** No.  
**High-reasoning?:** Yes.

## Phase 6: Post-Release

### R6-001 — Bounded Oversized-Module Splits

**Priority:** P4  
**Objective:** Improve cohesion in Commander, Diagnostics, MainWindow, Strategist, Assignments, and AAR without changing architecture.  
**Rationale:** Several modules exceed roughly 1,000 lines and combine policy, calculation, formatting, and lifecycle behavior.  
**Files/modules:** Oversized modules identified in the architecture assessment.  
**Dependencies:** Stable contracts from Phase 2 and external evidence.  
**Implementation steps:** Extract pure calculations/adapters one at a time; preserve public tables and load order; add characterization tests first.  
**Tests:** Output parity and lifecycle contract tests.  
**Commands:** Full suite and build after each extraction.  
**Acceptance:** Smaller cohesive units with unchanged behavior and no duplicate subsystem.  
**Rollback:** Recombine the one bounded extraction.  
**Risk:** Medium, no immediate release payoff.  
**Independent?:** No.  
**High-reasoning?:** Yes.

### R6-002 — Future Multiplayer Transport Decision

**Priority:** P4 decision gate  
**Objective:** Keep prohibited addon communication absent unless a separately approved trust, policy, UX, and compatibility design is accepted.  
**Rationale:** Current code has no addon-message transport; future transport specifications would add spoofing, replay, rate, authority, and privacy risks.  
**Files/modules:** Policy/specification only until approved; no current production target.  
**Dependencies:** Explicit product, security, and platform-policy approval.  
**Implementation steps:** Threat model authority/version/rate/replay; define opt-in and failure isolation; legal/platform review; prototype outside release branch only after approval.  
**Tests:** Malformed payload, spoof, replay, flood, stale version, mixed clients, opt-out, privacy.  
**Commands:** Separate security suite and live controlled test if ever approved.  
**Acceptance:** No transport enters this release; any future implementation has explicit approval and complete threat-model gates.  
**Rollback:** Remove/disable transport and retain local-only operation.  
**Risk:** High if pursued; zero if deferred.  
**Independent?:** Yes as a future decision.  
**High-reasoning?:** Yes.

## Parallelization Summary

R0-001 through R0-004 can be developed in parallel in separate worktrees but must integrate against Store characterization tests. R0-005 owns identity and migration and should merge before Reporter lifecycle work. R4-003 can proceed independently. Performance optimizations must not begin from the current zero-time soak baseline. Documentation/version alignment must occur after owner decisions to avoid another drift cycle.



