---
id: KWR-289
title: Reject invalid and expired evidence at the shared truth gate
owner: Codex
priority: high
risk: medium
status: completed
dependencies: [KWR-281, KWR-284]
affected_modules: [Util, TruthContract, tests]
authority_references: [AGENTS.md, PRODUCT_ROADMAP.md, RELEASE_READINESS.md]
---

# Objective

Repair the shared evidence-time primitive used by the production TruthContract
under OVR-02. Future timestamps currently clamp to age zero, invalid TTLs default
to unlimited lifetime, and EvidenceUsable trusts a cached fresh flag indefinitely.
The boolean false value is also lost through an and/or return expression.

# User outcome

Invalid or expired truth cannot keep aggressive-commit permission open. Explicit
false observations remain distinct from missing observations.

# Required behavior

Require finite nonnegative observation time, TTL and clock values; future times
remain unverified. Preserve original observation time and false/zero values.
EvidenceUsable rechecks age at use time without mutating the record. Explicit
zero TTL retains the existing unbounded-reference contract; missing/invalid TTL
must not become zero. Test the actual production TruthContract's commit gate.

# Non-goals

Complete per-field FactStore/BoardState migration, source conflict resolution,
objective IDs and tactical eligibility remain open OVR-02 work. No new mutable
store, persisted schema, installation or confidence upgrade.

# Technical constraints

Keep the existing Evidence and EvidenceUsable APIs and state names. Reuse the
production TruthContract owner. Existing valid positive-TTL evidence keeps its
boundary semantics; evidence construction metadata describes construction time.

# Acceptance criteria

- [x] Future/invalid times, TTLs and clocks cannot be fresh or usable.
- [x] False/zero survive; nil/protected values remain unknown.
- [x] Previously fresh records expire at use time and remain unmodified.
- [x] The real truth contract rejects future or expired core evidence.
- [x] Source and extracted-package checks pass with recorded hashes.

# Verification

Controlled clock tests across fresh, expiry, future, negative, NaN, infinity,
missing and protected cases; actual Contract coreFresh/aggressiveCommitAllowed
checks. Run smoke and validation, then include in the next combined package.

September 6 source Smoke passes with `tests/fixtures/evidence_freshness.lua`.
The fixture proves the actual production Contract grants its existing permission
for valid inputs, then withdraws it for future or expired core score evidence.
The follow-up dirty-source package `evidence-freshness-20260907-package` passed
validation, extracted Commander/developer smoke and 500-refresh soak, knowledge,
DevTools lifecycle, Sentinel transport, and four ZIP-hash verification. Its
package audit records 396 distribution entries, 9,011 developer entries, six
DevTools entries, and twelve Sentinel entries. Clean reproducibility was
intentionally skipped for this interim package, so it is neither installed nor a
release candidate. See the recorded
`artifacts/evidence-freshness-20260907-package/KWR_6_1_1_ALPHA_12_PACKAGE_AUDIT.json`
and [ADR-005](../architecture/ADR-005-evidence-time.md).

# Rollback

Revert primitive/tests together without restoring any lost SavedVariables; this
is transient evidence handling. Preserve earlier observation timestamp fixes.
