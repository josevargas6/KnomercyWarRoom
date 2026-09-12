---
id: KWR-292
title: Record installed Retail client metadata compatibility
owner: Codex
priority: high
risk: low
status: completed
dependencies: [KWR-042]
affected_modules: [tools/client-build-preflight.ps1, validation, field-verification]
authority_references: [RELEASE_READINESS.md, BATTLEGROUND_VERIFICATION.md]
---

# Objective

Make the exact Retail client version and declared interface contract observable
before a field session, instead of relying on a stale TOC assertion alone.

# Required behavior

Read the active `wow` product row from a specified `.build.info`, derive its
Retail interface number, compare it to both companion TOCs and the active patch
pack, and write a machine-readable receipt. A mismatch can fail automation only
when the caller requests `-FailOnMismatch`.

# Non-goals

The check does not load an addon, invoke game APIs, prove secure-frame safety,
validate a package archive, or approve a release. Those are separate live and
distribution gates.

# Acceptance criteria

- [x] The installed 12.1.0.69587 Retail client produces interface `120100`.
- [x] Commander, Sentinel and active `PatchData` metadata agree with that client.
- [x] The result records its limited metadata-only scope and gives a safe next step.
- [x] A fixture proves that a missing declared client interface is rejected.

# Verification

`tools/test-client-build-preflight.ps1` exercises matching and mismatched
metadata. The current local receipt is
`knowledge/client-build-preflight.json`; it is tied to the installed client and
source metadata only, not to an archive or a clean Git candidate.

# Rollback

Remove the preflight tool and receipt. It stores no SavedVariables and does not
change installed add-ons.
