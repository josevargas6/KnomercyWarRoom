# Historical: KWR Winning-State Execution Map

This is a supporting Commander execution ledger under `RELEASE_VISION.md`.
It does not own suite scope, component dependencies, repository recovery, or
release sequencing. The current Commander candidate is `6.1.0-alpha.28`.

This file reconciles the attached `KWR_Winning_State_Offline_Work_Plan.zip`
with the current repository state.

Latest imported source package:

- `C:\Users\josev\.codex\codex-remote-attachments\019f38e6-581c-7e71-a6a0-1e0593566370\9E719851-D4B8-4B27-A164-AE3DA4F94FAB\1-KWR_Winning_State_Offline_Work_Plan.zip`

It is the active repo-native translation of that imported plan within the
Commander engineering lane.

Use it to answer three questions:

1. What is already done and should not be reworked?
2. What still remains offline and should be executed now?
3. What can only be closed by live battleground or field verification?

If this file conflicts with the older zip tracker, this file wins because it is
based on the current codebase and current validation evidence.

The zip's CSV tracker remains useful as a planning seed, but it is not current
enough to drive execution directly because many items listed as `Not Started`
have already been completed, partially absorbed, or moved into live-only gates
inside this repo.

Latest retained enhancement slices completed after the offline winning-state pass:

