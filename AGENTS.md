# KnoMercy War Room Engineering Standard

These instructions apply to every task, chat, review, and implementation performed in this repository. They are the default unless a task states a stricter requirement.

This file is the sole authority for engineering rules. GitHub committed content
is the development and release source; World of Warcraft AddOns folders are
deployment targets only.

## Mission

KnoMercy War Room is a purpose-built Rated Battleground war-room addon, not a bundle of generic PvP widgets. Every change must strengthen strategy, map intelligence, assignments, enemy analysis, cooldown awareness, or commander clarity for real in-game use.

## Technology Standard

- Use Lua for application logic, state, events, UI behavior, and integrations.
- Use XML only when Blizzard templates, secure frames, or declarative UI definitions provide a clear advantage.
- Keep the TOC explicit and its loading order deterministic.
- Use Markdown for requirements, task contracts, architecture decisions, testing instructions, and release notes.
- Use YAML only for CI and machine-readable metadata.
- Use JSON only for fixtures or generated data that is not better represented as Lua tables.
- Use PowerShell or shell scripts for validation, testing, packaging, and release automation.
- Do not mix programming styles arbitrarily. Follow the Lua standard below throughout the addon.

## Existing Architecture Is Authoritative

This is an established addon, not an empty repository. Preserve and extend its current root-level organization instead of moving it into a generic `addons/ProductName/` wrapper:

- `Core/` owns bootstrap, utilities, and shared infrastructure.
- `Runtime/` owns the live pipeline: sensors, `MatchRuntime`, strategist, assignments, combat intelligence, and verification.
- `State/` owns persisted and runtime state boundaries.
- `Adapters/` and compatibility modules isolate Blizzard APIs and other unstable integrations.
- `UI/` owns commander surfaces such as `MainWindow`, `HUD`, `ReporterMap`, and `CombatRoster`.
- `Data/`, `Intelligence/`, and `Rulesets/` hold reviewed facts, doctrine, and decision inputs.
- `Features/` holds bounded optional systems such as `CursorRing`.
- `tests/` contains deterministic automated coverage.
- `tools/` contains validation, audit, build, packaging, and release automation.
- `docs/` contains durable specifications, handoffs, verification records, and architecture decisions.

Keep the same conceptual boundaries for small features, but combine trivial modules when splitting them would create file-count theater. Extend existing systems first. Do not create duplicate services or parallel state models.

## Operating Approach

Before editing, inspect the relevant code and determine:

1. What already handles the behavior.
2. Which module and state table own it.
3. Which Blizzard APIs, events, saved variables, UI surfaces, and tests it affects.
4. The combat-lockdown, secure-execution, taint, performance, compatibility, and migration risks.
5. The smallest path that meets the user outcome without a rewrite.

Do not silently remove features, break APIs, rename major systems, delete user work, invent unsupported data, or add fake “smart” behavior. Prefer minimal, high-impact, reviewable changes that preserve project identity.

## Lua Coding Standard

- Use four-space indentation and one statement per line.
- Use the addon namespace; never introduce accidental globals.
- Use PascalCase for modules, types, and Lua filenames.
- Use camelCase for local variables, parameters, and helper functions.
- Use UPPER_SNAKE_CASE for constants.
- Use `:` only for functions that operate on module or object state; use `.` for stateless helpers.
- Prefer early returns and explicit names over deep nesting or compressed expressions.
- Keep modules narrow and local-first. Separate data, logic, API access, and display where practical.
- Keep saved-variable access behind the existing Store, repository, settings, or state boundary.
- Give persisted data an explicit schema version and backward-compatible migrations.
- Put volatile or difficult-to-test Blizzard API calls behind `Adapters/` or the existing compatibility boundary.
- Centralize event registration through existing infrastructure instead of scattering frame scripts.
- Reuse existing UI components and theme primitives.
- Do not perform expensive work on every frame unless unavoidable; keep refresh work bounded.
- Treat combat lockdown, protected frames, secure execution, taint, nil API results, and addon-message limits as first-class constraints.
- Never silently swallow errors unless failure is intentionally non-critical and recorded through diagnostics.
- Keep user-facing text localizable.
- Comment the reason for unusual logic, not what the code already states.
- Avoid new dependencies unless their value, safety, licensing, and packaging impact are justified.

The preferred dependency direction is:

```text
Feature code
    -> internal service or interface
    -> compatibility adapter
    -> Blizzard Retail API
```

When Midnight or a later Retail patch changes an API, event payload, namespace, or restriction, update the adapter rather than multiple features.

## Product and Safety Standards

Prioritize correctness, in-game stability, maintainability, performance, security, UI clarity, future expansion, and then creative advantage. Strategic features must produce actionable assignments, rotations, counters, or win-condition calls rather than vague advice.

Use feature flags for unfinished or risky behavior. Use structured diagnostic logging that can be disabled in release builds. Never expose secrets, trust unvalidated addon messages, mutate domain state from rendering code, or package development-only files.

## Task Contract

Material implementation work must have a Markdown task brief in the task, issue, PR, or repository. Use this structure; omit a section only when it is genuinely inapplicable:

```markdown
---
id: KWR-000
title: Concise outcome
owner: unassigned
priority: medium
risk: low
dependencies: []
affected_modules: []
---

# Objective

# User outcome

# Current behavior

# Required behavior

# Non-goals

# Technical constraints

# Acceptance criteria

- [ ] Observable requirement

# Verification

1. Run automated validation.
2. Exercise relevant clean-install, upgrade, combat, and group-state cases.

# Rollback
```

The contract is the shared source of truth for product, engineering, QA, and review. Clarify contradictions before implementation. Do not expand scope beyond it without recording the decision.

## Build, Test, and Development Commands

Run the checks relevant to the change, and run the complete gate before a release:

```powershell
./tools/validate.ps1
./tools/knowledge-audit.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1
./tools/build.ps1
```

`validate.ps1` checks architecture, TOC wiring, safety rules, and release files. `knowledge-audit.ps1` verifies reviewed data. `tests/smoke.lua` covers deterministic pipeline behavior. `tests/soak.lua` proves refreshes stay bounded. `build.ps1` packages release artifacts.

Add or update deterministic assertions for every behavior change. For live PvP behavior, also capture `/kwr verify`, `/kwr bug`, AAR, screenshot, or field-test evidence as appropriate. Test clean saved variables and migrations whenever persistence changes. Review behavior in and out of combat and across relevant solo, party, raid, battleground, and rated states.

## Definition of Done

A task is complete only when:

- Its acceptance criteria are satisfied.
- Lua validation and relevant automated tests pass.
- No unintended globals or duplicate systems were introduced.
- Combat, secure-frame, taint, performance, message-limit, and nil-result risks were reviewed where relevant.
- Saved-variable compatibility and schema migration were considered.
- User-facing text is localizable.
- Changed behavior was tested in WoW or an appropriate deterministic mock.
- Documentation, task status, architecture decisions, and changelog were updated where applicable.
- The production package has the correct addon root and excludes development files.
- Another engineer can understand the implementation, validation evidence, risks, and rollback without verbal explanation.

## Architecture Decisions and Releases

Record an Architecture Decision Record for choices that affect multiple modules, persisted schemas, public contracts, compatibility strategy, or long-term maintenance. Pin validation and packaging tools where practical, and produce release ZIPs through automation.

This checkout has no `.git` metadata, so follow the documented repository flow: keep commits bounded to one truth, UI, safety, or performance concern, and open PRs against `develop`. Use the PR template fields `What changed`, `Why`, `Safety`, `Validation`, and `Rollback`; attach screenshots or field-test evidence for UI and battleground behavior changes.
