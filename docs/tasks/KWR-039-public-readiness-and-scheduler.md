---
id: KWR-039
title: Prove public readiness and restore governed Codex scheduling
owner: unassigned
priority: high
risk: medium
dependencies: [GitHub Actions, Codex desktop automations]
affected_modules: [repository workflow, release evidence, maintainer documentation]
---

# Objective

Audit every KWR GitHub repository and the live addon deployment, restore the
documented source-control boundary, and configure a read-only Codex scheduler
that continuously reports release-readiness drift.

# User outcome

Maintainers receive a truthful public-readiness verdict backed by local and
GitHub evidence, while recurring Codex checks detect drift without modifying
repositories, publishing releases, or touching production credentials.

# Current behavior

The live WoW addon directories are correctly outside Git, but the documented
clean development checkouts and weekly Codex automation are absent. The main
repository's `develop` branch is materially behind `main`, stale remote branches
remain, and some freshly checked-out generated Lua files are immediately dirty
because committed line endings conflict with `.gitattributes`.

# Required behavior

- Keep live addon directories as deployment targets and GitHub clones as source.
- Run the complete local validation and packaging gates from a clean checkout.
- Inventory public/private repository state, open work, branches, and CI evidence.
- Correct documentation that claims nonexistent local or scheduled state.
- Configure a read-only Codex readiness audit for the registered project.
- Record blockers that require repository-owner review or external credentials.

# Non-goals

- Do not merge, delete remote branches, publish stable builds, upload to
  CurseForge, post to Discord, rotate secrets, or alter gameplay behavior.
- Do not initialize Git inside a live WoW addon directory.

# Technical constraints

- GitHub remains the only release source.
- Scheduled Codex work is read-only and may not create commits, PRs, releases,
  deployments, uploads, announcements, or credential changes.
- Production publication remains behind reviewed GitHub workflow gates.

# Acceptance criteria

- [x] Clean development checkouts exist outside the WoW AddOns directory.
- [x] Repository and branch drift is documented with current evidence.
- [x] Validation, security, knowledge, deterministic tests, and build gates pass.
- [x] A read-only Codex scheduled audit is active and its configuration is verified.
- [x] Maintainer documentation reflects the actual scheduler and checkout state.
- [x] Remaining public-release blockers identify an owner and verification path.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `./tools/security-audit.ps1` and `./tools/knowledge-audit.ps1`.
3. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.
4. Run `./tools/test-automation.ps1` and `./tools/build.ps1`.
5. Inspect all four GitHub repositories, open work, branches, and latest CI state.
6. View the Codex automation after creation and confirm read-only scope.

## Verification result

- Live and clean-source gates passed, including reproducibility and extracted
  package audits. Both Commander distribution packages contain 129 entries.
- Source `test-lua.ps1`, replay, automation-contract, social-copy, and Discord
  dry-run checks pass after restoring their missing dependencies.
- `kwr-weekly-security-audit` is active and its stored prompt is read-only.
- Draft PR 20 records the `main`/`develop` reconciliation need but is not
  mergeable without an owner-reviewed conflict-resolution branch.

# Rollback

Disable or delete the Codex automation, revert this documentation change, and
remove only the newly created clean checkouts. The live addon deployment and
all external publication surfaces remain unchanged.
