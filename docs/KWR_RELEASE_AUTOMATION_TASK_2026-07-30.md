---
id: KWR-2026-07-30-RELEASE-SYNC
title: Synchronize Commander and Sentinel release publication
owner: unassigned
priority: high
risk: medium
dependencies: [GitHub release, CurseForge project secrets, Discord webhook, optional bot dispatch token]
affected_modules: [.github/workflows/release.yml, tools/curseforge-upload-sentinel.ps1, tools/*discord-announce.ps1]
---

# Objective

Make a matching Commander tag the single release event for the GitHub release,
Commander CurseForge file, Sentinel CurseForge file, and Discord availability
notice.

# User outcome

One release tag publishes both addons consistently, with versioned changelog
text and separate CurseForge project credentials.

# Required behavior

- Build and certify both archives before any external upload.
- Publish the existing GitHub prerelease.
- Upload each addon to its own CurseForge project.
- Post version-correct Commander and Sentinel Discord announcements.
- Notify the separate Discord bot repository with a signed GitHub API dispatch.

# Non-goals

- No automatic stable-release promotion.
- No Discord token or CurseForge credential in source control.
- Bot notification is optional and skipped when its protected secrets are absent.
- No upload of the developer archive or repository documentation.

# Acceptance criteria

- [ ] Sentinel upload display name is read from its TOC.
- [ ] Discord scripts can rewrite release version and archive links.
- [ ] Release workflow uses separate Commander and Sentinel project secrets.
- [ ] Bot dispatch carries both addon versions and the immutable release URL.
- [ ] All validation and deterministic tests pass before release changes are published.

# Verification

1. Run `./tools/validate.ps1` and `./tools/test-lua.ps1`.
2. Configure the required repository secrets.
3. Push a matching Commander tag and verify the GitHub release, both CurseForge files, and Discord announcement.

# Rollback

Disable the external-upload steps in `release.yml`; GitHub artifact generation
and local certified packaging remain available.
