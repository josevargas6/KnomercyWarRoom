# Historical: KWR Pillar Execution Sheet

This work-order sheet is subordinate to `RELEASE_VISION.md`. It applies to the
Commander candidate only; optional suite components keep separate release
lanes.

This is the strict no-drift execution sheet for finishing KWR into a
trustworthy alpha test candidate.

Work the pillars in order. Do not skip ahead for cosmetic polish if an earlier
pillar is still feeding bad truth into the system.

## Finish order

1. Pillar 1 - Truth
2. Pillar 2 - Stability and Safety
3. Pillar 3 - Decision Quality
4. Pillar 4 - Presentation and Commander Usability
5. Pillar 5 - Verification and Learning

## Current alpha status

Alpha 28 is code-complete for the current offline gate. The major remaining
risk is no longer missing architecture; it is GitHub recovery review, live
Retail proof, and doctrine validation under real battleground pressure.

Current pillar posture:

- Pillar 1: strong offline; still needs live map-marker and scoreboard proof.
- Pillar 2: strong offline; still needs live taint, secure-click, and full
  match-cycle confirmation.
- Pillar 3: materially stronger after doctrine expansion, response packaging,
  and knowledge freshness gating; still needs real-match quality review against
  high-MMR enemy comps.
- Pillar 4: premium offline baseline achieved; remaining work is now live
  readability and placement confirmation across actual resolutions and combat density.
- Pillar 5: strongest pillar offline; remaining work is evidence capture,
  AAR review, and doctrine tuning from real matches rather than invented data.

Recent completed execution slices:

