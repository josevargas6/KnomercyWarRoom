---
id: KWR-044
title: Publish exact release social receipts
owner: unassigned
priority: high
risk: low
dependencies: [KWR-041, KWR-042]
affected_modules: [release automation, Discord copy, tests]
---

# Objective

Make Discord release announcements and ops receipts agree with the exact
published candidate and distribution evidence.

# User outcome

Commander and Sentinel Discord messages contain current download links,
CurseForge receipts, version metadata, and honest promotion status.

# Current behavior

The tagged release workflow can substitute a current version into historical
message copy, leaving stale evidence and product relationships in the post.

# Required behavior

Keep current release copy under automated test and provide a guarded manual
workflow for corrected announcement and ops receipts.

# Non-goals

- No stable promotion.
- No unreviewed scheduled posting.
- No secret values in source or logs.

# Technical constraints

- External posts require `PUBLISH` confirmation and production webhooks.
- The workflow is read-only except for the explicitly requested Discord posts.
- Copy must state pending moderation and field-test gates honestly.

# Acceptance criteria

- [ ] Commander and Sentinel copy identifies Alpha 32.
- [ ] Copy records CurseForge file IDs 8558795 and 8558797.
- [ ] Social-copy validation rejects stale Alpha 29 and Alpha 25 claims.
- [ ] Dry-run rendering passes for both products and both receipt types.
- [ ] Corrected posts succeed through configured production webhooks.

# Verification

1. Run social-copy and automation tests.
2. Review dry-run output before enabling posts.
3. Record the successful workflow run URL.

# Rollback

Disable the workflow and revert KWR-044; Discord posts are immutable and must
be corrected with a new truthful receipt rather than deleted by automation.
