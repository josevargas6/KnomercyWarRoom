---
id: KWR-035
title: Managed Commander and Sentinel user guide wiki
owner: unassigned
priority: medium
risk: low
status: planned
authority_references: [DESIGN_CONTRACT.md, RELEASE_POLICY.md]
dependencies: []
affected_modules:
  - README.md
  - KWRSentinel/README.md
  - docs/KWR_USER_GUIDE_WIKI.md
---

# Objective

Create one repository-owned, wiki-ready guide for Commander and Sentinel users.

# User outcome

A new player can install the suite, choose a role, train through a first match,
understand every public command, and know what to do when evidence is stale.

# Current behavior

Commander and Sentinel guidance exists in separate README and contract files.

# Required behavior

Publish a consolidated documentation page without creating a second runtime
source of truth or claiming unsupported automation.

# Non-goals

- No in-game UI or Lua behavior changes.
- No external wiki account, project, or page publication.

# Technical constraints

Keep the guide Markdown, link current repository sources, preserve the safety
boundaries, and explain that Commander remains the final authority.

# Acceptance criteria

- [x] Commander and Sentinel roles are explained.
- [x] Install, training, command, troubleshooting, and safety guidance exist.
- [x] Managed-page ownership and validation expectations are documented.
- [x] No runtime files or APIs are changed.

# Verification

1. Review links and command names against the current README and Lua slash handlers.
2. Run repository validation if the documentation-only change is included in a release gate.

# Rollback

Remove the new guide and task brief; runtime behavior is unaffected.
