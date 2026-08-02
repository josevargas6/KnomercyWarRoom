# KWR Sentinel Discord Channel Updates

Status: ready-to-post

Date: 2026-08-02

No Discord connector or webhook credential is available in this workspace, so
these messages are prepared for manual posting or for the KWR Sentinel Discord
bot once its production connection is available.

Guarded webhook posting command:

```powershell
$env:DISCORD_WEBHOOK_URL = "<channel webhook>"
./tools/sentinel-discord-announce.ps1 -Section announcements -DryRun
./tools/sentinel-discord-announce.ps1 -Section announcements
./tools/sentinel-discord-announce.ps1 -Section support
./tools/sentinel-discord-announce.ps1 -Section field-testing
./tools/sentinel-discord-announce.ps1 -Section ops
```

Use a channel-specific webhook for each post. The script never stores tokens in
the repo.

GitHub Actions route:

1. Add repository secrets:
   - `DISCORD_WEBHOOK_ANNOUNCEMENTS`
   - `DISCORD_WEBHOOK_SUPPORT`
   - `DISCORD_WEBHOOK_FIELD_TESTING`
   - `DISCORD_WEBHOOK_OPS`
2. Run `.github/workflows/sentinel-release-ops.yml` with `post_discord=true`.

## #announcements

```text
KWR Sentinel 6.1.0-alpha.33 is available for alpha testing as the synchronized
execution-card companion for Commander 6.1.0-alpha.33.

Download:
https://github.com/josevargas6/KnomercyWarRoom/releases/download/v6.1.0-alpha.33/KWRSentinel_6_1_0_ALPHA_33.zip

Release page:
https://github.com/josevargas6/KnomercyWarRoom/releases/tag/v6.1.0-alpha.33

Install folder:
World of Warcraft/_retail_/Interface/AddOns/KWRSentinel

Scope:
Compact player execution card, commander trust badge, target confirmation cue, and one conservative readiness alert.

Distribution state:
The guarded release gate publishes the exact reviewed GitHub artifact and
submits the same build to CurseForge for Retail 12.1.0 and 12.0.7. CurseForge
moderation visibility may lag. Current packaged in-game evidence still gates
stable promotion.

Current limitation:
Same-client KWR bridge only. Cross-player Sentinel relay is not enabled.
```

## #kwr-support

```text
KWR Sentinel alpha support notes:

- Use /sentinel or /kwrs to toggle the execution card.
- Use /kwrs map for the Blizzard battlefield map.
- Use /kwrs score for the Blizzard scoreboard.
- If no commander data appears, confirm KnomercyWarRoom is installed on the same client for this alpha.
- Sentinel does not target, focus, cast, move, send chat, or automate gameplay.

Bug reports should include:
- Retail version
- battleground
- whether KWR was installed on the same client
- screenshot of the card if visible
- any Lua error text
```

## #kwr-field-testing

```text
KWR Sentinel 6.1.0-alpha.33 field-test targets:

1. Enter a Retail battleground with KWR and KWRSentinel installed on the same client.
2. Confirm the card shows LOCAL KWR when commander bridge data is available.
3. Confirm NO COMMANDER appears when KWR is disabled or unavailable.
4. Confirm the target cue is white on the reviewed target, red on a different enemy, and muted with no target instruction.
5. Confirm one readiness alert appears during staging and does not repeat during combat.
6. Confirm /kwrs map and /kwrs score only toggle Blizzard-native UI.

Report any taint, Lua errors, unreadable text, repeated alerts, or incorrect target state.
```

## Restricted Ops Thread

```text
KWR Sentinel 6.1.0-alpha.33 distribution receipt

GitHub repo:
https://github.com/josevargas6/KWRSentinel

GitHub prerelease:
https://github.com/josevargas6/KnomercyWarRoom/releases/tag/v6.1.0-alpha.33

ZIP:
https://github.com/josevargas6/KnomercyWarRoom/releases/download/v6.1.0-alpha.33/KWRSentinel_6_1_0_ALPHA_33.zip

SHA-256 manifest:
KWR_6_1_0_ALPHA_33_SHA256.txt on the GitHub prerelease

Validation:
- validate.ps1 passed
- knowledge-audit.ps1 passed
- smoke.lua passed, 275 checks
- soak.lua passed
- build.ps1 -IncludeSentinel package audit passed

CurseForge:
The guarded release workflow submits the certified artifact for Retail 12.1.0
and 12.0.7; public moderation visibility must be verified before readiness is announced.
```
