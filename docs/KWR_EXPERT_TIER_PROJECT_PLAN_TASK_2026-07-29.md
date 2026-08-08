---
id: KWR-036
title: Establish the expert-tier battlefield delivery plan
owner: codex
priority: critical
risk: low
dependencies:
  - KWR-032
  - KWR-033
  - KWR-034
  - KWR-035
affected_modules:
  - EXPERT_TIER_BATTLEFIELD_MASTER_PLAN.md
  - RELEASE_VISION.md
  - PROJECT_HANDOFF.md
  - README.md
  - docs/WORKFLOW_NOW.md
---

# Historical: expert-tier delivery plan task

# Objective

Create one repository-native project plan that carries Knomercy War Room from
the recovered `6.1.0-alpha.28` field candidate to an expert-tier, legally
observable, human-commanded, offline-benchmarked, and live-validated Rated
Battleground release.

# User outcome

The project owner can resume work without reconstructing product intent from
multiple historical plans. Engineering, knowledge, UX, QA, field testing, and
release work share one ordered path, explicit evidence gates, and an honest
standard for any future expert- or 2400-tier claim.

# Current behavior

KWR already has a strong alpha architecture, a Fight-Now combat path, reviewed
doctrine, deterministic smoke/soak coverage, field-evidence templates, and
several detailed roadmaps. Those sources do not yet provide one current plan
that:

- distinguishes declared intelligence from live-connected intelligence;
- defines the offline competitive decision lab;
- separates decision quality from execution quality;
- specifies expert-review and replay benchmarks;
- shows how the final system is used during real battlefield play;
- defines when a 2400-level claim is and is not supportable.

# Required behavior

- Preserve `RELEASE_VISION.md` as the suite and release-scope authority.
- Preserve the existing single-owner runtime and human-in-the-loop safety
  contract.
- Record the current alpha baseline and unresolved field blockers.
- Define the final expert-tier product and battlefield workflow.
- Map every workstream to the existing architecture.
- Define legal signal coverage, offline corpus, replay, evaluation, planner,
  learning, UX, live testing, promotion, and maintenance requirements.
- Provide ordered work packages with entry and exit gates.
- Define measurable offline, usability, safety, performance, and live evidence
  standards.
- Make the new plan discoverable from the release vision and project handoff.

# Non-goals

- Do not claim that the current alpha is already 2400-proven.
- Do not promise guaranteed wins or universal counterplay.
- Do not implement planner, sensor, UI, or persistence changes in this task.
- Do not replace the current release candidate or rewrite historical evidence.
- Do not create a second runtime, state owner, strategy engine, or combat HUD.

# Technical constraints

- The addon remains Lua 5.1-compatible and offline during play.
- Blizzard public-data, secret-value, protected-action, combat-lockdown, taint,
  and secure-frame boundaries remain first-class gates.
- Runtime facts, derived assessments, reviewed doctrine, meta data, and learned
  preferences must retain separate authority and freshness.
- The plan must extend the existing `Core`, `Runtime`, `State`, `Adapters`,
  `Intelligence`, `Data`, `UI`, `tests`, `tools`, `knowledge`, and `docs`
  boundaries.
- Current P0/P1 field defects remain ahead of new expert-tier behavior.

# Acceptance criteria

- [x] One expert-tier master plan exists in the repository root.
- [x] The plan includes product truth, final battlefield UX, architecture,
      work packages, phases, metrics, offline evaluation, live certification,
      release gates, risks, rollback, and immediate next actions.
- [x] The plan explicitly identifies live-connected, partial, and dormant
      intelligence paths.
- [x] The plan defines a reviewed decision corpus and timeline replay system.
- [x] The plan defines outcome attribution that separates decision,
      execution, sensor, and opponent effects.
- [x] The plan defines a bounded robust planner without claiming hidden
      information or automatic play.
- [x] The plan defines evidence required before using expert-tier and
      2400-competitive language.
- [x] `RELEASE_VISION.md` and `PROJECT_HANDOFF.md` point to the plan without
      losing their existing authority.

# Verification

1. Review the plan against `AGENTS.md`, `RELEASE_VISION.md`,
   `ARCHITECTURE.md`, `DESIGN_CONTRACT.md`, `PRODUCT_ROADMAP.md`,
   `PILLAR_EXECUTION_SHEET.md`, `RELEASE_READINESS.md`, and active task briefs.
2. Verify every proposed runtime responsibility has one existing owner or an
   explicitly named extension point.
3. Verify no requirement depends on hidden combat information, network access
   during play, automatic targeting, automatic communication, or protected
   action.
4. Run `./tools/validate.ps1` to ensure documentation changes do not disturb
   the current addon gate.

# Rollback

Remove the new master plan and its two authority references. No runtime,
SavedVariables, data pack, release package, or user setting changes in this
task.
