---
id: KWR-268
title: Retail release-candidate truth, stability, safety, and clarity repair
owner: Codex
priority: critical
risk: high
status: in_progress
dependencies: [KWR-032, KWR-033, KWR-052]
affected_modules: [Core, Runtime, State, UI, Features, Data, tests, tools, release]
authority_references: [AGENTS.md, RELEASE_READINESS.md, QA_CHECKLIST.md, docs/ADR_2026-07-29_UNIFIED_ROSTER_PRESENTATION.md]
---

# Objective

Repair the field-confirmed 6.1.1-alpha.2 defects so the next candidate has one
canonical roster/enemy identity, evidence-correct roles and AAR, revisioned
command invalidation, bounded runtime work, combat-safe layout handling, a
working native map action, visible reticle guides, and direct formation data.

# User outcome

Players can use KWR in Retail battlegrounds without duplicate team names,
misleading enemy/AAR records, churned calls, blocked actions, unreadable guides,
or no-op map controls. The package is reproducible and ready for player use
only after its version-bound automated and live evidence gates pass.

# Current behavior

The field WSG evidence from 2026-08-18 shows duplicate team identities,
duplicate enemy threats, verified healer specs published as damage, 581 stale
invalidations in 600 evaluations, P95 35.446 ms, 52 MB peak memory, a protected
StopMovingOrSizing call, a print-only MAP / SHIFT-M action, thin 1px guides,
and incomplete/misleading review presentation.

# Required behavior

- Centralize canonical identity, alias migration, and evidence precedence.
- Publish only validated unique roster/enemy identities.
- Consume semantic objective revisions once per active play and distinguish
  execution updates from strategic replacements.
- Use bounded dirty refresh lanes and retained-data limits.
- Avoid all protected frame mutation during combat.
- Restore usable native-map, reticle, formation, and AAR surfaces.
- Ship only a clean, tested, version/hash-bound Commander/Sentinel pair.

# Non-goals

- Guess or fabricate Retail-hidden data.
- Attribute the Blizzard guild-invite slash-command error to KWR without a
  reproducible KWR call path.
- Change player keybindings, target, spells, macros, chat, or secure behavior.

# Technical constraints

- Canonical Git source is authoritative; installed AddOns folders are evidence
  and deployment targets only.
- Preserve saved variables with an idempotent schema migration.
- Maintain Lua 5.1 and Retail combat-lockdown/API safety.
- Preserve the positively received Team-bar visual design.

# Acceptance criteria

- [ ] One identity/evidence service is used by live roster, enemy intel, AAR,
  notes, opponent models, assignments, UI, and Sentinel payloads.
- [ ] No duplicate player may be published across randomized roster hydration
  fixtures or live field evidence.
- [ ] Verified healer specs resolve to HEALER and role conflicts retain source.
- [ ] Replayed stale events cannot repeatedly invalidate active plays.
- [ ] Command, performance, memory, taint, map, reticle, formation, and AAR
  regression tests pass.
- [ ] Commander/Sentinel package versions, manifests, hashes, and release
  evidence are exact and reproducible.

# Verification

1. Run the complete validation, security, knowledge, Lua, automation,
   certification, and package suites.
2. Run deterministic identity, role, event, command-budget, migration, and
   event-storm fixtures.
3. Capture clean-install and complete Retail evidence for the exact RC hashes.

# Rollback

Keep the immutable 6.1.0 stable artifacts and the previous alpha package.
If any offline or field gate fails, stop promotion, preserve the defect bundle,
and issue a new candidate rather than overwriting a published artifact.
