# Historical: Final Release Audit

Date: 2026-07-13  
Repository: `KnomercyWarRoom`  
Candidate: `6.1.0-alpha.25`  
Audit mode: read-only except for the six requested audit reports

## Execution Update - 2026-07-14

The original audit was read-only. A follow-up execution pass has now repaired the core offline Phase 0 defects that were confirmed and reproducible in the audit:

- `RA-COR-001` exact Store publication semantics repaired and regression-tested
- `RA-COR-002` objective widget provenance repaired and regression-tested
- `RA-TRU-003` enemy coordinate truthfulness repaired and regression-tested
- `RA-ID-005` canonical identity and ambiguous short-name protections repaired and regression-tested
- `RA-SAF-004` suppression/request-path hardening repaired offline, but still requires Retail taint proof

Fresh post-repair evidence from 2026-07-14:

- `./tools/validate.ps1` passed
- `./tools/knowledge-audit.ps1` passed
- `npx --yes --package fengari-node-cli fengari tests/smoke.lua` passed with `KWR_SMOKE_PASS checks=277`
- `fengari tests/soak.lua` passed with deterministic injected-cost timing proof: `KWR_SOAK_PASS refreshes=500 durationSamples=120 avgMs=0.22166666667108 p95Ms=0.79999999998836 maxMs=3.2000000000116 commanderHistory=3 evidence=2`
- `./tools/build.ps1` passed with `KWR PACKAGE AUDIT PASSED`

Additional release-trust repairs completed in the same execution track:

- active release metadata aligned to `6.1.0-alpha.25` and `277` deterministic checks
- extracted distribution smoke and soak now run in `tools/package-audit.ps1`
- release workflow now rejects tags that do not match the addon TOC version exactly
- Verification now rejects duplicate live states before full entry construction
- ordinary friendly health churn no longer queues full strategy refreshes
- Commander stability telemetry now separates evaluations from published command changes
- bootstrap now performs typed SavedVariables normalization instead of scalar-preserving default fill
- malformed root/nested SavedVariables fields now recover field-by-field in smoke
- future-schema SavedVariables now enter explicit read-only compatibility mode instead of being downgraded on write
- in-progress AAR journals now persist a single explicit `INTERRUPTED` result on reload/relog/disable paths
- named flag return/capture messages now clear only the affected flag carrier, with a separate explicit global-reset path
- build output now emits explicit source, tool, and reproducibility manifests
- two clean builds now prove matching staged payload digests for distribution, developer, and Sentinel payloads, with a documented `Compress-Archive` ZIP-container exception for distribution/developer archive bytes
- the local teamfight multi-assignment command slice now runs through safe adapters, compliance/ruleset gates, normalized fact/teamfight state, assignment optimization, kill-target selection, countdown generation, display-only target assist, and debug reasons
- offline replay now proves the target scenario: Knomercy -> Subdue Priest-V, Stan -> Subdue Priest-M, Team -> Kill Warrior-Z in 5, with no auto-targeting, auto-casting, macros, focus changes, hidden communication, or spell-specific commander instructions

## Recommendation

**LIMITED GO - suitable only for controlled testers under stated restrictions**

Current readiness: **88 / 100**.

The offline P1 core defects from the original audit are no longer the primary blockers, and the new local teamfight command architecture closes a major commander-intelligence gap without crossing protected-action boundaries. The remaining gating risk is live proof: in-client combat-lockdown safety, visual scale/readability verification, reload/relog behavior on Retail, real battleground target-assist clarity, and the remaining Phase 1 correctness backlog. The correct strategy remains to retain the single runtime and Store architecture, continue bounded subsystem repair, and keep the repaired Phase 0 baseline plus the new package-certification path as the stable point.

## Executive Summary

The repository has strong product boundaries, one authoritative refresh orchestrator, clear data/runtime/UI separation, bounded major journals, safe-by-policy communication, broad deterministic strategy coverage, and a packaging pipeline that produced and hash-verified all three archives while emitting source/provenance/reproducibility manifests. The declared validator, knowledge audit, smoke test, soak test, and build all exited successfully.

