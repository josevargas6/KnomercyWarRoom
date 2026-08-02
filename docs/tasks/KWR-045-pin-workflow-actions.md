---
id: KWR-045
title: Pin all Commander workflow actions
owner: unassigned
priority: high
risk: low
dependencies: []
affected_modules: [GitHub Actions]
---

# Objective

Replace moving action tags in every Commander workflow with reviewed immutable
commit SHAs.

# User outcome

CI, release, packaging, Discord, and maintenance automation execute the exact
reviewed action code instead of silently changing underneath the project.

# Current behavior

Several workflows still reference moving major-version tags and one completed
run reports a deprecated Node.js action runtime.

# Required behavior

Pin official actions to the versions already used by CI, pin the GitHub App
token action to v3.2.0, and pin the BigWigs packager to v2.5.1.

# Non-goals

- No workflow behavior or permission expansion.
- No release or deployment trigger.

# Technical constraints

- Preserve existing inputs, permissions, and fail-closed behavior.
- Record the human-readable release beside each SHA.

# Acceptance criteria

- [ ] No Commander workflow references a moving `@vN` action tag.
- [ ] Automated validation and workflow contract tests pass.
- [ ] Hosted CI passes with the pinned actions.

# Verification

1. Search every workflow `uses:` declaration.
2. Run validation and automation contract tests.
3. Verify hosted CI on the PR and merged main.

# Rollback

Revert KWR-045 to the previously reviewed action references.
