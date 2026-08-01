# KWR field machine prep — 2026-07-29

This guide covers the local deterministic Lua runtime used by the repository
test runner and `package-audit.ps1`.

## What this is for

KWR already has:

- exact build artifacts
- exact hashes
- exact source and reproducibility manifests
- exact candidate package receipt

Source smoke, soak, and replay checks run through:

`powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`

The extracted runtime certification path for packaged copies of
`tests/smoke.lua` and `tests/soak.lua` still depends on the same machine
runtime.

## Authoritative machine-state report

Run:

`powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\runtime-preflight.ps1`

Then review:

- [knowledge/runtime-preflight.json](D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom\knowledge\runtime-preflight.json)

## What a ready machine looks like

- a readable Node runtime exists
- a readable Fengari CLI exists
- the local Fengari package files are readable
- `packageAuditReady` is `true`

## What blocked means

If `packageAuditReady` is `false`, the machine is not ready to finish the
offline extracted-runtime package certification step.

Common reasons:

- no `node` on PATH
- no readable bundled Node path
- Fengari command exists but points to unreadable package files
- a previous temp-installed runtime is present but ACL-blocked

## Current July 29, 2026 state

The current preflight for this workspace shows:

- bundled Node path exists
- no direct `node` on PATH in this shell
- local `kwr-lua-tools` package exists
- Fengari entrypoints are readable
- the underlying package files are readable
- `packageAuditReady` is `true`

That means the deterministic source checks are available and this machine has
the runtime prerequisite needed to run the extracted package-cert path.

## Best next machine action

Run:

- `tools/package-audit.ps1`
- `tools/candidate-package-report.ps1`

Then the package truth pack can be refreshed with a passing local package-audit
state. If a later preflight reports blocked package files, replace or reinstall
the local Fengari runtime into a readable location before rerunning those
commands.