Those passes now establish a repaired offline Phase 0 baseline, not full release readiness. The original P1 defects in state publication, objective authority, and coordinate truthfulness were repaired offline and revalidated. The remaining release-critical safety gate from that cluster is combat-lockdown proof for protected surfaces, which still requires Retail confirmation. Additional P2 defects that previously retained departed Reporter tracks, disabled periodic memory enforcement, evaluated doctrine before assignment integrity, over-cleared flag carriers, and left SavedVariables or AAR interruption behavior under-specified have now been repaired offline. The current soak proves collection bounds and deterministic percentile retention under an injected cost pattern, but it is still not a full in-client performance benchmark.

No P0 defect was found. There is no automatic addon-channel transport, automatic target/focus action, automatic casting, keybinding write, or dynamic unreviewed chat path. KWR Sentinel is a same-client `_G.KWR` consumer only. The future transport specification is not implemented and remains prohibited by current policy.

## Release Blockers

Original audit blocker table is retained for historical traceability. `RA-COR-001`, `RA-COR-002`, `RA-TRU-003`, and `RA-ID-005` were repaired in the 2026-07-14 execution pass; `RA-SAF-004` remains a live-proof gate.

## Historical Blockers

| ID | Severity | Confidence | Classification | Blocker |
| --- | --- | --- | --- | --- |
| RA-COR-001 | P1 | Confirmed, reproduced | Correctness | Store change detection silently retains stale nested state. |
| RA-COR-002 | P1 | Confirmed, reproduced | Truth/correctness | A live objective widget row can be overwritten by a lower-authority map POI. |
| RA-TRU-003 | P1 | Confirmed, reproduced | Trust/integrity | Inferred teammate or assignment locations become enemy map coordinates. |
| RA-SAF-004 | P1 | High, Retail proof required | Safety | Context suppression directly hides ancestors of secure controls in combat. |
| RA-ID-005 | P2 | Confirmed, reproduced | Correctness/persistence | Short-name identity matching merges different realm-qualified players. |

`RA-ID-005` is included in Phase 0 despite P2 severity because identity migration becomes more expensive after external SavedVariables are created.

## Evidence Findings

### RA-COR-001 - Lossy Store reconciliation retains stale truth

Severity: **P1**  
Confidence: **Confirmed; deterministic reproduction**  
Classification: confirmed defect

Evidence: `Core/Store.lua:9-34` truncates table keys at 24, stops semantic inspection at depth two, and uses array length as the token for deeper tables. `Core/Store.lua:80-101` reuses the previous branch when tokens match. `Core/Store.lua:345-399` applies this to strategy, combat, Reporter, command, prediction, and diagnostics state.

Trigger: change a nested scalar below the token depth, or change an omitted key in a table with more than 24 keys.

Expected: the newly published branch is authoritative. Actual: the previous branch is reused. The audit reproduction published nested values `A` then `B`; the Store returned `A` (`STORE_DEEP_VALUE=A EXPECTED=B`).

Impact: stale command or strategy evidence can survive a successful runtime refresh without an error. This undermines the claimed one-state contract and can desynchronize UI, AAR, and verification subscribers.

Correction: remove lossy generic equality from authoritative publication. Use explicit immutable domain revisions or complete, deterministic domain signatures. Until domain revisions exist, correctness must win over allocation reduction and changed branches should be published without reuse.

Required tests: nested strategy/combat mutation, more-than-24-key mutation, enemy row 13 mutation, unchanged-reference reuse, and subscriber notification behavior.

### RA-COR-002 - Objective authority is inverted by a source-key mismatch

Severity: **P1**  
Confidence: **Confirmed; deterministic reproduction**  
Classification: confirmed defect

Evidence: `Runtime/Sensors.lua:90-103` gives `ui_widget` owner/state authority 400 and unknown sources authority 0. `Runtime/Sensors.lua:322-342` labels widget rows `source = "widget"`. `Runtime/Sensors.lua:397` labels only the aggregate `ui_widget`. `Runtime/Sensors.lua:469-508` later merges `area_poi` rows carrying `owner = "UNKNOWN"` and `state = "MAP"` at authority 220.

Trigger: a widget objective and public POI normalize to the same label.

Expected: widget `FRIENDLY/CONTROLLED` remains authoritative while the POI contributes position. Actual: the reproduction changed `FRIENDLY/CONTROLLED source=widget` to `UNKNOWN/MAP selected=area_poi`.

