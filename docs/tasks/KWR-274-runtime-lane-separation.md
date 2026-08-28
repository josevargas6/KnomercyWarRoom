---
id: KWR-274
title: Separate live UI, tactical, and strategic runtime work
owner: Codex
priority: critical
risk: high
status: blocked
dependencies: [KWR-273]
affected_modules: [Runtime/MatchRuntime.lua, Runtime/EnemyIntel.lua, UI/MainWindowReports.lua, tests/smoke.lua, tests/soak.lua]
authority_references: [AGENTS.md, QA_CHECKLIST.md, RELEASE_READINESS.md]
---

# Objective

Keep live battleground surfaces responsive under raid event storms without
recomputing strategic doctrine for health, aura, targeting, or cast traffic.

# User outcome

KWR retains current battlefield calls through noisy combat, updates local
fight presentation promptly, and exposes exact evidence for every scheduled
strategic or tactical refresh.

# Current behavior

Direct health and aura events are already lightweight, but most target, cast,
and nameplate events share the same full refresh queue as authoritative score
and objective truth. A fixed two-second full pulse compounds that work and the
telemetry does not attribute executions by reason or lane.

# Required behavior

- Classify live work into direct UI, tactical, and strategic lanes.
- Health and aura traffic remains direct and never schedules either queue.
- Target, focus, nameplate, unit-target, and cast traffic refreshes tactical
  enemy/combat presentation first. Only a material change in bounded enemy
  location, engagement, carrier, death, or priority-cast truth may escalate to
  one coalesced strategic refresh.
- Score, objective, roster, match-phase, and battleground-system evidence owns
  the strategic queue.
- Replace the fixed full pulse with a bounded recovery heartbeat that runs only
  after strategic truth has gone stale.
- A pending strategic refresh absorbs redundant tactical work.
- Report event counts, queue counts, executions, coalescing, duration, and P95
  separately for tactical and strategic lanes.
- Preserve one Store authority and current combat-lockdown behavior.

# Non-goals

- Do not change battleground doctrine, command scoring, or release publishing.
- Do not make unknown truth authoritative.
- Do not add saved-variable schema or settings.

# Technical constraints

- All queues are bounded and use the existing runtime event owner.
- Tactical publication reuses the current prediction, assignments, command,
  and active play without invoking command audio or external relay.
- The strategic heartbeat is recovery, not the primary truth source.
- No secure attributes or frame hierarchy may be changed in combat.

# Acceptance criteria

- [x] Event classification is deterministic and covered by offline tests.
- [x] A combat-event storm with unchanged tactical truth produces no strategic
      executions.
- [x] Tactical updates publish current enemy/combat truth with the previous
      strategic decision intact.
- [x] Authoritative widget and battleground events still schedule strategy.
- [x] Queue reason attribution is visible in `/kwr perf`.
- [x] Tactical P95 can be evaluated independently against the 2 ms routine
      target; strategic duration remains visible rather than diluted.
- [x] Validation, smoke, soak, knowledge audit, and package build pass.

# Verification

1. Run `tools/validate.ps1` and `tools/knowledge-audit.ps1`.
2. Run the Lua smoke and soak suites.
3. Field-test a complete battleground and capture `/kwr perf`, `/kwr verify`,
   AAR, and command-stability output.

# Rollback

Reinstall the previous verified Commander and Sentinel archives. No persisted schema or
doctrine data changes are introduced.
