---
id: KWR-041
title: Enforce release tag provenance integrity
owner: unassigned
priority: critical
risk: medium
dependencies: [KWR-040]
affected_modules: [.github/workflows, tools]
---

# Objective

Ensure every tagged prerelease asset is built from the exact commit named by its release tag.

# User outcome

GitHub, CurseForge, hashes, and build provenance all describe one immutable source revision.

# Current behavior

A manually dispatched rerun accepts a release tag but checks out the workflow branch. It can therefore replace assets on an older tag with packages built from newer source.

# Required behavior

The release job checks out the requested tag and fails unless `HEAD` is exactly at that tag before packaging or external publication.

# Non-goals

- Moving or rewriting an existing Git tag.
- Promoting the alpha channel to stable.
- Changing addon runtime behavior.

# Technical constraints

- Preserve tag-driven pushes and manual recovery dispatches.
- Keep existing protected production credentials and publication steps.
- Never force-update a public tag.

# Acceptance criteria

- [ ] Manual release dispatch checks out `inputs.release_tag`.
- [ ] Tag pushes continue to check out the pushed tag.
- [ ] The job proves that checked-out `HEAD` exactly matches the requested tag.
- [ ] Automation tests lock both safeguards.
- [ ] Alpha 30 assets are rebuilt from the immutable Alpha 30 tag.

# Verification

1. Run validation, security audit, and automation tests.
2. Run hosted CI.
3. Dispatch Alpha 30 and inspect the published provenance commit and tag.

# Rollback

Revert the workflow commit. Do not move or delete the public tag.