Impact: objective control, assignment coverage, prediction, strategy, and commander calls can all be driven by downgraded truth.

Correction: normalize row source to `ui_widget`; merge POI position independently; prohibit `UNKNOWN/MAP` from replacing qualified owner/state regardless of recency.

Required tests: same-label widget/POI conflict in both orders, incoming state, flag row, and position enrichment without owner/state mutation.

### RA-TRU-003 - Enemy dots are fabricated from inferred friendly context

Severity: **P1**  
Confidence: **Confirmed; deterministic reproduction**  
Classification: confirmed trust-boundary defect

Evidence: `Runtime/EnemyIntel.lua:430-454` substitutes the observing teammate's coordinates or assignment location when enemy coordinates are unavailable. `Runtime/EnemyIntel.lua:455-473` stores those values on the enemy. `Runtime/Reporter.lua:255-272` converts any remaining semantic location to map coordinates. `Runtime/Reporter.lua:653-668` publishes those tracks. This contradicts `ARCHITECTURE.md` and `RELEASE_READINESS.md`, which state inferred evidence must not become a map dot.

Trigger: an enemy is seen through target/nameplate/team-target evidence without a legal enemy map position.

Expected: semantic `WITH <team role> -> <objective>` context remains list-only with `located=false`. Actual: the reproduction produced `INFERRED_ENEMY_LOCATED=true EXPECTED=false`.

Impact: commanders may act on a precise-looking enemy marker that represents a teammate or a static objective center, not the enemy.

Correction: model coordinate evidence separately from semantic location. Only legal enemy-coordinate sources may set `x`, `y`, or `located`. Keep inferred engagement as labeled non-spatial context.

Required tests: direct legal coordinate, teammate-coordinate inference, assignment-only inference, last-seen expiration, and no-dot UI rendering.

### RA-SAF-004 - Secure-surface visibility bypasses combat queuing

Severity: **P1**  
Confidence: **High static confidence; Retail behavior not executed**  
Classification: probable defect / safety blocker

Evidence: combat roster rows use `SecureUnitButtonTemplate` at `UI/CombatRoster.lua:199-202`. Explicit requests correctly queue in combat at `UI/CombatRoster.lua:736-768`. However, `UI/CombatRosterState.lua:6-13`, `UI/CombatRoster.lua:736-743`, and `UI/CombatRoster.lua:786-792` directly hide the surface on rejected context before a combat check. MainWindow contains secure Quick Calls created at `UI/QuickCalls.lua:175-190`; explicit `MainWindow:Hide` queues at `UI/MainWindow.lua:1429-1435`, while Store-driven suppression directly hides at `UI/MainWindow.lua:1323-1334` and rejected `Show` directly hides at `UI/MainWindow.lua:1352-1359`.

Trigger: arena/world/context suppression or a state update while the secure surface is visible and `InCombatLockdown()` is true.

Expected: visibility change is queued for `PLAYER_REGEN_ENABLED`. Likely actual: blocked action, taint, or inconsistent visibility.

Impact: a single protected-action failure is a release blocker under the repository's own gate policy.

Correction: route every secure-ancestor visibility and layout change through one combat-aware request queue. Add a static validator rule for direct `Show/Hide/SetShown` outside that owner.

Required tests: mock combat assertions that direct visibility methods are not invoked, plus Retail combat enter/leave, arena transition, battleground exit, and `/reload` evidence.

### RA-ID-005 - Short names are treated as unique identities

Severity: **P2**  
Confidence: **Confirmed; deterministic reproduction**  
Classification: confirmed defect

Evidence: `Runtime/AssignmentOverrides.lua:14-15` persists locks by short name. `Runtime/EnemyIntel.lua:244-269` matches records by full or short name before re-keying a new GUID. `Runtime/EnemyIntel.lua:96-111` and `UI/CombatRosterVisuals.lua:454-487` also treat short-name equality as friendly identity. The reproduction inserted `Same-RealmA/GUID-A` and `Same-RealmB/GUID-B` and retained one record (`SAME_SHORT_ENEMY_RECORDS=1 EXPECTED=2`).

Trigger: two players share a character name across realms, or an enemy shares a short name with a friendly player.

