---
id: KWR-128
title: Consolidate shared live facts under one authoritative owner
owner: unassigned
priority: high
risk: high
dependencies:
  - KWR-047
  - release-audit/R0-005
  - release-audit/R2-001
  - release-audit/R3-002
  - release-audit/R3-003
affected_modules:
  - Adapters/SafeUnitAdapter.lua
  - Core/Store.lua
  - Runtime/MatchRuntime.lua
  - Runtime/Sensors.lua
  - Runtime/TeamResolver.lua
  - Runtime/RosterInspector.lua
  - Runtime/EnemyIntel.lua
  - Runtime/CombatIntel.lua
  - Runtime/EncounterHistory.lua
  - Runtime/OpponentModels.lua
  - Runtime/SentinelBridge.lua
  - State/
  - UI/RosterPresentation.lua
  - UI/CombatRosterState.lua
  - UI/CombatRosterVisuals.lua
  - UI/CombatRoster.lua
  - UI/HUD.lua
  - UI/MainWindow.lua
  - UI/MainWindowPages.lua
  - UI/Presentation.lua
  - Features/CursorRing.lua
  - KWRSentinel/Bridge.lua
  - KWRSentinel/HUD.lua
  - tests/smoke.lua
  - tests/soak.lua
  - tools/validate.ps1
  - ARCHITECTURE.md
---

# Objective

Make every shared player, roster, enemy, assignment, match-context, and live
unit fact have one clear owner. Acquire or derive each fact once at the
appropriate lifecycle, publish one canonical record or revision, and let every
window, card, overlay, bridge, and intelligence consumer reuse it.

# User outcome

Team and enemy identity stays consistent everywhere. A name, class,
specialization, role, assignment, target, health display, or enemy observation
does not get rediscovered independently by each surface. Live facts remain
responsive because the owning domain updates once and selectively wakes the
consumers that depend on the changed domain.

# Current behavior

The main pipeline already has the correct high-level shape: `MatchRuntime` is
the full-refresh scheduler, `Sensors` captures snapshots, and `Store` publishes
live state. KWR-047 also established `TeamResolver`, `EnemyIntel`, and
`RosterPresentation` as roster boundaries. The current implementation still
contains several duplicate-owner paths beneath those boundaries.

## Confirmed duplicate work