- The first audit-remediation execution slice is now complete on the live repo baseline: `Store` no longer suppresses semantic nested-state changes through lossy sampled tokens, and smoke now locks that exact publication contract.
- The first objective-authority repair slice is now complete: `Sensors` normalizes live widget rows to canonical `ui_widget` provenance so reviewed source authority can no longer be bypassed by weaker POI state.
- The first truthfulness repair slice for enemy coordinates is now complete: enemy semantic engagement context remains available, but teammate/assignment fallback no longer becomes enemy positional truth or reporter fallback dots.
- The first canonical-identity repair slice is now complete across commander overrides, enemy truth, and compact roster normalization: same-short-name players no longer merge by default, and ambiguous short-name override queries fail closed.
- The first secure compact-surface suppression repair slice is now complete: compact roster auto-show no longer re-enters its own request/layout loop, and combat-safe suppression remains on the stable request path.
- The first post-baseline Phase 1 correctness slice is now complete: Reporter no longer keeps absent friendly contributors after the roster changes, MemoryBudget now samples the current Store state, MatchRuntime re-evaluates strategy after assignment integrity exists, and zero-deficit recovery summaries no longer claim fake urgent gaps.
- The first SavedVariables and interruption-policy repair slice is now complete: bootstrap now normalizes malformed persisted fields against typed defaults and normalizes known persisted roots before module consumption, while active AAR journals now persist and resolve as one explicit interrupted record instead of disappearing on teardown.
- The first objective-carrier message repair slice is now complete: named flag return/capture battleground messages now clear only the affected flag carrier, while explicit full-reset wording uses a separate global reset path proven in smoke.
- The future-schema compatibility slice is now complete: newer SavedVariables revisions now trigger explicit read-only compatibility mode so normalized working data can load without silently downgrading or rewriting the persisted schema.
- The release-packaging trust slice completed at the Alpha 25 milestone: the then-active metadata aligned to alpha.25, the release workflow began rejecting tag/version drift, and package audit certified the stripped distribution archive with extracted smoke and soak instead of proving only the developer package.
- The first release-provenance slice is now complete on the repo baseline: build output emits explicit source manifests, tool provenance, and reproducibility reports, and two clean builds now prove matching staged payload digests with a documented PowerShell ZIP-container exception instead of an unproven artifact story.
- The deterministic timing-proof slice is now complete on the repo baseline: `tests/soak.lua` injects a reviewed synthetic cost pattern so average, p95, and max runtime timing samples must retain nontrivial percentile behavior instead of passing on a flat stub clock.
- The first runtime-efficiency observability slice is now complete on the repo baseline: Verification now dedupes before full entry construction, ordinary friendly health churn no longer queues whole-pipeline refreshes, and Commander stability telemetry now separates raw evaluations from published command evidence.
- Objective rows in `Sensors` now preserve native widget semantics, source evidence, lineage roots, TTLs, and field-resolution metadata while keeping the generic objective contract stable.
- `Verification` now surfaces sampled per-objective source-resolution details for technical proof, including selected source, preserved native semantic, and conflict state, without promoting those internals into live commander UI.
- `Strategist` now treats objective-source conflict and non-authoritative objective state as a real uncertainty penalty: confidence drops, commit authorization is withheld, and deterministic smoke proves conflicted public objective truth cannot justify a hard macro commit.
- `Commander` now exposes the real baseline command-stability behavior instead of hiding it: current retention window, current TTL, bypass causes, churn counters, reversal detection, and command-lifetime metrics are recorded and shown in verification, which closes the P0 measurement prerequisite for the shared `ActivePlay` stability engine.
- The first shared `ActivePlay` contract now exists in the live state tree: `Commander` seeds a persistent authoritative play with objective, movers, stayers, timing windows, lifecycle phase, and success/abort/invalidation text, `Store` preserves it as first-class state, and `Verification` reports it. This closes the first half of the P1 shared stability-engine foundation.
- `Commander` now uses that `ActivePlay` state for a first real publication gate: it tracks candidate trend state, evaluates current-play invalidation, and can retain the current in-flight play when a new candidate lacks a bypass or a proven replacement edge. Deterministic smoke now proves the commander can hold an active node play instead of replacing it immediately with a fresh low-persistence alternative.
- Replacement control now has an explicit scored model instead of only implicit margins: `Commander` computes switch-cost, current remaining value, adjusted alternative value, and the applied margin, and `Verification` surfaces those numbers. Node-family policy is now attached to that scoring path through reviewed map timing (`captureSeconds`, `tickSeconds`, objective count, Blitz timing), which is the first concrete map-family stability policy slice.
- Override and invalidation are now explicit shared-engine behaviors instead of inferred outcomes: decisive invalidation can authorize replacement, override records are logged with evidence and lost commitment time, verification exposes override/invalidation counters plus the latest override event, and node-family hard invalidation now includes a proven held-node-loss path for committed node plays.
- AAR/export now closes the remaining offline review gap for the shared stability engine: completed match entries persist command-stability telemetry and the latest override record, the AAR window shows replacement/override summary data, and exports now carry a dedicated `Command Stability` section proven by validate + smoke + soak.
- The first battleground-aware node-policy refinement is now in place on top of that shared engine: reviewed travel estimates and map-specific structure penalties now increase reversal cost for Battle for Gilneas 2-base holds, Arathi outer-node swaps, Deepwind outer rotations, and central-anchor abandon cases, with deterministic smoke covering BFG and Arathi examples.
- The first flag-family execution-control slice is now in place on the same engine: ActivePlay commitment and replacement margins now recognize escort, return, and reset plays using safe flag-state truth (`friendlyFlagActive`, `enemyFlagActive`, public flag rows/positions, score capture state), and deterministic smoke proves a WSG escort play is retained through ordinary field pressure and invalidated only when the flag state changes decisively.
- The first orb-family execution-control slice is now in place on that same engine: ActivePlay commitment and replacement margins now recognize center/carry/hunt orb plays using safe carrier truth from `ObjectiveIntel`, orb possession changes can invalidate a held play explicitly, and deterministic smoke proves a Temple center-control play is retained through ordinary pressure and invalidated when friendly orb ownership changes.
- The first cart-family execution-control slice is now in place on that same engine: ActivePlay commitment and replacement margins now recognize escort, delay, crystal, and lane cart plays using safe public objective rows plus battlefield vehicle state, cart lane collapse can invalidate a held play explicitly, and deterministic smoke proves a Silvershard escort play is retained through ordinary lane noise and invalidated when the lane state actually breaks.
- The first resource/spawn-family execution-control slice is now in place on that same engine: ActivePlay commitment and replacement margins now recognize active-node and next-spawn plays using safe public resource-node truth, resource-node completion or disappearance can invalidate a held play explicitly, and deterministic smoke proves a Seething Shore active-node play is retained through ordinary spawn churn and invalidated when the node state actually changes.
- ActivePlay is no longer only a timer-driven contract: the live state now carries family-specific milestones derived from battleground truth (`OBJECTIVE_SECURED`, `FC_STANDOFF`, `CENTER_CONTEST`, `FRIENDLY_CART_LIVE`, `ACTIVE_NODE_LIVE`, etc.), and those milestones can promote the execution phase for node, flag, orb, cart, and resource plays before raw timers alone would do so. Deterministic smoke now covers milestone promotion across all of those families.
- ActivePlay decisions are now explainable in family-specific language instead of only counters and phases: the Commander attaches a current state reason to the decision payload, `/kwr verify` reports that reason directly, and smoke proves a held Warsong escort play exposes a concrete `both flags remain out` explanation rather than only a retained/replaced bit.
- The shared technical-review surfaces are now aligned on the same stability contract: performance payloads now include command churn, bypass counts, lifetime metrics, latest override, and current ActivePlay state, closing the last missing offline reporting gap between `/kwr verify`, AAR export, and perf/debug review.
- The first local teamfight multi-assignment command slice is now in place on the same safe-command architecture: safe adapters feed a compliance-gated FactStore, normalized local teamfight state detects enemy problems, friendly capability profiles score assignments, the optimizer prevents one player from taking conflicting jobs, the kill-target selector coordinates the kill window, presenter contracts expose command cards/crosshair/target-assist/countdown/debug reasons, and smoke replay proves the target scenario without any protected action or spell-specific command language.
- The first enemy-awareness depth slice is now complete: opponent profiles produce structured traits and commander takeaways, enemy notes support local structured tags, assignment scoring consumes those traits only as bounded advisory modifiers, Reporter emits a plain battlefield read, and Options exposes inventory/layout audit data with smoke coverage.

