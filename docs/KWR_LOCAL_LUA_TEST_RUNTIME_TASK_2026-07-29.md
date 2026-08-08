---
id: KWR-051
title: Restore reliable local Lua smoke, soak, and replay execution
owner: unassigned
priority: high
risk: medium
dependencies: []
affected_modules:
  - tests/smoke.lua
  - tools/test-lua.ps1
  - tools/replay-test-runner.lua
  - Data/ScenarioCalibration.lua
  - Data/ScenarioAdversarialCalibration.lua
  - Data/ProblemSignalRegistry.lua
  - Runtime/Strategist.lua
  - UI/MainWindow.lua
  - Core/Diagnostics.lua
  - tools/build-scenario-calibration.ps1
  - tools/build-scenario-adversarial-calibration.ps1
  - tools/offline-completion-audit.ps1
  - tools/candidate-package-report.ps1
  - docs/OFFLINE_COMPLETION_AUDIT_2026-07-29.md
  - docs/FIELD_MACHINE_PREP_2026-07-29.md
  - docs/CANDIDATE_PACKAGE_TRUTH_PACK_2026-07-29.md
  - DEVELOPMENT.md
  - CONTRIBUTING.md
  - AGENTS.md
---

# Objective

Make the repository's deterministic Lua smoke, soak, and replay checks runnable
from this Windows workspace without requiring a globally installed Lua command.

# User outcome

Maintainers and Codex can run the offline Lua gates through one repository
command, receive a hard failure for compile/runtime errors, and avoid treating a
Fengari zero exit code as success when the required pass marker is absent.

# Current behavior

Node.js and Fengari may exist in Codex or repository-local caches without being
available on `PATH`. Direct smoke execution is also blocked because the main
smoke chunk exceeds Lua's 200-active-local limit. Fengari can report that
compile error without returning a failing process exit code.

# Required behavior

- Keep the smoke harness below Lua's active-local limit without changing addon
  behavior or assertion coverage.
- Discover explicit, `PATH`, and known local Node/Fengari or native Lua
  runtimes.
- Run smoke, soak, and strict replay checks through one PowerShell entrypoint.
- Require the appropriate pass marker as well as a zero process exit code.
- Document the repository command as the normal offline test path.
- Restore the documented live calibration attachment through exact scenario IDs
  or the selected scenario's unique map/phase pair.
- Keep problem-signal audit metadata separate from actual problem definitions.

# Non-goals

- Do not change strategy selection, assignments, SavedVariables, UI design, or
  TOC loading order beyond restoring intended calibration and health-update
  behavior already covered by deterministic checks.
- Do not replace live Retail, combat-lockdown, secure-frame, taint, or
  battleground field testing.
- Do not download or install runtimes automatically.

# Technical constraints

- Support PowerShell 5.1 or newer.
- Preserve direct Lua 5.1+ and `fengari-node-cli` compatibility.
- Keep runtime discovery read-only and allow explicit environment overrides.
- Keep replay execution deterministic and strict by default.

# Acceptance criteria

- [x] `tests/smoke.lua` compiles and prints `KWR_SMOKE_PASS`.
- [x] `tests/soak.lua` prints `KWR_SOAK_PASS`.
- [x] The default replay prints `KWR_REPLAY_RUN_PASS` in strict mode.
- [x] Missing pass markers fail even when the runtime exits with code zero.
- [x] The runner works with the existing cached Node/Fengari runtime.
- [x] Developer instructions use the repository runner.
- [x] The strategist attaches the unique reviewed and adversarial calibration
      rows for the selected map/phase without changing the selected plan.

# Verification

1. Run
   `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.
2. Run
   `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate.ps1`.
3. Run
   `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\knowledge-audit.ps1`.
4. Confirm smoke, soak, and replay pass markers are present.

## Verification evidence

- Unified runner: `KWR_SMOKE_PASS checks=275`.
- Soak: `KWR_SOAK_PASS refreshes=500`, with bounded history and evidence.
- Replay: `KWR_REPLAY_RUN_PASS` and `KWR_LUA_TESTS_PASS suite=All`.
- Validation: 123 Lua files, 0 errors, 0 warnings.
- Knowledge audit: 0 errors.
- Runtime preflight: cached Node/Fengari readable and
  `packageAuditReady: true`.

# Scope decision

Once the smoke chunk compiled, it exposed that the live scenario library and
the generated calibration corpus use different scenario ID schemes. The data
contains exactly one reviewed and one adversarial row per map/phase. Restoring
the previously documented attachment is required for the existing deterministic
assertions, so that repair is included and its generator output is kept in sync.
The now-running suite also exposed module registration metadata being audited as
a problem type; the audit now considers only table-valued definitions. Existing
health-update and diagnostic checks also exposed ambiguous card fallback in the
frame mock plus stale battlefield-card and spotlight-height expectations; those
paths now use their explicit owners and current layout constants.

# Rollback

Remove `tools/test-lua.ps1`, restore the direct Fengari commands in developer
documentation, remove the smoke assertion scope, and restore exact-ID-only
calibration lookup. No persisted state requires rollback.
