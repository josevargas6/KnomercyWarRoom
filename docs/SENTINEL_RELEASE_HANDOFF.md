# KWR Sentinel Release Handoff

Status: distribution-prep

Date: 2026-07-17

## Product Scope

KWR Sentinel is the official compact non-commander player client for Knomercy
War Room. The release scope is:

- one commander-linked execution card;
- one target-confirmation cue;
- one conservative readiness alert;
- same-client KWR bridge only until the transport spec gates are implemented.

It is not a reporter map, enemy table, tactical board, Discord bot, or second
commander UI.

## GitHub

- KWR source repo: `https://github.com/josevargas6/KnomercyWarRoom`
- Sentinel source repo: `https://github.com/josevargas6/KWRSentinel`
- Sentinel prerelease: `https://github.com/josevargas6/KWRSentinel/releases/tag/v6.1.0-alpha.25`
- Visibility: public
- Current local limitation: this checkout has no `.git` directory and this
  shell does not provide `git`, so follow-up source sync must use GitHub API
  operations or a Git-enabled shell.
- Release ops workflow: `.github/workflows/sentinel-release-ops.yml`

## CurseForge Package Requirements

The Sentinel upload artifact must be the `KWRSentinel_<VERSION>.zip` file
created by:

```powershell
./tools/build.ps1 -IncludeSentinel
```

Upload only the dedicated Sentinel archive to the Sentinel CurseForge project.
Do not upload the KWR distribution archive, developer archive, Discord bot
files, local SavedVariables, or workspace-only docs.

Package shape required by CurseForge and the Blizzard client:

- zip root folder: `KWRSentinel/`
- TOC path: `KWRSentinel/KWRSentinel.toc`
- TOC basename matches parent folder: `KWRSentinel`
- Retail interface number: `120007`
- addon title: `KWR Sentinel`
- release notes source: `KWRSentinel/CURSEFORGE_DESCRIPTION.md`
- changelog source: `KWRSentinel/CHANGELOG.md`
- upload checklist: `KWRSentinel/CURSEFORGE_UPLOAD.md`
- guarded upload script: `tools/curseforge-upload-sentinel.ps1`
- workflow secrets:
  - `CURSEFORGE_PROJECT_ID`
  - `CURSEFORGE_API_TOKEN`
  - `CURSEFORGE_GAME_VERSION_IDS`

CurseForge support confirms that the TOC basename must match the parent addon
folder and each TOC must include the appropriate interface number for the game
flavor.

## Discord Updates

Discord is an announcement and support surface only for this addon release. It
must not be treated as approval authority or gameplay transport.

Recommended channels:

- `#announcements`: public release availability and download links.
- `#kwr-support`: install help, bug reports, and known limitations.
- `#kwr-field-testing`: alpha/beta Retail validation instructions.
- restricted ops thread: build hashes, GitHub release URL, CurseForge file ID,
  and rollback notes.

Prepared channel copy is available in
`docs/SENTINEL_DISCORD_CHANNEL_UPDATES.md`. Guarded webhook posting is
available through `tools/sentinel-discord-announce.ps1`.
The GitHub workflow expects these optional Discord secrets:

- `DISCORD_WEBHOOK_ANNOUNCEMENTS`
- `DISCORD_WEBHOOK_SUPPORT`
- `DISCORD_WEBHOOK_FIELD_TESTING`
- `DISCORD_WEBHOOK_OPS`

Minimum release post:

```text
KWR Sentinel <version> is available for alpha testing.
Download: <GitHub release URL>
CurseForge: <CurseForge file URL after moderation>
Install folder: World of Warcraft/_retail_/Interface/AddOns/KWRSentinel
Scope: compact execution card, target confirmation, readiness alert.
Limitations: same-client KWR bridge only; no cross-player relay yet.
```

## Download Links

Before public announcement, fill these exact links from the published artifacts:

- GitHub release: `https://github.com/josevargas6/KWRSentinel/releases/tag/v6.1.0-alpha.25`
- Sentinel ZIP: `https://github.com/josevargas6/KWRSentinel/releases/download/v6.1.0-alpha.25/KWRSentinel_6_1_0_ALPHA_25.zip`
- CurseForge project: `https://www.curseforge.com/wow/addons/kwr-sentinel`
- CurseForge file: `TBD after upload/moderation`
- SHA-256 manifest: `https://github.com/josevargas6/KWRSentinel/releases/download/v6.1.0-alpha.25/KWR_6_1_0_ALPHA_25_SHA256.txt`

Sentinel ZIP SHA-256:

```text
2F25602899C4F278C7A71A443C89C25DE7076F21FF818C5E4BD9670881CC2ED6
```

## Validation Gate

Before uploading or announcing:

```powershell
./tools/validate.ps1
./tools/knowledge-audit.ps1
fengari tests/smoke.lua
fengari tests/soak.lua
./tools/build.ps1 -IncludeSentinel
```

Then verify the generated Sentinel archive contains only the `KWRSentinel/`
root and includes `KWRSentinel/KWRSentinel.toc`.
