---
id: KWR-335
title: Accept any random rated battleground for bounded field collection
owner: Codex
priority: high
risk: low
status: completed
dependencies: [KWR-334]
affected_modules: [field-blocker-report, knowledge-audit, field-test-documentation]
authority_references: [AGENTS.md, RELEASE_POLICY.md, RELEASE_READINESS.md]
---

# Objective

Remove map selection and map-family prerequisites from the owner's two-game
diagnostic field collection.

# User outcome

Any two offered rated battlegrounds count, including the same map twice.

# Current behavior

The checklist allows any map, but the report recommends five map-specific sessions.

# Required behavior

Recommend at most two ANY_RATED_BG sessions. Separate collection completion from
observed failures and unobserved mechanics. Missing mechanics never fail a session
or automatically pass a release gate. Engineering owns remaining coverage gaps.

# Non-goals

No runtime/package changes, fabricated evidence, waived CPU/memory/error criteria,
or blanket live certification for unplayed map families.

# Technical constraints

Preserve installed alpha26 bytes and current candidate evidence bindings.

# Acceptance criteria

- [x] Generated report and checklist accept any rated map and repeats.
- [x] Report policy rejects missing-mechanic failures or automatic passes.
- [x] Validation and knowledge audit pass.

# Verification

Regenerate the field report and audit its map-independent policy, maximum session
count and absent-mechanic semantics. No WoW test needed for tooling/docs changes.

September 19: regenerated report recommends two ANY_RATED_BG sessions; full
knowledge audit PASS and source validation PASS, zero errors/warnings. Audit
assertions guard the two-game cap, repeated-map eligibility, lack of family
requirements and no automatic failure/pass for absent mechanics.
Incoming alpha26 NODE/CART telemetry is accepted independent of map family;
see `docs/evidence/ALPHA26_RANDOM_RATED_2026-09-19.md`. Its measured failures
require engineering work, not more random queues. Installed bytes are unchanged.

# Rollback

Revert this task's tooling and documentation commit; live addon is unchanged.