Expected: distinct GUID/full-name identities remain distinct. Actual: records can merge, disappear, inherit notes, or receive the wrong override.

Impact: wrong enemy tracking and wrong assignment authority. Existing short-name SavedVariables require migration, not deletion.

Correction: centralize canonical identity as GUID, then normalized full name plus realm. Short names are display aliases only; ambiguous slash input must be rejected with choices. Migrate legacy override keys conservatively.

Required tests: same short/different realm for friendly, enemy, note, Reporter, and override paths.

### RA-COR-006 - Reporter does not expire absent friendly tracks

Severity: **P2**  
Confidence: **Confirmed; deterministic reproduction**  
Classification: confirmed defect

Evidence: `Runtime/Reporter.lua:186-252` updates age only when a track is observed. `Runtime/Reporter.lua:785-817` adds current rows but never marks or sweeps missing rows. `Runtime/Reporter.lua:653-780` publishes all retained tracks. Removing the only roster member still returned `coverage.friendly=1` (`EXPECTED=0`).

Impact: departed or transient roster identities continue to affect pressure, ETA, momentum, and coverage until session reset.

Correction: mark-and-sweep each observation cycle; recompute age from `observedAt`; remove absent friendlies after a short documented settling grace and enemies after TTL.

### RA-COR-007 - Periodic memory enforcement receives the previous state

Severity: **P2**  
Confidence: **Confirmed; deterministic reproduction**  
Classification: confirmed defect

Evidence: Store callbacks are `callback(owner, nextState, previous)` at `Core/Store.lua:401-415`. `Runtime/MemoryBudget.lua:464` declares `function MemoryBudget:Update(_, state)`, so `state` is the previous state. The selector wakes on the new revision bucket at `Runtime/MemoryBudget.lua:456-462`, but the modulo guard checks the prior revision at `Runtime/MemoryBudget.lua:465`. The reproduction delivered next revision 20 and previous 19; `MeasureMB` was called zero times (`EXPECTED=1`).

Impact: periodic pressure checks and trims effectively do not run at their intended revisions. Startup trim and Verification's accidental measurements mask the failure.

Correction: use `Update(state, previous)` and test exact revision boundaries. Do not rely on Verification to measure memory.

### RA-ARC-008 - Doctrine is selected before assignment integrity exists

Severity: **P2**  
Confidence: **Confirmed by execution order**  
Classification: architectural correctness risk

Evidence: `Runtime/MatchRuntime.lua:317-324` runs `Strategist:Evaluate`, then builds assignments and integrity. `Runtime/Strategist.lua:90-134` reads `snapshot.assignmentIntegrity` during Evaluate to derive `onlyDefenderWouldMove` and `friendlyWaveSplit`. New sensor snapshots do not contain current-cycle integrity.

Impact: doctrine gates intended to protect uncovered objectives or split waves are always evaluated from empty integrity in the initial strategy pass.

Correction: split strategy into assignment-independent proposal and post-integrity policy finalization. Avoid a second strategist or implicit previous-cycle state.

### RA-SV-009 - SavedVariables migration had no typed schema validation

Severity: **P2**  
Confidence: **Resolved offline; upgrade matrix still incomplete**  
Classification: repaired architectural risk

Evidence: `Core/Addon.lua` now performs typed normalization against declared defaults, normalizes known persisted roots (`journal`, `learning`, `encounters`, `assignmentOverrides`, `opponentModels`), and adds deterministic malformed-field recovery coverage in `tests/smoke.lua`. Validated 2026-07-14 by `./tools/validate.ps1`, `npx --yes --package fengari-node-cli fengari tests/smoke.lua`, `npx --yes --package fengari-node-cli fengari tests/soak.lua`, and `./tools/build.ps1`.

  Residual gap: the malformed-field and future-schema gates are now covered offline, but the full historical-schema upgrade matrix is still not exhaustively fixture-proven.

Disposition: keep the typed normalization path, preserve unknown keys, and finish the remaining upgrade-matrix fixtures before broader external rollout.

### RA-PERF-010 - Verification performs heavy work before deduplication

Severity: **P2**  
Confidence: **Confirmed by hot path**  
Classification: performance risk

