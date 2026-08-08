---
id: KWR-063
title: Add branch-family evidence to generated corpus labels and outcomes
owner: Codex
priority: high
risk: low
dependencies: [KWR-060, KWR-061, KWR-062]
affected_modules: [tools/build-starter-corpus.ps1, tools/build-foundation-depth-corpus.ps1, tests/golden, tests/outcomes]
---

# Objective

Teach the offline corpus to carry branch-family evidence so labels and outcomes
do not only say what was acceptable, but also what strategic branch type the
decision represented.

# User outcome

KWR’s replay labels and outcome reviews become more useful for future learning,
calibration, and branch-aware review because they explicitly encode map-specific
decision-family evidence.

# Current behavior

- Starter labels and outcomes contain valid plan/action/success/abort data.
- They do not yet explicitly encode branch families such as hold, rotate,
  collapse, split, recover, bait, deny, escort, return window, or late-game
  score protection.

# Required behavior

- Add generated branch-family metadata to golden labels.
- Add generated branch-family metadata to outcome reviews.
- Preserve the metadata across reviewed variants and adversarial cases where
  applicable.
- Rebuild generated corpus files from the updated scripts.

# Non-goals

- Changing runtime strategy selection in this task.
- Claiming field-reviewed proof beyond the current synthetic corpus.

# Technical constraints

- Keep the current schema-valid artifacts intact.
- Use additive metadata rather than breaking required schema fields.
- Keep branch evidence deterministic and map-authentic.

# Acceptance criteria

- [ ] Generated golden labels include branch-family evidence.
- [ ] Generated outcome reviews include branch-family evidence.
- [ ] Generated reviewed variants preserve and deepen branch evidence.
- [ ] Rebuilt corpus passes audit and test gates.

# Verification

1. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build-starter-corpus.ps1`.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build-foundation-depth-corpus.ps1`.
3. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\corpus-audit.ps1`.
4. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.
5. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate.ps1`.

# Rollback

Remove the added metadata blocks and regenerate the previous corpus artifacts.
