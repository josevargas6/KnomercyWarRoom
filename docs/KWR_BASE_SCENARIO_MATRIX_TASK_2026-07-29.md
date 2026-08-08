---
id: KWR-044
title: Define five common base scenarios per supported RBG map
owner: Codex
priority: high
risk: low
dependencies: [KWR-042, KWR-043]
affected_modules: [knowledge/rbg-scenario-matrix.json, knowledge/schemas/rbg-scenario-matrix-schema.json, tools/knowledge-audit.ps1, README.md, docs/WORKFLOW_NOW.md]
---

# Objective

Define the minimum common scenario set that every supported RBG map should have
before deeper expert-tier collection and tuning.

# User outcome

The project stops improvising map scenario coverage and instead builds toward a
fixed five-scenario base per map.

# Current behavior

The repository now has one starter replay slice per map, but no explicit
machine-readable statement of the five most common scenario families that should
exist for each battleground.

# Required behavior

- Add one schema-backed all-RBG scenario matrix.
- Set the default collection target to five common scenarios per map.
- Require the matrix through knowledge audit.

# Non-goals

- Immediate creation of all fifty scenario fixtures.
- Expansion to ten scenarios per map in this task.

# Technical constraints

- Align with current map keys and supported profile names.
- Keep the scenario families commander-facing and practical.

# Acceptance criteria

- [x] The repository contains one machine-readable five-scenario matrix per map.
- [x] Each supported RBG map has exactly five starter common scenarios listed.
- [x] Knowledge audit fails if the matrix is removed or malformed.

# Verification

1. Run `./tools/knowledge-audit.ps1`.
2. Confirm `targetBaseScenariosPerMap` is 5.
3. Confirm all ten supported maps are represented.

# Rollback

Remove the new matrix/schema and revert audit and documentation references.