| Priority | Current duplicate work | Evidence | Intended owner |
| --- | --- | --- | --- |
| P1 | Friendly identity, class, role, specialization, health, position, and target are reacquired together on every snapshot even though most fields are stable or event-dirty. The specialization cache is used mainly as a fallback after another specialization read. | `Runtime/Sensors.lua:676-700`, `Runtime/Sensors.lua:722-914`, `Runtime/MatchRuntime.lua:304-313`, `Runtime/MatchRuntime.lua:363-381` | `TeamResolver` owns the canonical match roster; `Sensors` supplies sanitized deltas; `RosterInspector` owns inspect acquisition. |
| P1 | Published friendly normalization and enemy filtering/deduplication run again in both compact and expanded UI. | `UI/CombatRosterState.lua:167-175`, `UI/MainWindowPages.lua:1086-1107` | `TeamResolver` publishes an already normalized friendly roster; `EnemyIntel` publishes already filtered enemy truth. |
| P1 | Base KWR has two `UNIT_HEALTH`/`UNIT_MAXHEALTH` event owners for the compact roster. `MatchRuntime` forwards health to the roster and main window, while `CombatRoster` separately registers and handles the same events. MainWindow and CombatRoster also implement separate direct-health writers. | `Runtime/MatchRuntime.lua:667-683`, `UI/CombatRoster.lua:504-524`, `UI/CombatRosterVisuals.lua:18-65`, `UI/MainWindow.lua:144-170` | `MatchRuntime` owns the game event; one shared roster presentation health boundary fans out safe direct bar updates without persisting or comparing secret values. |
| P1 | HUD and Presentation register lifecycle events already owned by `MatchRuntime`, then schedule their own refresh bursts. Presentation also subscribes to every Store publication and schedules two more refreshes for each revision. | `Runtime/MatchRuntime.lua:80-125`, `Runtime/MatchRuntime.lua:604-727`, `UI/HUD.lua:334-471`, `UI/HUD.lua:788-818`, `UI/Presentation.lua:132-175` | `MatchRuntime` owns lifecycle settling; Store domain revisions wake filtered presentation consumers. |
| P2 | Player/assignment identity joins are rebuilt independently in CombatRoster, CursorRing, HUD, MainWindow, MainWindowPages, and SentinelBridge. Several paths call `UnitName("player")` or `UnitGUID("player")` again and linearly scan the same assignments/enemies. | `UI/CombatRosterState.lua:6-69`, `Features/CursorRing.lua:305-325`, `Features/CursorRing.lua:768-783`, `UI/HUD.lua:313-331`, `UI/HUD.lua:551-581`, `UI/MainWindow.lua:374-411`, `UI/MainWindowPages.lua:843-865`, `Runtime/SentinelBridge.lua:23-63` | One ephemeral canonical entity/assignment index, built from authoritative records and containing references rather than copied player models. |
| P2 | Compact and expanded enemy surfaces independently create session-stable slot maps after independently filtering the same enemies. | `UI/CombatRosterState.lua:72-115`, `UI/CombatRosterState.lua:175`, `UI/MainWindowPages.lua:1095-1107` | `EnemyIntel` owns canonical session order/slot identity; CombatRoster alone owns protected secure row bindings. |
| P2 | Store consumers repeatedly build large row signatures even though Store already performs branch reconciliation. HUD and CursorRing also include the aggregate Store revision, so they wake on every publish regardless of the narrower fields listed after it. | `Core/Store.lua:20-38`, `UI/CombatRoster.lua:138-197`, `UI/MainWindow.lua:185-298`, `UI/HUD.lua:489-514`, `Features/CursorRing.lua:814-844` | Store publishes explicit domain revisions; consumers select only the revisions they need. |
| P2 | Active PvP season is read separately and repeatedly for player/enemy history and opponent profiles. EncounterHistory can call it several times per entity in one refresh. | `Runtime/EncounterHistory.lua:16-20`, `Runtime/EncounterHistory.lua:57-100`, `Runtime/EncounterHistory.lua:105-123`, `Runtime/OpponentModels.lua:20-24`, `Runtime/OpponentModels.lua:266-325` | Match/session context captures the active season once and passes it to history/model consumers. |
| P3 | Entity matching and roster presentation helpers are duplicated across modules, including `sameCallTarget`, current-state lookup, class/health color rules, active combat target selection, and short-name matching. | `UI/CombatRosterState.lua:14-24`, `UI/CombatRosterVisuals.lua:6-16`, `UI/CombatRoster.lua:14-89`, `UI/MainWindow.lua:127-140`, `Features/CursorRing.lua:71-123` | Canonical identity matching belongs to the entity index; reusable display rules belong to `RosterPresentation` or `Theme`. |
| P3 | Enemy unit scanning reads some facts more than once in one scan, such as `UnitAffectingCombat`, while CombatIntel separately resolves unit identity on spell events. | `Runtime/EnemyIntel.lua:512-599`, `Runtime/CombatIntel.lua:225-276` | The safe unit adapter returns one sanitized observation record that EnemyIntel and CombatIntel can consume by canonical key. |
| P3 | Sentinel correctly consumes the War Room bridge when available, but its 4 Hz update still rescans group healer state, target/nameplates, casts, ranges, and health. Some of that is already known to War Room. | `KWRSentinel/Bridge.lua:97-150`, `KWRSentinel/Bridge.lua:206-252`, `KWRSentinel/HUD.lua:563-619` | When War Room is present, Sentinel consumes a revisioned bridge projection and performs only irreducibly local range/cast display checks. Standalone fallback remains independent. |

## Work that is not automatically a duplicate

- Direct Blizzard-backed health-bar writes are a deliberate safe-display
  exception. Consolidation must centralize their event and rendering boundary,
  not copy protected health into ordinary Lua state.
- `FactStore`, `BoardState`, and `LocalTeamfightState` provide a bounded
  compliance and teamfight-planning contract. They should not be removed
  merely because they project the snapshot. First gate them by relevant domain
  revisions and measure their cost.
- CombatRoster secure row creation and binding remain presentation-owned.
  Runtime may own canonical identity and order, but it must not mutate protected
  UI state.
- A standalone Sentinel installation must retain enough local acquisition to
  function without War Room.

# Required behavior

## Ownership contract

