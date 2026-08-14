---
id: KWR-2026-07-31-AUTO-SCHEDULE
title: Codify automated maintenance schedule across Discord GitHub CurseForge and Codex
owner: unassigned
priority: high
risk: medium
dependencies: [GitHub Actions, Discord webhooks, CurseForge project secrets]
affected_modules: [.github/workflows/kwr-automated-maintenance.yml, tools/kwr-maintenance-schedule.ps1, docs/maintainers/AUTOMATED_MAINTENANCE_SCHEDULE.md]
---

# Objective

Create an executable maintenance schedule that coordinates the local addon
checks, Discord status updates, GitHub scheduled automation, and CurseForge
release-readiness validation.

# User outcome

Maintainers can run one documented schedule locally or through GitHub Actions
and know which lane handles daily upkeep, patch-day checks, release dry-runs,
Discord reporting and CurseForge readiness.

# Current behavior

The repository has validation, test, build, Discord, CurseForge, and release
tools, plus a proposed continuous maintenance plan. There is no single checked
in schedule runner that executes those tools by maintenance lane.

# Required behavior

- Add a PowerShell maintenance runner with explicit schedule lanes.
- Add a GitHub Actions workflow with cron triggers and manual dispatch.
- Keep all external writes behind owner confirmation.
- Generate dry-run evidence for Discord, GitHub CI, and CurseForge upload
  metadata without requiring production credentials.
- Document the schedule, secrets, authority boundaries, and rollback path.

# Non-goals

- No production release promotion without the existing protected release path.
- No committed Discord bot token, webhook URL, GitHub token, CurseForge token,
  project ID, or game-version ID.
- No claim that a Codex-native recurring task exists in this environment.
- No automatic strategic-truth update from Discord, bot, GitHub, CurseForge, or
  AI output.

# Technical constraints

GitHub scheduled workflows run in UTC. The runner converts current time to
Central time for schedule classification. Scheduled runs default to dry-run
mode; external Discord posts require a manual workflow dispatch with
`confirm_external_writes=PUBLISH`. Repository dispatch was retired because the
bot repository has no receiver for those events.

# Acceptance criteria

- [ ] `tools/kwr-maintenance-schedule.ps1` exposes daily, patch, weekly,
  biweekly, monthly, release dry-run, full dry-run, status, and auto lanes.
- [ ] `.github/workflows/kwr-automated-maintenance.yml` runs the auto lane on
  the maintenance cadence and supports manual lane dispatch.
- [ ] `docs/maintainers/AUTOMATED_MAINTENANCE_SCHEDULE.md` documents the full
  Discord, GitHub, CurseForge, and Codex operating model.
- [ ] External writes are blocked unless explicitly confirmed by an owner.
- [ ] Local validation passes.

# Verification

1. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\kwr-maintenance-schedule.ps1 -Lane status`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\kwr-maintenance-schedule.ps1 -Lane release-dry-run`.
3. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate.ps1`.

# Rollback

Disable `.github/workflows/kwr-automated-maintenance.yml` or remove it. The
existing CI, release, Discord, and CurseForge scripts remain independent.
