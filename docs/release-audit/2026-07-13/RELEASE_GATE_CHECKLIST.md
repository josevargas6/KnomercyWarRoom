# Release Gate Checklist

## Status Definitions

| Status | Meaning |
|---|---|
| PASS | The stated method was run and the pass condition was observed. |
| FAIL | Evidence demonstrates the pass condition is not met. |
| PARTIAL | A related check passed, but the method does not prove the complete requirement. |
| NOT RUN | Requires a client, environment, fixture, or procedure not available during this audit. |
| DECISION | Product/release/security owner choice is required before the gate can be evaluated. |

Passing offline validation does not override a failed correctness or safety gate. Controlled external testing remains blocked until all Phase 0 gates are accepted.

## Offline, Architecture, And Correctness Gates

| Gate | Requirement | Method | Pass condition | Current status | Evidence location |
|---|---|---|---|---|---|
| RG-001 | Repository validator passes | Run `./tools/validate.ps1` | Exit 0 with zero errors and zero warnings | PASS | Audit command log: 75 Lua files, 0 errors, 0 warnings, `VALIDATION PASSED`; `FINAL_RELEASE_AUDIT.md` |
| RG-002 | Reviewed knowledge data passes audit | Run `./tools/knowledge-audit.ps1` | Exit 0 with zero errors | PASS | Audit command log: 0 errors, `KNOWLEDGE AUDIT PASSED`; `FINAL_RELEASE_AUDIT.md` |
| RG-003 | Deterministic smoke suite passes | Run Fengari smoke command | Exit 0 and all assertions pass | PASS | `KWR_SMOKE_PASS checks=277`; `tests/smoke.lua` |
| RG-004 | Functional soak remains bounded | Run Fengari soak command | Exit 0, expected refresh count, collection caps hold | PASS | `KWR_SOAK_PASS refreshes=500 ... commanderHistory=3 evidence=2`; `tests/soak.lua` |
| RG-005 | Soak measures actual runtime duration | Use advancing timer and intentional slowdown | Nonzero percentiles are recorded and the timer no longer reports all-zero durations | PASS | `tests/soak.lua` now injects a deterministic cost pattern and preserves nontrivial runtime percentiles; 2026-07-14 soak/build output `avgMs=0.22166666667108 p95Ms=0.79999999998836 maxMs=3.2000000000116` |
| RG-006 | Store publishes every semantic state change exactly once | Run deep/nonsampled/alias regression fixtures | Changed nested/key-25+/same-length content is observed; unchanged state is reused | PASS | Repaired in `Core/Store.lua`; smoke includes nested publication regression; 2026-07-14 validate + smoke + soak passed |
| RG-007 | Objective ownership follows documented source authority | Conflict widget and POI observations in both orders | Fresh high-authority widget state cannot be downgraded | PASS | Repaired in `Runtime/Sensors.lua`; canonical `ui_widget` provenance restored; 2026-07-14 validate + smoke + soak passed |
| RG-008 | Enemy coordinates have truthful direct provenance | Exercise assignment-only, teammate-only, direct, and stale observations | Map marker exists only for direct supported observation | PASS | Repaired in `Runtime/EnemyIntel.lua` and `Runtime/Reporter.lua`; smoke includes engagement-only truth regression; 2026-07-14 validate + smoke + soak passed |
| RG-009 | Distinct players cannot merge by short name | Same short name with different GUID/realm fixture | Two independent records/settings remain | PASS | Repaired in `Runtime/EnemyIntel.lua`, `Runtime/AssignmentOverrides.lua`, and `UI/CombatRosterVisuals.lua`; smoke includes same-short-name and ambiguous override regressions |
| RG-010 | Reporter removes absent friendly influence | Roster removal and transient API-gap fixture | Coverage/pressure excludes absent members within documented grace | PASS | Repaired in `Runtime/Reporter.lua`; smoke now covers roster replacement without stale friendly carryover |
| RG-011 | MemoryBudget receives current Store state | Cross sampling threshold fixture | Current revision triggers exactly one measure | PASS | Repaired in `Runtime/MemoryBudget.lua`; smoke now covers callback argument order against current-state revision sampling |
| RG-012 | Strategy integrity dependencies are available in the intended cycle | First-cycle only-defender/friendly-wave fixtures | Integrity-derived flags are correct without unbounded reevaluation | PASS | Repaired in `Runtime/MatchRuntime.lua`; smoke now verifies final execution-assessment organization matches published assignment integrity |
| RG-013 | Recovery recommendations require a positive gap | Fully covered ledger fixture | No urgent recovery output or �needs 0 more� | PASS | Repaired in `Runtime/Assignments.lua`; smoke now covers zero-deficit response-package recovery output |
| RG-014 | Required module init failure cannot report ready | Fault-inject each required initializer | Runtime remains disabled and health identifies cause | NOT RUN | Bootstrap static review; RA-ARC-019 and R2-003 |
| RG-015 | Iteration and refresh outputs are deterministic | Repeat identical fixtures/processes | Same recommendations, ordering, and evidence each run | PARTIAL | Existing 277-check smoke passed; authority, identity, and strategy sequencing gaps lack coverage |
| RG-055 | Local teamfight command slice remains commander-smart and restriction-safe | Run smoke replay and static validator | Multiple enemy problems produce distinct friendly assignments, a kill target, countdown, debug reasons, UNKNOWN-safe presenters, and no protected-action APIs or spell-specific command instructions | PASS | `tests/smoke.lua`; `tools/replay-test-runner.lua`; `tools/validate.ps1`; `Compliance/`, `Rulesets/`, `Adapters/`, `State/`, `Intelligence/`, and UI presenter modules |

