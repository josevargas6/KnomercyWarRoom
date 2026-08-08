---
id: KWR-238
title: Expand all-map scenario matrix beyond the ten-scenario floor
owner: Codex
priority: high
risk: medium
dependencies: []
affected_modules:
  - knowledge/rbg-scenario-matrix.json
  - tests/smoke.lua
  - tools/build-starter-corpus.ps1
  - tools/build-foundation-depth-corpus.ps1
  - tools/build-scenario-calibration.ps1
  - tools/build-scenario-adversarial-calibration.ps1
---

# Objective

Increase the all-map scenario matrix beyond the current ten-scenario floor by
adding equal expert-tier second-wave scenarios to every supported rated
battleground map.

# User outcome

KWR’s offline source-of-truth matrix covers more expert-important battleground
situations per map, not just deeper review on the same initial scenario set.

# Current behavior

- Every supported map currently has ten scenarios.
- Corpus and calibration depth are strong, but they still grow from the same
  ten-scenario per-map source.

# Required behavior

- Increase `targetBaseScenariosPerMap` evenly across all supported maps.
- Add the same second-wave scenario count to every supported map.
- Keep the new scenarios production-grade, map-specific, and commander-usable.
- Regenerate the full corpus and calibration chain from the expanded matrix.

# Non-goals

- No fake live evidence.
- No placeholder scenario IDs or generic filler language.

# Technical constraints

- Preserve current supported map keys and profile names.
- Keep deterministic build/test flow green after regeneration.
- Maintain equal depth across all supported rated battlegrounds.

# Acceptance criteria

- [ ] The scenario matrix target count increases evenly for all supported maps.
- [ ] Every supported map has the new second-tier scenarios.
- [ ] Corpus and calibration rebuild from the deeper matrix successfully.
- [ ] Validation, knowledge audit, and Lua tests pass after regeneration.

# Verification

1. Rebuild starter corpus.
2. Rebuild foundation depth corpus.
3. Rebuild calibration artifacts.
4. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate.ps1`.
5. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\knowledge-audit.ps1`.
6. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.

# Rollback

Restore the previous matrix target, remove the second-tier scenarios, and
rebuild the prior corpus/calibration artifacts.
