---
id: KWR-265
title: Polish CurseForge listing presentation
owner: Codex
priority: medium
risk: low
status: completed
authority_references: [AGENTS.md, RELEASE_READINESS.md, CURSEFORGE_UPLOAD.md]
dependencies: [KWR-264]
affected_modules:
  - CURSEFORGE_DESCRIPTION.md
  - KWRSentinel/CURSEFORGE_DESCRIPTION.md
  - tools/build.ps1
  - tools/package-audit.ps1
  - tools/candidate-package-report.ps1
  - .github/workflows/ci.yml
  - .github/workflows/release.yml
---

# Objective

Make the Commander and Sentinel CurseForge listings read cleanly in the
CurseForge client and use player-facing archive filenames on the next release.

# User outcome

Players see concise plain-text descriptions, clear Commander/Sentinel roles,
an explicit Sentinel requirement, and download names that identify the addon
and version without internal build terminology.

# Current behavior

CurseForge renders the existing Markdown syntax literally and exposes the
Commander archive as `KWR_<version>_DISTRIBUTION.zip`.

# Required behavior

- Keep descriptions plain text with short sections and no Markdown markers.
- Identify Sentinel as a companion that requires Knomercy War Room.
- Emit `KnomercyWarRoom-<version>.zip` and
  `KWR-Sentinel-<version>.zip` as public release archives.
- Preserve package roots, hash evidence, automated validation, and release
  gates.

# Non-goals

- Do not alter the immutable v6.1.0 release assets.
- Do not upload screenshots, tag, publish, or deploy a release.

# Verification

1. Run social-copy and automation contract tests. Completed locally.
2. Build both packages and run the extraction/package audit. Completed locally.
3. Save the plain-text descriptions and verify public rendering. Completed on
   both CurseForge project pages.

# Rollback

Revert this bounded presentation change. Existing public v6.1.0 files remain
unchanged and recoverable.