## SavedVariables And Lifecycle Gates

| Gate | Requirement | Method | Pass condition | Current status | Evidence location |
|---|---|---|---|---|---|
| RG-016 | Fresh install initializes a valid current schema | Clean Retail profile | No error; typed defaults and schema version valid | NOT RUN | Bootstrap defaults reviewed; XT-001 pending |
| RG-017 | Every supported prior schema upgrades without data loss | Fixture and sanitized real-file upgrade | Migration is idempotent and preserves valid settings/data | PARTIAL | typed normalization and sanitized malformed-field recovery now pass offline smoke; full historical-schema matrix still pending; `Core/Addon.lua`, `tests/smoke.lua`, 2026-07-14 validate/smoke/soak/build |
| RG-018 | Malformed SavedVariables recover by field | Wrong root/nested types and partial records | Invalid field falls back/quarantines without wholesale valid-data loss | PASS | typed bootstrap normalization plus malformed-field smoke fixture; `Core/Addon.lua`, `tests/smoke.lua`, 2026-07-14 full suite |
| RG-019 | Future schema fails safely | Load schema greater than current | No destructive downgrade/write; explicit compatibility status | PASS | read-only compatibility mode plus future-schema smoke fixture; `Core/Addon.lua`, `tests/smoke.lua`, 2026-07-14 validate/smoke/soak/build |
| RG-020 | `/reload` is idempotent | Repeat idle/staging/match reload | One registration/ticker set, valid state, documented AAR behavior | NOT RUN | XT-003 pending; no Retail lifecycle evidence |
| RG-021 | Relog/reconnect recovers authority and expires stale state | Controlled relog and reconnect | No stale match/roster/enemy state and no duplicates | NOT RUN | XT-004/XT-009 pending |
| RG-022 | Enable/disable tears down all active work | Disable/re-enable optional and core modules with reload | No residual ticker/callback/frame work; initializes once | NOT RUN | Static lifecycle inventory only; XT-005 pending |
| RG-023 | Active AAR interruption has an explicit safe result | Reload/relog/disable mid-match | Partial record is persisted/labeled or explicitly discarded once | PASS | interrupted AAR checkpoint + single explicit `INTERRUPTED` commit proven in smoke; `Runtime/AAR.lua`, `tests/smoke.lua`, 2026-07-14 full suite |
| RG-024 | Retained collections have declared and tested bounds | Cap+1 and long soak across every collection | Every persistent/process collection has owner/cap/eviction assertion | PARTIAL | Many caps exist and soak covers selected histories; Sensors spec aliases and overrides are unbounded/omitted; RA-MEM-018 |

## UI, Combat, And Gameplay Gates

