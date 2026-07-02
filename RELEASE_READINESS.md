# Release Readiness - 6.1.0-alpha.9

## Current decision

**Ready for focused in-client alpha validation. Not ready for stable public promotion.**

## Proven offline

- One authoritative Store and one MatchRuntime ticker.
- Complete TOC and version consistency.
- No legacy patch markers.
- No automatic chat, addon messages, targeting/focus, macro execution, spell
  casting, or keybinding writes; fixed quick calls execute only from an
  explicit player click.
- Secure compact-row target/focus bindings are centralized and changed only
  out of combat.
- Secure fixed Instance Chat quick calls are centralized, immutable in combat,
  and retain a compact right-click copy fallback.
- Lua 5.1 syntax for all runtime and test files.
- World, Arathi prediction, assignment, commander, preview, journal, and AAR pipeline smoke coverage.
- Reporter objective state, bounded permitted movement evidence, and minimized-view integration.
- Local kill-target selection, roster-validated assigned-team normalization,
  and explicit unknown handling for Midnight-blocked combat evidence.
- Dated Murlok RBG specialization snapshot with an explicit advisory boundary.
- Two hundred fifteen deterministic diagnostics plus a 500-refresh bounded-state soak
  and knowledge audit.
- All ten supported battlegrounds exercise lead, deficit, tie, assignment
  family, valid-location, and map-specific node-priority fixtures.
- Forty deterministic scenario combinations per map cover opening,
  stabilization, pressure, recovery, and endgame response shapes.
- GUID-based role validation prevents incompatible healer assignments.
- Bounded current-season encounter history remains explicitly distinct from
  live and last-observed evidence.
- Five-second freshness gates prevent stale score or objective evidence from
  driving live recommendations.
- `/kwr verify` includes map and team identity, source ages, complete command,
  assignment audit and rows, Reporter coverage, and transition performance.
- Versioned capabilities, composition archetypes, battle plans, counters,
  patch overlays, source authority, and bounded reviewed learning.
- Fourteen bounded specialization ratings, nine battlefield-job preferences,
  advisory Hero talent modifiers, and observed tactical ability windows all
  feed existing engines without duplicate polling or state ownership.
- Every weighted category has three or more evidence signals, three documented
  battlefield effects, and objective-plan influence.
- Objective commands publish success and abort criteria; all seven generic
  enemy archetypes have reviewed three-step counter sequences.
- Capability caching, summary reuse, render-signature skipping, and
  lightweight friendly health/aura handling reduce repeat work.
- Multi-source confidence, objective ETA, enemy intent, opportunity, momentum,
  resource economy, assignment-integrity, and five-candidate heuristic
  simulation all feed the existing Strategist and Commander path.
- Low-confidence calls become conservative; unknown information remains
  unknown and cannot inflate the confidence budget.
- Counterfactual decision reviews are bounded developer logs and never
  self-modify battlefield doctrine.
- Manual AAR export reuses the existing AAR subscriber and copy dialog, records
  bounded evidence only, has no automatic chat behavior, and can be disabled.
- Export sections explicitly separate recommendations, evidence, execution,
  known outcomes, enemy observations, and unavailable facts.
- Live performance telemetry and enforced strategic refresh budgeting.

## Requires Retail proof

- Actual map-art dimensions and marker alignment on all ten maps.
- PvP scoreboard fields under Retail 12.0.7 secret-value behavior.
- Event-fed teammate-target/nameplate last-seen behavior.
- Live objective-marker changes; instanced player coordinates are unavailable
  through the public map-position API.
- Reporter pressure/hotspot quality across objective families.
- UI clipping and scaling at common resolutions.
- Match-complete and instance-exit journal behavior.
- Taint, blocked-action, CPU, and memory checks.
- Assigned-team resolution across native, mercenary, and cross-faction matches.
- Enemy/friendly secure row click behavior through a complete combat cycle.
- Fixed Quick Call behavior and taint through a complete battleground cycle.
- Kill-target quality across melee and ranged local-fight conditions.

## Intentionally incomplete

- Enemy buffs not explicitly observed remain unknown.
- Defensive and trinket readiness is never assumed. Retail 12 blocks the combat
  log subscription formerly used for observations, so live state remains unknown.
- An enemy's health may be displayed directly by a protected StatusBar when the
  client permits it, but secret health cannot be used in target scoring.
- External meta data is release-dated and cannot reveal an individual enemy's
  actual talents, gear, enchants, or PvP build.
- Reporter cannot plot an enemy whose map position Blizzard does not safely expose; roster knowledge alone never becomes a fabricated dot.
- Predictions for public widgets not exposed by Blizzard remain low-confidence or unknown.

Promotion requires the live sections of `QA_CHECKLIST.md` to pass with captured evidence.
