---
id: KWR-266
title: Integrate the Strategist Nexus
owner: Codex
priority: high
risk: high
status: completed
authority_references: [AGENTS.md, docs/ADR_2026-08-16_STRATEGIST_NEXUS.md, docs/KNOWLEDGE_MAINTENANCE.md]
dependencies: [KWR-264]
affected_modules:
  - knowledge/season2-rbg-simulation-corpus.json
  - Data/StrategistNexusCorpus.lua
  - Data/StrategistNexusKnowledge.lua
  - Data/StrategistNexusPolicy.lua
  - Runtime/StrategistNexus.lua
  - Runtime/Strategist.lua
  - Runtime/Verification.lua
  - tools/build-strategist-nexus-corpus.ps1
  - tools/knowledge-audit.ps1
  - tests/smoke.lua
---

# Objective

Deploy a production Strategist Nexus that combines reviewed doctrine,
capability math, audited simulation coverage, and gated reviewed AAR learning.

# User outcome

The Commander selects clearer map and matchup plans, anticipates likely enemy
responses, exposes a safe fallback, and remains adaptable as reviewed corpus
evidence changes between patches.

# Current behavior

`Runtime/Strategist.lua` directly joins plans, heuristics, doctrine, scenario
calibration, expert labels, and enemy-response evaluation. The audited
5,000-case corpus covers the decision space but is not empirical match proof.
Its old zero-row promotion lifecycle duplicates the real reviewed AAR learning
path and does not add useful production evidence.

# Required behavior

- Compile all 5,000 simulation cases into a deterministic, compact Lua index.
- Retrieve corpus coverage by map, phase, score state, counter state, and
  composition-watch family without scanning the raw corpus at runtime.
- Evaluate every legal strategic candidate through one Nexus interface.
- Use reviewed plans, capabilities, composition theory, score state, and
  reversibility as bounded candidate adjustments.
- Use simulation coverage only as a missing-branch guard; never infer a win
  rate or reward a candidate from synthetic case counts.
- Return a Decision Envelope with the primary action, fallback, enemy response,
  abort/success conditions, evidence state, and confidence.
- Preserve objective-rule, truth, confidence, and combat-safety gates.
- Keep simulation, reviewed doctrine, and reviewed live evidence explicitly
  separate in the decision provenance.
- Refine plan selection only from truth-qualified, player-reviewed AAR results
  through the existing minimum-sample and patch-reset gates.
- Remove the unused simulation-to-live promotion lifecycle.
- Keep the generated index rebuildable and patch-versioned.

# Non-goals

- No protected actions, targeting, casting, movement, automatic chat, or
  unreviewed doctrine promotion.
- No claim that simulated cases are live match proof or empirical outcomes.
- No network, AI, or external-service dependency in the addon runtime.
- No release, publication, deployment, or live AddOns mutation.

# Technical constraints

- Runtime retrieval must be bounded and allocation-conscious.
- Missing or stale evidence must reduce authority, never create facts.
- Existing Strategist result fields remain backward compatible.
- Raw JSON remains development evidence and is excluded from the player addon.

# Acceptance criteria

- [x] Generated corpus index accounts for exactly 5,000 unique input cases.
- [x] All ten supported maps and five phases have runtime coverage.
- [x] Nexus evaluates and deterministically reorders legal candidates.
- [x] Low truth and illegal-action gates remain authoritative.
- [x] Decision Envelope exposes fallback, counter, success, abort, and separate
      production, simulation-only, reviewed-doctrine, and live provenance.
- [x] Smoke, soak, knowledge, validation, and packaging gates pass.

# Verification

1. Rebuild the generated runtime corpus and prove deterministic output.
2. Run knowledge and corpus audits.
3. Run Lua smoke, Sentinel transport, and soak tests.
4. Run validation and extracted-package audit.
5. Field-test the Decision Envelope across each map family before release.

# Rollback

Remove the Nexus call, policy, knowledge contract, and generated runtime index;
the existing Strategist, reviewed AAR learning, doctrine, scenario,
counterplay, and assignment systems remain intact.