| Gate | Requirement | Method | Pass condition | Current status | Evidence location |
|---|---|---|---|---|---|
| RG-025 | Secure UI never mutates protected state in combat | Retail taint matrix for CombatRoster/QuickCalls/MainWindow | No taint/blocked action; deferred state flushes once | PARTIAL | Offline request-path hardening repaired in `UI/CombatRoster.lua`, `UI/CombatRosterState.lua`, and `UI/MainWindow.lua`; Retail taint proof still required |
| RG-026 | UI remains usable across supported scales/resolutions | XT-012 visual matrix | Controls remain reachable/readable; no unsafe layout | NOT RUN | No screenshots/live UI matrix captured |
| RG-027 | Group/combat/zone transitions clear stale state | XT-006/XT-007 with diagnostics | Finite settle, correct activation, no stale roster/objectives | NOT RUN | Runtime static map exists; live transition evidence absent |
| RG-028 | Leadership and role changes update authority correctly | XT-008 | One correct assignment/authority update and no stale role | NOT RUN | No live group authority evidence |
| RG-029 | Complete matches produce coherent calls and AAR | XT-019 across supported map families | No high-confidence false call, error, or missing cleanup | NOT RUN | Deterministic fixtures only; field evidence absent |
| RG-030 | Supported locale policy is explicit and met | Owner decision plus parser/live locale tests | Supported locales pass or English-only restriction is disclosed/enforced | DECISION | English strings/aura names in `Runtime/ObjectiveIntel.lua:82-165,219-245`; RA-LOC-015 |
| RG-031 | Flag carrier events cannot clear unrelated carriers | Multiple-carrier return/capture fixtures and live check | Only affected carrier/flag state changes | PASS | named return/capture scoping plus explicit global reset proven in smoke; `Runtime/ObjectiveIntel.lua`, `tests/smoke.lua`, 2026-07-14 full suite |
| RG-032 | Optional modules can be absent/disabled safely | Base package and each optional configuration | Core remains healthy; inactive cost is absent | NOT RUN | Structural package checks only; XT-011 pending |

## Performance And Observability Gates

| Gate | Requirement | Method | Pass condition | Current status | Evidence location |
|---|---|---|---|---|---|
| RG-033 | One authoritative release performance budget exists | Owner approves thresholds and docs align | Validator-enforced single budget | DECISION | Conflicting `ALPHA_S_TIER_MASTER_PLAN.md`, `S_TIER_EXECUTION_SCORECARD.md`, `PRODUCT_ROADMAP.md`, and QA thresholds; `PERFORMANCE_AUDIT.md` |
| RG-034 | Full runtime meets frame-time budget | Retail 10-player and worst-case instrumented runs | p95 <= adopted target; routine max and hard max pass | NOT RUN | No Retail profile; current soak timing invalid |
| RG-035 | Addon meets FPS impact budget | Matched addon-disabled/enabled trials | Median and 1% low deltas meet adopted targets | NOT RUN | No FPS captures |
| RG-036 | Retained memory remains bounded over 30 minutes | Warm-up plus minute samples | Growth < adopted threshold and caches stay capped | NOT RUN | No Retail memory trace; MemoryBudget callback defective |
| RG-037 | Friendly health bursts do not force excess full pipelines | Reason/execution counters under burst | Health rate does not drive full refresh above cadence | PASS | `Runtime/MatchRuntime.lua` now updates friendly bars without queueing `friendly-health-sync`; smoke covers `UNIT_HEALTH` with no pending full refresh |
| RG-038 | Verification rejects duplicates before expensive work | Instrument duplicate publication | No full entry/memory summary on duplicate | PASS | `Runtime/Verification.lua` now computes a lightweight signature before `BuildEntry`; smoke proves duplicate live state only builds one entry |
| RG-039 | Cursor Ring meets optional-module budget | Enabled/disabled 0/20/40 plate benchmark | Aggregate thresholds pass and inactive work is absent | NOT RUN | `Features/CursorRing.lua:250-385,735-777`; no live profile |
| RG-040 | Sentinel combined package meets budget | Full group/nameplate combined benchmark | Aggregate thresholds pass with bounded resolution | NOT RUN | Sentinel HUD/Bridge static inventory only |
| RG-041 | Diagnostic metrics represent distinct decisions | Repeat identical Commander state | Repeated refresh cannot create readiness | PASS | `Runtime/Commander.lua` now counts `evaluations` separately from published `issued` commands; smoke proves evaluation-only churn cannot create certification readiness |
| RG-042 | Diagnostics are bounded and privacy-safe | Inspect each export and stress cap | No names/GUIDs/chat/account paths; bounded output | PARTIAL | Static local-only design; no complete privacy review of live exports |

## Trust And Communication Gates