| Fact or behavior | Single owner | Update lifecycle |
| --- | --- | --- |
| Friendly canonical identity, name, class, unit binding, roster membership | `TeamResolver` | Session start, group/name hydration events, reconnect, explicit rescan |
| Friendly specialization and specialization provenance | `RosterInspector` acquisition into the `TeamResolver` record | Inspect completion, player specialization event, explicit rescan |
| Friendly role and assignment-independent live status | `TeamResolver` record fed by sanitized Sensors deltas | Relevant role, roster, death, connection, and bounded live events |
| Enemy canonical identity, scoreboard merge, observation, last-seen truth, session order | `EnemyIntel` | Scoreboard, target/nameplate/unit observation, TTL/session reset |
| Combat casts, defensives, trinkets, and target scoring | `CombatIntel` keyed by canonical enemy identity | Relevant unit spell/cast observations and expiry |
| Objective/carrier truth | `ObjectiveIntel` | Widget, message, aura, and objective events |
| Match context, lifecycle scheduling, invalidation, and settling | `MatchRuntime` | Blizzard lifecycle/event input |
| Published references and domain revisions | `Store` | Semantic owner changes only |
| Reusable roster row projection and direct safe health display | `RosterPresentation` or a narrowly named shared UI helper beneath it | Domain revision or direct unit-health display event |
| Secure row hierarchy, attributes, and combat-lockdown queue | `CombatRoster` | Legal out-of-combat binding/layout points |
| Cards, windows, HUD, map, CursorRing, and Sentinel view | Their presenter only | Subscribe to the smallest relevant published revision |

## Phase 0: Characterize and lock the contract

1. Add deterministic counters around roster identity acquisition, inspect
   resolution, scoreboard reads, direct-health delivery, entity-index builds,
   Store domain changes, and UI renders/skips.
2. Add failing tests that demonstrate the duplicate paths listed above.
3. Record an ADR that adopts the existing release-audit target architecture:
   canonical identity, domain revisions, one event owner, fast display lane,
   and thin selectors. Do not create a competing pipeline or Store.
4. Establish a current ten-player and worst-case bounded baseline before
   optimization so stale data is not mistaken for saved work.

Exit gate: the tests can distinguish an acquisition, a semantic state change,
a Store publication, and a UI mutation.

## Phase 1: Establish canonical player identity and roster ownership

1. Define one canonical key rule: GUID first, normalized full name plus realm
   second. Short names are display aliases and never silently merge ambiguous
   players.
2. Extend `TeamResolver`; do not add a parallel roster service. Maintain one
   match-scoped canonical friendly registry plus bounded indexes by canonical
   key, GUID, full name, and stable unit.
3. Split Sensors roster input into:
   - structural/static acquisition triggered by roster/name/spec/role dirtiness;
   - bounded live deltas for facts that truly change during play.
4. Make `RosterInspector` update the canonical record. Stop asking for a known
   specialization every snapshot. Bound or session-prune `Sensors.specCache`
   and retain EncounterHistory as the explicit historical source.
5. Publish an already normalized roster. Remove UI calls to
   `NormalizePublishedRoster`.
6. Preserve the existing Store roster shape during migration so strategy,
   assignments, AAR, and UI can move one consumer at a time.

Exit gate: repeated active pulses with no roster dirtiness perform zero class,
name, role, or specialization reacquisition for already resolved teammates.

## Phase 2: Make EnemyIntel the complete enemy-truth owner

1. Apply friendly exclusion and duplicate resolution inside
   `EnemyIntel:Capture` before publishing `snapshot.enemies`.
2. Give every enemy a canonical key and stable session sequence/slot. Priority,
   visibility, or last-seen changes may alter emphasis, not identity.
3. Let CombatIntel attach evidence by canonical enemy key instead of maintaining
   an independently ambiguous short-name identity.
4. Remove UI calls to `FilterPublishedTruth` and remove the expanded page's
   separate enemy slot registry. CombatRoster retains only its protected
   key-to-secure-row binding.
5. Add same-name/different-realm and GUID-hydration fixtures for enemy notes,
   priority, casts, target/focus, and session ordering.

Exit gate: Store contains the exact canonical enemy set and every consumer sees
the same key, order, and provenance without another cleanup pass.

## Phase 3: Build shared reference indexes once

1. Add one ephemeral published-state index under `State/` or as a documented
   Store projection. It contains references to canonical records, not copied
   player/enemy models.
2. Include bounded lookups for:
   - local player;
   - friendly and enemy by canonical key, GUID, full name, and stable unit;
   - assignment by canonical player key;
   - execution command for the local player;
   - enemy target/call matching.
3. Build the index only when roster, enemy, assignment, or execution revisions
   change.
4. Replace the independent lookup tables and linear identity scans in
   CombatRoster, CursorRing, HUD, MainWindow, MainWindowPages, and
   SentinelBridge.
5. Keep explicit ambiguity results. Never turn a short-name collision into an
   arbitrary match.

