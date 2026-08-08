# Historical: KWR Alpha S-Tier Master Plan

This is the final objective-driven execution plan for taking KWR from the
current offline-validated alpha candidate to an alpha test build that feels
premium, trustworthy, and intentionally engineered.

`RELEASE_VISION.md` is the top-level authority for product scope, component
ownership, recovery policy, and release sequencing. This plan is the Commander
engineering-quality plan inside that release vision.

- `PILLAR_EXECUTION_SHEET.md` defines work order.
- `S_TIER_EXECUTION_SCORECARD.md` defines scoring, acceptance criteria, and proof.
- `RELEASE_READINESS.md` defines the current release posture.
- `QA_CHECKLIST.md` defines the live proof checklist.

Current candidate: `6.1.0-alpha.28`. Older alpha references below document the
engineering path and retained behavior; they do not redefine the current
candidate or restore retired surfaces.

If a proposed change does not improve one of the categories named here, it does
not belong in the final alpha execution pass.

## Objective

Ship a focused alpha candidate that:

- is trustworthy on battlefield truth;
- is stable through a full battleground lifecycle;
- produces high-quality commander guidance from safe evidence;
- gives players useful local execution help without fabricating certainty;
- feels visually deliberate instead of unfinished;
- is packaged, testable, and evidence-backed for external alpha use.

## Finish line

KWR is considered `alpha S-tier ready` only when all of the following are true:

1. Every critical system category is at least `9.0`.
2. Truth, safety, decision quality, reporter, local targeting, and commander
   usability are each at least `9.2`.
3. No category remains below `8.8`.
4. `validate`, `knowledge-audit`, `smoke`, `soak`, and `build` pass together.
5. Live proof exists for the high-risk Retail-only categories.
6. No open issue remains in the `Unsafe`, `Wrong`, or `Broken` class that
   affects commander trust.

This is not a stable-release definition. It is the alpha bar for serious
external testing.

## Non-negotiable rules

1. Truth beats polish.
2. Safety beats convenience.
3. Unknown stays unknown.
4. One system owns each kind of truth.
5. Local assistance may refine execution, but may not silently replace map
   strategy.
6. Every score increase requires proof.
7. No feature survives because it is interesting; it survives because it
   materially improves truth, decisions, usability, safety, or evidence.

## Current baseline

Current state should be treated as:

- strong offline architecture;
- good alpha candidate for focused in-client testing;
- materially stronger visual baseline with shared badge/header language across the primary command surfaces;
- not yet fully proven on live Retail edge cases;
- not yet at S-tier confidence in reporter quality, local target quality,
  option discipline, or several commander surfaces.

Recent completed slices:

- configuration discipline: options now expose only functional grouped controls with live state refresh;
- local execution clarity: KWR now distinguishes local-fight targeting from broader command pivot language across the runtime and commander surfaces.
- reporter clarity: reporter trust pace, visible/recent/stale enemy track quality, and top route memory are now surfaced directly on the reporter map and tactical telemetry.
- launcher polish: the minimap launcher now uses centered ring geometry and state-aware status treatment rather than the old off-center tracking border.
- roster/dashboard consistency: combat spotlight, enemy tracker emphasis, and tactical card sizing now align to the same local-target truth model instead of mixing older kill-target wording with newer local execution language.
- compact HUD readability: the compact command board now has cleaner top-rail spacing and more room for the full-call and local-target sections.
- sentinel packaging and audit coverage: the Sentinel relay path is now included in smoke coverage, and release packaging now correctly stages, zips, hashes, and audits the Sentinel artifact.
- AAR evidence surface: the review window now shows match snapshot, decision-review, and evidence-check summaries instead of forcing all trust into the export path alone.
- status feedback: quick calls now report clearer transient send/copy/block states, and the compact HUD now surfaces one collapsed alert line for the latest meaningful battlefield update.
- enemy-tracker clarity: enemy row note badges, hover tooltips, and the manual note editor now present manual note and learned-model context as one clearer commander workflow.
- tactical-map hover context: tactical markers now expose bounded hover context directly on the map so objectives, carriers, local targets, and tracked units can be inspected without leaving the command board.
- options dependency clarity: child toggles now show when they require a parent KWR system instead of implying every setting is independently active.
- quick-call intent guidance: fixed battleground calls now carry grouped commander-intent language and tooltip guidance instead of reading as a flat button wall.
- reporter footer polish: the reporter surface now uses stable embedded-map anchoring plus a dedicated trust/coverage/footer legend above the truth cards.
- tactical reporter summary: the main tactical board now publishes reporter trust, coverage, and intent in a dedicated footer line under the live map.
- reticle player-only clarity: the target reticle now distinguishes local target versus command target and suppresses battleground guidance on non-player targets.
- shared status-badge system: commander surfaces now reuse one bounded badge treatment rather than inventing separate status chrome per window.
- dashboard header scan order: the main board now surfaces current command state and headline action in the global header before the page body.
- roster readability: combat spotlight state is now badge-driven and the pane headers summarize local/direct/stale enemy pressure more clearly.
- alert hierarchy: the compact HUD now exposes a dedicated alert-severity badge so urgency is visible without reading the whole alert sentence first.
- AAR summary hierarchy: result, review completion, export readiness, and next lesson now appear before the longer evidence blocks.
- enemy toolbar state: the enemy tracker now surfaces live/preview/formation status in the header instead of burying that context in body text.
- enemy toolbar coverage summary: the tracker now summarizes direct, recent, stale, and noted enemy coverage at a glance.
- enemy note truth split: note tooltips now clearly separate live truth from manual note and learned-model context.
- enemy note editor badges: the note editor now surfaces seen-state and model-trust badges before the longer profile text.
- reporter trust header: the reporter surface now exposes trust state as a dedicated header badge.
- reporter forecast header: the reporter surface now exposes projected pace/status in a dedicated forecast badge.
- reporter quiet-state headings: the reporter cards now mark when pressure or route/event sections are quiet or empty instead of looking silently blank.
- intel summary badges: the learning library now surfaces matches, reviewed count, and latest match state in top-line badges.
- intel review badges: the intel review card now surfaces latest result, review state, and export readiness before the body copy.
- launcher menu command summary: the launcher menu now carries a command-state badge and compact summary so it does not feel detached from live command truth.
- objectives state badges: the objectives page now surfaces projected state and objective-truth status before the detailed rows.
- objectives urgency badges: urgency and prediction confidence now read as top-line signals before the win-condition body copy.
- team readiness badges: the team page now surfaces ready/open-slot/readiness state at the summary level instead of only body text.
- assignments state badges: the assignments page now surfaces command state, coverage health, and commander-lock status directly.
- assignments override-state heading: the logic card now marks when overrides are active instead of silently mixing override and baseline logic.
- verification truth contract: `/kwr verify` now states whether core truth is fresh enough for aggressive commitment and how much evidence coverage exists.
- verification target split: `/kwr verify` now separates local target from commander target instead of collapsing them into one field.
- verification reporter trust: `/kwr verify` now surfaces reporter trust label, pace, and rationale directly.
- reticle observation detail: observed-target reticle state now carries more context even when no local or command target is active.
- tactical header rail: the tactical map now exposes command-state, trust, coverage, and objective-source badges plus a local/pivot/hot context rail above the map body.
- quick-call status rail: quick calls now expose intent-group badges, per-button group labels, and a dedicated ready/send/blocked status lane.
- HUD truth-status split: the compact HUD now surfaces truth authority separately from alert urgency.
- combat spotlight truth badge: the combat roster spotlight now shows whether the shown threat is direct, recent, tracked, or absent instead of relying on action state alone.
- launcher truth summary: the launcher menu now surfaces both command-state and live-truth badges before the action list.
- comp threat modeling: the strategist now classifies reviewed enemy pressure archetypes before selecting doctrine branches.
- enemy defense modeling: the strategist now classifies likely bunker, escort, split, and trap structures before selecting opener and recovery branches.
- opener doctrine library: KWR now exposes reviewed per-map opener branches instead of one implied start shape.
- recovery doctrine library: KWR now exposes reviewed per-map abandon/reinforce/trade/reset branches for failed-open and failed-fight states.
- endgame doctrine library: KWR now exposes reviewed protect/stall/punish/force/desperation branches per map.
- doctrine fixture coverage: deterministic branch fixtures now certify doctrine selection contracts offline.
- premium visual pass: TacticalMap now uses dedicated telemetry rails, ReporterMap uses a dedicated briefing card and denser evidence cards, MainWindow exposes one shared command/truth/reporter/doctrine header rail, CombatRoster uses a larger spotlight lane, CursorRing uses readable caption plates, and offline diagnostics now audit these geometry contracts.