| Gate | Requirement | Method | Pass condition | Current status | Evidence location |
|---|---|---|---|---|---|
| RG-043 | Release sends no addon messages | Static API search and live traffic observation | No registration/send/receive transport in candidate | PARTIAL | Static repository audit found no addon-message APIs; live traffic observation not run |
| RG-044 | Fixed quick calls require user hardware action | Inspect secure button attributes and live click | Only fixed local `/instance` macro on click; no automated send | PARTIAL | `UI/QuickCalls.lua:175-190`; live secure behavior pending RG-025 |
| RG-045 | Future transport cannot enter without separate approval | Release diff/policy check | No transport code/spec activation in candidate | PASS | Current implementation local-only; R6-002 decision gate |
| RG-046 | Malformed external/user-controlled data cannot cascade | Fuzz parser/API fixtures and bounded diagnostics | Invalid input is rejected/degraded without error or unbounded work | NOT RUN | Parser/static defensive checks reviewed; comprehensive fuzz/live suite absent |

## Build, Package, And Release Gates

| Gate | Requirement | Method | Pass condition | Current status | Evidence location |
|---|---|---|---|---|---|
| RG-047 | Build completes outside the source tree | Run build with temp output | Exit 0; archives and hashes created; source unchanged | PASS | Final audit build to `%TEMP%/kwr-release-audit-final-2026-07-13-01`; distribution/developer/Sentinel archives and three hashes created |
| RG-048 | Package audit passes | Observe build-integrated package audit | Zero package audit errors | PASS | Build output `KWR PACKAGE AUDIT PASSED`; distribution 76, developer 141, Sentinel 7 entries; 3 hashes verified; extracted smoke and soak passed |
| RG-049 | Release-pruned distribution executes runtime tests | Extract distribution and run production-order tests | Production artifact loads and deterministic runtime passes | PASS | `tools/package-audit.ps1` now runs extracted distribution smoke and soak via a release-only harness; 2026-07-14 build output shows `Extracted distribution smoke and soak: passed` |
| RG-050 | Version is consistent across release surfaces | Search active release surfaces/docs/metadata/changelog/template | TOC, release docs, metadata, and field-test template agree on one release version and current check count | PASS | Active release surfaces updated to alpha.25/277: `README.md`, `CHANGELOG.md`, `CURSEFORGE_DESCRIPTION.md`, `BATTLEGROUND_VERIFICATION.md`, `META_SOURCES.md`, `THIRD_PARTY_NOTICES.md`, `.github/ISSUE_TEMPLATE/battleground-test.yml` |
| RG-051 | Release tag is validated against addon version | Workflow test with match/mismatch | Matching tag passes and mismatch fails | PASS | `.github/workflows/release.yml` now compares `${{ github.ref_name }}` to the TOC `## Version:` value before packaging |
| RG-052 | Artifacts are reproducible and attributable | Two clean builds plus manifest inspection | Stable content hashes or documented deterministic exceptions; commit/tag/tool provenance present | PASS | `tools/build.ps1` now emits `*_SOURCE_MANIFEST.json`, `*_BUILD_PROVENANCE.json`, and `*_REPRODUCIBILITY.json`; two clean builds matched staged payload digests for distribution/developer/Sentinel, with a documented `Compress-Archive` container exception for distribution/developer ZIP bytes; 2026-07-14 build + package audit passed |
| RG-053 | Exact external candidate passes clean and upgrade install | XT-001/XT-002 on hashed artifact | Both pass with backup/rollback proof | NOT RUN | No external candidate certified |
| RG-054 | Exact external candidate passes stop-criteria matrix | Execute all mandatory external scenarios | No stop criterion, no open P0/P1, approved P2 dispositions | NOT RUN | `EXTERNAL_TEST_PLAN.md` pending Phase 0 |

## Current Gate Summary

| Category | Pass | Partial | Fail | Not run | Decision |
|---|---:|---:|---:|---:|---:|
| Offline/architecture/correctness | 14 | 1 | 0 | 1 | 0 |
| SavedVariables/lifecycle | 3 | 1 | 0 | 4 | 0 |
| UI/combat/gameplay | 1 | 1 | 0 | 5 | 1 |
| Performance/observability | 4 | 1 | 0 | 5 | 1 |
| Trust/communication | 1 | 2 | 0 | 1 | 0 |
| Build/package/release | 6 | 0 | 0 | 2 | 0 |

The arithmetic summary is informational; release authority is severity-based. The original offline Phase 0 correctness blockers RG-006 through RG-009 were repaired in the 2026-07-14 execution pass. The remaining release-critical gate from that set is RG-025, which now requires live Retail taint proof rather than additional offline code repair.






