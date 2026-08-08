---
id: KWR-042
title: Establish authoritative all-RBG foundation
owner: Codex
priority: high
risk: low
dependencies: [KWR-038, KWR-040, KWR-041]
affected_modules: [Data/Maps.lua, Data/RBGMapProfiles.lua, Data/KnowledgeManifest.lua, tools/knowledge-audit.ps1, tests/smoke.lua, README.md]
---

# Objective

Create one authoritative all-RBG foundation that future doctrine, corpus, replay,
and benchmark work can extend without inventing new per-map structure ad hoc.

# User outcome

The project has a fixed base system for every supported RBG map so new work is
improvement of an existing model, not new structure each time.

# Current behavior

The addon already contains supported-map logic, doctrine, and plans, but the
offline expert-tier build path does not yet have one explicit all-map
foundation contract joining live map support to corpus/benchmark expansion.

# Required behavior

- Add one authoritative all-RBG profile module in addon data.
- Add one machine-readable offline foundation artifact in `knowledge/`.
- Require both through validation.
- Document the foundation as the starting point for corpus expansion.

# Non-goals

- Full expert doctrine completion for every map.
- Full replay corpus for every map.
- Enemy search/planning expansion beyond the foundation layer.

# Technical constraints

- Preserve current map keys and supported battleground scope.
- Do not create a parallel map identity system.
- Keep the foundation bounded to safe, reviewed fields.

# Acceptance criteria

- [x] Every supported RBG map has a starter profile in one authoritative module.
- [x] The offline knowledge layer has a machine-readable all-RBG foundation file.
- [x] Knowledge audit fails if the foundation artifacts drift or disappear.
- [x] Smoke bootstrap loads the new profile module.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `./tools/knowledge-audit.ps1`.
3. Confirm the new foundation exposes ten supported maps and shared layers.

# Rollback

Remove `Data/RBGMapProfiles.lua`, remove the TOC/smoke/audit wiring, and revert
the documentation references added in this task.
