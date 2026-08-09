---
id: KWR-047
title: Establish a pristine single-source-of-truth repository
owner: Terra
priority: high
risk: high
status: completed
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

# Required behavior

Preserve a rollback snapshot, inventory all live-versus-canonical differences,
enforce document and source ownership audits, package from an allowlist, and
reject missing, changed, or extra installed files.

# Non-goals

Do not rewrite gameplay architecture, discard unclassified evidence, or treat
offline/package certification as Retail battleground proof.

# Acceptance criteria

- [x] Disposition report classifies every relevant canonical and live file.
- [x] Document and source-drift audits run in validation and CI.
- [x] Production staging uses an explicit allowlist and manifest.
- [x] Live deployment comparison rejects extras and content drift.

# Verification

1. Current GitHub `main` passed hosted certification at commit `77829fe780be72cb0b115f12a51c2ce3f6613b31`.
2. The Alpha 36 Commander and Sentinel release archives matched their published SHA-256 receipts.
3. The synchronized Commander installation contains exactly 387 package files with zero missing, changed, or extra entries.
4. The synchronized Sentinel installation contains exactly 9 package files with zero missing, changed, or extra entries.
5. The final disposition classified 8,926 files with zero `REVIEW_REQUIRED` entries.
6. `main` and `develop` require PR review, CODEOWNERS review, conversation resolution, and the `certify` check; force push and deletion are disabled.
7. The `production` environment requires owner review and accepts only `v*` tag deployments.

The durable completion record is
`docs/audits/2026-08-08/KWR-047-closure.md`.

# Rollback

`D:\KnomercyWarRoom-rollback-snapshots\KnomercyWarRoom-live-20260803-012025`
is the read-only pre-cleanup snapshot. Git history, the public Alpha 36 release,
and its package manifests provide the remaining recovery paths.