- Completed a local-target semantics pass. Local-fight target selection remains bounded to safe local evidence and is now labeled consistently as a local target rather than a generic global kill call.
- Completed a configuration-discipline pass. The options surface now groups real functional toggles by system, refreshes live state on open, and removes duplicate/dead control exposure from the main settings path.
- Completed a reporter-clarity pass. Reporter now distinguishes visible, recent, and stale enemy track quality, surfaces route memory, and shows trust pace directly on the reporter map and tactical telemetry.
- Completed a launcher-polish pass. The minimap launcher now uses centered ring geometry, state-aware color treatment, and clearer tooltip/status feedback instead of the off-center tracking border skin.
- Completed a combat-roster/dashboard consistency pass. Combat spotlight idle copy, enemy-row emphasis, enemy tracker highlighting, and tactical card sizing now align to the same local-target truth model.
- Completed a compact-HUD readability pass. The compact HUD now has cleaner top controls, more section breathing room, and a less cramped local-target/full-call presentation.
- Completed a Sentinel packaging and audit pass. Smoke now covers the Sentinel relay path, and release packaging now reliably stages and verifies the Sentinel build artifact.
- Completed an AAR evidence-surface pass. The review window now exposes match snapshot, decision-review, and evidence-check summaries directly instead of burying that context only in exports.
- Completed a status-feedback pass. Quick calls now publish clearer transient send/copy/block feedback, and the compact HUD now shows one collapsed alert line for the latest meaningful change.
- Completed an enemy-tracker clarity pass. Enemy note badges, hover tooltips, and the manual note editor now separate manual field notes from learned-model context more cleanly.
- Completed a tactical-map hover-context pass. Tactical markers now expose bounded hover context for objective, unit, carrier, and vehicle state directly on the map.
- Completed an options-dependency pass. Child toggles now reveal when they depend on a parent KWR system instead of behaving like isolated settings.
- Completed a quick-call intent pass. Fixed battleground calls now expose grouped commander-intent guidance and tooltip context instead of a flat button wall.
- Completed a reporter-footer polish pass. The reporter surface now uses stable embedded-map anchoring plus explicit trust and legend footer lines above the truth cards.
- Completed a tactical reporter-summary pass. The main tactical board now surfaces reporter trust, coverage, and intent in a dedicated footer line under the live map.
- Completed a reticle-clarity pass. The target reticle now separates local target, command target, and swap-local states and stays silent on non-player battleground targets.
- Completed a shared-badge pass. Commander surfaces now reuse one bounded badge treatment instead of each window inventing separate status chrome.
- Completed a dashboard-header pass. The main board now surfaces current command state and headline action in the global header before the page body.
- Completed a roster-readability pass. Combat spotlight state is now badge-driven and roster pane headers summarize local/direct/stale pressure more clearly.
- Completed an alert-hierarchy pass. The compact HUD now exposes a dedicated alert-severity badge so urgency is visible before the full sentence.
- Completed an AAR-summary pass. The review window now exposes result, review completion, export readiness, and the next lesson ahead of the longer evidence blocks.
- Completed an enemy-toolbar state pass. The enemy tracker now exposes live/preview/formation status in the header instead of burying it in body text.
- Completed an enemy-toolbar coverage pass. The enemy tracker now summarizes direct, recent, stale, and noted enemy coverage at a glance.
- Completed an enemy-note truth split pass. Note tooltips now separate live truth from manual note and learned-model context.
- Completed an enemy-note editor badge pass. The note editor now surfaces seen-state and model-trust badges before the longer profile text.
- Completed a reporter trust-header pass. The reporter surface now exposes trust state as a dedicated header badge.
- Completed a reporter forecast-header pass. The reporter surface now exposes projected pace/status in a dedicated forecast badge.
- Completed a reporter quiet-state pass. Reporter cards now mark when pressure or route/event sections are quiet or empty instead of looking silently blank.
- Completed an intel-summary badge pass. The learning library now surfaces matches, reviewed count, and latest match state in top-line badges.
- Completed an intel-review badge pass. The intel review card now surfaces latest result, review state, and export readiness before body copy.
- Completed a launcher-menu command-summary pass. The launcher menu now carries a command-state badge and compact summary so it stays tied to live command truth.
- Completed an objectives-state badge pass. The objectives page now surfaces projected state and objective-truth status before the detailed rows.
- Completed an objectives-urgency badge pass. Urgency and prediction confidence now read as top-line signals before the win-condition body copy.
- Completed a team-readiness badge pass. The team page now surfaces ready/open-slot/readiness state at the summary level instead of only body text.
- Completed an assignments-state badge pass. The assignments page now surfaces command state, coverage health, and commander-lock status directly.
- Completed an assignments override-state pass. The logic card now marks when overrides are active instead of silently mixing override and baseline logic.
- Completed a verification truth-contract pass. `/kwr verify` now states whether core truth is fresh enough for aggressive commitment and how much evidence coverage exists.
- Completed a verification target-split pass. `/kwr verify` now separates local target from commander target instead of collapsing them into one field.
- Completed a verification reporter-trust pass. `/kwr verify` now surfaces reporter trust label, pace, and rationale directly.
- Completed a reticle observation-detail pass. Observed-target reticle state now carries more context even when no local or command target is active.
- Completed a tactical-header rail pass. The tactical map now exposes command-state, trust, coverage, and objective-source badges plus a local/pivot/hot context rail above the map body.
- Completed a quick-call status-rail pass. Quick calls now expose intent-group badges, per-button group labels, and a dedicated ready/send/blocked status lane.
- Completed a HUD truth-status pass. The compact HUD now surfaces truth authority separately from alert urgency.
- Completed a combat-spotlight truth-badge pass. The enemy spotlight now shows whether the threat is direct, recent, tracked, or absent instead of relying on action state alone.
- Completed a launcher truth-summary pass. The launcher menu now surfaces both command-state and live-truth badges before the action list.
- Completed a comp-threat modeling pass. The strategist now classifies reviewed enemy pressure archetypes before selecting doctrine branches.
- Completed an enemy-defense modeling pass. The strategist now classifies likely bunker, escort, split, and trap structures before selecting opener and recovery branches.
- Completed an opener-doctrine pass. KWR now exposes reviewed per-map opener branches instead of one implied start shape.
- Completed a recovery-doctrine pass. KWR now exposes reviewed per-map abandon/reinforce/trade/reset branches for failed-open and failed-fight states.
- Completed an endgame-doctrine pass. KWR now exposes reviewed per-map protect/stall/punish/force/desperation branches.
- Completed a doctrine-fixture pass. Deterministic scenario fixtures now certify doctrine selection contracts offline.
- Completed a premium-visual pass. TacticalMap now reserves dedicated telemetry rails, ReporterMap now carries a briefing card plus denser evidence cards, MainWindow now exposes a shared command/truth/reporter/doctrine header rail, CombatRoster now uses a larger spotlight lane, CursorRing now uses readable caption plates, and offline diagnostics now audit those geometry contracts.
- Completed a compact battlefield-identifier pass. Friendly players now use role icon plus short name, enemies use class icon plus short name, confirmed flag/orb carriers replace that identity marker, and KWR adds health only to the current enemy target and cast progress only to an active priority cast. The presenter remains transparent, bounded, and battleground-only.
- Completed the first full visual-audit consolidation pass. Before-BG, live-BG, and after-BG screenshot sets are now converted into one implementation brief at `docs/visual-direction/2026-07-15/COMPREHENSIVE_BATTLEGROUND_VISUAL_AUDIT.md`, closing the direction gap and leaving only implementation plus re-verification.