## Status buckets

- `DONE` means current repo evidence already proves the offline requirement.
- `OFFLINE REMAINING` means code, packaging, UX, or deterministic-proof work is
  still required now.
- `LIVE ONLY` means offline work may be complete, but the gate requires field
  verification before promotion.
- `DEFERRED` means intentionally held for post-winning-state work and must not
  enter the alpha execution pass unless it replaces an existing system.

## A. Completed from the zip plan

These plan items were already completed or materially closed before this
winning-state map was activated.

### Runtime and performance

- `DONE` Fix Commander nil-score failure.
  Evidence:
  - [Runtime/Commander.lua](/D:/Program%20Files/World%20of%20Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/Commander.lua)
  - [tests/smoke.lua](/D:/Program%20Files/World%20of%20Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/tests/smoke.lua)
- `DONE` Bounded scheduler / refresh convergence hardening.
  Evidence:
  - [Runtime/MatchRuntime.lua](/D:/Program%20Files/World%20of%20Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/MatchRuntime.lua)
- `DONE` Hidden-surface render suppression for major commander surfaces.
  Evidence:
  - [Core/Store.lua](/D:/Program%20Files/World%20of%20Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Core/Store.lua)
  - [UI/MainWindow.lua](/D:/Program%20Files/World%20of%20Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/MainWindow.lua)
  - [UI/CombatRoster.lua](/D:/Program%20Files/World%20of%20Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/CombatRoster.lua)
  - [UI/ReporterMap.lua](/D:/Program%20Files/World%20of%20Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/ReporterMap.lua)
  - [UI/HUD.lua](/D:/Program%20Files/World%20of%20Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/UI/HUD.lua)
  - [Features/CursorRing.lua](/D:/Program%20Files/World%20of%20Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Features/CursorRing.lua)
