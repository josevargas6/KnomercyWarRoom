# Knomercy War Room 6.1.0-alpha.29

## Distribution summary

The Commander and Sentinel packages are prepared as a synchronized Retail
12.0.7 alpha field-test candidate. The release is intended for controlled
testing by Rated Battleground players and commanders.

## Highlights

- Tactical Command Board with compact Fight Now command HUD.
- Objective-aware assignments, enemy tracking, response planning, and AAR.
- Stable team and enemy roster presentation with evidence-backed local fight
  signals.
- Native Blizzard battlefield-map integration without an external map
  dependency.
- Optional Sentinel execution card linked to the Commander on the same client.
- No automatic targeting, casting, movement, chat, addon messaging, or other
  gameplay actions.

## Verification

- Architecture validation: passed.
- Knowledge audit: passed.
- Deterministic Lua suite: passed.
- Smoke coverage: 275 checks.
- Bounded soak: 500 refreshes; p95 0.80 ms in the recorded run.
- Replay coverage: passed.
- Commander and Sentinel package audit: generated with provenance and SHA-256.

## Field-test status

Tonight's Retail 12.0.7 field test completed with no functional, runtime,
assignment, taint, or gameplay-automation issues observed. The identified
visual repairs are now complete. Perform the final packaged visual recheck
before broad stable promotion.

## Installation

Install `KnomercyWarRoom` as the Commander addon. Install `KWRSentinel` only
when the player execution card is desired. Do not install developer archives,
workspace files, SavedVariables, or local WTF data.
