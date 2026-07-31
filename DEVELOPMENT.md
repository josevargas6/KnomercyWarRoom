# KWR Developer Package

The implementation and validation sequence for the complete product is defined
in `PRODUCT_ROADMAP.md`.

Start every continuation by reading `PROJECT_HANDOFF.md`. It records the
certified Alpha 9 baseline, agreed Alpha 10 slices, visual rules, evidence
contract, live test factors, and promotion gates. Suggestions must be folded
into existing owners rather than implemented as parallel engines.

## Requirements

- PowerShell 5.1 or newer for validation and packaging.
- World of Warcraft Retail 12.0.7 for field testing.
- A Lua 5.1+ runtime or Node.js/Fengari for offline tests. The repository test
  runner also discovers the standard Codex and local Fengari caches.
- BugSack/BugGrabber or equivalent Lua error capture is strongly recommended.

## Validate

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate.ps1
```

The validator checks TOC resolution, version consistency, legacy patch markers,
automatic action APIs, ownership of secure targeting macros, ticker ownership,
direct UI sensor reads, slash-handler duplication, and required release
documents.

## Offline pipeline test

Run all deterministic offline Lua gates from the addon root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1
```

The runner discovers explicit environment overrides, commands on `PATH`, and
the standard local Node/Fengari caches. It runs `tests/smoke.lua`,
`tests/soak.lua`, and one strict default replay, and requires each pass marker
even if the underlying runtime returns a misleading zero exit code.

Use `-Suite Smoke`, `-Suite Soak`, or `-Suite Replay` for one gate. Supply a
different replay with `-ReplayPath`; optional `-ReplayLabelPath` and
`-ReplayOutputPath` arguments pass through to the replay runner.

The smoke test loads the entire TOC dependency graph, boots the addon, and
exercises world, live-Arathi, preview, assignment, commander, journal, and
diagnostic flows. The soak test executes 500 complete pipeline refreshes and
proves that runtime samples, command history, Reporter tracks, verification
evidence, and AAR history remain bounded.

## Build packages

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build.ps1
```

The build validates first, creates a CurseForge-compatible distribution ZIP with one root addon folder, creates a separate developer ZIP, and writes SHA-256 hashes.
It then runs `tools/package-audit.ps1`, which verifies archive roots, required
files, legacy exclusion, hashes, and the extracted developer validation gates.

## In-game review

- `/kwr preview` displays the complete visual system outside PvP. It is not a substitute for live testing.
- `/kwr test` runs deterministic runtime diagnostics.
- `/kwr verify` captures assigned-team, sensor, decision, and performance truth
  for the current state; `/kwr evidence` exports the bounded transition ledger.
- Inspect `RELEASE_READINESS.md` and complete `QA_CHECKLIST.md` before promotion.

## Contribution rules

- Preserve the one Store / one MatchRuntime / one Commander architecture.
- Add no timer loop outside `MatchRuntime`.
- Add no automatic chat, addon communication, targeting, focus, macro,
  keybinding, or protected action.
- Keep player-click target/focus bindings inside `UI/CombatRoster.lua` and
  fixed player-click Instance Chat bindings inside `UI/QuickCalls.lua`.
  Prepare secure attributes only out of combat; never include spell casts,
  dynamic communication, or inferred private data.
- Treat unavailable or secret values as unknown.
- Protected health may be passed directly to a Blizzard StatusBar but must not
  enter Store, comparisons, arithmetic, persistence, or target scoring.
- Refresh `Data/MetaSnapshot.lua` and `META_SOURCES.md` together; external meta
  remains advisory and release-dated.
- Keep preview fixtures explicitly labeled and unable to replace live PvP truth.
- Every predictor change requires a deterministic diagnostic fixture.
- Every new map must declare its objective family and public data sources.