- `DONE` Hot-path state structural sharing.
  Evidence:
  - [Core/Store.lua](/D:/Program%20Files/World%20of%20Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Core/Store.lua)
- `DONE` Soak-backed performance budget gate.
  Evidence:
  - [tests/soak.lua](/D:/Program%20Files/World%20of%20Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/tests/soak.lua)
- `DONE` Unified memory-pressure bands and central retention trimming.
  Evidence:
  - [Runtime/MemoryBudget.lua](/D:/Program%20Files/World%20of%20Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/Runtime/MemoryBudget.lua)

### Visual, clarity, and state language

- `DONE` Local target vs commander pivot split.
- `DONE` Shared status-badge language.
- `DONE` Tactical/reporter footer and header telemetry consolidation.
- `DONE` Enemy note truth split and editor badges.
- `DONE` Enemy note structured tags, learned-trait summary, and commander takeaway card.
- `DONE` Objectives, team, assignments, launcher, HUD, and reporter header-state polish.
- `DONE` Arena/PvE suppression policy for commander surfaces is implemented in code.

Commander engineering references under `RELEASE_VISION.md`:
- [ALPHA_S_TIER_MASTER_PLAN.md](/D:/Program%20Files/World%20of%20Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/ALPHA_S_TIER_MASTER_PLAN.md)
- [S_TIER_EXECUTION_SCORECARD.md](/D:/Program%20Files/World%20of%20Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/S_TIER_EXECUTION_SCORECARD.md)

## B. Offline execution status

These zip-plan items required offline execution in the current repo. The items
below are now reconciled against the current evidence so the map shows what is
actually still open versus what has been closed offline.

### B1. Product consolidation into one default command center

Status: `DONE`

Required outcome:
- one default primary command surface in normal use;
- reporter is an expanded state, not a competing live command window;
- duplicate action/assignment/trust summaries are removed from competing frames.

Offline evidence:
- default launcher/slash entry points route to the command-center path;
- tactical minimize returns to the compact command-center path;
- standalone reporter restore obeys the explicit `autoReporter` preference;
- shell, launcher, HUD, tactical board, and support-view labels now reinforce
  one command-center product with subordinate support/review views;
- deterministic smoke guards the top-level shell naming contract.

### B2. Strict command-language formatter

Status: `DONE`

Required outcome:
- primary visible command uses consistent `ACTION / WHO / TRIGGER` grammar;
- doctrine prose stays behind secondary detail surfaces;
- assignment copy/export formatting is normalized.

Offline evidence:
- primary, HUD, tactical, caller, and assignments-plan paths use the shared
  `ACTION / WHO / TRIGGER` family;
- review/export headings were cleaned to battleground-facing language;
- support-view and shell wording were cleaned to plain player-facing language;
- smoke guards the command-review layout and shell naming contract.

### B3. Repo-native winning-state documentation set

Status: `DONE`

Required outcome:
- zip plan is represented inside the repo as current state, not external notes;
- add a deferred backlog file for ideas frozen out of the current pass.

Offline evidence:
- the imported winning-state zip is recorded in this repo;
- the repo-native execution map, gate board, readiness file, scorecard, visual
  worksheet, and QA checklist form the supporting Commander planning set under
  `RELEASE_VISION.md`;
- the zip tracker is explicitly treated as a stale seed rather than a live
  source of truth.

### B4. Full offline/release gate wiring

Status: `DONE`

Required outcome:
- release packaging should explicitly include the winning-state gate posture;
- deterministic validation should cover the remaining non-live UX contracts
  where practical.

Offline evidence:
- performance gates are wired through validation, smoke, and soak;
- release-gate board and QA checklist are synchronized to the current
  command-center candidate and current smoke/soak posture;
- no `OPEN` offline gate remains in `WINNING_STATE_RELEASE_GATES.md`;
- remaining release promotion work is field evidence, not additional offline
  repo bookkeeping.

### B5. Visual QA matrix documentation and capture scaffold

Status: `DONE`

