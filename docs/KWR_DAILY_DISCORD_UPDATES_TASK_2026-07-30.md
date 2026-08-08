---
id: KWR-051
title: Add a guarded daily Discord update path for KWR progress accountability
owner: unassigned
priority: medium
risk: low
dependencies: []
affected_modules:
  - docs
  - tools
---

# Objective

Create one repo-owned daily Discord update path for KWR so maintainers can post
consistent status updates without inventing a new format every day.

# User outcome

Maintainers can generate one concise daily KWR progress update from the current
workspace evidence, append what was completed and what is next, and post it
through the existing Discord webhook or bot integration.

# Current behavior

The repository already contains Sentinel release Discord update scaffolding, but
KWR itself has no equivalent daily-status contract or guarded posting helper.
Daily progress updates depend on ad hoc manual drafting, and no repository
workflow schedules a KWR status post.

# Required behavior

- Add one KWR daily-update playbook document that defines the intended channels,
  cadence, and operator workflow.
- Add one guarded PowerShell script that can build a daily status post from the
  current KWR readiness, blocker artifacts, and `docs/WORKFLOW_NOW.md`.
- Add one repository workflow that posts the generated update once per day when
  Discord webhook secrets are configured.
- Keep webhook credentials out of the repository and validate Discord webhook
  URLs before posting.
- Support dry-run output so maintainers can preview posts before publishing.
- The generated daily message must include current workflow, known issues,
  repairs, recent changes, direction, and progress toward that direction.

# Non-goals

- Do not add in-game networking or addon-side Discord behavior.
- Do not grant autonomous production posting authority to Codex.
- Do not replace the external Sentinel bot or Render scheduler plan.
- Do not add bot-side state storage or new external dependencies.

# Technical constraints

- The addon remains fully functional without any external Discord service.
- Webhook tokens must stay outside the repository.
- The script must fail closed on missing or malformed source artifacts.
- Use existing machine-readable readiness and blocker artifacts rather than
  creating a parallel truth source.
- The scheduled workflow must skip posting when the required Discord webhook
  secret is not configured.

# Acceptance criteria

- [ ] `docs/KWR_DAILY_DISCORD_UPDATES.md` defines the daily KWR posting flow.
- [ ] `tools/kwr-daily-discord-update.ps1` can dry-run a daily progress post.
- [ ] The script validates Discord webhook host and path before posting.
- [ ] The generated message reflects the current candidate version, workflow
      direction, recent repairs/changes, and known issues from repo artifacts.
- [ ] A GitHub Actions workflow exists to post the daily update on a daily
      schedule when secrets are present.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `./tools/kwr-daily-discord-update.ps1 -Section daily-progress -DryRun`.
3. Run `./tools/kwr-daily-discord-update.ps1 -Section ops -DryRun`.
4. Inspect `.github/workflows/kwr-daily-discord.yml`.

# Rollback

Delete the KWR daily-update document and script. No persisted addon data or
saved variables are affected.
