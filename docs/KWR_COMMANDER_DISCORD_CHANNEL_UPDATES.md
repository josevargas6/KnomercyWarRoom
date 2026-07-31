# KWR Commander Discord Channel Updates

Status: ready-to-post

Date: 2026-07-31

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
Knomercy War Room Commander 6.1.0-alpha.29 is prepared for controlled
Rated Battleground field distribution.

Project page:
https://www.curseforge.com/wow/addons/knomercy-war-room/preview

Current candidate:
Knomercy War Room 6.1.0-alpha.29

Current state:
Offline certification and tonight's live Retail 12.0.7 field test are green.
No functional bugs were found, and the identified visual repairs are complete.
Final packaged visual verification remains before stable-release promotion.

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
KWR Commander alpha.29 field-test focus:

1. Confirm Fight Now HUD wording stays clean and readable in live combat.
2. Confirm Team and Enemy tracking stay truthful after battleground transitions.
3. Confirm tactical map markers stay centered, readable, and updated by live facts.
4. Confirm flag-map routing uses canonical carrier/route language instead of raw event prose.
5. Capture /kwr verify, /kwr perf, AAR, and screenshots for any blocker or major win.

Remaining release work:
- verify the final packaged ZIPs install and upgrade cleanly
- recheck readability from the packaged build across supported resolutions
- attach final screenshots before stable promotion
```

## Restricted Ops Thread

```text
KWR Commander distribution status

CurseForge project:
https://www.curseforge.com/wow/addons/knomercy-war-room/preview

CurseForge project id:
1632632

Current candidate:
Knomercy War Room 6.1.0-alpha.29 with KWRSentinel 6.1.0-alpha.25

Certified artifact:
KWR_6_1_0_ALPHA_29_DISTRIBUTION.zip

Validation:
- validate.ps1 passed
- knowledge-audit.ps1 passed
- test-lua.ps1 passed
- build.ps1 passed package audit
- commander CurseForge upload dry-run passed

Current truth:
- Commander CurseForge project exists
- first commander file is not yet publicly proven uploaded
- Discord copy is prepared
- live field blockers still gate broad release promotion
```