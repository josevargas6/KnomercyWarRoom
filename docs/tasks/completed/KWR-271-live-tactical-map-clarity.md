---
id: KWR-271
title: Reduce live Tactical Map clutter
owner: Codex
priority: high
risk: medium
status: completed
dependencies: [KWR-270]
affected_modules: [UI, tests, docs]
authority_references: [AGENTS.md, DESIGN_CONTRACT.md, RELEASE_READINESS.md]
---

# Objective

Make the live Tactical Map preserve the visual hierarchy of Preview while
remaining strictly bound to observed battlefield information.

# User outcome

The commander can distinguish the active objective, critical actors, and recent
movement without dense full-size player markers obscuring the map.

# Required behavior

- Render non-critical players as compact team-colored dots.
- Keep critical targets and objectives visually prominent.
- Draw only short, observed movement trails.
- Bound trail density evenly per team so friendly volume cannot hide enemies.
- Leave tactical decisions, capability weights, and doctrine unchanged.

# Acceptance criteria

- [x] Live markers use a compact non-critical presentation.
- [x] Priority objectives and actors remain emphasized.
- [x] Trails require observed positions and remain bounded per team.
- [x] Validation, deterministic smoke, soak, package reproducibility, and
  installed-manifest audits pass.

# Verification

1. `tools/validate.ps1`: PASS.
2. Smoke suite: 276 checks PASS.
3. Bounded soak: 0.242 ms average, 0.800 ms P95, 3.200 ms maximum.
4. Local Alpha 5 Commander/Sentinel manifest deployment: zero drift.

# Rollback

Restore the KWR-270 telemetry-qualification presentation and rebuild the exact
Alpha 5 package if live map density regresses.
