---
id: KWR-047
title: Establish a pristine single-source-of-truth repository
owner: Terra
priority: high
risk: high
status: in_progress
authority_references: [AGENTS.md, RELEASE_READINESS.md, RELEASE_POLICY.md]
dependencies: []
affected_modules: [repository governance, documentation, validation tooling, build and packaging, GitHub workflow]
---

# Objective

Make GitHub committed content the auditable development source and make the
live WoW AddOns folder a verified deployment target only.

# User outcome

Every source, documentation, data, test, and release concern has one declared
owner; deployment is provably identical to a verified package.

# Current behavior

The live folder is not a Git worktree and contains uncommitted source, assets,
temporary files, and superseded planning documents.

# Required behavior

Preserve a rollback snapshot, inventory all live-versus-canonical differences,
enforce document and source ownership audits, and package from an allowlist.

# Non-goals

Do not overwrite the live addon, publish a release, rewrite gameplay
architecture, or delete unclassified material.

# Technical constraints

GitHub `main` is canonical pending owner-approved changes. Unreviewed live
differences remain in the snapshot and disposition report rather than being
silently merged or removed.

# Acceptance criteria

- [ ] Disposition report classifies every relevant canonical and live file.
- [ ] Document and source-drift audits run in validation and CI.
- [ ] Production staging uses an explicit allowlist and manifest.
- [ ] Live deployment comparison rejects extras and content drift.

# Verification

1. Run validation, knowledge audit, Lua tests, soak, and build.
2. Produce a fresh-clone provenance and reproducibility record.
3. Compare the live installation with the generated package manifest.

# Rollback

`D:\KnomercyWarRoom-rollback-snapshots\KnomercyWarRoom-live-20260803-012025`
is read-only rollback evidence. Git history and package manifests retain all
subsequent recovery paths.
