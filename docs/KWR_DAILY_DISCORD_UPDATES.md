# KWR Daily Discord Updates

Status: ready-to-post

Date: 2026-07-30

This document defines the daily KWR progress update path for Discord.

The goal is not to automate trust or promotion. The goal is to keep the team
posted on what moved, what is blocked, and what session or evidence is needed
next.

## Operating notes

- Use one short daily progress post in the KWR progress or maintainer channel.
- Use one short ops post in a restricted channel when the team needs the exact
  candidate, blocker, and field-session state.
- Keep webhook credentials in Discord, Render, or GitHub secrets only.
- Use dry runs first.
- Treat the generated post as the baseline, then append only the smallest
  human-written deltas for completed work, next work, and asks.

## Recommended cadence

- One daily update near the end of the working day in `America/Chicago`.
- One extra update only when a blocker is cleared, a candidate changes, or a
  field session materially changes release readiness.

## Repository automation

- `.github/workflows/kwr-daily-discord.yml` posts the `daily-progress` update
  once per day when `DISCORD_WEBHOOK_DAILY_PROGRESS` is configured.
- The same workflow can also post the `ops` update when
  `DISCORD_WEBHOOK_OPS` is configured or when a maintainer triggers it
  manually.
- GitHub Actions schedules are UTC-based. The repository uses a fixed daily UTC
  schedule, so the local post time will shift by one hour across daylight
  saving boundaries.

## Guarded posting command

```powershell
$env:DISCORD_WEBHOOK_URL = "<channel webhook>"
./tools/kwr-daily-discord-update.ps1 -Section daily-progress -DryRun
./tools/kwr-daily-discord-update.ps1 -Section daily-progress `
    -ReportDate (Get-Date "2026-07-30") `
    -Headline "Offline base is in place; Twin Peaks live clearance is still the gate." `
    -Completed @("Built the daily status script.", "Documented the operator flow in the repo.") `
    -Next @("Run the first Twin Peaks blocker-clearing session.") `
    -Ask @("Need one focused flag-map field block with /kwr verify, /kwr perf, AAR, and screenshots.")
./tools/kwr-daily-discord-update.ps1 -Section ops -DryRun
./tools/kwr-daily-discord-update.ps1 -Section ops
```

Use a channel-specific webhook for each post. The script never stores tokens in
the repo.

## Suggested bot handoff

If the external Sentinel bot or Render worker is going to own this cadence, let
it call `tools/kwr-daily-discord-update.ps1` and supply the human delta lines
from the operator command or scheduled job context. This keeps the repo-owned
message contract and the bot-owned scheduler separate.

## Message contract

The generated daily message should always answer:

1. What build are we on?
2. What is actually complete offline?
3. What live blockers still prevent certification?
4. What session or map should happen next?
5. What help or evidence is needed from the team?