Evidence: `Runtime/Verification.lua:448-465` builds the complete entry before computing its transition signature. `BuildEntry` formats and copies broad state and calls `MemoryBudget:Summary()` at `Runtime/Verification.lua:443`; Summary invokes addon memory measurement. This happens on every live Store publish, even when the entry is discarded.

Correction: compute a cheap state signature first; build full entries only for accepted transitions or explicit reports.

### RA-PERF-011 - Friendly unit events still trigger full strategic refreshes

Severity: **P2**  
Confidence: **Confirmed by event path**  
Classification: performance risk

Evidence: `Runtime/MatchRuntime.lua:564-583` updates bars directly but still queues `friendly-health-sync` every 0.35 seconds for ordinary friendly health/aura events. Each accepted queue executes the entire pipeline at `Runtime/MatchRuntime.lua:290-377`.

Correction: reserve full refresh for objective carriers or decision-invalidating domain changes; publish a lightweight UI health revision otherwise.

### RA-REL-012 - Offline and package gates overstate tested behavior

Severity: **P2**  
Confidence: **Confirmed**  
Classification: test/release defect

Evidence: `tests/soak.lua` still reuses `tests/smoke.lua`, where `debugprofilestop()` returns mocked `currentTime * 1000`. Time does not advance during a refresh, so the soak remains a bounded-state check rather than a realistic benchmark. The original package and tag-identity gaps have now been repaired: `tools/package-audit.ps1` certifies the extracted release-pruned distribution runtime, `.github/workflows/release.yml` rejects tag/version mismatch, and `tools/build.ps1` now emits source/provenance/reproducibility manifests plus a two-clean-build staged-payload comparison. The remaining reproducibility exception is container-level: `Compress-Archive` did not produce byte-identical distribution/developer ZIP files across clean builds even though staged payload digests matched.

Correction: keep the new provenance manifests and documented container exception, and finish the remaining benchmark-side work by adding a real slowdown/perf harness instead of treating soak percentiles as live performance proof.

### RA-COR-013 - Covered objectives are reported as urgent recovery gaps

Severity: **P3**  
Confidence: **Confirmed; deterministic reproduction**  
Classification: confirmed defect

Evidence: `Runtime/Assignments.lua:1242` initializes `criticalGap` to the first coverage row before searching for `UNCOVERED`. `Runtime/Assignments.lua:1256-1287` therefore reports urgency for any non-empty ledger. A covered Blacksmith produced `urgent=true`, `criticalGap=Blacksmith`, and `needs 0 more`.

Correction: initialize `criticalGap=nil`; set it only for `UNCOVERED`; test all-covered, overcommitted, and reassignment cases.

### RA-OBS-014 - Command certification counts evaluations as issued commands

Severity: **P3**  
Confidence: **Confirmed by code and tests**  
Classification: observability defect

Evidence: `Runtime/Commander.lua:1988` increments `metrics.issued` on every Compose call. `Runtime/Commander.lua:65-79` marks certification `READY` at eight issued records even with no replacement, while the runtime composes every refresh. Tests explicitly construct this interpretation at `tests/smoke.lua:776-826`.

Impact: field reports can claim a useful command-stability sample after seconds of identical refreshes.

Correction: separate evaluations, initial commands, signature transitions, replacements, and completed-match evidence.

### RA-LOC-015 - Objective parsing is English-only

Severity: **P2 decision gate**  
Confidence: **High**  
Classification: compatibility risk

Evidence: `Runtime/ObjectiveIntel.lua:82-165` parses English literal battleground messages, and `Runtime/ObjectiveIntel.lua:219-245` searches English aura names. There is no locale table or English-only product declaration. The first orb pattern at line 91 also uses unsupported alternation syntax, though the following loop compensates.

Decision: either declare and gate an English-only alpha or implement localized, Blizzard-global-backed patterns. Do not silently imply supported locales.

### RA-COR-016 - Any flag return/capture cleared every flag carrier

  Severity: **P2**  
  Confidence: **Resolved offline; live/locale semantics still need proof**  
  Classification: repaired probable defect

  Evidence: `Runtime/ObjectiveIntel.lua` now scopes named return/capture messages to the affected flag objective and uses a separate explicit global-reset path for full resets. `tests/smoke.lua` now proves that an `Alliance Flag` return does not clear `Horde Flag`, that named capture clears only the named objective, and that an explicit global reset clears both. Validated 2026-07-14 by validate, smoke, soak, knowledge audit, and build/package audit.

  Residual gap: localized parser coverage and live-message proof still belong to `RA-LOC-015` / `R1-006`.

