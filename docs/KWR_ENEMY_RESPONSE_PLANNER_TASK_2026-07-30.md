---
id: KWR-238
title: Add bounded enemy-response planner and consequence scoring
owner: Codex
priority: high
risk: medium
dependencies: []
affected_modules:
  - Runtime/EnemyResponsePlanner.lua
  - Runtime/Strategist.lua
  - Runtime/Verification.lua
  - tests/smoke.lua
  - KnomercyWarRoom.toc
---

# Objective

Add a bounded enemy-response planner that estimates the most likely enemy answer
to each candidate plan, prices the consequence, and rewards the safer
counter-response line.

# User outcome

KWR does not just name a plan; it compares candidate calls against likely enemy
answers and favors the line that preserves the score path through the next
response window.

# Current behavior

- Strategist simulates candidate plans with heuristic probability and risk.
- Doctrine and expert review layers describe safer answers and reviewed lines.
- The engine does not yet attach a structured likely enemy response per
  candidate or price the follow-on consequence explicitly.

# Required behavior

- Add a runtime enemy-response planner that uses only current safe sensor truth,
  doctrine guidance, and reviewed corpus data.
- Estimate likely enemy response, safest reply, and consequence adjustment for
  each strategist candidate.
- Feed the response adjustment into candidate scoring before final ranking.
- Surface the selected response plan on strategist output for verification and
  AAR.

# Non-goals

- No unsupported hidden-information claims.
- No fake forward simulation beyond bounded next-response reasoning.
- No commander-language UI rewrite in this task.

# Technical constraints

- Use safe visible battlefield truth only.
- Keep the planner deterministic and lightweight.
- Keep the planner additive to current strategist logic.
- Preserve current module boundaries and test determinism.

# Acceptance criteria

- [ ] Every strategist candidate can carry a bounded enemy-response evaluation.
- [ ] Candidate ranking changes when enemy-response consequence changes the safer line.
- [ ] Selected strategy output exposes the enemy-response plan and consequence score.
- [ ] Offline validation and Lua tests pass.

# Verification

1. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.

# Rollback

Remove the enemy-response planner module and strategist hooks, then restore the
previous candidate simulation behavior.