Exit gate: a Store revision builds at most one relevant index, and UI renderers
perform no Blizzard identity reads to find records already present in Store.

## Phase 4: Separate event-driven live lanes from full strategy

1. Make `MatchRuntime` the sole base-addon registration owner for lifecycle,
   roster truth, target/focus, and unit-health events.
2. Introduce explicit dirty domains such as context, roster identity, roster
   live state, scoreboard, objectives, enemy observations, combat, and
   presentation. Each event marks only its dependent domains.
3. Route ordinary unit health through one shared direct-display boundary:
   - no persisted secret health;
   - no comparison or formatting outside the existing permitted safe path;
   - one event fan-out to registered visible bars;
   - a full strategic refresh only for documented dependencies such as an
     objective carrier, death, or other threshold that strategy actually uses.
4. Remove CombatRoster's duplicate health registrations and MainWindow's
   duplicate direct-health implementation.
5. Remove HUD lifecycle refresh bursts and Presentation's per-publication
   delayed refreshes. Store context revisions and the existing runtime
   transition sweeps supply authoritative updates.
6. Preserve necessary feature-local visual animation. Cursor movement and
   secure combat-lockdown application are not forced into Store.

Exit gate: one health event reaches each registered bar once, ordinary friendly
health does not rebuild the complete strategy pipeline, and lifecycle events do
not create independent UI refresh storms.

## Phase 5: Publish domain revisions and reusable projections

1. Give each authoritative domain an explicit revision that changes only when
   its semantic state changes.
2. Publish stable domain references and revisions through the existing Store
   API. Retain aggregate `revision` and legacy snapshot fields during the
   compatibility window.
3. Replace UI-wide row signature reconstruction with selectors over the
   smallest relevant domain revisions.
4. Build shared friendly and enemy semantic row projections once in
   `RosterPresentation` for compact and expanded surfaces. Keep protected
   binding data out of ordinary expanded rows.
5. Gate FactStore/BoardState/teamfight planning on its true input revisions and
   reuse its prior result when those inputs are unchanged.
6. Remove generic deep reconciliation only after exact revision tests prove
   parity; do not combine correctness migration and cleanup in one step.

Exit gate: a score-only change does not rebuild roster indexes or roster row
projections, and an unchanged pulse does not mutate any non-health roster UI.

## Phase 6: Consolidate smaller repeated reads and presentation helpers

1. Capture active season once in match/session context and pass it to
   EncounterHistory and OpponentModels.
2. Expand the existing safe adapter boundary to produce one sanitized unit
   observation per event/scan, then reuse it in EnemyIntel and CombatIntel.
3. Read volatile unit fields once per observation; for example, reuse one
   `UnitAffectingCombat` result.
4. Move canonical entity/call matching to the shared identity/index boundary.
5. Move class color, health tone, role label, and roster-location formatting
   to `Theme` or `RosterPresentation`.
6. Remove obsolete helpers and caches only after all callers have migrated.

Exit gate: validation rejects new direct identity cleanup in UI and new
duplicate registrations for events already owned by MatchRuntime.

## Phase 7: Reuse War Room facts in Sentinel when both are installed

1. Add a bounded bridge revision/signature to the existing Sentinel view.
2. When War Room is available, update Sentinel commander content only when the
   relevant bridge revision changes.
3. Reuse the War Room entity/unit mapping for the watched enemy. Keep only
   irreducibly local display checks such as current range or cast presentation
   where required.
4. Retain the existing standalone fallback and test it separately.

Exit gate: combined War Room plus Sentinel does not rescan group/nameplate
identity already supplied by War Room, while standalone Sentinel remains
functional.

# Non-goals

- Do not rewrite the strategy, assignment, command, objective, Reporter, AAR,
  or local teamfight engines.
- Do not create a second Store, roster, enemy tracker, event router, ticker, or
  persistent player database.
- Do not cache a live field beyond the lifecycle in which it is authoritative.
- Do not persist, compare, derive, or expose protected/secret health values.
- Do not move protected secure-row mutation into runtime state code.
- Do not redesign the visible roster, HUD, MainWindow, CursorRing, or Sentinel.
- Do not delete legacy SavedVariables or ambiguous identity records.
- Do not optimize bounded transformations without a measured or contract-level
  reason.

# Technical constraints

- Preserve `KWR_DB`, existing snapshot fields, commands, profile keys, bridge
  fields, secure row names, and target/focus click behavior through the
  compatibility window.
- Static identity and match-scoped data require explicit invalidation. A cache
  without a documented owner, key, TTL/session boundary, and reset event is not
  acceptable.
