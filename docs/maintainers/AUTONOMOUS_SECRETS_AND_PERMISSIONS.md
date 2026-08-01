# Autonomous Secrets and Permissions Matrix

This is the one-time configuration for unattended KWR operations. Secret
values must be entered directly into GitHub/hosting-provider secret stores.
Never send them to Codex, Discord, issues, or commit them to the repository.

## GitHub repository variables

Set these as non-secret Actions variables:

| Variable | Value |
| --- | --- |
| `KWR_BOT_REPOSITORY` | `josevargas6/kwr-sentinel-bot` |
| `KWR_AUTOMATION_APP_ID` | `4459432` |
| `CURSEFORGE_COMMANDER_PROJECT_ID` | `1632632` |
| `CURSEFORGE_SENTINEL_PROJECT_ID` | `1614463` |
| `KWR_RELEASE_CHANNEL` | `alpha` |

## GitHub production-environment secrets

Create a GitHub Environment named `production` and add:

| Secret | Scope |
| --- | --- |
| `CURSEFORGE_API_TOKEN` | CurseForge upload for both approved project IDs |
| `KWR_AUTOMATION_APP_PRIVATE_KEY` | Short-lived App token minting for repository dispatch |
| `KWR_BOT_DISPATCH_TOKEN` | Temporary rollback credential; remove after App-token canary |
| `DISCORD_WEBHOOK_ANNOUNCEMENTS` | Public release announcements |
| `DISCORD_WEBHOOK_SUPPORT` | Support notices |
| `DISCORD_WEBHOOK_FIELD_TESTING` | Field-test coordination |
| `DISCORD_WEBHOOK_OPS` | Restricted operations channel |
| `DISCORD_WEBHOOK_DAILY_PROGRESS` | Daily progress digest |

For fully unattended operation, leave required reviewers empty but keep:

- deployment branch restriction to `main` and release tags;
- required KWR CI status checks;
- a short environment wait timer if the repository plan supports it;
- concurrency so only one publication runs at a time.

This removes routine approval clicks without removing automated safety gates.

## GitHub App / dispatch permissions

Prefer a GitHub App over a long-lived PAT. Install it only on the Commander and
private bot repositories with:

- Contents: read/write;
- Issues: read/write;
- Pull requests: read/write;
- Actions: read and workflow dispatch where required;
- Metadata: read.

Do not grant the bot repository administration, organization administration,
secret administration, branch deletion, or unrestricted repository access.
Set branch protection once as the repository owner; do not give the bot admin
permission merely to make that setting.

## Private Discord bot host variables

Set these in the hosting provider's encrypted environment (Render, container
secret store, or equivalent):

| Variable | Required | Purpose |
| --- | --- | --- |
| `DISCORD_TOKEN` | yes | Bot gateway token |
| `DISCORD_CLIENT_ID` | yes | Discord application ID |
| `DISCORD_GUILD_ID` | yes | Server where commands are registered |
| `ENABLE_GITHUB_ISSUES` | yes | `true` for structured intake |
| `GITHUB_TOKEN` | yes | Least-privilege receipt/intake credential under Codex policy |
| `GITHUB_OWNER` | yes | `josevargas6` |
| `GITHUB_REPO` | yes | `KnomercyWarRoom` |
| `AUTO_LABEL_CODEX_READY` | yes | `true` after the label exists |
| `CODEX_READY_LABEL` | yes | `codex-ready` |
| `ENABLE_AI` | no | Sentinel is an execution transport; Codex owns analysis |
| `OPENAI_API_KEY` | no | Keep analysis and implementation in Codex |
| `KWR_STABLE_DOWNLOAD_URL` | yes | Verified public stable link |
| `KWR_TEST_DOWNLOAD_URL` | yes | Verified public alpha link |
| `KWR_DOCS_URL` | yes | Public documentation URL |
| `KWR_SUPPORT_URL` | yes | Public support URL |
| `HEALTH_HOST` | yes | `0.0.0.0` |
| `HEALTH_PORT` | yes | `3000` |

Also set the configured Discord channel IDs and moderation role IDs. Keep
`INCLUDE_SUBMITTER_IDENTIFIERS=false` unless there is a documented support need.

## Discord application permissions

Use only the intents and permissions the bot needs:

- Gateway intent: `Guilds` for slash commands;
- Send Messages, Embed Links, Read Message History;
- Manage Messages only where moderation commands require it;
- no Administrator permission;
- no privileged message-content intent unless a reviewed feature explicitly
  requires it.

## CurseForge setup

Create/rotate the API token in the CurseForge author dashboard, then place it
only in the GitHub `production` environment. Verify that the token can upload
to Commander `1632632` and Sentinel `1614463`. The workflow must verify HTTP
2xx, JSON, and a positive file ID, then poll the public file page before
announcing availability.

## One-time autonomous canary

After configuration, run this sequence once:

1. GitHub Actions dry-run with no external writes.
2. Bot `/healthz` and `/readyz` check.
3. Bot `/ping` and one private test submission.
4. Protected release workflow with an alpha artifact.
5. Verify CurseForge public file visibility.
6. Verify Discord message delivery and bot event deduplication.
7. Record run URL, file IDs, message IDs, and bot commit/image digest.

After the canary passes, scheduled maintenance can run without routine owner
approval. Rotate all credentials independently and rerun the canary after any
rotation.
