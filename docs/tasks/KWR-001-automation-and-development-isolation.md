---
id: KWR-001
title: Enforce automation and development-channel isolation
owner: unassigned
priority: high
risk: medium
status: planned
authority_references: [AGENTS.md, RELEASE_POLICY.md]
dependencies: []
affected_modules: [tools, docs, .github]
---

# Objective

Make GitHub-originated releases and isolated development deployment the
default operating model without rewriting the existing addon architecture.

# User outcome

Experimental work cannot overwrite the stable WoW installation by accident.

# Current behavior

The repository has validation and packaging scripts, but no single channel
contract or safe deployment command.

# Required behavior

Provide a channel-aware build/deploy tool, production-contamination checks,
documentation, and an owner-action checklist.

# Non-goals

External GitHub, Discord, or CurseForge configuration; addon-message protocol
approval; and a full Commander/Sentinel directory rewrite.

# Technical constraints

Preserve the current root-level layout, forbidden-API policy, SavedVariables,
and package audit behavior.

# Acceptance criteria

- [ ] Dirty builds resolve to `local` and cannot deploy to production.
- [ ] Development deployment targets are distinct from production targets.
- [ ] Production builds reject development/local suffixes and metadata.
- [ ] Owner-only external actions are documented without fabrication.

# Verification

1. Run `tools/validate.ps1 -Channel production`.
2. Run `tools/kwr.ps1 status` and `tools/kwr.ps1 deploy-development -WhatIf`.
3. Run the existing Lua, knowledge, and package checks.

# Rollback

Revert the new policy scripts and documentation; existing addon code and
release packaging remain unchanged.
