---
id: KWR-029
title: Keep local kill and healer-control truth on the compact HUD
owner: unassigned
priority: high
risk: medium
dependencies: []
affected_modules:
  - Core/Store.lua
  - Data/CounterplayMatrix.lua
  - Data/EnemyProblemTypes.lua
  - Intelligence/AssignmentOptimizer.lua
  - Intelligence/EnemyProblemDetector.lua
  - Intelligence/ExecutionCommandBuilder.lua
  - UI/HUD.lua
  - tests/smoke.lua
---

# Objective

Make the enabled live compact commander HUD reserve one permanent local-fight card containing the current local kill target and healer-control lanes.

# User outcome

During a local battleground fight, the commander can always read who the team should kill and who controls each confirmed local healer without opening another surface.

# Current behavior

The live HUD explicitly hides its dedicated team-plan and local-target cards. Healer-control state also disappears between casts because a control problem is created only while a healer is actively free-casting.

# Required behavior

Reuse one existing compact HUD section as a permanent `LOCAL FIGHT` card. Render structured kill and healer-control state independently, use explicit placeholders when either lane is unknown, and clear expired names without hiding the card. Keep a confirmed local healer assigned to a control lane throughout the observed local fight, with higher priority while free-casting.

# Non-goals

- Do not retain stale targets after local evidence expires.
- Do not create healer-control calls from scoreboard-only or remote enemies.
- Do not automate targeting, focus, crowd control, or secure actions.
- Do not change expanded-window or arena suppression rules.

# Technical constraints

- The HUD remains a pure Store consumer.
- `snapshot.executionCommand` owns synchronized kill and control assignments.
- `snapshot.combat` remains the safe fallback for a local kill target.
- Unknown actors and targets must remain explicit; the renderer must not invent identity.
- Refresh and assignment work must remain bounded to battleground team size.

# Acceptance criteria

- [x] The enabled live compact HUD always shows a `LOCAL FIGHT` card.
- [x] Kill and healer-control lanes render independently.
- [x] A confirmed local healer receives a control lane even between casts.
- [x] A remote or scoreboard-only healer does not receive a local control lane.
- [x] Free-casting healer control remains higher priority than passive local healer control.
- [x] Ending the local fight clears stale names but leaves the card visible.
- [x] Setup-mode content and surface suppression remain unchanged.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `./tools/knowledge-audit.ps1`.
3. Run `fengari tests/smoke.lua`.
4. Run `fengari tests/soak.lua`.
5. Field-test a local battleground fight with a kill target and at least one observed enemy healer.

Offline evidence on 2026-07-28:

- `tools/validate.ps1`: passed with 118 Lua files, 0 errors, and 0 warnings.
- `tools/knowledge-audit.ps1`: passed with 0 errors.
- `tests/smoke.lua`: passed with `KWR_SMOKE_PASS checks=275`.
- `tests/soak.lua`: passed 500 refreshes with 120 bounded duration samples,
  0.234 ms average, 0.800 ms p95, and 3.200 ms maximum synthetic refresh time.
- Deterministic fixtures cover passive local healers, remote-healer rejection,
  free-cast priority, recent-local retention, expiry clearing, HUD placeholders,
  and protected objective-assignment precedence.
- Live battleground visual and API confirmation remains the final user-side gate.

# Rollback

Revert the bounded healer-control qualification, live HUD card presentation, and their regression assertions. No saved-variable migration is involved.
