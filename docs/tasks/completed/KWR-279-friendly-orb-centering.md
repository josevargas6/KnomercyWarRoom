---
id: KWR-279
title: Center friendly role markers on visible nameplates
owner: Codex
priority: high
risk: low
status: completed
dependencies: [KWR-278]
affected_modules: [Features, tests]
authority_references: [AGENTS.md, QA_CHECKLIST.md]
---

# Objective

Anchor friendly healer and role markers to the visible nameplate identity center
instead of an internally offset health-bar region.

# Acceptance criteria

- [x] Friendly role-marker center follows the visible name/text anchor.
- [x] Existing role, carrier, reticle, and tactical-badge behavior remains intact.
- [x] Deterministic Lua tests and validation pass.
