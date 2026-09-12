---
id: KWR-286
title: Preserve scenario runtime APIs across knowledge regeneration
owner: Codex
priority: high
risk: medium
status: completed
dependencies: [KWR-281]
affected_modules: [ScenarioCalibration, ScenarioAdversarialCalibration, ScenarioExpertCorpus, tools, tests]
authority_references: [AGENTS.md, PRODUCT_ROADMAP.md, RELEASE_READINESS.md]
---

# Objective

Close the generator/runtime mismatch found during OVR-01/11 reconciliation before
changing the production knowledge representation.

# User outcome

Updating reviewed knowledge preserves the commander's summary lookup APIs and
selects the same map/phase fallback regardless of Lua table traversal order.

# Current behavior

Three scenario builders omit GetSummary and GetSummaryByMapAndPhase even though
the committed modules and Strategist use them. Calibration and adversarial phase
indexes use last-row-wins pairs traversal. Existing knowledge audit regenerates
Nexus only, so these mismatches pass its gate.

# Required behavior

Keep each module's Lua implementation in a build template, generate its data from
the existing reviewed inputs, and verify the complete generated runtime against
the canonical module. Allow generators to write to an isolated output directory.
Use one index path for full and compact lookups. Calibration/adversarial fallbacks
choose the lexicographically smallest scenario ID; this is a deterministic tie
break, not a new tactical rank. Preserve the expert module's existing eligibility
and season-prep priority, with deterministic ID ties and activation invalidation.

# Non-goals

No corpus projection, evidence relabeling, tactical expansion, doctrine edits,
SavedVariables migration, installation or performance claim.

# Technical constraints

Preserve all current data, public methods, copy isolation and season activation.
Templates belong under tools; the addon loads only generated Data modules.
Regeneration checks must not overwrite canonical data or knowledge JSON.

# Acceptance criteria

- [x] All three builders retain existing runtime APIs and generated data.
- [x] Full and summary fallbacks agree under reversed table traversal.
- [x] Expert eligibility, activation changes and return-copy isolation hold.
- [x] Knowledge audit fails on stale generated runtime or missing templates.
- [x] Source and extracted-package smoke/knowledge checks pass with evidence.

# Verification

Regenerate into isolated directories and compare normalized runtime contents;
record hashes. Exercise actual module APIs with forward/reverse traversal,
season activation changes and mutation attempts. Run validation, smoke and
knowledge audit, then verify the extracted package. Field tactical quality
remains under the existing candidate-bound review gates.

Source checkpoint: `artifacts/scenario-generation-20260905-01/generation-audit.json`
records matching hashes for all three complete generated modules (200 calibration,
200 adversarial and 1,200 expert rows). Smoke and validation pass. The fixture
loads actual modules with opposite table traversal orders, checks every scenario
ID, all represented map/phases and false/true/false season activation transitions.
No corpus data or knowledge JSON was changed.

The complete knowledge audit passes with the new generator gate. Isolated copies
of the real generators and inputs rejected both a removed summary method and a
missing template with nonzero exits; canonical source was not modified. See
`artifacts/scenario-negative-20260906/negative-checks.json` and its failure logs.

Package closure: `artifacts/generation-availability-20260906-package/` passed
extracted player/developer smoke and 500-refresh soak, the full knowledge gate
including three-module regeneration, Sentinel transport, DevTools lifecycle and
four ZIP checksums. Its manifest and provenance bind the tested content. This
dirty interim build skipped clean reproducibility; OVR-11 runtime projection and
real memory/performance gates remain open. The later KWR-287 scoreboard-repair
follow-up is not in this package and does not affect this generator closure.

# Rollback

Revert templates, generator wiring and generated modules together. Retain all
original knowledge inputs and previous recovery fixes; do not touch installation.
