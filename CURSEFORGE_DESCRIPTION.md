# Knomercy War Room

Knomercy War Room is a player-controlled Rated Battleground command system for World of Warcraft Retail.

## Commander experience

- Expanded Tactical Command Board as the primary interface.
- Compact synchronized command HUD with score, win condition, personal
  assignment, and a persistent local kill/healer-control card.
- Always-running Reporter objective intelligence with movement evidence only
  where Blizzard exposes permitted coordinates.
- Native `Shift-M` battlefield-map guidance without an external map dependency.
- Objective control and map-status reporting.
- Team roster and deterministic one-player/one-job assignments.
- Enemy Tracker with scoreboard identity, safe last-seen evidence, priority marks, and notes.
- Compact Team/Enemy health bars with role symbols, secure click target/focus,
  and an evidence-backed local kill-target glow.
- Explicitly unknown live defensive/trinket state under Retail 12 restrictions,
  plus a dated advisory RBG meta snapshot.
- Persistent match history, learning summary, and After Action Review feedback.
- Developer-only non-live preview mode for interface review outside PvP; not part of the packaged tester build.

## Decision system

KWR reads public battleground score, objective, map, and friendly-roster state, projects the current win path with map-specific rules, then publishes one NEXT / WHO / WHEN command and its measured reason.

Supported families include node, hybrid, flag, orb, cart, and resource battlegrounds.

## Player control and safety

KWR never sends chat or addon messages automatically, changes keybindings,
casts abilities, or performs protected combat actions automatically. Compact roster rows can
target on left-click and focus on right-click through Blizzard secure templates;
fixed Quick Calls can send one reviewed phrase to Instance Chat on the player's
explicit click. Their bindings are prepared out of combat. Unavailable combat
facts remain unknown, and dynamic calls remain manual.

## Alpha status

Version 6.1.0-alpha.29 adds battlefield truth contracts, monitored assignments,
objective-aware candidate decisions, complete response packages, and optional target/cast
clarity, bounded execution assessment, and retains structured
manual post-match evidence export,
stale-evidence rejection, assignment validation, richer field-test reports,
one-click fixed battlefield calls with visible confirmation and a compact fallback,
aligned decision tables, commander-focused
information hierarchy, coordinated window layering, direct player specialization
truth, transition-safe lazy UI, enhanced combat rosters, and tactical maps alongside contextual strategy, composition, counterplay,
learning, provenance, bounded specialization capability ratings, battlefield
job preferences, observed tactical ability windows, sourced visible/last-seen
locations, explicit objective success/abort criteria, and reduced repeat
runtime/UI work, plus a reviewed expert scenario corpus, bounded enemy-response
planning, production KWR brand assets, and a guarded CurseForge commander
distribution path. It passes offline
validation, 275 deterministic diagnostics, a 500-refresh bounded-state soak,
live enemy-token binding, reassessment
feedback, and final-score AAR handling. Live Retail 12.0.7 field testing,
including secure-row taint checks,
Tonight's Retail 12.0.7 field test completed with no functional bugs observed.
The identified visual repairs are complete. The current package is a
field-tested candidate and should be promoted to stable after final packaged
visual verification.