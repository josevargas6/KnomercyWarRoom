---
id: KWR-260
title: Publish the Alpha 42 certified Commander and Sentinel field-test release
owner: KWR
priority: high
risk: medium
status: in_progress
authority_references: [RELEASE_POLICY.md, RELEASE_READINESS.md, .github/workflows/release.yml]
dependencies: [PR-41]
affected_modules: [KnomercyWarRoom.toc, KWRSentinel/KWRSentinel.toc, Core/Addon.lua, KWRSentinel/Core.lua, tools/build.ps1, release.yml]
---

# Objective

Create one immutable Alpha 42 release from the certified PR-41 main source and
publish exactly matching Commander and Sentinel archives.

# User outcome

Players can install one current, verifiable Commander/Sentinel pair without
being directed to a stale Alpha 41 archive.

# Current behavior

Alpha 41 remains an immutable, already-published historical candidate. PR-41
has merged current Sentinel and UI repairs that are not in that archive.

# Required behavior

Advance all active version surfaces together to `6.1.0-alpha.42`, certify the
merged source, tag it as `v6.1.0-alpha.42`, and use the guarded release
workflow for GitHub, CurseForge, and Discord publication.

# Non-goals

Do not rewrite Alpha 41, alter historical evidence, or promote the alpha to a
stable/release channel without later field evidence.

# Technical constraints

Commander and Sentinel TOC and runtime versions must match. The release tag
must match the Commander TOC exactly. Public copy must identify only the
current candidate.

# Acceptance criteria

- [ ] Commander and Sentinel report `6.1.0-alpha.42` consistently.
- [ ] Full validation, knowledge, Lua, and package gates pass.
- [ ] PR certification is green and the release source is merged to `main`.
- [ ] The `v6.1.0-alpha.42` GitHub prerelease contains Commander, Sentinel,
  checksum, source-manifest, provenance, and reproducibility artifacts.
- [ ] CurseForge receives both exact certified archives.
- [ ] Matching Discord publication receipts are produced by the guarded workflow.

# Verification

1. Run `validate.ps1`, `knowledge-audit.ps1`, `test-lua.ps1`, and
   `build.ps1 -IncludeSentinel`.
2. Verify the merged commit, exact tag, GitHub release assets, workflow logs,
   and public CurseForge file records.
3. Verify Wiki sync and maintenance separately after publication.

# Rollback

Do not delete or overwrite the immutable tag. If publication fails, preserve
the candidate and fix the explicit failed release gate in a new reviewed
commit.
