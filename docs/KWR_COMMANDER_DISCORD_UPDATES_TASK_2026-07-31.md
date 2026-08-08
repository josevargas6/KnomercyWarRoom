---
id: KWR-038
title: Add commander Discord release update path
owner: Codex
priority: high
risk: low
dependencies: []
affected_modules:
  - docs/KWR_COMMANDER_DISCORD_CHANNEL_UPDATES.md
  - tools/kwr-commander-discord-announce.ps1
  - docs/SENTINEL_RELEASE_STATUS.md
  - CHANGELOG.md
---

# Objective

Create a repository-owned Discord update path for the main Knomercy War Room
commander addon so release and testing messages are prepared with the same
discipline already used by Sentinel.

# User outcome

The maintainer has ready-to-post Discord copy and a guarded posting script for
Commander, plus a refreshed Sentinel status record that reflects the current
date and still-pending external posting state.

# Current behavior

Sentinel has a Discord channel update document and guarded announce script.
Commander only has the generic daily progress path and no release-shaped
channel update pack.

# Required behavior

- Add commander Discord channel updates with announcement, support, field-test,
  and ops message blocks.
- Add a guarded commander Discord post helper with dry-run support.
- Refresh Sentinel release status date so the current state is explicit.

# Non-goals

- Posting to Discord from this workspace without a configured webhook.
- Claiming CurseForge file publication before a real file URL exists.
- Changing Sentinel product scope or release version.

# Technical constraints

- Keep Discord credentials out of the repository.
- Keep commander messaging truthful: the CurseForge project page exists, but
  the first commander file is not yet publicly proven uploaded.
- Reuse the existing guarded webhook validation pattern.

# Acceptance criteria

- [x] Commander has a ready-to-post Discord channel update document.
- [x] Commander has a guarded announce script with dry-run support.
- [x] Sentinel release status date is refreshed to the current release-work date.
- [x] Dry-run output works for both commander and sentinel announcement paths.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `./tools/kwr-commander-discord-announce.ps1 -Section announcements -DryRun`.
3. Run `./tools/kwr-commander-discord-announce.ps1 -Section ops -DryRun`.
4. Run `./tools/sentinel-discord-announce.ps1 -Section announcements -DryRun`.

# Rollback

Remove the commander Discord update document and announce script, then revert
the Sentinel status and changelog entries.
