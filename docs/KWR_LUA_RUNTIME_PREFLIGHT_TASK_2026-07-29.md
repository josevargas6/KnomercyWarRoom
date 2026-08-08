---
id: KWR-042
title: Publish the local Lua runtime preflight for package certification
owner: Codex
priority: high
risk: low
dependencies: []
affected_modules:
  - tools/package-audit.ps1
  - tools/knowledge-audit.ps1
  - knowledge/schemas/runtime-preflight-schema.json
  - tools/runtime-preflight.ps1
  - knowledge/runtime-preflight.json
  - docs/FIELD_MACHINE_PREP_2026-07-29.md
---

# Objective

Create one authoritative offline runtime-preflight report for the deterministic
Lua package-audit path.

# User outcome

The owner can tell exactly why package certification is ready or blocked on the
local machine before starting live field sessions.

# Current behavior

KWR package builds, hashes, manifests, and reproducibility reports are working,
but the extracted package-audit runtime depends on local Node/Fengari discovery
and file accessibility.

# Required behavior

- Generate one machine-readable runtime-preflight report.
- Publish one human-readable machine-prep guide for the package-cert path.
- Distinguish clearly between:
  - Node on PATH,
  - bundled Node availability,
  - Fengari command availability,
  - local lua-tools package presence,
  - local lua-tools package readability.
- Record whether the machine is currently ready for extracted package-audit
  certification.

# Non-goals

- Do not fabricate a working Lua runtime if the machine does not have one.
- Do not claim package certification if the runtime is blocked.
- Do not change live gameplay logic.

# Technical constraints

- Reuse local filesystem evidence only.
- Keep the report tied to the active candidate version.
- Make the output understandable to an operator, not just a script author.

# Acceptance criteria

- [ ] A runtime-preflight JSON artifact exists.
- [ ] A machine-prep Markdown guide exists.
- [ ] Knowledge audit validates the new artifact.
- [ ] The report states whether package-audit is currently ready on this
      machine.

# Verification

1. Run `./tools/runtime-preflight.ps1`.
2. Run `./tools/knowledge-audit.ps1`.
3. Run `./tools/validate.ps1`.

# Rollback

Delete the preflight files and remove the audit requirement if they stop being
useful or truthful.
