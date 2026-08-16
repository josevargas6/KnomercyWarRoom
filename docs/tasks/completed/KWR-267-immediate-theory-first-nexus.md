---
id: KWR-267
title: Activate theory-first Nexus decisions immediately
owner: Codex
priority: high
risk: high
status: completed
authority_references: [AGENTS.md, docs/ADR_2026-08-16_STRATEGIST_NEXUS.md]
dependencies: [KWR-266]
affected_modules:
  - Data/StrategistNexusKnowledge.lua
  - Data/StrategistNexusPolicy.lua
  - Runtime/Strategist.lua
  - Runtime/StrategistNexus.lua
  - Runtime/EnemyResponsePlanner.lua
  - Runtime/Verification.lua
  - tests/smoke.lua
---

# Objective

Activate KWR's complete reviewed theory model and 5,000-case branch index for
every supported legal battleground decision immediately, without waiting for
live evidence to promote the theory.

# User outcome

The Commander always receives the best map-specific theoretical primary,
fallback, enemy counter, success condition, and abort condition available.
Weak live truth lowers confidence and blocks unsupported hard commitment, but
does not erase the theoretical solution into a generic VERIFY call.

# Current behavior

The Nexus ranks candidates immediately, but later low-truth gates replace its
selected recommendation with generic HOLD or VERIFY instructions. The default
enemy response can also collapse into `STANDARD_REINFORCE`.

# Required behavior

- Treat reviewed theory as active from the first supported decision.
- Use the full compact simulation index as a theory-branch activation and
  coverage contract, never as empirical outcomes or verified match evidence.
- Preserve the selected legal theoretical recommendation under low truth.
- Express weak truth as an execution/commit gate, confidence reduction,
  required evidence, and abort condition instead of replacing the plan.
- Provide a candidate-specific theoretical enemy response for every legal
  HOLD, ROTATE, TRADE, TEAMFIGHT, or SPLIT branch.
- Let reviewed current-patch AAR results refine or disprove active theory;
  live evidence is not required to activate it.
- Preserve objective legality, protected-action, secret-value, and combat
  safety constraints.

# Non-goals

- Do not label simulation or theory as verified match evidence.
- Do not automate movement, targeting, casting, communication, or commitment.
- Do not publish a release or change remote services.

# Technical constraints

- Runtime retrieval and ranking remain bounded.
- Illegal candidates never become viable.
- Unknown facts remain visibly unknown.
- Existing result fields remain backward compatible.

# Acceptance criteria

- [x] Nexus contract reports immediate theory-first activation.
- [x] Low-truth and stale-composition states retain a legal theoretical primary.
- [x] Commit authorization remains false when required live truth is absent.
- [x] Every candidate has a non-generic enemy-response theory.
- [x] Simulation provenance remains explicitly non-empirical.
- [x] Validation, knowledge, Lua, performance, and package gates pass.

# Verification

1. Add deterministic low-truth and response-completeness assertions.
2. Run source and knowledge audits.
3. Run the full Lua, transport, replay, and soak suites.
4. Build reproducibly and audit extracted packages.
5. Install locally only after a recoverable backup and WoW-process check.

# Rollback

Revert KWR-267 and restore the prior low-truth replacement behavior. The
KWR-266 production Nexus and reviewed AAR learning remain intact.
