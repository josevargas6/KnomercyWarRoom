---
id: KWR-285
title: Bound memory polling and distinguish measured from cached memory
owner: Codex
priority: high
risk: medium
status: completed
dependencies: [KWR-281]
affected_modules: [MemoryBudget, MatchRuntime, MainWindowReports, tests]
authority_references: [AGENTS.md, PRODUCT_ROADMAP.md, RELEASE_READINESS.md]
---

# Objective

Recover safe memory-poll throttling from the installed runtime under OVR-01/09/10
and make performance reports accurately identify cached measurements.

# User outcome

Recurring refreshes do not repeatedly run a global addon-memory scan. Performance
reports show when memory was actually measured, including when combat or API
failure prevents a fresh scan.

# Current behavior

MemoryBudget skips UpdateAddOnMemoryUsage during combat but reads the cached
GetAddOnMemoryUsage value and re-stamps it as newly measured. MatchRuntime stamps
its own current time regardless of measurement freshness. The report calls that
value a fresh sample. Two recurring callers can independently request scans.
Installed code adds a 30-second Update throttle, but not at the shared Sample
boundary; other callers bypass it.

# Required behavior

- Centralize a minimum routine sampling interval in MemoryBudget:Sample, shared
  by Store callbacks and strategic telemetry. Permit an explicit report refresh
  outside combat; never force a restricted scan in combat.
- Separate attempt/read time from successful measurement time. Missing/throwing
  refresh or read APIs cannot advance the successful timestamp or masquerade as
  a fresh sample. Bound repeated failed routine attempts.
- Keep cached measured memory available with its age and reason for reuse.
- Preserve hard-cap degradation, retention bounds and existing processed-match
  deduplication storage. Do not adopt the installed skip-all-persistent-pruning
  behavior without proving every affected store's write-time bound.
- Carry the shared successful timestamp into strategic diagnostics and show
  measured/cached/unavailable status in reports.

# Non-goals

Real-client CPU/FPS certification, full runtime-stage instrumentation, corpus
projections and broader cache recovery remain separate OVR work. Reduced scan
count is not a measured frame-rate improvement.

# Technical constraints

Preserve the existing Sample return value and callers; use optional arguments
and summary metadata for new behavior. Keep protected APIs within MemoryBudget.
Preserve KWR-280 stage samples and historical strategic-memory reporting.

# Acceptance criteria

- [x] Routine callers collectively scan at most once per configured interval.
- [x] Explicit out-of-combat refresh obtains a new timestamp when APIs succeed.
- [x] Combat, missing APIs, exceptions and invalid readings preserve prior sample
  age, report the limitation and recover on a later successful refresh.
- [x] Initial unknown memory is unavailable, not zero or fresh.
- [x] Retention caps and hard-pressure degradation still operate correctly.
- [x] Source and extracted-package regressions validate sampling and report text.

# Verification

Use controlled clocks and API counters to verify scheduling and provenance, plus
existing smoke/soak retention checks. Record source/package hashes. Real WoW
memory growth and CPU/FPS gates remain unverified until measured on the candidate.

September 5 source checkpoint: Smoke, 500-refresh Soak and validation passed. The memory fixture
uses an isolated copy of the actual MemoryBudget module and the real performance
report builder. Six hundred routine calls through both entry points share one
scan across the initial 30-second interval; an explicit refresh bypasses that
interval. Combat and failing/invalid API cases preserve the prior sample age,
and a later 40 MB sample still activates hard-pressure degradation. These are
mock scheduling/provenance results, not client performance measurements.

Package closure: `artifacts/memory-sampling-20260905-package/` passed extracted
player/developer smoke and 500-refresh soak, Sentinel transport, DevTools lifecycle
and four ZIP checksums. Source hashes are in
`artifacts/memory-sampling-20260905/source-checks.json`; the package manifest and
provenance bind the tested payload. This dirty interim build skipped clean
reproducibility. OVR-09/10 real-client performance and broader cache/pruning work
remain open. No installed addon was changed.

The public API names remain consistent with Blizzard's
[performance bar source](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_PerformanceBar/PerformanceBar.lua).

# Rollback

Revert sampling/report changes together while retaining prior fixes and all
SavedVariables. Do not remove processed-match ledgers or alter the installation.
