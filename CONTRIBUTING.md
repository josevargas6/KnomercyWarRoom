# Contributing to Knomercy War Room

KWR is a player-controlled Rated Battleground command assistant. Contributions
must preserve one authoritative Store, one MatchRuntime, one Strategist, and one
Commander.

## Development flow

1. Branch from `develop`.
2. Keep changes bounded to one decision, truth, UI, or performance concern.
3. Add a deterministic diagnostic for every behavior change or defect.
4. Run:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate.ps1
   powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\knowledge-audit.ps1
   fengari tests\smoke.lua
   fengari tests\soak.lua
   ```

5. Open a pull request into `develop`. Promotion from `develop` to `main`
   requires the applicable live checks in `QA_CHECKLIST.md`.

## Non-negotiable rules

- No automatic targeting, focus, chat, macros, keybindings, or spell actions.
- Never compare, persist, sort, or calculate with a secret value.
- Unknown data remains unknown.
- No independent ticker or parallel command brain.
- Preview data never substitutes for live PvP truth.
- Combat HUD remains concise; detailed reasoning belongs in `/kwr explain`.
- Do not commit SavedVariables, account data, screenshots containing private
  player information, generated ZIP files, or extracted packages.

## Releases

Version metadata must agree between `KnomercyWarRoom.toc`, `Core/Addon.lua`,
documentation, diagnostics, and the changelog. A `v*` tag triggers certified
package generation and creates a GitHub prerelease.
