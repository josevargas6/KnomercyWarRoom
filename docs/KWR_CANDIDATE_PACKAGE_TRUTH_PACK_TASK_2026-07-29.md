---
id: KWR-041
title: Publish the exact candidate package truth pack
owner: Codex
priority: high
risk: low
dependencies: []
affected_modules:
  - tools/build.ps1
  - tools/knowledge-audit.ps1
  - knowledge/schemas/candidate-package-report-schema.json
  - tools/candidate-package-report.ps1
  - knowledge/candidate-package-report.json
  - docs/CANDIDATE_PACKAGE_TRUTH_PACK_2026-07-29.md
---

# Objective

Create one authoritative offline package receipt for the current field-test
candidate so live evidence can be tied back to exact built bytes.

# User outcome

The project owner can install, upgrade, verify, and roll back the exact
candidate package without guessing which ZIP or hash belongs to live testing.

# Current behavior

The build pipeline already emits exact ZIPs, hashes, source manifests, and a
reproducibility report, but there is no single operator-facing package truth
pack for the current candidate.

# Required behavior

- Generate one machine-readable candidate package report for the current
  candidate build output.
- Publish one human-readable package truth pack with install, upgrade, backup,
  evidence-binding, and rollback instructions.
- Tie the receipt to the exact built distribution ZIP hash.
- Record environment-limited certification gaps honestly instead of inventing
  package-trust proof that this shell cannot produce.

# Non-goals

- Do not change live gameplay logic.
- Do not claim live install or upgrade proof that has not happened yet.
- Do not add new SavedVariables or migrations.

# Technical constraints

- Reuse the existing build artifacts and reproducibility manifests.
- Keep candidate identity aligned to the active TOC version.
- Preserve the current packaging architecture instead of creating a parallel
  release system.

# Acceptance criteria

- [ ] A candidate package report JSON artifact exists for the current version.
- [ ] A human-readable candidate package truth pack exists.
- [ ] The report includes exact distribution and developer ZIP hashes.
- [ ] The report records reproducibility status and source digests.
- [ ] The report states the current environment limitation around package-audit
      runtime discovery.
- [ ] Knowledge audit validates the new artifact.

# Verification

1. Build the current candidate into a writable artifact directory.
2. Generate the candidate package report.
3. Run `./tools/knowledge-audit.ps1`.
4. Run `./tools/validate.ps1`.

# Rollback

Delete the package truth pack files and remove the knowledge-audit requirement
if the report proves misleading or redundant.
