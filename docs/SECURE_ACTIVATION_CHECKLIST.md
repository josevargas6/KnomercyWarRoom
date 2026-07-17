# Secure Service Activation Checklist

Never paste credential values into this repository, a GitHub issue, Discord, or a Codex prompt. Enter them directly in the named platform secret store and record only the secret name, owner, purpose, and rotation date.

## GitHub

- [ ] Merge security-foundation changes through a reviewed PR into `develop`.
- [ ] Promote `develop` to `main` through a separate reviewed PR after CI passes.
- [ ] Upgrade the GitHub account plan if private-repository branch protection is required; do not make private repositories public only to unlock protection.
- [ ] Enable secret scanning, push protection, Dependabot alerts, and security updates where the plan supports them.
- [ ] Replace broad classic/PAT access with per-service GitHub Apps or fine-grained tokens.

Bot GitHub identity, when issue sync is enabled:

- repository access: selected `KnomercyWarRoom` repository only;
- repository permission: Issues read/write;
- no Contents, Actions, Administration, Deployments, Environments, or Secrets permission.

## Discord application

- [ ] Create or verify the `KWR Sentinel` application in the Discord Developer Portal.
- [ ] Rotate the bot token if it has ever appeared outside the portal or Render secret store.
- [ ] Invite with `bot` and `applications.commands` scopes.
- [ ] Grant only View Channels, Send Messages, Embed Links, and Use Application Commands in approved channels.
- [ ] Keep Administrator, Manage Messages, Manage Threads, Moderate Members, and privileged Gateway intents disabled unless future reviewed code proves they are required.
- [ ] Create separate staging channels or a staging guild before enabling GitHub issue or AI features.

Required Render secret values:

- `DISCORD_TOKEN`
- `DISCORD_CLIENT_ID`
- `DISCORD_GUILD_ID`

Optional bot values should stay disabled until staged:

- `ENABLE_GITHUB_ISSUES=false`
- `ENABLE_AI=false`
- `INCLUDE_SUBMITTER_IDENTIFIERS=false`

## Render

- [ ] Keep production auto-deploy disabled.
- [ ] Deploy an explicitly reviewed commit after its GitHub checks and staging smoke test pass.
- [ ] Confirm the container runs as a non-root user.
- [ ] Configure an independent heartbeat monitor; the worker's local HTTP endpoint is not a Render web-service health check.
- [ ] Record the prior successful commit/deployment before every promotion.
- [ ] Keep durable scheduler, receipt, or evidence state in a managed datastore, not the ephemeral worker filesystem.

## CurseForge and release announcements

- [ ] Verify project ownership and record the numeric project ID outside source control.
- [ ] Generate a dedicated author API token and store it only in the protected `sentinel-release-ops` GitHub environment.
- [ ] Resolve current Retail game-version IDs immediately before upload.
- [ ] Configure environment secrets:
  - `CURSEFORGE_PROJECT_ID`
  - `CURSEFORGE_API_TOKEN`
  - `CURSEFORGE_GAME_VERSION_IDS`
- [ ] Configure separate Discord webhook secrets only for channels that will receive release posts:
  - `DISCORD_WEBHOOK_ANNOUNCEMENTS`
  - `DISCORD_WEBHOOK_SUPPORT`
  - `DISCORD_WEBHOOK_FIELD_TESTING`
  - `DISCORD_WEBHOOK_OPS`
- [ ] Run the release workflow in dry-run mode first.
- [ ] Verify the exact ZIP SHA-256 and require the explicit publish confirmation.
- [ ] Wait for CurseForge moderation and verify the public download before posting announcements.

## Codex automation

- [ ] Keep scheduled audits read-only.
- [ ] Review the first three runs for false positives, excessive permissions, or attempted writes.
- [ ] Use GPT-5.6 Sol/high for security and release audits, Terra/medium for routine reviewed edits, and Luna only for bounded repetitive cleanup.
- [ ] Do not grant scheduled tasks merge, tag, release, deployment, upload, Discord-posting, or secret-management authority.

## Rotation and recovery

- [ ] Record credential owner and next rotation date without recording the credential.
- [ ] Test Discord token, GitHub token/App, CurseForge token, webhook, and OpenAI key revocation independently.
- [ ] Retain the last-known-good addon artifact hash and bot commit/deployment.
- [ ] Rehearse bot rollback and addon superseding-release procedures before stable publication.
