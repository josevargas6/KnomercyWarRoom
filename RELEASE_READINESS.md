# Release Readiness - 6.1.0-alpha.40

This is the sole current-version, blocker, and promotion-status authority.
GitHub committed content is the canonical development source; the live AddOns
folder is deployment evidence only after package-manifest verification.

## Current decision

**Alpha 40 is the composition-aware opener candidate; Alpha 39 is the deployed
managed-Sentinel-layout candidate; Alpha 36 remains the verified public prerelease.**
The recovery PR, KWR-047 source governance, package manifests, installed-folder
comparisons, and protected release workflow passed on 2026-08-08. Alpha 37
Commander and Sentinel were deployed together on 2026-08-09 from the certified
candidate packages: Commander has 388 exact files and Sentinel has 9 exact
files, with zero missing, changed, or extra entries. Both addons are enabled
for the active `Verite-Bladefist` character, so Sentinel's reviewed same-client
`KWR.SentinelBridge` will activate on the next client load. Alpha 38 adds the
reviewed bounded `KWRSync1` cross-client transport. Alpha 39 adds managed
Sentinel docking beside active Commander UI. Alpha 40 expands every supported
map to fifteen theory-reviewed opening branches, selected by friendly/enemy
composition matchups and qualified roster tiers. It also activates the
1,000-entry season-prep matrix/corpus as explicitly pending, advisory guidance;
it remains pending package deployment and Retail opening validation. The public
prerelease remains
[`v6.1.0-alpha.36`](https://github.com/josevargas6/KnomercyWarRoom/releases/tag/v6.1.0-alpha.36).
CurseForge, Discord, and the Sentinel-bot dispatch passed in the protected
workflow. Render production verification also passed: `kwr-sentinel-bot` is
deployed on its current `main` commit `8d84fef`, and the Render logs record its
health endpoint and Discord session online.

The product owner attests that five complete Retail battlegrounds cleared
`LIVE-TEAM-TRUTH`, `LIVE-STABILITY`, `LIVE-CARRIER-TARGET`, and
`LIVE-READABILITY` with zero observed errors. Those four field gates are no
longer release blockers; the attestation is recorded in
`knowledge/field-verification-attestation.json`. Candidate-bound journal
telemetry remains an instrumentation debt because the local SavedVariables file
did not retain the corresponding rows. Cross-PC Sentinel still requires its
separate ten-client safety/value proof.

The read-only SavedVariables audit in
`knowledge/retail-field-certification.json` found four completed matches and
four interrupted records across Deephaul, Deepwind, Gilneas, and Silvershard.
All four completed matches report `FAIL_REVIEW` command stability, with 36-75
replacements and 6-28 reversals. The records predate the exact deployment
certification receipt and are therefore useful defect evidence but remain
`UNBOUND` for promotion. KWR-250 owns deterministic candidate binding.

The first preserved Twin Peaks screenshot pass is recorded at
`docs/field-evidence/2026-07-28-twin-peaks/README.md`. It confirms working
Horde-relative score direction, native-map coexistence, roster/assignment
population, conservative unknown handling, enemy observation aging, and a live
lose-state command transition. It also confirms two P1 trust blockers:

- expanded Team health is empty/dim while compact legal health is visible;
- expanded Team specialization labels drop historical `(HIST)` provenance.

Twin Peaks remains partial because that screenshot predates the repaired
candidate and cannot certify it.

Supplemental match-end evidence confirms the final Horde-relative `0-3`
defeat agrees with the AAR and captures flag pickup/drop/return/capture events.
It also adds two P1 command blockers:

- `KWR-033`: the prior candidate recorded 58 replacements and misleading
  `0:00` lifetime semantics;
- `KWR-034`: the prior candidate allowed raw flag-event prose into a tactical
  target.

The Team and carrier-target implementation repairs remain closed offline. The
command-stability repair is reopened by real AAR evidence: after the minimum
commitment window, a non-superior alternative could replace an active play
despite a negative replacement decision. The closure branch now retains the
active play until superiority or an explicit invalidation is proven; fresh
candidate-bound Retail evidence is required to verify the repair.

Current repo state:

- the offline winning-state execution pass is closed by repo evidence;
- the expert scenario corpus and bounded enemy-response planner are integrated
  into the strategist and verified offline;
- the current offline candidate passes validation, knowledge audit, smoke,
  soak, and replay as of 2026-07-30;
- the interrupted local-fight HUD slice is closed by deterministic evidence;
- synchronized personal routing now preserves protected objective assignments;
- package certification requires explicit smoke and soak pass markers;
- the recovered distribution and developer package audits pass, with exact
  evidence recorded in `artifacts/recovery-candidate/BUILD_RECEIPT.md`;
- the default release package now excludes the optional Sentinel bundle unless
  `tools/build.ps1 -IncludeSentinel` is used intentionally;
- remaining promotion gates are Retail-only: live stability, taint/safety,
  field-performance proof, screenshot matrix, supported-map certification, and
  release-presentation proof;
- `LIVE-TEAM-TRUTH`, `LIVE-STABILITY`, `LIVE-CARRIER-TARGET`, and
  `LIVE-READABILITY` are the field-gate identifiers in
  `knowledge/field-blocker-report.json`; implementation task IDs are not reused
  as live evidence IDs.

## Alpha engineering gate

The implementation is above the 8.5 pre-field gate in architecture, safety,
performance design, map knowledge, deterministic decision behavior, UI
consistency, packaging, and diagnostics. Team/enemy tracking, score
convergence, transition repainting, and complete-match trust remain
provisional at 8.5 until repeated Retail matches confirm the public APIs behave
as modeled. A field failure lowers that category and blocks promotion; it does
not get hidden by the aggregate score.

## Proven offline

- One authoritative Store and one MatchRuntime ticker.
- Four finite zone-transition confirmations and three finite roster
  confirmations repair loading-screen truth without adding another ticker.
- Full spoken command calls list every named mover and defender; numeric
  shorthand is not used on the Scout HUD.
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
- Internal Reporter objective state and bounded permitted movement evidence.
- Local kill-target selection, roster-validated assigned-team normalization,
  and explicit unknown handling for Midnight-blocked combat evidence.
- Dated Murlok RBG specialization snapshot with an explicit advisory boundary.
- Two hundred seventy-five deterministic diagnostics plus a 500-refresh bounded-state soak
  and knowledge audit.
- Reviewed expert scenario labels now inform preferred line, fallback line,
  safest counter, expected enemy answer, and review confidence on live
  strategist output.
- A bounded enemy-response planner now classifies likely punish patterns and
  adjusts candidate consequence scoring before the final recommendation is
  selected.
- Reviewed doctrine depth now includes comp-threat models, enemy-defense models,
  per-map opener branches, per-map recovery branches, per-map endgame branches,
  deterministic doctrine fixtures, and verification-surface doctrine reporting.
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
- Knowledge freshness gating now scores patch alignment, reviewed-data age,
  live enemy specialization certainty, and historical-spec dependence before
  composition-specific or meta-assisted calls are allowed to influence the
  command path.
- Stale or unaligned meta data can no longer silently bias kill-target scoring
  or composition-driven strategic commits.
- Counterfactual decision reviews are bounded developer logs and never
  self-modify battlefield doctrine.
- Manual AAR export reuses the existing AAR subscriber and copy dialog, records
  bounded evidence only, has no automatic chat behavior, and can be disabled.
- The existing Strategist now derives bounded commitment, reinforcement,
  pressure, rotation-economy, collapse, recovery, organization, and
  single-action assessments from already-sanitized state.
- Execution assessments are review evidence only in this candidate; they do
  not add HUD lines, automatic actions, or a second decision owner.
- The optional target spotlight and priority-cast accents are precreated with
  the compact roster and update from fixed target/event evidence.
- Observed swap-class protection suppresses automatic kill-candidate ranking;
  KWR never changes the player's target or claims interruptibility.
- Tactical telemetry remains on the expanded command board, the compact HUD
  reserves one persistent local-fight card, the combat roster spotlight uses a
  dedicated readability lane, and native `Shift-M` owns battlefield-map display.
- Qualified execution evidence produces one shared response package containing
  movers, stayers, success, and abort; all command and review surfaces consume
  that same package.
- Assignment audits reject non-roster identities, invalid priorities, and
  incompatible flag carriers.
- Repeated execution assessments and carrier aura reads use bounded caches.
- Export sections explicitly separate recommendations, evidence, execution,
  known outcomes, enemy observations, and unavailable facts.
- Live performance telemetry and enforced strategic refresh budgeting.
- Field distribution packaging now excludes developer preview and deterministic diagnostics paths.

## Requires Retail proof

- Native `Shift-M` coexistence across battleground transitions and combat.
- PvP scoreboard fields under Retail 12.0.7 secret-value behavior.
- Event-fed teammate-target/nameplate last-seen behavior.
- Live objective-marker changes; instanced player coordinates are unavailable
  through the public map-position API.
- Reporter pressure/hotspot quality across objective families.
- Compact local-fight card readability with zero, one, two, and three healers.
- UI clipping and scaling at common resolutions.
- Match-complete and instance-exit journal behavior.
- Taint, blocked-action, CPU, and memory checks.
- Assigned-team resolution across native, mercenary, and cross-faction matches.
- Enemy/friendly secure row click behavior through a complete combat cycle.
- Fixed Quick Call behavior and taint through a complete battleground cycle.
- Kill-target quality across melee and ranged local-fight conditions.
- Knowledge-status thresholds across real inspected, partially observed, and
  fully unknown enemy lobbies.

## Intentionally incomplete

- Enemy buffs not explicitly observed remain unknown.
- Defensive and trinket readiness is never assumed. Retail 12 blocks the combat
  log subscription formerly used for observations, so live state remains unknown.
- An enemy's health may be displayed directly by a protected StatusBar when the
  client permits it, but secret health cannot be used in target scoring.
- External meta data is release-dated and cannot reveal an individual enemy's
  actual talents, gear, enchants, or PvP build.
- KWR can identify when composition certainty is too weak for an advanced
  commit, but it still cannot discover hidden enemy builds that Blizzard does
  not safely expose.
- Reporter cannot plot an enemy whose map position Blizzard does not safely expose; roster knowledge alone never becomes a fabricated dot.
- Predictions for public widgets not exposed by Blizzard remain low-confidence or unknown.

Promotion requires the live sections of `QA_CHECKLIST.md` to pass with captured evidence.
This document is the current gate board; prior gate plans are retained only under
`docs/audits/historical-plans/` for provenance.
