# Long-Term External Access and Automation

## Principle

Production access must live in protected service configuration, not in a
Codex session, Chrome cookies, a developer workstation, or repository files.
Codex should need GitHub pull-request permission only. GitHub Actions and the
Discord bot hold the narrowly scoped publication credentials.

## GitHub

1. Create a GitHub App for KWR automation, or use a fine-grained token as a
   temporary migration step.
2. Grant the App only:
   - repository contents: read/write on the KWR repository;
   - pull requests: read/write;
   - issues: read/write for bot intake;
   - actions: read, plus workflow dispatch only where required.
3. Do not grant repository administration, secret administration, branch
   deletion, or unrestricted organization access to the bot.
4. Protect `main` and require pull requests plus the KWR CI status check.
5. Store the App private key or temporary token in the GitHub organization or
   repository secret store, never in Codex, Chrome, `.env`, or a commit.

Required repository variables/secrets:

| Name | Type | Purpose |
| --- | --- | --- |
| `CURSEFORGE_API_TOKEN` | environment secret | protected CurseForge upload |
| `DISCORD_WEBHOOK_ANNOUNCEMENTS` | environment secret | public release posts |
| `DISCORD_WEBHOOK_SUPPORT` | environment secret | support notices |
| `DISCORD_WEBHOOK_FIELD_TESTING` | environment secret | field-test notices |
| `DISCORD_WEBHOOK_OPS` | environment secret | restricted operator notices |

Use a protected `production` environment with required reviewer approval for
CurseForge uploads and public Discord posts. Dry-run workflows must not need
those secrets.

## CurseForge

1. Create or rotate one CurseForge API token owned by the project maintainer.
2. Store it only as `CURSEFORGE_API_TOKEN` in the protected GitHub environment.
3. Use numeric project IDs: Commander `1632632`, Sentinel `1614463`.
4. Upload only the certified ZIP produced by the same GitHub run that creates
   the release.
5. Require the upload helper to verify HTTP 2xx, JSON, and a positive file ID.
6. Poll the public project/file page before announcing availability. A GitHub
   workflow success is not proof of CurseForge acceptance.

## Discord bot

Host the bot as a managed service with restart policy, private logs, and a
health check against `/healthz`. Store these only in the host secret manager:

- `DISCORD_TOKEN`, `DISCORD_CLIENT_ID`, `DISCORD_GUILD_ID`;
- channel IDs and role IDs;
- `GITHUB_TOKEN` or GitHub App credentials for issue intake;
- optional `OPENAI_API_KEY`.

Keep GitHub issue sync and AI explicitly enabled by environment configuration.
The bot may collect reports, research summaries, and suggestions, but may not
merge code, publish releases, upload CurseForge files, or change addon doctrine.

## One-time verification

Run the protected GitHub workflow `KWR Automated Maintenance Schedule` with
`mode=external` and `confirm_external_writes=PUBLISH`. It must:

1. build and certify both packages;
2. upload and receive CurseForge file IDs;
3. verify the public CurseForge files;
4. post announcement/support/field-test messages;
5. verify the Commander and Sentinel Discord release notices, including their
   matching version and release link;
6. record the successful release workflow receipt.

Record the run URL, release URL, CurseForge file IDs, bot commit/image digest,
and Discord message IDs in a private maintenance receipt. Do not paste any
secret values into that receipt.

## Rotation and recovery

Rotate the CurseForge token and Discord webhooks independently. After
rotation, rerun the dry-run and protected
external verification. If any credential is suspected exposed, revoke it
first, disable external workflows, rotate, then re-enable the production
environment after a successful canary.

## What Codex needs

Codex does not need to receive or remember any production secret. It needs a
working GitHub connector or an authenticated GitHub App-backed workflow plus
the resulting run URLs and public verification. This avoids repeating browser
login setup and keeps credentials durable across Codex sessions.