## Execution model

All remaining work should run in this loop:

1. Pick the highest-gap category from `S_TIER_EXECUTION_SCORECARD.md`.
2. Restate the acceptance criteria before editing code.
3. Implement only the bounded slice needed to satisfy those criteria.
4. Run local proof:
   - `./tools/validate.ps1`
   - `./tools/knowledge-audit.ps1`
   - `fengari tests/smoke.lua`
   - `fengari tests/soak.lua`
   - `./tools/build.ps1` when release packaging is affected
5. Capture proof artifacts:
   - deterministic output;
   - screenshots;
   - `/kwr verify`;
   - AAR export;
   - live battleground evidence when required.
6. Move the score only if the proof actually supports it.
7. Advance to the next category only when the current category is no longer the
   highest-risk blocker.

## Workstreams

## Workstream 1 - Truth and authority

### Goal

Every major KWR surface tells the same battlefield story or explicitly says
that the truth is unknown.

### Categories

- Truth and state authority
- Assignment engine
- Reporter and battlefield awareness
- Enemy intelligence and opponent modeling

### Primary objectives

- keep faction, score, objective, roster, and match-end truth synchronized;
- ensure enemy state labels remain consistent across all windows;
- prevent reporter or enemy systems from contradicting stronger authoritative
  truth;
- make assignment language identical across command, roster, reporter, and HUD.

### Exit criteria

- no surface shows wrong battleground truth after state settles;
- reporter never presents stronger certainty than its evidence supports;
- enemy, objective, and assignment labels use one shared commander vocabulary;
- AAR reflects the same match truth the live surfaces used.

### Proof required

- `/kwr verify` snapshots on battleground start, mid-match, and match end;
- screenshot agreement across main board, HUD, roster, and reporter;
- map-specific QA evidence for score and objective transitions.

## Workstream 2 - Stability and protected behavior

### Goal

KWR survives the entire battleground cycle without taint, blocked actions,
frozen frames, or refresh drift.

### Categories

- Stability and protected-action safety
- Performance and bounded refresh cost
- Verification, diagnostics, and auditability

### Primary objectives

- protect secure target/focus interactions;
- eliminate combat-time protected mutations;
- keep refresh cost bounded during heavy activity;
- make failures diagnosable instead of mysterious.

### Exit criteria

- no protected-action errors or combat taint in a complete battleground cycle;
- world, queue, loading, death, rez, scoreboard, and match-end transitions work
  without `/reload`;
- soak remains bounded and live profiling shows no obvious runaway cost.

### Proof required

- deterministic smoke and soak results;
- complete battleground cycle test notes;
- taint-free live screenshot or log evidence where available.

## Workstream 3 - Decision quality and execution intelligence

### Goal

KWR makes stronger, clearer, more defensible tactical calls with safe evidence
and honest confidence.

### Categories

- Decision quality and doctrine
- Local kill-targeting and execution assist
- Commander usability and action clarity
- AAR, learning, and reviewed memory

### Primary objectives

- improve plan selection, switch conditions, and abort conditions;
- separate commander target from local target cleanly;
- make local target help role-aware and locally actionable;
- keep reviewed learning advisory and bounded rather than self-authoritative.

### Exit criteria

- command output has named reason, evidence, and reversibility;
- local target help is useful when the global target is not locally actionable;
- low-confidence situations become conservative rather than fake certainty;
- AAR can explain what KWR believed, why, and what happened next.