### RA-LIFE-017 - In-progress AAR was lost on reload/relog

Severity: **P3**  
Confidence: **Resolved offline**  
Classification: repaired lifecycle/design defect

Evidence: `Runtime/AAR.lua` now checkpoints active journals and commits a single explicit `INTERRUPTED` entry on disable/reload/relog-style teardown. `tests/smoke.lua` now proves that an in-progress journal is persisted once, labeled, and cleared. Validated 2026-07-14 by `./tools/validate.ps1`, smoke, soak, and build/package audit.

Residual gap: Retail reload/relog proof is still required to certify the real client lifecycle path end to end.

### RA-MEM-018 - Retention contract omits spec cache and assignment overrides

Severity: **P3**  
Confidence: **Confirmed**  
Classification: maintainability/performance risk

Evidence: `Runtime/Sensors.lua:774-795` retains GUID and name aliases in `specCache` without pruning. `Runtime/AssignmentOverrides.lua:187-211` clears locks but leaves records indefinitely. Neither appears in `Runtime/MemoryBudget.lua:34-153`, violating the documented shared retention rule.

### RA-ARC-019 - Oversized owners and UI/runtime coupling raise change risk

Severity: **P3**  
Confidence: **Confirmed**  
Classification: maintainability concern

Evidence: Commander is 2,219 lines, Diagnostics 1,836, MainWindow 1,553, Strategist 1,355, Assignments 1,292, and AAR 1,057. Reporter reads `KWR.ReporterMap.frame` and `KWR.MainWindow.frame` at `Runtime/Reporter.lua:653-661`, so runtime DTO shape depends on UI visibility. MemoryBudget reaches into most runtime owners. Bootstrap continues after module initialization errors and sets `ready=true` at `Core/Addon.lua:213-261`.

Disposition: refactor bounded subsystems after correctness gates; do not rebuild.

### RA-DOC-020 - Release documents disagree with code and each other

Severity: **P3**  
Confidence: **Confirmed**  
Classification: release maintainability concern

Evidence: current code/TOCs are alpha.25, while `CHANGELOG.md` stops at alpha.23, `CURSEFORGE_DESCRIPTION.md` and `META_SOURCES.md` state alpha.23, dated handoff files state alpha.23, and the battleground issue template shows alpha.13. `README.md` and `BATTLEGROUND_VERIFICATION.md` claim 254 checks while current smoke reports 277; other release docs claim 277. `ARCHITECTURE.md` describes retention targets that differ from the actual MemoryBudget caps. Performance gates conflict between p95 4 ms in the master plan and p95 2 ms in QA/Roadmap.

Correction: choose one normative release gate source and generate version/check-count fields where practical.

### RA-PERF-021 - Optional visual loops require field budgets

Severity: **P3**  
Confidence: **Confirmed code path; impact unmeasured**  
Classification: performance risk

Evidence: `Features/CursorRing.lua:735-777` runs at 30 Hz while the driver is active and refreshes every active nameplate orb every 0.12 seconds. Each orb scans roster/enemy state and repeats unit, health, parenting, and layout calls at `Features/CursorRing.lua:250-385`. Sentinel rebuilds its view at 4 Hz at `KWRSentinel/HUD.lua:215-227`; an unresolved watch target scans up to 40 nameplates at `KWRSentinel/Bridge.lua:137-151`.

Correction: dirty-event updates, cached identity indexes, no redundant re-anchoring, and dedicated benchmarks with 40 nameplates.

## Architecture Assessment

Classification: **retain architecture; repair locally; refactor selected subsystems; replace none; rebuild none**.

Preserve the TOC-ordered module model, one MatchRuntime scheduler, one Store publication point, source/runtime/UI separation, reviewed data modules, safe API wrappers, secure click-only controls, bounded AAR/opponent/enemy-note collections, release exclusion manifest, and same-client-only Sentinel boundary.

Repair immediately: Store correctness, source authority, coordinate provenance, secure visibility, canonical identity, Reporter expiry, MemoryBudget callback, and strategy/integrity sequencing.

