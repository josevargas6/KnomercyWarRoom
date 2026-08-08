# Historical: Secure Workspace Setup Plan

Status: foundation implemented; credential-dependent activation pending  
Audit date: 2026-07-17  
Workspace: `KnomercyWarRoom`

## Executive decision

Keep GitHub as the source of truth, Render as the Discord bot runtime, CurseForge as the addon distribution surface, Discord as intake/notification, and Codex automations as read-only audit and reminder workers until the source-control and approval gates below are complete.

Do not grant any AI or Discord-originated workflow direct merge, tag, release, deployment, secret-management, or stable-publishing authority.

## Verified state

### Workspace and GitHub

- The Codex GitHub connector is installed for `josevargas6` and can access `josevargas6/KnomercyWarRoom`, `josevargas6/kwr-sentinel-bot`, `josevargas6/KWR-Beacon`, and `josevargas6/KWRSentinel`.
- Connector permissions report admin/push/pull access to the four repositories.
- GitHub CLI authentication is active through the operating-system keyring. Its current token has `repo`, `workflow`, `read:org`, and `gist` scopes, which is broader than routine audit work requires.
- This live addon directory remains intentionally outside Git. Git for Windows 2.55.0.3 is installed, GitHub CLI credential integration is configured, and clean development checkouts now live under `C:\Users\josev\source\repos\`.
- Public `KWRSentinel/main` is protected with PR enforcement, required CI, conversation resolution, administrator enforcement, and force-push/deletion blocking. GitHub rejected protection for the two private repositories because the current account plan requires GitHub Pro or public visibility; privacy was preserved.
- No Actions or environment secret names were returned for the three inspected repositories. External publishing workflows are therefore not ready to perform authenticated writes.
- High-confidence local scanning found no GitHub, OpenAI, Discord, webhook, or private-key material.
- The public `KWRSentinel` repository reports secret scanning, push protection, validity checks, and Dependabot security updates disabled.

### Discord bot project

The Discord bot is a separate private repository: `josevargas6/kwr-sentinel-bot`. `KWRSentinel/` in this workspace is an in-game addon, not the bot.

Verified bot structure:

- Node 22 ESM application with `discord.js`, Octokit, and optional OpenAI integration.
- Slash-command-only Gateway configuration using the `Guilds` intent.
- `.env.example`, `.gitignore`, lockfile, Dockerfile, Docker Compose, Render Blueprint, environment validation, graceful shutdown, and a readiness endpoint are present.
- GitHub issue creation and AI features default to disabled.
- The latest recorded Render deployment succeeded for commit `cd690cd2cb1d05ee73a3b3ad94bbe9a76ee3abcf`.

Material gaps:

- CI performs syntax checks only; there are no unit/integration tests, lint, dependency audit, SBOM, or container scan.
- The documented Discord invite permissions exceed current code needs. The current bot needs `bot` plus `applications.commands`, View Channels, Send Messages, and Embed Links in its allowed channels. Attach Files, Read Message History, Manage Messages, Manage Threads, and Moderate Members are not justified by the inspected implementation.
- Discord submitter tags and IDs are copied into GitHub issues. A retention/redaction decision is required before production intake.
- Raw exception messages can be returned to users. Public responses should use a correlation ID while detailed errors remain in restricted logs.
- GitHub uses a long-lived token. Replace it with a GitHub App or fine-grained token limited to Issues read/write on the target repository.
- OpenAI user input has no explicit abuse controls, rate limit, or durable audit policy. Keep `ENABLE_AI=false` until those controls and a current model review are complete.

### Hosting and deployment

- `render.yaml` defines a Docker Background Worker on the Starter plan with `autoDeployTrigger: checksPass` and secret values marked `sync: false`.
- GitHub has successful Render deployment records, proving the repository-to-Render link exists.
- Production is still coupled directly to an unprotected `main` branch. A passing syntax-only check can deploy automatically.
- Render HTTP health checks apply to web/private services, not background workers. The bot's local `/healthz` and Docker `HEALTHCHECK` are useful, but an independent heartbeat monitor is still required.
- No durable scheduler/ledger/database is defined. Render's filesystem is ephemeral, so automation state must not live only on disk.

### CurseForge

- The release script uses the documented multipart endpoint `POST /api/projects/{projectId}/upload-file`, `X-Api-Token`, `metadata`, and `file` fields.
- The dedicated package shape is correct: `KWRSentinel/` at ZIP root with `KWRSentinel/KWRSentinel.toc`.
- Project metadata, English description, license/category/logo, supported game version, ZIP file, display name, release type, and changelog are required for submission. Files enter moderation after upload.
- Alpha files do not become the default CurseForge App download. At least one approved Release file is required for normal app synchronization.
- The expected project URL is documented, but the public project page and ownership were not verifiable from the available connector. Project ID, author token, current Retail game-version IDs, upload receipt, moderation state, and approved file URL remain unverified.

### Codex automation support

- The desktop environment exposes scheduled automation create/update/view/delete support and recognizes this local project.
- Supported selectable models include GPT-5.6 Sol, Terra, and Luna with configurable reasoning effort.
- `KWR Weekly Security Audit` is active as a read-only GPT-5.6 Sol/high scheduled audit.
- The automation targets the registered live addon project and is explicitly prohibited from writes or external mutations. Write-capable schedules remain blocked; reviewed development occurs in the Git checkout.

## Secure activation plan

### Phase 0: source control and identity

1. Clone `josevargas6/KnomercyWarRoom` into a normal development path with Git installed; do not use the live WoW AddOns directory as the authoritative checkout.
2. Reconcile this newer local workspace with the remote repository through a reviewed branch. Preserve the live folder as a test deployment target only.
3. Protect `main` and `develop`; require PR review, passing CI, conversation resolution, and no force pushes. Restrict tag and release creation.
4. Enable secret scanning/push protection and Dependabot where the GitHub plan permits it.
5. Replace broad personal tokens with per-service identities. Record owner, purpose, permissions, rotation date, and revocation procedure without storing values.

Exit gate: every change has branch/commit provenance and no production service uses a broad personal token.

### Phase 1: bot hardening and staging

1. Add schema-based environment validation, unit tests, lint, `npm audit`, dependency review, and container scanning.
2. Reduce Discord installation permissions to the inspected minimum and restrict commands by channel/role.
3. Redact or hash Discord identifiers before GitHub persistence; define retention/deletion rules.
4. Return generic user errors with correlation IDs; keep sanitized details in restricted logs.
5. Create a staging Discord guild/channel set and a staging Render service with separate credentials.
6. Keep production auto-deploy off. Promote an approved exact commit/image digest after staging smoke tests.

Exit gate: staging proves commands, issue creation, revocation, restart, and rollback with production credentials absent.

### Phase 2: guarded publication

1. Create protected GitHub environments for `curseforge-alpha`, `discord-release`, and `render-production` with required reviewers.
2. Add only the minimum secrets to their matching environments.
3. Resolve current CurseForge project ID and Retail game-version IDs from the author dashboard/API immediately before upload.
4. Build once, verify SHA-256, upload the exact certified Sentinel ZIP, and retain the returned file ID/status.
5. Announce only after the file is approved and its public download resolves.

Exit gate: GitHub, CurseForge, and Discord receipts identify the same version, SHA-256, and approved artifact.

### Phase 3: Codex read-only automations

Start with isolated, non-mutating schedules:

- weekly GitHub security/CI drift report;
- Tuesday source-freshness and patch-note review reminder;
- dependency and release-readiness summary;
- stale release receipt/CurseForge moderation check.

Use GPT-5.6 Sol/high for security and release audits, Terra/medium for routine follow-up, and Luna for bounded metadata/checklist cleanup. Require a human-triggered task for any edit, PR, deployment, upload, or announcement.

Exit gate: three reviewed runs complete without secrets, duplicate work, direct live-folder edits, or external mutations.

## Controls implemented in this workspace

- Expanded `.gitignore` coverage for environment files, private keys, certificates, and credential JSON.
- Added `tools/security-audit.ps1` with redacted high-confidence credential detection.
- Added the security audit to KWR CI and explicitly set CI to read-only repository contents.
- Added serialized Sentinel release operations and a required `PUBLISH` confirmation for external writes.
- Disabled checkout credential persistence in the release-ops job.
- Removed the user-specific default CurseForge artifact path; callers must name the certified artifact explicitly.
- Restricted Discord webhook posts to HTTPS Discord webhook endpoints.
- Installed Git for Windows and configured GitHub CLI as its credential helper with a GitHub noreply commit identity.
- Created clean development checkouts for the addon, Discord bot, and public Sentinel release repository.
- Opened three passing draft PRs for workspace, bot, and release-operation hardening.
- Enabled vulnerability alerts and automated security fixes on all three repositories.
- Enabled public Sentinel secret scanning and push protection, protected `main`, and created a maintainer-approved `sentinel-release-ops` environment.

## Authoritative references

- CurseForge upload API: https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-upload-api
- CurseForge project submission: https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project
- Discord OAuth2 and permissions: https://docs.discord.com/developers/platform/oauth2-and-permissions
- Discord application commands: https://docs.discord.com/developers/interactions/application-commands
- Render deploys: https://render.com/docs/deploys
- Render health checks: https://render.com/docs/health-checks
- Codex scheduled tasks: https://learn.chatgpt.com/docs/automations.md