Required outcome:
- supported resolution/UI-scale matrix is clearly defined in-repo;
- screenshot checklist and defect-capture structure exist for field use.

Evidence:
- [LIVE_VISUAL_SCRUB_WORKSHEET_2026-07-12.md](/D:/Program%20Files/World%20of%20Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/LIVE_VISUAL_SCRUB_WORKSHEET_2026-07-12.md)
- [QA_CHECKLIST.md](/D:/Program%20Files/World%20of%20Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/QA_CHECKLIST.md)
- [WINNING_STATE_RELEASE_GATES.md](/D:/Program%20Files/World%20of%20Warcraft/_retail_/Interface/AddOns/KnomercyWarRoom/WINNING_STATE_RELEASE_GATES.md)

## C. Remaining live-only or field-verification gates

These items are the remaining blockers after the offline execution pass. They do
not require more offline repository work; they require Retail field evidence.

### Runtime and safety

- `LIVE ONLY` 20 consecutive battlegrounds with zero Lua errors.
- `LIVE ONLY` zero taint / blocked-action events in real battleground cycles.
- `LIVE ONLY` no reload-required lifecycle failures across queue, load, match,
  death, rez, exit, and requeue.

### Performance

- `LIVE ONLY` battleground P95 refresh under the real field budget.
- `LIVE ONLY` no user-visible stutter attributable to addon activity.
- `LIVE ONLY` 30-minute post-GC growth within the field budget.

### UX and field trust

- `LIVE ONLY` command-center comprehension and action-readability checks.
- `LIVE ONLY` supported-map behavior proof.
- `LIVE ONLY` player-only targeting claims and non-player classification proof.
- `LIVE ONLY` local teamfight assignment proof with real battleground facts: two support problems, one kill target, distinct friendly assignments, display-only target assist, no taint, and no protected-action side effects.
- `LIVE ONLY` screenshot matrix across supported resolutions/scales inside the
  actual client.

### Release and presentation

- `LIVE ONLY` blind presentation/demo comprehension proof.
- `LIVE ONLY` release-candidate promotion checklist.

## D. Deferred backlog rule

Anything in the zip that would add:

- a second decision brain;
- a new map family;
- a new advisor subsystem;
- a new export family;
- a new live command surface;
- speculative targeting capability beyond secure WoW APIs;

must go to `POST_WINNING_BACKLOG.md` unless it replaces an existing owner.

## E. Next execution order

1. Capture Retail evidence for the live-only combat-safety and lifecycle gates below.
2. Finish the remaining Retail lifecycle and field-performance proof items without widening the architecture.
3. Fix only defects discovered during that field validation or live proof work.
4. Re-run the full offline gates after each live-field repair.

Recent proof improvement:

- top-level command-center naming now has deterministic smoke coverage for the
  `REVIEW / AAR`, `LIVE BATTLEFIELD VIEW`, and launcher-menu `SUPPORT VIEW`
  contract, reducing drift risk on the remaining command-surface cleanup work.
- objective rows now preserve native widget semantics plus source-evidence and
  field-resolution metadata inside `Sensors`, with smoke coverage proving the
  backward-compatible evidence envelope exists on live objective rows.

## F. Zip tracker translation

The attached CSV should be interpreted against the current repo like this:

- `P1-001` through `P1-003`: materially completed offline; remaining closure is
  live validation only.
- `P2-001` through `P2-003`: partially completed offline; deterministic budget
  and suppression work exists, but real-field proof and a few release-gate
  checks remain.
- `P3-001` through `P4-002`: partially completed offline; command-center
  routing and command grammar are mostly aligned, but a final consolidation pass
  is still required on secondary/detail surfaces.
- `P5-001` through `P8-003`: materially closed offline on the current repo
  baseline; remaining closure is live validation or targeted deterministic proof
  only when a field defect exposes a new gap.
- `P9-001` through `P12-002`: mostly gate or release work; keep these in the
  queue, but do not let them preempt the remaining command-center, language, and
  release-proof slices.
