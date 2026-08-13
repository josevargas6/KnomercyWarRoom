---
id: KWR-046
title: Publish source-complete Alpha 33
owner: unassigned
priority: critical
risk: high
status: completed
authority_references: [RELEASE_READINESS.md, RELEASE_POLICY.md]
dependencies: [KWR-249, KWR-SENTINEL-009]
affected_modules: [Core, UI, KWRSentinel, release automation, release documentation]
---

# Objective

Supersede Alpha 32 with a source-complete Alpha 33 whose Commander and Sentinel
source, package metadata, hosted artifacts, CurseForge uploads, and installed
addon trees agree.

# User outcome

Players receive the reviewed live UI corrections and the safe visual-only
Sentinel runtime from either GitHub or CurseForge without source/artifact drift.

# Current behavior

Commander Alpha 32 is public and operational, but its live UI corrections were
merged after that tag. The standalone Alpha 32 Sentinel artifact also contains
a runtime/source version mismatch that must remain immutable and be superseded.

# Required behavior

Merge the reviewed Commander and Sentinel corrections, identify both products
as Alpha 33, build deterministic packages from one tagged Commander commit,
publish through the guarded release workflow, and verify every public endpoint
before announcing readiness.

# Non-goals

- Do not rewrite, delete, or replace Alpha 32 artifacts or tags.
- Do not enable protected gameplay actions, cross-player transport, or
  unreviewed doctrine.
- Do not claim stable status; Alpha 33 remains an explicit field-test release.

# Technical constraints

- The Commander tag must point at the reviewed merge commit.
- Embedded and standalone Sentinel runtime files must be identical.
- Both TOCs and runtime version constants must agree on 6.1.0-alpha.33.
- Release announcements must not carry Alpha 32 file IDs or hashes into Alpha 33.
- CurseForge and Discord writes remain guarded by repository workflows and
  platform-managed secrets.

# Acceptance criteria

- [x] Commander UI parity changes are merged with a clean final review.
- [x] Standalone Sentinel Alpha 33 source is merged after all completed review findings were resolved.
- [x] Embedded Sentinel is byte-identical to standalone reviewed source.
- [x] Complete local and hosted release gates pass.
- [x] The Alpha 33 tag resolves to the reviewed Commander merge commit.
- [x] GitHub prerelease artifacts and SHA-256 manifests resolve publicly.
- [x] Commander and Sentinel Alpha 33 CurseForge files resolve publicly.
- [x] Render runs the reviewed bot main commit with healthy Discord readiness.
- [x] Installed Commander and Sentinel trees matched the public Alpha 33 packages before the verified Alpha 36 superseding deployment.

# Verification

1. Run validation, security, knowledge, automation, social-copy, Lua, soak,
   replay, package, and reproducibility gates.
2. Verify tag/commit identity and all generated artifact hashes.
3. Verify GitHub and CurseForge public endpoints after publication.
4. Compare extracted packages with the installed addon trees.

# Known constraints

GitHub's Codex reviewer reached the account review-usage limit after four
completed Sentinel review rounds. The final completed round's findings were
resolved, all review threads are closed, hosted CI passed on the merged source,
and the remaining documentation-only correction passed CI in PR 10. Do not
describe this as a fresh automated review of the final documentation commit.

# Rollback

Keep Alpha 32 public as the immutable rollback release, remove no historical
evidence, and stop announcements if any Alpha 33 public endpoint or hash fails.
