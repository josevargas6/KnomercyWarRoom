---
id: KWR-037
title: Anchor alpha.29 as the new offline-stable field candidate
owner: Codex
priority: high
risk: low
dependencies: []
affected_modules:
  - CHANGELOG.md
  - RELEASE_READINESS.md
  - QA_CHECKLIST.md
  - docs
---

# Objective

Record the current alpha.29 offline-complete state as the new stable working
anchor before the next visual field-testing session.

# User outcome

The project has one clear documented baseline for tonight's testing and the
next release package, instead of mixed alpha.28 and alpha.29 state.

# Current behavior

The repo passes offline validation, knowledge audit, smoke, soak, and replay
gates with the expert corpus and enemy-response planner integrated, but the
top-level release-readiness and QA docs still describe alpha.28 as the active
candidate.

# Required behavior

- Update the changelog to reflect the alpha.29 offline-decision-engine work.
- Update release-readiness language so alpha.29 is the current candidate.
- Update the QA checklist title and automated-gate wording to match the new
  stable anchor.
- Add one durable stable-anchor report under `docs/` that summarizes what is
  now proven offline and what still requires live field proof.

# Non-goals

- Rewriting the release gate philosophy.
- Claiming that unresolved live field blockers are closed without evidence.
- Changing addon runtime behavior.

# Technical constraints

- Preserve the existing release-gate structure and evidence discipline.
- Keep all statements truthful to validated offline results captured on
  2026-07-30.

# Acceptance criteria

- [x] Alpha.29 changelog includes the expert corpus and enemy-response planner wave.
- [x] Release-readiness names alpha.29 as the current candidate.
- [x] QA checklist reflects alpha.29 as the active field checklist.
- [x] A stable-anchor document summarizes the current offline truth and next live focus.

# Verification

1. Review changed Markdown files for internal consistency.
2. Run package build after the documentation anchor is updated.

# Rollback

Revert the documentation-only changes and discard the new stable-anchor report.
