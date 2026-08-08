# KWR Sentinel Release Status

Status date: 2026-07-31

## Distribution State

KWR Sentinel `6.1.0-alpha.25` is built, validated, packaged, and available from
the public GitHub release.

Public links:

- Repository: `https://github.com/josevargas6/KWRSentinel`
- Release: `https://github.com/josevargas6/KWRSentinel/releases/tag/v6.1.0-alpha.25`
- ZIP: `https://github.com/josevargas6/KWRSentinel/releases/download/v6.1.0-alpha.25/KWRSentinel_6_1_0_ALPHA_25.zip`
- SHA-256 manifest: `https://github.com/josevargas6/KWRSentinel/releases/download/v6.1.0-alpha.25/KWR_6_1_0_ALPHA_25_SHA256.txt`
- Release ops issue: `https://github.com/josevargas6/KWRSentinel/issues/1`
- Release ops workflow: `https://github.com/josevargas6/KWRSentinel/actions/workflows/sentinel-release-ops.yml`

Certified ZIP SHA-256:

```text
2F25602899C4F278C7A71A443C89C25DE7076F21FF818C5E4BD9670881CC2ED6
```

## Completed Evidence

- Sentinel follows `docs/SENTINEL_DESIGN_HANDOFF.md` scope: compact execution
  card, target cue, readiness alert, and same-client bridge only.
- Public GitHub repository exists and contains source, docs, release scripts,
  and release workflow.
- Public GitHub prerelease exists with the certified ZIP and SHA manifest.
- GitHub Actions release-ops dry-run passed:
  `https://github.com/josevargas6/KWRSentinel/actions/runs/29609216500`
- `./tools/validate.ps1` passed.
- `./tools/knowledge-audit.ps1` passed.
- `fengari tests/smoke.lua` passed with 277 checks.
- `fengari tests/soak.lua` passed.
- `./tools/build.ps1 -IncludeSentinel` passed package audit.
- Public ZIP download resolves with `200 OK`.

## CurseForge State

Ready for upload, not yet proven uploaded.

Required secrets for automated upload:

- `CURSEFORGE_PROJECT_ID`
- `CURSEFORGE_API_TOKEN`
- `CURSEFORGE_GAME_VERSION_IDS`

After those are set, run `KWR Sentinel Release Ops` with
`upload_curseforge=true`.

The expected CurseForge project URL is:

```text
https://www.curseforge.com/wow/addons/kwr-sentinel
```

The exact approved file URL remains `TBD` until CurseForge upload and
moderation complete.

## Discord State

Channel update copy is ready, not yet proven posted.

Required secrets for automated webhook posting:

- `DISCORD_WEBHOOK_ANNOUNCEMENTS`
- `DISCORD_WEBHOOK_SUPPORT`
- `DISCORD_WEBHOOK_FIELD_TESTING`
- `DISCORD_WEBHOOK_OPS`

After those are set, run `KWR Sentinel Release Ops` with `post_discord=true`.

Prepared copy is in:

```text
docs/SENTINEL_DISCORD_CHANNEL_UPDATES.md
```

## Completion Rule

The full release goal is complete only after:

1. CurseForge upload succeeds and the approved file URL is recorded.
2. Discord channel posts are sent through the configured server connection.
3. `docs/SENTINEL_RELEASE_HANDOFF.md` and this file are updated with those
   external receipts.