---

## Pillar 1 - Truth

### Goal

Every primary surface must agree on battlefield truth.

That means:

- main commander board;
- compact command HUD;
- combat roster;
- reporter map;
- assignment output;
- verify output;
- AAR match summary.

### Tasks

1. Fix faction truth everywhere.
   - Friendly faction must resolve correctly on every battleground.
   - Horde/Alliance side logic must stay aligned with map doctrine.

2. Fix score and objective truth convergence.
   - Main HUD and compact HUD must agree.
   - Reporter must agree with public widgets or safely remain unknown.
   - End-of-match state must settle correctly without `/reload`.

3. Tighten objective ownership and mechanic truth.
   - Node maps: owner, incoming, contested, reinforce state.
   - Flag maps: carrier, return, escort/kill state.
   - Cart maps: control, route pressure, turn-in race.
   - Orb/resource maps: carrier/pickup/channel state when public.

4. Fix local enemy truth.
   - `VISIBLE`, `ENGAGED`, `LAST`, and `ROSTER` must mean consistent things.
   - Engagement location must use the same short location vocabulary as command calls.
   - Unknown must remain unknown; wrong labels must disappear.

5. Fix compact HUD freshness.
   - Compact HUD must refresh when the main state refreshes.
   - No stale objective, stale score, or stale assignment should survive normal transitions.

6. Align assignment location language.
   - If command says `LM`, tracker/reporter/kill-target context must also say `LM`.
   - Same abbreviations everywhere.

### Done conditions

- No battleground shows the wrong faction.
- No battleground shows a wrong score after state settles.
- Compact HUD and main board agree through start, live play, and match end.
- Reporter never contradicts public objective truth.
- Enemy location labels use consistent commander language.
- `/reload` is not required to correct normal truth updates.

---

## Pillar 2 - Stability and Safety

### Goal

KWR must survive live play without taint, blocked actions, hidden recursion,
or refresh failures.

### Tasks

1. Eliminate protected-action faults.
   - No blocked frame suppression.
   - No forbidden hide/show on protected surfaces.
   - No combat-time secure mutation.

2. Preserve secure PvP interactions.
   - Enemy row left-click target must work.
   - Enemy row right-click focus must work.
   - Team/enemy split panes must not break secure bindings.

3. Fix transition stability.
   - World -> queue -> BG start.
   - Live BG -> scoreboard -> world.
   - Death/rez/respawn.
   - Zone/loadscreen transitions.

4. Remove stale recursion / loop risks.
   - No minimize/show recursion.
   - No Print/chat overflow loops.
   - No surface suppression loops.

5. Keep bounded runtime behavior.
   - No runaway row duplication.
   - No unbounded event logs.
   - No repeated rebuilds when a dirty-state refresh would do.

### Done conditions

- Zero BugSack errors in a normal match cycle.
- Zero taint / blocked / forbidden action reports.
- Target and focus behavior works in combat.
- Surfaces hide and restore correctly when leaving battlegrounds.
- No recursive show/hide or message-loop behavior remains.

---

## Pillar 3 - Decision Quality

### Goal

KWR must stop making generic calls and start making battleground-specific,
composition-aware, assignment-safe commander calls.

### Tasks

1. Deepen opener doctrine.
   - Every active battleground needs multiple reviewed opening shapes.
   - Openers must account for:
     - faction side;
     - our comp shape;
     - enemy comp shape;
     - safe default pug fallback.

2. Deepen stabilize doctrine.
   - Hold plans.
   - Two-base / three-base / route-control states.
   - Minimum defender and floater logic.

3. Deepen recovery doctrine.
   - What to do after a failed opener.
   - What to abandon.
   - What to reinforce.
   - When to trade instead of mirror-fight.

4. Deepen endgame doctrine.
   - Clock protection.
   - Overcommit punish.
   - Stall vs full commit.
   - “Do not peel” / “do not chase” conditions.

5. Add deep-truth doctrine layers in order.
   - `Data/ObjectiveRules.lua`
   - `Data/AssignmentDoctrine.lua`
   - `Data/CompThreats.lua`
   - `Data/EnemyDefenseModels.lua`

