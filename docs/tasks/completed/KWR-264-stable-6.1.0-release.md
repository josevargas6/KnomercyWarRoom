---
id: KWR-264
title: Reconcile and publish stable 6.1.0
owner: Codex
priority: critical
risk: high
status: completed
authority_references: [RELEASE_POLICY.md, RELEASE_READINESS.md, DESIGN_CONTRACT.md, ARCHITECTURE.md, AGENTS.md]
dependencies: [KWR-263]
affected_modules:
  - Core/Addon.lua
  - KnomercyWarRoom.toc
  - KWRSentinel/Core.lua
  - KWRSentinel/KWRSentinel.toc
  - .github/workflows/release.yml
  - knowledge/candidate-package-report.json
---

# Objective

Reconcile the reviewed post-Alpha 43 field-test commits into one stable 6.1.0
Commander and embedded Sentinel release without changing any existing tag or
published prerelease asset.

# Owner decision and retained risk

The product owner directed stable publication on 2026-08-15. That direction
authorizes a new `v6.1.0` release and accepts the previously disclosed live
evidence gaps as refinement telemetry. It does not create candidate-bound live
proof, certify ten-client Sentinel transport, or approve unreviewed 12.1 tuning.
Patch-dependent 12.1 data remains fail-closed.

# Acceptance criteria

- [x] Commander and embedded Sentinel TOC/runtime versions are exactly 6.1.0.
- [x] Stable GitHub and CurseForge publication semantics are deterministic and
      covered by automation tests; suffixed versions remain prereleases.
- [x] Validation, security, knowledge, Lua, soak, replay, build, extraction,
      reproducibility, and package audits pass on the final source.
- [x] Required GitHub `certify` status is green on the final PR head.
- [x] The PR merges to `main`, a new annotated `v6.1.0` tag points to that merge,
      and `v6.1.0-alpha.43` remains unchanged.
- [x] The protected production run publishes exactly five GitHub player assets,
      submits Commander and Sentinel as CurseForge `Release` files, and posts
      the synchronized release announcement.
- [x] Public hashes, manifests, file IDs, and installed-folder comparison are
      verified against the stable tag.

# Verification

1. Run `tools/certify-offline.ps1` and the full local release gate.
2. Build both packages and verify extracted runtime plus hash manifests.
3. Require the GitHub `certify` check before merge and tagging.
4. Verify the protected release run, public assets, stable channel, and local
   installed manifests without reading or exposing secrets.

# Rollback

Keep the prior Alpha 43 packages and installed-folder snapshot intact. If the
stable package fails, stop distribution, restore the snapshot, and ship a new
patch version after review; never move or recreate `v6.1.0` or Alpha 43.