### Proof required

- AAR exports with evidence and outcome comparison;
- local-fight target validation captures;
- `/kwr explain` or equivalent command reasoning output;
- reviewed bug notes from high-MMR live testing.

## Workstream 4 - Battlefield sensor depth

### Goal

KWR has the right bounded structures to model human nuance and battlefield
patterns without crossing safety or truth boundaries.

### Categories

- Enemy intelligence and opponent modeling
- Reporter and battlefield awareness
- Knowledge freshness and data governance

### Primary objectives

- collect and retain reviewed opponent tendencies separately from live truth;
- trust tendency models only when evidence and freshness support them;
- improve reporter confidence routing, hotspot quality, and route readability;
- keep external and historical knowledge subordinate to direct evidence.

### Exit criteria

- player profile notes communicate trust, strength, weakness, and tendency
  without overstating certainty;
- reporter evidence is explainable and ages out cleanly;
- stale reviewed knowledge can no longer silently bias live calls.

### Proof required

- enemy profile screenshots and note readback;
- reporter comparison captures across multiple battleground types;
- knowledge audit output and manual freshness review.

## Workstream 5 - Surface polish and command ergonomics

### Goal

Every commander-facing and player-facing surface looks intentional, aligned,
readable, and worth trusting under pressure.

### Categories

- Global visual system
- Main dashboard / MainWindow
- Commander HUD
- Reporter map
- Tactical map
- Combat roster
- Enemy tab / note editor
- Quick calls
- Options window
- AAR window
- Cursor ring / crosshair / local target
- Minimap button / ring
- Status messaging / toasts / alerts
- Configuration quality and feature discipline

### Primary objectives

- remove overlap, misalignment, clipping, and weak hierarchy;
- standardize spacing, badges, colors, labels, and state language;
- reduce clutter and dead options;
- make urgent state obvious without visual noise.

### Exit criteria

- no visible overlap or broken layout remains at the supported resolutions and
  UI scales;
- every major surface has a readable hierarchy in under three seconds;
- every toggle that survives has a clear reason to exist;
- local target, commander target, stale data, and inferred data are visually
  distinguishable.

### Proof required

- screenshot matrix at `1280x720`, `1920x1080`, and `2560x1440`;
- screenshot matrix at `0.80`, `1.00`, and `1.15` UI scale;
- copy audit and option inventory review;
- short combat clips for HUD, roster, and reporter readability.

## Workstream 6 - Alpha release gate

### Goal

Produce one alpha package that is technically clean, visually credible, and
supported by enough proof that outside testers can trust what they are testing.

### Categories

- Release packaging and distribution readiness
- Verification, diagnostics, and auditability
- QA and evidence capture across all critical workstreams

### Primary objectives

- ensure the shipped artifact matches validated source;
- tie scores to proof artifacts;
- make remaining known risk explicit rather than hidden.

### Exit criteria

- build artifacts, hashes, and validation outputs are current;
- the scorecard reflects the actual tested state of the addon;
- known live-risk items are listed clearly for testers.

### Proof required

- release zip, developer zip, hashes;
- final validation outputs;
- completed live sections of `QA_CHECKLIST.md`;
- issue log with severity and disposition.

## Workstream 7 - Performance budget and truth-preserving efficiency

### Goal

Keep KWR fast enough that it never competes with actual gameplay for frame
time, while preserving the truth model and commander value.

### Categories

- Performance and bounded refresh cost
- Truth and state authority
- Stability and protected-action safety
- Release packaging and distribution readiness

### Target field budgets

These are the default release budgets for live battleground play unless proof
shows a stricter budget is required.

- addon memory target: `<= 25 MB` steady-state in live battlegrounds
- addon memory warning line: `> 28 MB`
- addon memory fail line: `> 32 MB`
- average refresh time target: `<= 1.5 ms`
- p95 refresh time target: `<= 4.0 ms`
- fail line for p95 refresh: `> 6.0 ms`
- worst-case single refresh fail line: `> 10.0 ms`
- average CPU share target in normal play: `<= 1.0%`
- peak CPU share target during heavy moments: `<= 3.0%`
- fail line for repeated peak CPU: `> 5.0%`
- minimum refresh spacing target: `>= 0.40 s`
- live command-surface refresh target during churn: no more than `2.5` full
  refreshes per second
