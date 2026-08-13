---
id: KWR-042
title: Declare Retail 12.1 interface compatibility
owner: unassigned
priority: critical
risk: low
status: completed
authority_references: [ARCHITECTURE.md, RELEASE_READINESS.md]
dependencies: [KWR-041]
affected_modules: [KnomercyWarRoom.toc, KWRSentinel]
---

# Objective

Make the packaged TOCs agree with the two Retail versions declared in public distribution metadata.

# User outcome

Commander and Sentinel load normally on supported Retail 12.0.7 and 12.1.0 clients without an out-of-date metadata warning.

# Current behavior

CurseForge declares both versions, but the Alpha 31 TOCs declare only interface 120007.

# Required behavior

Both packaged TOCs declare interfaces 120007 and 120100, and the superseding candidate is versioned Alpha 32.

# Non-goals

- Runtime behavior changes.
- Stable-channel promotion.
- Support for Classic flavors.

# Technical constraints

- Preserve exact-tag provenance.
- Keep Commander and Sentinel versions aligned.
- Retain current deterministic and package gates.

# Acceptance criteria

- [x] Commander and Sentinel TOCs declare 120007 and 120100.
- [x] Commander, embedded Sentinel, public copy, and candidate evidence identify Alpha 32.
- [x] Validation, Lua, automation, and package gates pass.
- [x] GitHub and CurseForge packages are published from the immutable Alpha 32 tag.

# Verification

1. Run the complete local gate.
2. Run hosted PR and tagged-release gates.
3. Verify package TOCs and public file metadata.

# Rollback

Keep Alpha 31 available as the prior immutable artifact and revert before tagging if validation fails.
