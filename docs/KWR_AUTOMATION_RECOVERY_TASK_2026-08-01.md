---
id: KWR-031
title: Restore truthful GitHub and CurseForge alpha automation
owner: unassigned
priority: critical
risk: high
dependencies: [GitHub Actions, CurseForge upload API]
affected_modules: [.github/workflows, tools/curseforge-upload-*.ps1, tools/kwr-maintenance-schedule.ps1, UI/ReporterMap.lua, tests]
---

# Objective

Restore the automated maintenance and alpha-publication paths so a successful
GitHub Actions run is evidence that the intended operation actually completed.

# User outcome

The public GitHub alpha remains downloadable, scheduled maintenance completes
reliably, and a tagged release either creates a real CurseForge file or fails
with an actionable error.

# Current behavior

- Scheduled maintenance passes an array splat that binds `-Lane` as the lane
  value and fails before running any maintenance work.
- Scheduled runs default to external writes despite the maintainer contract
  defining scheduled maintenance as dry-run.
- CurseForge upload scripts accept an HTTP redirect to an error page as a
  successful upload.
- Release configuration supplies UUID-like identifiers even though CurseForge
  requires the numeric project ID shown on the public project page.
- Three locally prepared workflows are absent from GitHub `main`.
- The local TOC references `UI/ReporterMap.lua`, but the checkout is missing
  the authoritative file that exists on GitHub `main`, blocking validation and
  packaging.

# Required behavior

- Scheduled workflow parameters bind by name and scheduled runs default to
  dry-run without Discord or bot writes.
- CurseForge uploads require a numeric project ID, an HTTP 2xx response, valid
  JSON, and a positive returned file ID.
- Commander project `1632632` and Sentinel project `1614463` are used by the
  release workflows.
- CI and release gates execute deterministic automation assertions.
- All repository-owned workflows are published to GitHub.
- The authoritative ReporterMap module is restored so the declared load graph
  validates and packages.

# Non-goals

- Do not publish a stable release.
- Do not rotate or expose API tokens or webhook secrets.
- Do not bypass CurseForge moderation.

# Technical constraints

- Preserve the current release artifacts and addon versions.
- Keep scheduled maintenance read-only with respect to external services.
- Never treat an HTTP redirect or HTML response as an accepted upload.

# Acceptance criteria

- [ ] Scheduled maintenance status invocation no longer misbinds `Lane`.
- [ ] Scheduled automation defaults to dry-run and disables external posts.
- [ ] CurseForge upload helpers reject nonnumeric project IDs.
- [ ] CurseForge upload helpers reject redirects, non-JSON bodies, and missing file IDs.
- [ ] A valid simulated `{"id":20402}` response is accepted.
- [ ] CI, validation, Lua tests, and build gates pass.
- [ ] The TOC load graph contains every declared Lua file.
- [ ] Corrected workflows exist on GitHub `main`.
- [ ] Commander alpha is publicly downloadable from CurseForge.

# Verification

1. Run `./tools/test-automation.ps1`.
2. Run `./tools/validate.ps1` and `./tools/knowledge-audit.ps1`.
3. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.
4. Run `./tools/build.ps1`.
5. Run the GitHub maintenance workflow in `status`/dry-run mode.
6. Run the protected tagged prerelease workflow and verify the returned
   CurseForge file ID appears on the public Commander files page after review.

# Rollback

Revert the workflow, helper, test, and documentation changes together. Disable
the tagged release workflow if CurseForge responses stop matching the reviewed
contract; retain the existing public GitHub prerelease assets.