- queued follow-up budget: at most `1` coalesced follow-up and `1`
  settle-refresh pending at a time
- persistent reviewed-memory budget target: `<= 8 MB`
- live runtime/transient budget target: `<= 10 MB`
- UI/frame/cache budget target: `<= 7 MB`

These are not arbitrary. KWR is a commander addon, not a combat rotation
engine. It should spend almost all of its time waiting, not working.

### Hard runtime rules

1. No unbounded timer chaining.
2. No repeated follow-up scheduling for the same truth state.
3. No polling when an event or explicit stale-state transition can do the same
   job.
4. No heavy table copying on every refresh if the surface only needs a compact
   view.
5. No full-surface redraw when no commander-visible state changed.
6. No repeated string building in hot paths unless the string is actually shown
   or exported.
7. No subsystem may keep its own silent retention policy outside the shared
   memory-budget contract.
8. Unknown or stale truth must degrade gracefully instead of forcing extra
   refreshes to “try again.”
9. Live battleground runtime must favor coalescing and dropping redundant work
   over chasing perfect immediacy.
10. If a refresh storm risks gameplay, KWR must preserve core truth first and
    defer secondary surfaces.

### Runtime budget rules by layer

#### Sensor layer

- only request expensive public data when the context is battleground-relevant;
- scoreboard requests must be rate-limited;
- repeated identical objective/widget reads within the same refresh cycle are
  forbidden;
- nameplate, target, focus, and mouseover reads must remain event-driven.

#### Runtime/orchestration layer

- one pending queue entry per refresh class;
- one settle window owner;
- one transition sweep owner;
- repeated queue revisions must collapse into one next eligible refresh instead
  of forming chains;
- after a heavy refresh, the runtime must bias toward cooldown/backoff instead
  of immediate catch-up.

#### Strategy/assignment layer

- comp matching, doctrine selection, and assignment generation should run only
  when their inputs changed materially;
- reviewed-model or explanation payloads must not be rebuilt on every event if
  the underlying decision did not move;
- local-target scoring must stay bounded to the visible/known candidate set.

#### UI layer

- windows must consume thin view data, not re-derive runtime truth;
- hidden windows do no heavy formatting work;
- compact surfaces get priority over expanded/review surfaces during pressure;
- export text is built on demand only.

### Execution pass strategy

This pass should run in this exact order:

1. Instrument the hot path.
   - capture refresh reason frequency
   - capture queue/follow-up/settle counts
   - capture p50/p95/max refresh time
   - capture per-subsystem time where practical
2. Stop refresh storms.
   - hard-cap chained follow-ups
   - collapse repeated settle refreshes
   - add backoff when queue churn exceeds budget
3. Reduce work per refresh.
   - skip unchanged subsystems
   - stop rebuilding unchanged surface payloads
   - stop formatting/export text in live hot paths
4. Thin retained/runtime payloads.
   - trim transient DTO copies
   - move expensive presentation strings to lazy builders
   - enforce one retention contract across live and reviewed memory
5. Verify against live budgets.
   - city idle
   - queue/building group
   - battleground start
   - first team fight
   - heavy objective swing
   - match end / scoreboard

### Exit criteria

- no script-ran-too-long errors in a full battleground cycle;
- refresh queues remain bounded during heavy battleground churn;
- KWR stays under the defined memory target or explains every justified
  exception;
- average and p95 refresh times remain under budget in live testing;
- FPS impact is not meaningfully felt by the player in normal use.

### Proof required

- `/kwr verify` or equivalent runtime diagnostics showing queue/follow-up
  counts;
- live memory and CPU snapshots during battleground play;
- before/after profiling notes for refresh count, p95, and peak time;
- one explicit budget report added to the field-test handoff after the pass.

