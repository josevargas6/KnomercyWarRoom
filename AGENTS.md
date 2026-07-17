# Repository Guidelines

## Mission

KnoMercy War Room is a purpose-built Rated Battleground war-room addon. Every change should strengthen strategy, map intelligence, assignments, enemy analysis, cooldown awareness, or commander clarity for real in-game use.

## Structure

`Core/` owns bootstrap, utilities, and the Store. `Runtime/` contains sensors, match runtime, strategist, assignments, combat intel, and verification. `UI/` holds commander surfaces. `Data/` stores maps, doctrine, rules, and reviewed meta snapshots. `Features/` is for bounded optional systems. Tests live in `tests/`; validation, build, and audit scripts live in `tools/`.

## Operating rules

- Inspect existing owners, state, and patterns before editing. Extend existing modules before creating new ones.
- Preserve player control. Never automate protected actions, communication, keybindings, casting, targeting, focus, or movement.
- Treat unavailable or secret-backed game facts as unknown. Do not invent live data or unsupported strategic truth.
- Keep data, logic, and presentation separated where practical. Use local-first Lua modules, defensive checks, and four-space indentation.
- Do not commit credentials, SavedVariables, WTF data, local diagnostics, generated packages, or account identifiers.
- Keep changes small and reviewable. Do not silently remove features, rename major systems, or duplicate state owners.

## Validation

Run before handoff:

```powershell
./tools/security-audit.ps1
./tools/validate.ps1
./tools/knowledge-audit.ps1
fengari tests/smoke.lua
fengari tests/soak.lua
./tools/build.ps1
```

Strategic behavior changes require deterministic assertions plus `/kwr verify`, `/kwr bug`, or AAR evidence where live Retail behavior matters.

## GitHub and automation safety

- Open PRs against `develop`; promote reviewed changes from `develop` to `main`.
- Keep GitHub Actions permissions minimal and never run untrusted PR code with production secrets.
- Use protected environments and human approval for releases, CurseForge uploads, Discord announcements, and production deployments.
- Codex automations may audit, report, and prepare bounded draft changes. They must not merge, tag, publish, deploy, rotate secrets, or change strategic truth without explicit human approval.

## Definition of done

A change is complete when it fits the existing architecture, improves gameplay or operational safety, creates no duplicate system, remains readable, and includes validation and rollback instructions.