6. Wire those layers conservatively into:
   - `Runtime/Strategist.lua`
   - `Runtime/Assignments.lua`
   - `Data/ScenarioLibrary.lua`
   - `Runtime/AAR.lua`

7. Improve assignment integrity decisions.
   - If someone peels, what becomes exposed?
   - If a strike team moves, who stays?
   - If a defender dies, who replaces them?
   - If a push fails, what is the audible?

8. Improve kill-target and next-move logic.
   - Local actionable target first.
   - Swap when target is protected.
   - Promote next best target when current kill target dies.
   - Keep commander surfaces explicit about local target versus command pivot.

### Done conditions

- KWR no longer opens with generic “go two nodes” level calls on battlegrounds that need smarter starts.
- Every call names who moves, who stays, and what remains covered.
- Failed openers produce a believable recovery plan.
- Endgame calls protect the win path instead of chasing noise.
- Assignment integrity affects command quality in real matches.

---

## Pillar 4 - Presentation and Commander Usability

### Goal

The addon must be easy to lead from without covering the battlefield or forcing
the commander to open the large board for obvious answers.

### Tasks

1. Compact HUD quality pass.
   - Keep it current.
   - Keep it readable.
   - Show full actionable objective call when needed.
   - Keep assignment and command groups consistent with main board.
   - Keep local target wording distinct from broader commander pivot language.
   - Preserve enough vertical room that full-call and local-target text do not collapse into the header rail.

2. Combat roster quality pass.
   - Team and enemy panes movable independently.
   - Shared header/toolbar behaves correctly.
   - Split and combined modes both remain clean.
   - Health bars update reliably.
   - Keep spotlight wording and enemy-row emphasis aligned with the same local-target truth model used on the tactical board and HUD.

3. Reporter quality pass.
   - Replace guessy emptiness with safe useful detail.
   - Keep icons small, clean, and commander-readable.
   - Align abbreviations and location language.
   - Surface direct versus recent versus stale movement quality in plain commander language.

4. Battlefield clutter pass.
   - Reduce opacity where appropriate.
   - Avoid covering action with oversized panels.
   - Keep commander-first information on screen, not duplicated everywhere.

5. Target/spotlight clarity.
   - Current target remains obvious.
   - Kill target and next move remain readable.
   - No noisy false emphasis.

### Done conditions

- Commander can lead from compact surfaces during a match.
- Panels do not block the battlefield more than necessary.
- Team/enemy panes and reporter are placeable and stable.
- Full call language is available where the commander actually needs it.
- Presentation improves action speed without adding cognitive load.

---

## Pillar 5 - Verification and Learning

### Goal

KWR must be explainable, testable, and tunable from evidence.

### Tasks

1. Expand doctrine visibility in explanation paths.
   - `/kwrwhy`
   - command center details
   - AAR structured export

2. Log why a plan was chosen.
   - plan ID
   - doctrine layers used
   - confidence
   - switch condition
   - abort condition

3. Log whether it worked.
   - success after 15/30/60s where possible
   - objective retained or lost
   - defender coverage held or broke
   - push converted or stalled out

4. Keep learning subordinate to truth.
   - no hidden player blacklists
   - no permanent speculative reliability claims
   - no meta/historical override of live truth

5. Keep audit discipline.
   - syntax
   - validation
   - knowledge audit
   - smoke/soak
   - field-test truth agreement

### Done conditions

- We can explain why KWR made a call.
- We can see what doctrine influenced it.
- We can compare the call to the outcome.
- Learning remains advisory and evidence-bounded.

---

## Active execution focus

Do not spread effort evenly.

Current active focus should be:

1. Pillar 1 - Truth
2. Pillar 2 - Stability and Safety
3. Pillar 3 - Decision Quality

Pillar 4 and Pillar 5 continue only when they support one of the first three.

---

## Live bug triage rules

When testing, categorize every issue as one of:

1. Broken
2. Wrong
3. Stale
4. Unsafe
5. Generic

Priority order:

1. Unsafe
2. Wrong
3. Broken
4. Stale
5. Generic

### Test report format

- Map:
- Faction:
- What happened:
- What KWR showed:
- What it should show:
- Error text:
- Screenshot:

---

## No-drift rule

If a proposed feature does not improve:

- battlefield truth,
- safety,
- decision quality,
- commander usability,
- or evidence quality,

then it does not belong in the current execution pass.