## Priority order

The remaining execution order should be:

1. Truth and authority
2. Stability and protected behavior
3. Decision quality and execution intelligence
4. Battlefield sensor depth
5. Surface polish and command ergonomics
6. Alpha release gate
7. Performance budget and truth-preserving efficiency

Do not spread effort evenly. Work the biggest trust blockers first.

## Performance gap-closure slice plan

This is the ordered offline execution package required to close the remaining
quality gap between the current alpha and a true premium field build.

### Slice 1 - Runtime scheduler hardening

Why first:
- current live risk is refresh-storm behavior, and that can disqualify every
  other quality win immediately.

Status:
- completed offline on 2026-07-13; `MatchRuntime` now bounds coalesced queue
  follow-ups to a single chained pass before settle work, clears queue-chain
  state explicitly on preemption/manual refresh, and retains smoke/soak
  coverage for bounded follow-up behavior.

Required work:
- redesign `MatchRuntime` queue handling into explicit refresh classes;
- allow only one pending refresh per class;
- hard-cap coalesced follow-ups;
- hard-cap settle refreshes;
- add queue backoff when event churn exceeds budget;
- guarantee repeated identical churn collapses instead of chaining.

Exit criteria:
- no refresh path can self-chain indefinitely;
- no `script ran too long` from queue/timer churn in synthetic soak or live
  battleground pressure.

### Slice 2 - Incremental truth pipeline

Why second:
- once the scheduler is safe, the next biggest cost is recomputing too much
  truth too often.

Status:
- completed offline on 2026-07-13; Store now supports filtered subscriptions,
  the heaviest commander surfaces (`MainWindow`, `CombatRoster`,
  `ReporterMap`, `HUD`, `CursorRing`) only wake when their visibility gate or
  rendered slice changes, and Store publish now reuses unchanged snapshot and
  command branches instead of churning fresh tables every refresh.

Required work:
- split refresh work into bounded domains:
  - context
  - roster
  - objectives
  - enemy intel
  - reporter
  - combat/local target
  - strategy
  - assignments
  - command;
- add dirty-state/dependency gating between those domains;
- only rerun downstream stages when upstream truth changed materially.

Exit criteria:
- unchanged truth domains do no heavy work;
- strategy/assignment/command passes do not rerun on cosmetic-only updates.

### Slice 3 - Thin live DTO rewrite

Why third:
- live payload duplication increases both memory and per-refresh cost.

Status:
- completed offline on 2026-07-13 for the hot-path publish contract; Store now
  structurally shares unchanged published branches (`snapshot` sections,
  `prediction`, `assignments`, `command`, `diagnostics`) so unchanged runtime
  truth is reused instead of duplicated each refresh. Remaining DTO cleanup is
  limited to future presentation/export separation, not the live runtime path.

Required work:
- define one minimal live snapshot contract;
- define one minimal command DTO;
- define separate lazy export/review payload builders;
- remove presentation-ready strings from hot-path runtime state;
- remove repeated copied reasoning payloads where one owner is enough.

Exit criteria:
- runtime stores facts, not pre-rendered presentation;
- UI and export layers consume thinner contracts with less copy churn.

### Slice 4 - Surface work suppression

Why fourth:
- even with a safer runtime, UI can still burn frame time by formatting hidden
  or unchanged surfaces.

Status:
- completed offline on 2026-07-13; `MainWindow`, `CombatRoster`, `ReporterMap`,
  `HUD`, and `CursorRing` are now filtered or signature-gated so hidden or
  unchanged surfaces do not perform redundant refresh work.

Required work:
- hidden windows do no expensive formatting;
- unchanged visible values do not trigger relayout/repaint;
- long export, verify, and explanation strings are built only on demand;
- compact surfaces get priority under runtime pressure;
- expanded review surfaces are lazy and dormant by default.

Exit criteria:
- hidden UI is nearly free;
- visible UI updates only when player-visible state changed.

### Slice 5 - Memory budget enforcement

