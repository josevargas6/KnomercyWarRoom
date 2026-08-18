# KWR Commander Discord Channel Updates

Status: draft-do-not-post

Date: 2026-08-17

No Discord connector or webhook credential is available in this workspace, so
these messages are prepared for manual posting or for the KWR Sentinel Discord
bot once the production connection is available.

Guarded webhook posting command:

```powershell
$env:DISCORD_WEBHOOK_URL = "<channel webhook>"
./tools/kwr-commander-discord-announce.ps1 -Section announcements -DryRun
./tools/kwr-commander-discord-announce.ps1 -Section announcements
./tools/kwr-commander-discord-announce.ps1 -Section support
./tools/kwr-commander-discord-announce.ps1 -Section field-testing
./tools/kwr-commander-discord-announce.ps1 -Section ops
```

Use a channel-specific webhook for each post. The script never stores tokens in
the repo.

## #announcements

```text
Knomercy War Room Commander 6.1.1-alpha.4 is the Season 2 field-test candidate.

Do not post until the matching tag, public assets, CurseForge Alpha file, and
production readiness evidence are verified.

GitHub release:
https://github.com/josevargas6/KnomercyWarRoom/releases/tag/v6.1.1-alpha.4

CurseForge project:
https://www.curseforge.com/wow/addons/knomercy-war-room

Current state:
The guarded release gate publishes the exact reviewed GitHub artifact and
submits the same build to CurseForge for Retail 12.1.0 and 12.0.7. CurseForge
moderation visibility may lag. GitHub assets and their hashes remain the
authoritative release record.

What this addon is:
Player-controlled Rated Battleground command, assignments, enemy tracking, tactical map, Fight Now HUD, and AAR support.
```

## #kwr-support

```text
Knomercy War Room commander support notes:

- Use /kwr preview outside battlegrounds to inspect the full interface safely.
- Use /kwr verify to capture current battlefield truth.
- Use /kwr perf to capture runtime and refresh behavior.
- Use /kwr bug immediately if you hit a Lua error, taint issue, false fact, or reload requirement.
- Live field reports should include battleground, screenshot, whether you were commander or spectator, and AAR/export if available.

KWR does not auto-target, auto-focus, auto-cast, auto-send chat, or automate gameplay.
```

## #kwr-field-testing

```text
KWR Commander 6.1.1-alpha.4 field-test focus:

1. Confirm Fight Now HUD wording stays clean and readable in live combat.
2. Confirm Team and Enemy tracking stay truthful after battleground transitions.
3. Confirm tactical map markers stay centered, readable, and updated by live facts.
4. Confirm flag-map routing uses canonical carrier/route language instead of raw event prose.
5. Capture /kwr verify, /kwr perf, AAR, and screenshots for any blocker or major win.

Ongoing field work:
- verify upgrades and fresh installs across supported systems
- recheck readability across supported resolutions
- attach version- and package-bound evidence to any issue
```

## Restricted Ops Thread

```text
KWR Commander 6.1.1-alpha.4 distribution receipt

CurseForge project:
https://www.curseforge.com/wow/addons/knomercy-war-room

CurseForge project id:
1632632

GitHub release:
https://github.com/josevargas6/KnomercyWarRoom/releases/tag/v6.1.1-alpha.4

Certified artifact:
KnomercyWarRoom-6.1.1-alpha.4.zip

SHA-256 manifest:
KWR_6_1_1_ALPHA_3_SHA256.txt on the GitHub release

Validation:
- validate.ps1 passed
- knowledge-audit.ps1 passed
- test-lua.ps1 passed
- build.ps1 passed package audit
- commander CurseForge upload dry-run passed

Current truth:
- CurseForge receives the exact certified artifact for Retail 12.1.0 and 12.0.7
- GitHub release assets and their public hashes are the authoritative published record
- CurseForge file type is Alpha for the suffixed semantic version
```
