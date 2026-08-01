# Deep Release Audit — 2026-08-01

## Candidate

- Commander: `6.1.0-alpha.29`
- Sentinel: `6.1.0-alpha.25`
- Intended Commander artifact: `KWR_6_1_0_ALPHA_29_DISTRIBUTION.zip`

## Verified locally

- Architecture and TOC validation: passed.
- Security audit: passed; one expected warning because this WoW checkout has no `.git` metadata.
- Knowledge audit: passed.
- Runtime preflight: passed.
- Offline completion audit: passed.
- Smoke, soak, and replay suite: passed.
- Extracted distribution/developer package audit: passed.
- Distribution package: 128 entries, Commander TOC present, release exclusions honored.
- Developer package: 4,927 entries, extracted validation and tests passed.
- Sentinel package: 13 entries, hash verified.

## Release observations

- Commander and Sentinel intentionally have separate alpha versions. They must not be advertised as one synchronized version without an explicit Sentinel release decision.
- The full local reproducibility wrapper exceeded the local execution timeout. The direct extracted package audit passed; the complete reproducibility result still needs to be obtained in GitHub Actions or a longer-running release environment.
- The local folder is not a Git worktree and has no configured remote or authenticated `gh` CLI. No commit, push, GitHub release, CurseForge upload, or Discord post was performed from this checkout.

## Required launch actions

1. Restore or clone the repository as a real Git worktree.
2. Review and commit the intended release changes.
3. Push to the protected release branch or create the version tag through the repository release flow.
4. Confirm the production environment approval and CurseForge/Discord secrets.
5. Run the tagged release workflow and inspect its artifacts, checksums, CurseForge file IDs, GitHub release, and Discord posts.
6. Record public URLs and the final workflow run in the release handoff.

## Automation policy

- Weekly non-urgent maintenance remains scheduled through `kwr-automated-maintenance.yml` and its weekly reconciliation lane.
- Hotfixes remain tag-driven through the protected release workflow.
- External writes require explicit production credentials and approval; this audit did not bypass that safety boundary.