Refactor after correctness: explicit domain revisions, two-stage strategy finalization, cheap Verification transition filtering, a lightweight unit-event lane, central identity service, lifecycle health reporting, and smaller Commander/MainWindow/AAR units.

No evidence justifies replacing the Store, MatchRuntime, strategy engine, assignment engine, UI system, or SavedVariables root. A broad rewrite would create greater migration and gameplay risk than the bounded repairs.

## Security And Multiplayer Integrity

Current trust boundary is local Blizzard API data, local SavedVariables, and explicit user input. Static search and validator output found no `SendAddonMessage`, automatic `SendChatMessage`, target/focus API call, cast call, keybinding write, or combat-log subscription. Quick Calls are six fixed secure macros and require a hardware click. Dynamic text remains manual copy.

No remote packet parser exists, so spoof/replay/rate/version/authority conflict risks in `SENTINEL_TRANSPORT_SPEC.md` are future policy decisions, not current defects. Transport must remain prohibited until README, validator, privacy disclosures, protocol validation, roster authentication, replay protection, rate limits, and authority tests are deliberately approved.

Local trust weaknesses remain: ambiguous short-name identities, malformed SavedVariables, and semantic location promoted to spatial truth. Field defect exports include player names, enemy notes, assignments, and match evidence; testers must review/redact before sharing.

## Test And Package Assessment

Observed command results:

| Command | Result |
| --- | --- |
| `./tools/validate.ps1` | Exit 0; 75 Lua files; 0 errors; 0 warnings; `VALIDATION PASSED`. |
| `./tools/knowledge-audit.ps1` | Exit 0; 0 errors; `KNOWLEDGE AUDIT PASSED`. |
| `npx --yes --package fengari-node-cli fengari tests/smoke.lua` | Exit 0; `KWR_SMOKE_PASS checks=277`. |
| `npx --yes --package fengari-node-cli fengari tests/soak.lua` | Exit 0; 500 refreshes; bounded buffers passed; timing output was `avgMs=0.0 p95Ms=0 maxMs=0`. |
| `./tools/build.ps1 -OutputDirectory "$env:TEMP\kwr-release-audit-final-2026-07-13-01"` | Exit 0; distribution/developer/Sentinel ZIPs and SHA-256 file created; package audit passed; entries 76/141/7; 3 hashes verified; extracted developer smoke and soak passed. |

Limits: no Retail client was available. No taint, blocked-action, secret-value, real API, FPS, CPU, memory plateau, map-art, locale, SavedVariables upgrade, reload/relog, reconnect, or full-match behavior was observed. The build ran before these audit reports were added, so the package result represents the pre-audit source tree and does not certify documentation packaging after this audit.

## External-Test Risk

Current external risk is high enough to block distribution: a commander can receive stale Store state, wrong objective ownership, fabricated enemy coordinates, or a protected-frame failure. After Phase 0, use only named controlled testers, one current Retail client version, English clients unless the locale decision is resolved, no future Sentinel transport, clean backups of SavedVariables, BugSack/BugGrabber or equivalent error capture, and stop-on-first P1 rules from `EXTERNAL_TEST_PLAN.md`.

Broad alpha expansion requires all P1/P2 correctness gates, release-pruned load certification, fresh and upgrade persistence tests, one complete combat cycle without taint, p95 and memory evidence under the chosen budget, and at least one clean match per battleground family.

## Decision Gates

1. Locale support: English-only controlled alpha or localized objective message parsing.
2. Legacy identity migration: retention duration and ambiguity behavior for short-name overrides/notes.
4. Performance authority: choose p95 `2 ms` or `4 ms` as the normative pass threshold; retain `6 ms` warning and `10 ms` hard stop unless revised.
5. Sentinel distribution: separate optional package or included tester requirement; transport remains disabled.
6. Release provenance: define tag-to-TOC equality, certified rollback version, and reproducible-build requirement.

## Exact Release Condition

External testing may begin only when Phase 0 is complete, all Phase 0 acceptance tests pass in source and release-pruned packages, and one owner-approved Retail combat-lockdown smoke produces zero Lua, taint, or blocked-action errors. This is not approval for stable public promotion.