Why fifth:
- once payloads and runtime cost are reduced, memory policy can be enforced
  cleanly without hiding larger architecture problems.

Status:
- completed offline on 2026-07-13; MemoryBudget now owns soft/warning/fail
  pressure bands, trims through one unified live retention path, re-applies
  contract caps during live trims, and runs on filtered Store checkpoints
  instead of waking every publish.

Required work:
- formalize three memory domains:
  - live transient
  - reviewed retained
  - UI/cache;
- bind every subsystem to one budget owner;
- add hard cap + prune order enforcement to all retained stores;
- remove subsystem-local silent retention growth;
- add non-release assertions for over-budget growth.

Exit criteria:
- no retained store grows without an explicit cap and prune path;
- live memory fits the release target with justified exceptions only.

### Slice 6 - Performance diagnostics parity

Why sixth:
- truth diagnostics are strong; performance diagnostics need to be equally
  explainable.

Status:
- completed offline on 2026-07-13 for the release gate layer; soak now asserts
  average/p95/max refresh budgets and zero runtime refresh errors, and package
  certification already depends on that soak pass.

Required work:
- expose refresh count, queue depth, follow-up count, settle count, p95, max,
  and memory in a bounded runtime report;
- add per-subsystem timing where practical;
- expose dropped/coalesced work so throttling remains explainable.

Exit criteria:
- live performance failures are diagnosable from KWR evidence instead of guesswork.

### Slice 7 - Release build performance gate

Why last:
- this turns all of the above into an enforceable product standard.

Status:
- completed offline on 2026-07-13; soak enforces deterministic refresh budgets,
  package certification already depends on smoke/soak success, and the memory
  contract is loaded inside the offline harness rather than bypassed.

Required work:
- fail build/package audit when:
  - performance budgets are violated in deterministic harnesses;
  - dev/preview payloads leak into release;
  - retention contract coverage is incomplete;
  - runtime scheduler protections are disabled or missing.

Exit criteria:
- release artifacts cannot drift outside budget without breaking the gate.

## Golden-standard engineering parameters

These are the executive-grade product quality parameters KWR should be judged
against.

1. Truth integrity
2. Runtime efficiency
3. Architectural discipline
4. Product clarity
5. Stability and lifecycle safety
6. Memory and retention discipline
7. UX consistency and polish
8. Auditability and supportability
9. Release governance

Current highest gaps relative to that standard:

1. runtime scheduling and backpressure
2. full live performance enforcement
3. lifecycle hardening under heavy battleground churn
4. thinner hot-path payloads and lazy UI work
5. hard release-gate enforcement for performance and retention

## Score movement rules

Scores do not move because code changed. Scores move only when:

- acceptance criteria were named before the change;
- the implementation clearly addresses those criteria;
- deterministic validation still passes;
- any required live proof exists;
- the new state is documented in the scorecard.

If proof is missing, the score stays where it was.

## Bug triage rules

Every bug found during the final alpha pass must be classified as:

1. Unsafe
2. Wrong
3. Broken
4. Stale
5. Generic

Priority order is the same as the category order above.

No `Unsafe`, `Wrong`, or `Broken` issue in a critical workstream can be
deferred behind cosmetic polish.

## Daily stop/go gate

At the end of any major work session, answer these:

1. Which category moved?
2. What exact acceptance criteria were satisfied?
3. What proof artifact supports that claim?
4. What remains the highest-risk blocker?
5. Did any score go down because live proof failed?

If those answers are not available, the session did not actually advance the
master plan.

## Final alpha definition

KWR has reached the target state for external alpha testing when:

- commander trust is earned by truth agreement and explainable evidence;
- the addon survives live battleground use without safety excuses;
- local execution help is useful and disciplined;
- enemy and reporter intelligence are helpful without pretending to know more
  than Blizzard safely exposes;
- visuals look deliberate enough that testers evaluate the product, not the
  rough edges;
- the repo contains the evidence needed to justify the current score.

Once this plan is in effect, all remaining work should map directly to one of
its workstreams and one or more entries in `S_TIER_EXECUTION_SCORECARD.md`.
