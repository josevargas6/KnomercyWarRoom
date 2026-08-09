---
id: KWR-030
title: Align the KWR ecosystem to one release train
owner: codex
priority: high
risk: medium
dependencies: []
affected_modules:
  - docs/audits/historical-plans/RELEASE_VISION.md
  - docs/audits/historical-plans/ALPHA_S_TIER_MASTER_PLAN.md
  - docs/audits/historical-plans/PILLAR_EXECUTION_SHEET.md
  - docs/audits/historical-plans/S_TIER_EXECUTION_SCORECARD.md
  - docs/audits/historical-plans/WINNING_STATE_EXECUTION_MAP.md
  - docs/audits/historical-plans/WINNING_STATE_RELEASE_GATES.md
  - RELEASE_READINESS.md
  - PROJECT_HANDOFF.md
  - QA_CHECKLIST.md
  - docs/WORKFLOW_NOW.md
---

# Objective

Restore one authoritative product and release direction after the local
recovery revealed version, repository, and planning-document drift.

# User outcome

Every KWR component has one defined role, one promotion lane, and one
unambiguous relationship to the Commander release. New work can be prioritized
without rebuilding finished systems, overwriting newer local work, or treating
optional utilities as hidden dependencies.

# Current behavior

- The recovered in-game Commander is `6.1.0-alpha.28`, while GitHub `main` is
  `6.1.0-alpha.9` and `develop` is `6.1.0-alpha.12`.
- The local Beacon is `1.0.0-beta.1`, while GitHub is `0.1.0`.
- Sentinel is `6.1.0-alpha.25` locally and on GitHub, but its polish task still
  has unverified acceptance criteria.
- Multiple planning documents each claim top-level or authoritative status.
- Dated handoffs mix historical rollback baselines with current release
  candidates.
- The Commander has retired external map dependencies, but adjacent local
  `KWR_Maps` and `KWR_ScoreCard` folders could still be mistaken for required
  release components.

# Required behavior

- Define one release-train authority and document hierarchy.
- Define a bounded product contract for Commander, Sentinel, Beacon, the
  Discord bot, Maps, and ScoreCard.
- Keep component versions independent while aligning them to one field-test
  milestone.
- Treat the recovered local Commander and Beacon copies as recovery sources
  until their complete diffs are reviewed on dedicated GitHub recovery
  branches.
- Preserve Sentinel's standalone and embedded parity.
- Separate offline certification from Retail field proof.
- Produce an ordered backlog for repository recovery, field testing, and
  promotion.

# Non-goals

- No merger of all projects into one repository, addon folder, ZIP, runtime, or
  version number.
- No live cross-player addon communication.
- No new Commander, Sentinel, Beacon, bot, Maps, or ScoreCard features.
- No direct push to an existing GitHub branch from a checkout without
  repository metadata.
- No claim that unchecked live acceptance criteria have passed.

# Technical constraints

- Commander remains the only strategic decision authority.
- Optional components may not become hard dependencies.
- Blizzard secure-action, combat-lockdown, taint, and addon-message boundaries
  remain unchanged.
- Historical records remain available but cannot override current release
  authority.
- GitHub recovery must use reviewable branches and preserve remote rollback
  history.

# Acceptance criteria

- [x] `docs/audits/historical-plans/RELEASE_VISION.md` defines the single release-train authority.
- [x] Every known component has a documented role and dependency boundary.
- [x] Local and GitHub version drift is recorded without overwriting either
  side.
- [x] The planning-document authority hierarchy is explicit.
- [x] Commander offline proof and remaining Retail-only gates are separated.
- [x] The Sentinel polish handoff remains visibly open.
- [x] Repository recovery and promotion work is sequenced.
- [x] Active planning, readiness, handoff, QA, and workflow documents defer to
  the release vision.

# Verification

1. Confirm all active release documents link to `docs/audits/historical-plans/RELEASE_VISION.md`.
2. Confirm all recorded versions match the local TOCs and inspected GitHub
   branches as of 2026-07-28.
3. Run repository validation to prove documentation edits did not disturb the
   addon load graph or release files.
4. Review the remaining backlog against the Retail-only release gates.

# Rollback

Remove `docs/audits/historical-plans/RELEASE_VISION.md` and this task brief, then revert only the authority
notices added to the existing planning documents. No runtime or saved-variable
behavior changes in this task.
