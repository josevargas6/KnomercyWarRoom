# Owner-only action checklist

Use this checklist in the GitHub repository settings tomorrow. The repository
files and local validation are already prepared.

These items cannot be truthfully configured from this checkout:

- [x] Protect `main` and `develop`: PRs, required checks, current branch,
  conversation resolution, stale-approval dismissal, CODEOWNERS review, no
  force push/delete, and protected production environment approval.
- [x] Require the `certify` job from `KWR CI` on pull requests before merge.
- [x] Require one owner approval for `production`; do not allow administrators
  to bypass the environment rule for normal releases.
- [x] Create GitHub environments `development`, `beta`, and `production`.
- [x] Add `production` environment reviewers and prevent deployment from
  untrusted branches. The tagged release workflow is the production path.
- [ ] Add production CurseForge, Discord, and GitHub App secrets only to the
  protected environments; never expose them to fork PRs.
- [ ] Add these production environment secrets only when the corresponding
  service is ready: `CURSEFORGE_API_TOKEN`, `CURSEFORGE_GAME_VERSION_IDS`, and
  `DISCORD_WEBHOOK_ANNOUNCEMENTS`. Project IDs are public numeric workflow
  configuration: Commander `1632632`, Sentinel `1614463`.
- [ ] If Sentinel dispatch is enabled, add `KWR_BOT_DISPATCH_TOKEN` and
  `KWR_BOT_REPOSITORY` only after verifying the destination repository.
- [ ] Create separate development Discord application, token, channels,
  webhooks, and allowlists.
- [x] Confirm Commander `1632632` and Sentinel `1614463` CurseForge channel mapping.
- [x] Approve or reject any future addon-message protocol change. The current
  decision remains rejection until `PROTOCOL.md` requirements are satisfied.
- [ ] Run a dry-run release and rollback drill, then record the evidence.

## Tomorrow's verification order

1. Confirm the `develop` branch exists and add the branch rules above.
2. Create the three environments and add reviewers to `production`.
3. Configure only the secrets that have been independently verified.
4. Open a test pull request and confirm `KWR CI / certify` is required.
5. Run a tag-based release candidate and verify the workflow pauses for approval.
6. Approve it only after checking package contents, checksums, and both addon
   versions. Confirm the CurseForge and Discord results.
7. Perform a rollback drill using the prior GitHub artifact and record the
   checksum and field verification in the release notes or maintainer log.

No external configuration is claimed complete by repository changes alone.
