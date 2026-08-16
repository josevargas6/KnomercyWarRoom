# KWR Sentinel Discord Channel Updates

Status: ready-to-post

Date: 2026-08-15

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
KWR Sentinel 6.1.0 is available as the synchronized stable execution-card
companion for Commander 6.1.0.

Download:
https://github.com/josevargas6/KnomercyWarRoom/releases/download/v6.1.0/KWRSentinel_6_1_0.zip

Release page:
https://github.com/josevargas6/KnomercyWarRoom/releases/tag/v6.1.0

Install folder:
World of Warcraft/_retail_/Interface/AddOns/KWRSentinel

Scope:
Compact player execution card, commander trust badge, target confirmation cue, and one conservative readiness alert.

Distribution state:
The guarded release gate publishes the exact reviewed GitHub artifact and
submits the same build to CurseForge for Retail 12.1.0 and 12.0.7. CurseForge
moderation visibility may lag. GitHub assets and their hashes remain the
authoritative release record.

Current limitation:
KWRSync1 cross-player relay is enabled as a bounded, conservative path;
same-client bridge remains the fallback. Team-scale transport proof remains in
the refinement queue.
```

## #kwr-support

```text
KWR Sentinel stable support notes:

- Use /sentinel or /kwrs to toggle the execution card.
- Use /kwrs map for the Blizzard battlefield map.
- Use /kwrs score for the Blizzard scoreboard.
- If no commander data appears, confirm KnomercyWarRoom is installed on the same client.
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
KWR Sentinel 6.1.0 refinement targets:

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
KWR Sentinel 6.1.0 distribution receipt

GitHub repo:
https://github.com/josevargas6/KWRSentinel

GitHub release:
https://github.com/josevargas6/KnomercyWarRoom/releases/tag/v6.1.0

ZIP:
https://github.com/josevargas6/KnomercyWarRoom/releases/download/v6.1.0/KWRSentinel_6_1_0.zip

SHA-256 manifest:
KWR_6_1_0_SHA256.txt on the GitHub release

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
