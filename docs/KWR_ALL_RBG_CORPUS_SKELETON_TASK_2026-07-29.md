---
id: KWR-043
title: Build all-RBG starter corpus skeleton
owner: Codex
priority: high
risk: low
dependencies: [KWR-041, KWR-042]
affected_modules: [knowledge/corpus-manifest.json, tests/replays, tests/golden, tests/replay-results, tests/outcomes, docs/WORKFLOW_NOW.md, README.md]
---

# Objective

Establish one starter replay, golden label, replay result, and outcome review
for every supported rated battleground map.

# User outcome

Every supported RBG now has the same offline starter path so future expert-tier
work extends a real corpus instead of creating new map scaffolding.

# Current behavior

The Decision Lab previously had only Twin Peaks and Arathi Basin starter cases.

# Required behavior

- Add starter corpus files for every remaining supported RBG map.
- Update the corpus manifest to reflect all-map starter coverage.
- Keep the files schema-valid and benchmark-valid.

# Non-goals

- Deep expert corpus density per map.
- Full adversarial coverage for every map.
- Replay runner execution on this machine.

# Technical constraints

- Use current supported map keys and profile names.
- Keep fixtures synthetic and safe.
- Preserve deterministic audit and benchmark compatibility.

# Acceptance criteria

- [x] Each supported RBG has one replay fixture.
- [x] Each supported RBG has one golden label.
- [x] Each supported RBG has one replay result.
- [x] Each supported RBG has one outcome review.
- [x] Corpus manifest counts match the new all-map baseline.

# Verification

1. Run `./tools/corpus-audit.ps1`.
2. Run `./tools/decision-benchmark.ps1`.
3. Run `./tools/outcome-report.ps1`.

# Rollback

Remove the added starter fixtures and restore the earlier two-map manifest.
