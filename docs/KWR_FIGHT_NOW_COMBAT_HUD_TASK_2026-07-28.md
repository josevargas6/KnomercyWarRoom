---
id: KWR-035
title: Make live combat surfaces issue pure Fight-Now direction
owner: codex
priority: critical
risk: high
dependencies:
  - KWR-029
  - KWR-126
affected_modules:
  - Core/CommandView.lua
  - Features/CursorRing.lua
  - UI/Theme.lua
  - UI/HUD.lua
  - UI/CombatRosterState.lua
  - UI/CombatRosterVisuals.lua
  - tests/smoke.lua
---

# Objective

Turn the existing compact battleground HUD and combat roster into one
Fight-Now direction system for live battleground combat.

# User outcome

During combat, a player can immediately read the current score and projected
result, the objective that protects the win path, current defense and offense
posture, the current and next team call, the reviewed local kill target, the
healer-control assignment, and every teammate's current synchronized job.

# Current behavior

The compact HUD gives win condition, current call, personal assignment, local
fight, trust badges, technical controls, and status prose equal visual weight.
The expanded command vocabulary also leaks into the compact view. Current and
next direction do not consistently present WHAT, WHO, WHERE, and WHEN. The
friendly combat-roster row displays the static assignment in a narrow state
column instead of promoting the synchronized current job.

# Required behavior

- In live battleground combat, show only the current score, projected
  win/loss/tie, short win path, current call, next call, defense posture,
  offense posture, reviewed local kill/pressure target, and healer-control
  assignments.
- Render both current and next calls with explicit WHAT, WHO, WHERE, and WHEN
  fields.
- Use short battleground terms and reviewed map abbreviations instead of
  engineering, evidence, confidence, revision, source, or verification terms.
- Keep setup-mode roster-building content unchanged outside a live
  battleground.
- Use the crosshair/reticle combat palette as the shared meaning for movement,
  kill, stop/CC, recovery, carrier/objective, unknown, and stale states.
- Make friendly health rows display the synchronized execution job when one
  exists, falling back to the static battleground assignment.
- Mark enemy health rows as KILL, PRESS, or CC only when the same reviewed
  local-fight packet owns that call.
- Preserve direct health updates, secure row binding, target/focus behavior,
  arena suppression, and combat-lockdown safety.

# Non-goals

- Do not add another HUD, state model, planner, ticker, or combat roster.
- Do not automate movement, targeting, focus, crowd control, spells, chat, or
  group communication.
- Do not expose unavailable enemy health or promote a merely tracked enemy to a
  reviewed kill target.
- Do not remove the expanded planning, verification, enemy-intelligence, or
  AAR pages.
- Do not change prediction, assignment, or teamfight decision logic.

# Technical constraints

- `snapshot.executionCommand` remains the authority for synchronized personal
  jobs and local kill/control calls.
- `command.activePlay` and `command.activePlayCandidate` remain the authority
  for stabilized current and candidate next team direction.
- The compact UI remains a pure Store consumer.
- All render work remains bounded to battleground team size and Store updates;
  no new `OnUpdate` work is allowed.
- Color cannot be the only carrier of meaning; every state keeps a short text
  label.
- Unknown identity, location, health, or timing must remain explicit and must
  never be inferred by the renderer.

# Acceptance criteria

- [x] Live compact HUD contains no source, confidence, revision, seen-count,
      verification, refresh, or reassessment copy.
- [x] Score and `PROJ WIN`, `PROJ LOSS`, or `PROJ TIE` are visible together.
- [x] The win path and next objective use battleground-specific short terms.
- [x] Current and next calls each render WHAT, WHO, WHERE, and WHEN.
- [x] Defense and offense posture remain visible without long doctrine prose.
- [x] Local KILL/PRESS and CC lanes remain independent and clear safely.
- [x] Friendly health rows replace static jobs with synchronized current jobs
      and revert cleanly when the packet clears.
- [x] Enemy health rows distinguish reviewed KILL/PRESS/CC from tracked or
      last-seen enemies.
- [x] HUD, combat roster, target reticle, and battlefield identifiers consume
      one shared combat palette.
- [x] Setup mode, arena suppression, secure bindings, and direct health updates
      remain intact.
- [x] Deterministic smoke and soak coverage passes.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `./tools/knowledge-audit.ps1`.
3. Run `fengari tests/smoke.lua`.
4. Run `fengari tests/soak.lua`.
5. Run `./tools/build.ps1`.
6. In a live battleground, confirm current/next WHAT-WHO-WHERE-WHEN direction
   can be read at a glance while the team rows change jobs with the execution
   packet.
7. Confirm unknown enemy health and unreviewed tracked enemies are never
   promoted to KILL or CC.

# Verification evidence

- `tools/validate.ps1`: passed; 118 Lua files, 0 errors, 0 warnings.
- `tools/knowledge-audit.ps1`: passed; 0 errors.
- `tests/smoke.lua`: `KWR_SMOKE_PASS checks=275`.
- `tests/soak.lua`: `KWR_SOAK_PASS refreshes=500`; 0.234 ms average,
  0.800 ms p95, 3.200 ms maximum synthetic refresh cost.
- Reproducibility audit: passed.
- Extracted distribution and developer package smoke/soak audit: passed.
- Direct Retail battleground verification remains the field promotion gate.

# Rollback

Restore the previous compact HUD section layout and static combat-roster
assignment lookup. The shared palette is display-only and introduces no saved
variable migration.
