# KWR 6.0 Architecture

## Runtime flow

1. `MatchRuntime` owns battleground lifecycle, active events, and the single live ticker.
2. `TeamResolver` establishes the roster-validated team assigned for this match.
3. `Sensors` captures one sanitized, team-relative snapshot from public Blizzard APIs.
4. `EnemyIntel` enriches that snapshot with scoreboard knowledge and safe visible-unit evidence.
5. `Capabilities` supplies bounded specialization ratings and battlefield-job
   preferences; `CombatIntel` selects a local target only from safely observed
   unit, defensive, trinket, and tactical-ability evidence.
6. `Reporter` records bounded movement only where public coordinates exist and always tracks objective state.
7. `Predictor` evaluates score/objective truth together with Reporter evidence.
8. `Assignments` gives each friendly player one deterministic job.
9. `Commander` composes one command object with state, action, who, when, why, confidence, movement evidence, source, expiry, and signature.
10. `Store` atomically publishes the complete immutable-by-convention live state.
11. `AAR` records match, command, system-event, and Reporter transitions from published state.
12. HUD, dashboard pages, expanded tactical map, minimized Reporter map, and compact combat roster subscribe to Store and render.

`Preview` enters at step 2 only when explicitly enabled outside a live battleground. Its state is marked `context.preview` and `mode = PREVIEW` through the entire pipeline.

## Alpha 8 decision-quality integration

Alpha 8 deepens the existing pipeline; it does not add a second recommendation
engine or battlefield state.

- `Reporter` derives bounded objective ETAs, likely enemy intent, momentum, and
  match-only rotation memory from sanitized movement and objective evidence.
- `CombatIntel` summarizes observable cooldown/resource economy and temporary
  opportunity evidence while leaving unavailable friendly or enemy facts
  explicitly unknown.
- `Strategist` owns the confidence budget and lightweight comparison of HOLD,
  ROTATE, TRADE, TEAMFIGHT, and SPLIT candidates. Unchanged inputs reuse a
  short-lived cached evaluation.
- `Assignments` verifies whether each issued job is on station, moving,
  abandoned, impossible, or unverified and proposes a compatible replacement.
- `Commander` remains the sole translator of the selected decision into the
  three-line command object.
- `/kwrwhy` presents evidence, risks, competing outcomes, success conditions,
  abort conditions, and counter sequence without enlarging the combat HUD.
- `AAR` stores bounded counterfactual review records for developer tuning only;
  review records cannot alter live logic.

## Manual AAR evidence export

The existing `AAR` Store subscriber also owns the post-match evidence export.
It reuses already published snapshot, command, assignment-integrity, objective,
Reporter, and safely sanitized scoreboard evidence. It adds no polling, map
logic, recommendation path, combat HUD line, or automatic chat behavior.

Per-match storage is bounded to 40 command transitions, 120 objective
transitions, 20 locations and 12 integrity notes per friendly player, and the
existing 30-match journal. Secret or unavailable score fields are discarded
before persistence. `/kwr aar copy` formats the latest completed entry only
when the player requests it and displays it through the existing copy dialog.

## Product surfaces

- Tactical Command Board: the primary expanded interface containing map art, score, win condition, objective action, assignments, target, and timeline.
- Scout HUD: the compact view of that command workflow.
- Reporter mini-map: an on-demand clean map with dots and short paths. Expanding it opens the Tactical Command Board.
- Compact combat roster: one secure Team/Enemy health-bar surface. Left-click
  targets and right-click focuses; the local kill target receives the only glow.
- Objectives: public control truth, projection, map status, and six fixed
  player-click secure Instance Chat calls with a compact copy fallback.
- Team: roster, composition, positions, readiness, and formation doctrine.
- Enemy Tracker: roster identity, observed age, health when visible, location source, priority, and notes.
- Assignments: one job and one location per detected player.
- Intel/AAR: persistent match history, evidence-based insights, doctrine, and review feedback.

The Scout mockup documents the workflow between compact and expanded states; it does not define an additional page. All surfaces are views over one domain model, not independent mini-addons.

## Ownership rules

- UI never refreshes sensors or reads strategic battlefield APIs.
- `CombatRoster` is the narrow presentation exception: it may pass
  `UnitHealthPercent` directly to a StatusBar and register secure click
  attributes out of combat. It never stores or compares protected health.
- Tactical map may request map-art textures; marker truth comes only from Store.
- Sensors never create command text.
- Predictors never mutate UI or SavedVariables.
- Commander never calls game APIs.
- Store is the only published live truth.
- MatchRuntime is the only owner of polling.
- Reporter runs inside MatchRuntime whether its views are shown or hidden.
- CombatIntel runs inside MatchRuntime whether Team/Enemy views are shown or hidden.
- Capability and patch data are pure inputs; they add no polling, events, or
  separately published state.
- Capability resolution is cached by specialization and Hero talent. Public
  callers receive isolated copies; hot-path scoring uses read-only cached rows.
- Formation publishes its capability summary once and Strategist reuses it.
- Ordinary friendly health/aura events update direct Blizzard-backed bars
  without rebuilding strategy; friendly objective carriers remain full events.
- Compact HUD and roster rows skip unchanged text/style renders while direct
  health bars continue receiving unit-event updates.
- Reporter retains only bounded in-memory tracks and consumes sanitized snapshot coordinates.
- AAR consumes published state and cannot alter live decisions.
- Optional features cannot modify battlefield truth.

## Data confidence

- Public score/objective widgets: authoritative when sanitized successfully.
- Scoreboard identity: roster-known, not proof of visibility.
- Target, focus, mouseover, nameplate, or ally-target evidence: observed/last-seen.
- Visible and last-seen locations retain observation source and age. Evidence
  without legal coordinates remains list intelligence and never becomes a map dot.
- Retail 12 blocks addon combat-log subscriptions; live defensive/trinket state
  remains unknown unless Blizzard exposes a separate permitted source.
- Murlok snapshot: dated advisory specialization context, never individual-player truth.
- Missing cooldown, aura, trinket, health, or position: unknown.
- Preview fixtures: visual review only and always labeled not live.

## Extending a map

Add or update its definition in `Data/Maps.lua`, doctrine in `Data/Doctrine.lua`, and deterministic fixtures in `Core/Diagnostics.lua`. Do not add map strategy or sensor calls to UI files.
