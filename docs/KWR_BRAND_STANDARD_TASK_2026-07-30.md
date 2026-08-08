---
id: KWR-237
title: Establish a repository-owned KWR brand and UI design standard
owner: unassigned
priority: medium
risk: low
dependencies: []
affected_modules:
  - UI/Theme.lua
  - docs/KWR_BRAND_STANDARD_2026-07-30.md
  - docs/KWR_UI_STANDARD_2026-07-30.md
---

# Objective

Create one authoritative KWR brand standard and one developer-facing UI standard,
then lock the first shared design-token layer into `UI/Theme.lua`.

# User outcome

Maintainers can add or update KWR windows, cards, badges, and alerts without each
surface inventing its own visual language.

# Current behavior

KWR already has a recognizable command-center direction and an existing
`UI/Theme.lua`, but the design doctrine is split across visual-direction notes and
legacy color names. The repo does not yet expose one locked brand standard,
component rules, and canonical token contract under a single current document set.

# Required behavior

- Publish a concise KWR brand standard that defines identity, color semantics,
  typography, component families, and asset rules.
- Publish a developer-facing UI standard that defines shell, card, button, badge,
  tooltip, and rollout rules for addon surfaces.
- Add canonical design tokens to `UI/Theme.lua` while preserving backward
  compatibility for existing theme consumers.

# Non-goals

- Rebuild existing windows to the new visual standard in this task.
- Add external font dependencies.
- Add runtime-only animations, polling, or texture churn.

# Technical constraints

- Preserve current `KWR.Theme` call sites.
- Keep WoW-safe font usage and existing backdrop behavior.
- Do not introduce combat-lockdown, secure-frame, taint, or per-frame risks.
- Keep semantic state color distinct from decorative accent usage.

# Acceptance criteria

- [ ] The repo contains a current brand-standard document for KWR.
- [ ] The repo contains a current developer-facing UI standard for KWR surfaces.
- [ ] `UI/Theme.lua` exposes canonical token names without breaking legacy theme lookups.
- [ ] Deterministic tests cover the token contract at a smoke-test level.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.
3. Confirm the new token names resolve through `KWR.Theme` without changing legacy consumers.

# Rollback

Revert the new docs and the token alias layer in `UI/Theme.lua`. Existing surfaces
continue to function because no saved-variable schema or runtime ownership changes
are introduced by this task.
