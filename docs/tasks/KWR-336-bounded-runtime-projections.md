---
id: KWR-336
title: Reduce runtime CPU and allocation pressure from alpha26 field failures
owner: Codex
priority: critical
risk: high
status: in_progress
dependencies: [KWR-334, KWR-335]
affected_modules: [MatchRuntime, runtime-projections]
authority_references: [AGENTS.md, RELEASE_POLICY.md, RELEASE_READINESS.md]
---

# Objective

Profile and correct repeated computation/allocation behind alpha26 CPU and sampled
memory failures across NODE and CART field captures.

# User outcome

Preserve commander decisions and current truth with less repeated work. Do not
ask for another randomly selected map to establish an already observed failure.

# Current behavior

Strategic P95 22.415/33.962 ms, tactical P95 6.087/7.095 ms, sampled peaks
35.83/38.12 MB. Cache and queue improvements did not meet total runtime budgets.

# Required behavior

Measure attributable work; remove redundant allocations/computations at existing
owners; preserve freshness, mutation isolation and secret-value safety. Add
regressions and compare representative host workload before/after, without
claiming mocked host timing as a Retail certification.

# Non-goals

No raised thresholds, forced combat GC, discarded strategic functionality or
unobserved live pass. Do not modify installed files while WoW is running.

# Technical constraints

Existing single runtime/Store/Commander ownership and compatible saved data.

# Acceptance criteria

- [ ] Profile establishes targeted costs and repeatable work counts.
- [ ] Fixes preserve decisions, freshness and published-state isolation.
- [ ] Regression, soak, validation and package checks pass.
- [ ] Candidate provenance and remaining Retail-only limits are recorded.

# Verification

Run attributable host profile, deterministic regressions, full Lua tests,
validation/knowledge audits and extracted-package checks.

# Rollback

Restore the verified alpha26 archives; preserve saved variables and evidence.
