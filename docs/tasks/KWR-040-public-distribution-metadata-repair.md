---
id: KWR-040
title: Repair public distribution metadata and webhook aliases
owner: unassigned
priority: critical
risk: medium
dependencies: []
affected_modules: [.github/workflows, tools]
---

# Objective

Prevent release automation from publishing World of Warcraft Retail packages with missing CurseForge game-version metadata, and connect the existing Discord webhook secret names to the maintained workflows.

# User outcome

Commander and Sentinel releases are classified as Retail on CurseForge, while scheduled and release Discord updates use the already-configured repository secrets.

# Current behavior

The release workflow silently omits invalid game-version IDs. CurseForge then assigns an unrelated game flavor. Several Discord workflows reference canonical secret names while the repository contains legacy aliases.

# Required behavior

CurseForge production uploads fail closed unless numeric version IDs are configured. Existing Discord secret aliases remain supported without exposing or copying secret values.

# Non-goals

- Promoting an alpha build to stable release status.
- Deleting historical CurseForge files.
- Bypassing protected production gates.

# Technical constraints

- Keep credentials in GitHub secrets.
- Preserve explicit confirmation for external writes.
- Retain dry-run behavior for local verification.

# Acceptance criteria

- [ ] Commander and Sentinel release uploads reject blank or nonnumeric CurseForge game-version IDs.
- [ ] Maintenance, daily, and Sentinel release workflows recognize the configured Discord secret aliases.
- [ ] Automation tests cover both safeguards.
- [ ] Retail version IDs are configured without exposing credentials.
- [ ] Correctly classified public files are verified after a protected upload.

# Verification

1. Run automated validation and automation tests.
2. Run the protected release workflow using configured Retail IDs.
3. Verify both CurseForge project file listings identify Retail 12.1.0 and 12.0.7.

# Rollback

Revert the workflow commit and restore the previous repository variable value. Existing published files remain unchanged.
