---
id: KWR-2026-07-30-CF-AUTO
title: Automate certified KWR CurseForge alpha deployment
owner: unassigned
priority: medium
risk: medium
dependencies: [CF_API_KEY, CF_PROJECT_ID repository secrets]
affected_modules: [.github/workflows/deploy.yml, .pkgmeta, KnomercyWarRoom.toc]
---

# Objective

Publish tagged KWR Commander alpha builds to CurseForge through the maintained
BigWigsMods packager after repository validation passes.

# User outcome

Pushing a matching `v<TOC Version>` tag produces a clean CurseForge alpha file
without manual zipping or accidentally shipping development material.

# Current behavior

The repository can build certified ZIPs locally and create GitHub prereleases,
but CurseForge submission still requires a manual upload.

# Required behavior

- Validate the TOC version and matching release tag.
- Run the existing architecture/release validator.
- Package only production addon files, the TOC, release changelog, and license.
- Upload through `BigWigsMods/packager@v2` using repository secrets.

# Non-goals

- No automatic production release promotion.
- No upload of KWRSentinel, Discord tooling, tests, docs, or local artifacts.
- No credentials committed to the repository.

# Technical constraints

CurseForge credentials remain in GitHub Actions secrets named `CF_API_KEY` and
`CF_PROJECT_ID`. Tags must exactly match the TOC version.

# Acceptance criteria

- [ ] `.pkgmeta` excludes development-only content and bundles KWR as `KnomercyWarRoom`.
- [ ] Tag pushes validate `v<TOC Version>` before packaging.
- [ ] Packager receives only GitHub Actions secrets.
- [ ] Local validation passes.

# Verification

1. Run `./tools/validate.ps1`.
2. Push a matching alpha tag after adding the two repository secrets.
3. Confirm the CurseForge file contains `KnomercyWarRoom/KnomercyWarRoom.toc` and no `.github`, `docs`, `tests`, `tools`, or `KWRSentinel` paths.

# Rollback

Disable the `KWR CurseForge Deploy` workflow or remove the two repository
secrets; local and GitHub prerelease packaging remains available.