- Revisions must be exact for their documented domain. A missing dependency is
  a correctness failure, not merely a stale visual.
- UI code may receive canonical records and display projections but cannot
  mutate domain truth.
- All new API reads go through an existing or deliberately extended adapter.
- All loops remain bounded to supported roster, scoreboard, objective, and
  nameplate limits.
- No new `OnUpdate`, ticker, or event frame is allowed without proving that an
  existing owner cannot supply the requirement.
- Implementation is incremental. Each phase retains an isolated rollback and
  passes its own parity gate before the next phase starts.

# Acceptance criteria

- [ ] Every shared fact in the ownership table has exactly one documented
      writer and a documented invalidation lifecycle.
- [ ] Friendly records use canonical GUID/full-name identity; short name is
      display-only and ambiguous short names remain distinct.
- [ ] Repeated unchanged pulses do not reacquire known friendly name, class,
      role, or specialization.
- [ ] `snapshot.roster` and `snapshot.enemies` are canonical before Store
      publication; UI performs no roster normalization or enemy truth cleanup.
- [ ] Compact and expanded surfaces consume the same canonical enemy ordering.
- [ ] One shared index serves local-player, entity, assignment, and target/call
      lookup needs across all base-addon surfaces.
- [ ] Base KWR has one owner for each Blizzard lifecycle and unit event.
- [ ] Ordinary friendly health events update direct bars once without forcing a
      complete sensor-to-commander refresh.
- [ ] Protected health values are not persisted, compared, or copied into
      ordinary state by the new fast lane.
- [ ] HUD and Presentation do not schedule redundant lifecycle render bursts.
- [ ] Store selectors use exact domain revisions instead of rebuilding
      overlapping full-row signatures.
- [ ] A change in one domain wakes only its documented dependents.
- [ ] Active season is acquired once per relevant session/context transition.
- [ ] Combined Sentinel reuses bridge identity/truth while standalone Sentinel
      retains its fallback behavior.
- [ ] No new accidental globals, parallel state models, tickers, `OnUpdate`
      loops, or duplicate event frames are introduced.
- [ ] Secure target/focus clicks, combat-lockdown behavior, and taint safety are
      unchanged.

# Verification

1. Add deterministic API-call counters for a stable ten-player roster. Prove
   one initial identity acquisition, zero unchanged-pulse reacquisition, and
   one update after each explicit invalidation.
2. Test roster join/leave, raid-slot hydration, reconnect, duplicate short
   names across realms, GUID arrival, role change, specialization change,
   inspect failure/retry, manual rescan, and session reset.
3. Test scoreboard partial/full hydration, cross-faction team resolution,
   enemy GUID enrichment, duplicate enemy evidence, target/focus/nameplate
   churn, note retention, priority retention, and stable order.
4. Inject health bursts for ordinary teammates, friendly carriers, enemies,
   target/focus, dead/alive, max-health change, and missing units. Assert direct
   render counts and full-pipeline counts separately.
5. Assert domain dependency behavior: roster-only, health-only, score-only,
   objective-only, enemy-only, combat-only, assignment-only, and unchanged
   inputs.
6. Exercise compact TEAM/ENEMY/BOTH, expanded Team/Enemies, HUD, Tactical Map,
   CursorRing, MainWindow hide/show, combat enter/leave, preview, and arena
   suppression.
7. Run combined and standalone Sentinel fixtures with zero, twenty, and forty
   visible nameplates.
8. Run:

   ```powershell
   ./tools/validate.ps1
   ./tools/knowledge-audit.ps1
   powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1
   ./tools/build.ps1
   ```

9. Capture live `/kwr perf`, `/kwr verify`, taint log, UI error log, a complete
   ten-player battleground, reconnect, match completion, and combined Sentinel
   evidence.
10. Compare executed refreshes, API reads, allocations, p95/max runtime cost,
    Store notifications, and actual UI mutations against the Phase 0 baseline.

# Rollback

Roll back one phase at a time through compatibility adapters:

1. Keep legacy snapshot arrays while removing new indexes/revisions from
   consumers.
2. Restore old UI selectors without restoring UI-owned truth cleanup.
3. Restore direct per-surface health handling only behind a diagnostic flag if
   the shared safe-display boundary fails Retail verification.
4. Restore full roster capture while retaining canonical identity keys and
   migration data.
5. Disable combined Sentinel reuse and return Sentinel to its standalone path.

Never delete migrated identity or SavedVariables data during rollback. Preserve
the pre-migration schema reader for at least one external-test cycle.

