# Changelog

## 6.1.1-alpha.9 - 2026-08-27

- Keep Blizzard's combined backpack and individual bag windows above KWR
  surfaces, including safe strata-only updates during combat lockdown.
- Split live runtime work into direct UI, tactical, and strategic lanes while preserving one Store and one decision engine.
- Route target, focus, nameplate, unit-target, cast, and combat-state traffic through a bounded tactical queue that reuses the current strategic call.
- Escalate only material tactical truth changes to one coalesced strategic refresh and replace the two-second full pulse with an eight-second recovery heartbeat.
- Add lane-specific queue attribution, duration samples, P95, coalescing, absorption, escalation, and retention telemetry.
- Add a deterministic 500-event tactical storm soak that proves bounded refreshes and command retention.

## 6.1.1-alpha.8 - 2026-08-27

- Treat unresolved opening ownership as unresolved, not as proof that a held node was lost.
- Collapse unqualified duplicate-name friendly roster transition rows until a realm-qualified identity proves they are distinct players.

## 6.1.1-alpha.7 - 2026-08-27

- Make design preview provide explicit synthetic assigned-team truth while
  retaining its unmistakable not-live provenance.
- Reuse unchanged preview state for unrelated queued refreshes, so preview
  interaction no longer repeatedly invokes the full battlefield strategy path.
- Prevent preview roster rescans from requesting Retail inspection for
  synthetic roster rows.

## 6.1.1-alpha.6 - 2026-08-27

- Reconciled all 20 audited live-addon enhancement candidates into canonical
  source without copying the installed tree or weakening newer reviewed fixes.
- Added bounded scoreboard reuse with explicit invalidation, reason-aware
  critical refresh timing, current-roster rescans, and truthful lightweight
  world standby state.
- Added roster-safe assignment filtering, response mover/stayer deduplication,
  explicit active-play clearing, and canonical flag-target verification.
- Added observable one-result formation caching, retained bounded strategist
  caches during active PvP, and clear both safely between matches.
- Preserved canonical AAR map identity, historical specialization provenance,
  location-first enemy truth, brawl bracket evidence, carrier-target evidence,
  and health eligibility across the compact and expanded surfaces.
- Reviewed Blizzard's official hotfix ledger through August 26, including
  Warlock in the August 25 PvP tuning list and the August 26 Training Grounds
  surrender fix, with no inferred capability weights or doctrine changes.
- Added deterministic regressions for the adopted enhancement boundaries and
  corrected localization-fixture isolation and manual roster-rescan ordering.

## 6.1.1-alpha.5 - 2026-08-18

- Corrected the Season 2 hotfix boundary to Blizzard's July 28, 2026 ledger
  and removed a legacy 2017 article from the advisory watchlist without
  changing capability weights or tactical doctrine.
- Reduced live Tactical Map clutter with smaller non-critical team dots,
  bounded observed-only trails, and clearer priority objective emphasis.
- Added a canonical command-emphasis contract for Tactical Map/Reporter Map,
  with one command, one observed threat, one qualified route, one decisive
  timer, explicit provenance, and conflict suppression for audio execution.
- Derived bounded score-rate evidence from monotonic verified widget
  transitions and require current timestamped score/objective evidence before
  any live predictor can publish an aggressive call.
- Anchor modeled score intervals to accepted score transitions rather than
  intervening refresh pulses, preventing inflated live win-clock rates.
- Preserve fallback objective provenance while allowing newer accepted system
  carrier observations to invalidate stale pickup commands.
- Separated observed player positions and speeds from semantic map estimates;
  estimated anchors no longer create objective pressure, reinforcement
  advantage, or assignment-abandonment certainty.
- Added a 20-case competitive truth matrix covering all ten supported maps in
  standard and Blitz variants, plus fail-closed freshness, rate, route,
  pressure, attention-authority, and command-consistency regressions.
- Treat identical active plays as confirmations, preventing false replacements and commitment resets.
- Require observed objective evidence before a cart-state change can invalidate a live cart order.
- Reconcile ambiguous short-name roster snapshots from complete scoreboard truth and suppress duplicate visible team-bar rows while secure frames settle.
- Ignore irrelevant UI-widget events and route health/aura observation through
  the lightweight local-intelligence path.
- Keep all non-carrier health/aura observation lightweight; it can refresh local
  enemy records but cannot schedule a full strategic recompute.
- Record each terminal ActivePlay transition once, rather than counting the
  same expired or completed play on every later refresh.
- Store only compact transition fields in the verification ledger; the full
  `/kwr verify` report remains generated on demand.
- Compact shipped calibration and expert-corpus tables while retaining the complete audit corpus outside the runtime load path.

## 6.1.1-alpha.4 - 2026-08-18

- Repaired Retail roster publication at its source boundary: group, scoreboard,
  and historical observations now collapse to one canonical player record before
  any Commander surface renders. Same-short-name teammates now retain their
  realm-qualified display identities, so two legitimate players cannot render
  as indistinguishable duplicate bars.
- Reconciled enemy observation identities from name to GUID, preserved the best
  available class/spec/role facts, and count visibility episodes rather than
  repeated refreshes as separate sightings.
- Restored command stability: flag invalidation is now edge-triggered from the
  command's own baseline, response packages no longer automatically bypass
  replacement discipline, and the active-play key no longer churns with a
  changing assignee list.
- Deferred and guarded all KWR drag-stop calls across combat lockdown, replaced
  the nonfunctional Shift-M menu stub with an actual battlefield-map action,
  and reduced AAR write work during high-frequency refreshes.
- Added a shared Sentinel drag-completion queue released only after combat,
  removed its dormant carrier-unit observer, and made both UI button factories
  reject missing callbacks at creation time. The release validator now audits
  every declared control surface and rejects unfinished production markers.
- Completed the exact Season 2 matrix at 100,000 actionable branches across
  all ten Retail RBG maps; every phase/family branch is now reachable from a
  real candidate action and exercised by the runtime regression suite.
- Made target reticles materially easier to see with layered 2-4 px guides,
  stronger contrast, and an explicit Standard/Bold preference.
- Simplified composition selection into one counterpick decision: a selected
  plan now states playstyle, strongest matchups, and weaknesses without
  repeating watch/recruit text.
- Added explicit Diagnostic/Commander/Spectator AAR context and unavailable
  player states; corrected opponent session counting so re-entry does not
  inflate profile samples.
- Corrected final review-path edge cases: command replacement now preserves an
  urgent coverage gap, repeat opponents count across separate same-map matches,
  direct player specialization outranks stale scoreboard data, assignment swaps
  cannot disappear from AAR sampling, and interrupted AARs cannot satisfy the
  stability checklist.
- Unified Nexus and live carrier execution metadata so the issued action,
  target, envelope, fallback, and active-play evidence cannot describe
  different objectives. Formation wording now separates favorable situations,
  vulnerabilities, and practical counterplay; Sentinel relay traffic is opt-in
  until Field mode is explicitly activated.
- Synchronized the embedded Sentinel companion for the candidate release.

## 6.1.1-alpha.3 - 2026-08-17

- Made Season 2 field mode the default for upgraded local profiles: Command
  guidance, live HUD, team/enemy roster, reticle, battlefield presentation,
  bounded Sentinel transport, automatic AAR capture, and AAR review now arm
  together. `/kwr field` reapplies the complete local field profile.
- Activated Season 2 theory rows for field use. They now surface as active
  theory with an explicit awaiting-field-feedback status, while real Retail
  observations and AARs remain distinct evidence that can refine or disprove
  the theory.
- Added a clear in-addon Season 2 hotfix watchlist for the official August 11
  PvP changes. It is deliberately advisory: it exposes affected specs and
  source provenance without modifying ratings, predictions, or doctrine.
- Added `/kwr season2`, a compact local evidence-run checklist for team truth,
  carrier targeting, stability/performance, and readability. It routes to the
  existing automatic AAR review/export path through `/kwr season2 aar`.

## 6.1.1-alpha.2 - 2026-08-17

## 6.1.1-alpha.1 - 2026-08-17

- Bound the integrated Season 2 candidate to a new Commander/Sentinel version
  so it can no longer collide with the immutable public `6.1.0` release.
- Reviewed the active Retail 12.1 pack against official Season 2 and PvP
  hotfix sources through July 28. Theory-first Season 2 branches are active;
  the stale 12.0.7 ladder snapshot remains excluded from meta influence and
  simulation/provisional guidance still requires Retail validation.
- Corrected the knowledge audit to inspect the declared active patch pack and
  all TOC interfaces instead of accidentally accepting a dated review from an
  inactive historical pack.
- Made release ZIP construction deterministic through canonical entry order
  and normalized timestamps; clean-build certification now fails on any
  binary archive mismatch instead of accepting a container exception.
- Made the public release-surface audit tolerate an intentionally retired
  `develop` branch, declared `main` as the sole release authority, and encoded
  Beacon, Maps, and ScoreCard as optional non-blocking estate components.

- Activated the full Strategist Nexus theory immediately across every
  supported legal branch. Weak or conflicting live truth now gates commitment
  and names the evidence required without replacing the map-specific primary,
  fallback, or counterplan with generic HOLD/VERIFY text.
- Replaced the generic default enemy reinforce assumption with explicit HOLD,
  ROTATE, TRADE, TEAMFIGHT, and SPLIT countertheory. Live AAR evidence now
  refines or disproves active theory rather than unlocking it gradually.
- Added the production Strategist Nexus: reviewed doctrine, capability and
  composition theory, score-state discipline, and reversible fallbacks now
  form one bounded decision envelope. The audited 5,000-case simulation index
  guards branch coverage only, while player-reviewed AAR results refine plans
  through existing patch and minimum-sample gates.
- Removed the unused zero-row simulation promotion lifecycle so synthetic
  records cannot be confused with observed match evidence.
- Rewrote the CurseForge listing copy as concise plain text so the CurseForge
  client does not display raw Markdown markers; Sentinel now states its
  Commander requirement directly.
- Renamed future player downloads to `KnomercyWarRoom-<version>.zip` and
  `KWR-Sentinel-<version>.zip`; the published v6.1.0 assets remain immutable.
- Added an optional minimal live-combat HUD mode, high-contrast presentation
  tokens, a readable multiline manual-copy surface, and full 15-player roster
  capacity without reducing the normal Fight-Now kill/CC direction stack.
- Closed tactical calls cleanly at match completion, directed players into
  Review/AAR, and suppressed the target reticle over Options, copy, and AAR
  modal surfaces while restoring it after those surfaces close.
- Hardened embedded Sentinel identity, session, cast, and payload handling so
  protected secret values fail closed before serialization or transport.
- Added deterministic coverage for focus-mode restoration, match-complete call
  closure, high contrast, modal reticle recovery, 15-player roster capacity,
  and protected Sentinel transport inputs.

## 6.1.0 - 2026-08-15

- Promoted the reconciled Commander and embedded Sentinel packages to the first
  stable Season 2 release without moving or replacing the immutable Alpha 43
  tag.
- Included the reviewed field-test refinements for target-reticle clarity,
  protected Sentinel aura handling, compact battlefield identifiers, and
  stable roster/marker presentation.
- Preserved explicit reticle-guide, battlefield-marker, and orb opt-outs when
  older profiles receive the stable presentation defaults.
- Made tagged publication choose GitHub and CurseForge release channels from
  the version: stable semantic versions publish as releases, while suffixed
  versions remain prereleases. Commander and Sentinel announcement versions
  remain distinct when their release lanes differ.
- Kept Retail 12.1 patch-dependent overlays fail-closed pending separately
  reviewed official tuning data; generic doctrine and safety fallbacks remain
  available.

## 6.1.0-alpha.43 - 2026-08-14

- Added native class markers for enemies and square role/objective badges for teammates without duplicating Blizzard nameplate identity, health, or cast panels.
- Kept the target reticle above the native nameplate, preserved actionable cast details, and prevented marker/reticle overlap.
- Added lightweight arena and world-PvP context handling: RBG Commander surfaces stay hidden outside battlegrounds, enemy-player reticles remain available, and the full cursor ring restores on battleground entry.
- Added native Retail role-atlas coordinates, bounded marker sizing, target preference handling, and idle-driver cleanup for lower CPU use.

- Prepared the Alpha 42 certified field-test candidate from the reviewed main
  source. It carries the Sentinel secret-value guards, larger compact
  battlefield identifiers, settled Team/Enemy roster presentation, preview
  reticle support for approved PvP training dummies, and combat-safe Options
  closing behavior.

- Added Alpha 41 Retail 12.1 compatibility mode. The detected 12.1.0 client
  now fails closed on the prior 12.0.7 meta and capability overlays until
  official tuning is reviewed; generic doctrine and advisory season-prep
  review remain available.
- Recorded product-owner authorization to move the four outstanding live-proof
  items from release blockers into the refinement queue. This does not claim
  candidate-bound field evidence or cross-PC Sentinel proof was completed.
- Added KWR-253 composition-aware opening coverage. Each of the ten supported
  maps now exposes fifteen theory-reviewed starting branches, including ten new
  friendly/enemy composition matchups and qualified-tier routes. They retain
  conservative fallbacks and require Retail validation before promotion.
- Activated the Alpha40 season-prep scenario corpus and matrix as advisory
  guidance. Its 1,000 pending entries can inform scenario review, but cannot
  replace live evidence, Commander decisions, assignments, or safety gates.
- Added managed Sentinel docking to the Commander LayoutCoordinator. When both
  addons run on one client, the execution card and status helper choose the
  lowest-overlap screen edge around active Commander surfaces; dragging either
  Sentinel surface preserves its player-selected placement.
- Added Alpha 38's reviewed `KWRSync1` cross-client Sentinel transport. Commander
  remains the only strategic brain; Sentinel sends bounded observations and
  receives addressed assignment, control, and action relays with protocol,
  session, sender, sequence, rate, and expiry validation.
- Added KWR-250 read-only SavedVariables certification, which found four
  completed Alpha 36-compatible Retail matches and four interruptions without
  exposing local account paths or player identities.
- Fixed active-play replacement so a non-superior alternative remains held
  after the minimum commitment window; command issuance timestamps now remain
  anchored to the published command instead of resetting every evaluation.
- Added KWR-053 with 1,000 evenly distributed, deterministic season-prep
  scenarios and corpus fixtures (100 per supported battleground). Every new
  entry is pending season review and excluded from runtime expert selection
  until it has official and field-evidence approval.
- Added KWR-052 leader-entry roster hardening. Transient group tokens that
  resolve to the leader no longer create duplicate Team tracker rows while a
  battleground roster is still hydrating.
- Added KWR-051 compatibility hardening for Better Blizzard Frames and other
  raid-frame managers. Presentation no longer reads, hides, restores, or
  otherwise touches Blizzard-owned raid frames.
- Reopened KWR-032 through KWR-034 as offline implementation blockers and
  closed their deterministic/code criteria: Retail-safe direct health display,
  evidence-derived command stability totals, and canonical flag action targets.
- Kept live screenshots, complete-match stability, taint, performance, and
  map certification explicitly live-only.
- Added repository-owned Commander and Sentinel Wiki sources plus a guarded
  GitHub Actions synchronizer so command and training documentation can be
  republished after approved addon updates. Configure `WIKI_PUBLISH_TOKEN` in
  repository secrets to enable cross-repository Wiki writes.

## 6.1.0-alpha.33

- Preserved the reviewed live Commander UI corrections, including coordinated reset behavior for launcher and combat-roster positions.
- Restored standalone and embedded Sentinel source parity with matching Alpha 33 runtime metadata.
- Removed protected target/focus actions from Sentinel enemy rows and kept the tracker visual-only.
- Corrected Sentinel HUD, minimap, standalone asset, and default panel-layout defects found during review.
- Advanced guarded release automation to exact Alpha 33 artifacts without rewriting Alpha 32 history.

## 6.1.0-alpha.32

- Declared both supported Retail interface builds, 12.0.7 and 12.1.0, in Commander and Sentinel TOCs.
- Supersedes Alpha 31 packaging without changing addon runtime behavior.

## 6.1.0-alpha.31

- Repaired CurseForge Retail version metadata and made invalid upload metadata fail closed.
- Enforced exact-tag source provenance for every GitHub prerelease build.
- Aligned Commander and embedded Sentinel on one immutable release commit.
- Connected scheduled Discord publication to the configured production webhook names.

## 6.1.0-alpha.30

- Certified field-test polish for tracker readability and local-fight synchronization.
- Repaired canonical release sources and extracted package validation.
- Added release automation readiness for weekly maintenance and hotfix delivery.

## 6.1.0-alpha.29

Distribution note: this is the synchronized Commander/Sentinel Retail 12.0.7
field-test candidate. Release notes, package provenance, checksums, CurseForge
submission guidance, and ready-to-post Discord copy are included with the
certified distribution evidence. The 2026-07-31 live field test found no bugs
outside the visual repairs, which are now complete; promotion remains gated on
the final packaged visual recheck.

- Added resolution-aware KWR window clamping and Blizzard Options collision avoidance.
- Added a scroll viewport for lower Command Center content at compact heights.
- Removed the redundant quick-call secondary label that collided with action text.
- Lowered KWR surfaces beneath Blizzard spellbook, map, quest, and options windows while keeping them above the game world.
- KWR no longer relocates Fight Now when Blizzard windows open; it remains at the saved position and only lowers its layer.
- Fixed a Retail taint error by removing dynamic frame-strata changes from the protected CombatRoster trackers.
- Simplified the live Enemy tracker call card to show the CC caller/class and initial, kill class and initial, and the coordinated switch countdown.
- Fixed Team tracker bound-row hydration from showing a qualified and short-name copy of the same teammate when the short name is unique.
- Reworked the compact Enemy target bar into separate target, status, and action lines, removing duplicate LIVE badges and clipped action text.
- Suppressed unresolved Enemy call cards and synchronized Fight Now's current recommendation with confirmed live local-fight targets and locations while retaining the strategic play under NEXT.

- Added a commander Discord release-update pack and guarded announce script so
  KWR Commander now has ready-to-post announcement, support, field-testing,
  and ops copy alongside the existing Sentinel Discord path.
- Added a repository-owned CurseForge commander upload checklist and guarded
  upload script so the certified commander distribution ZIP can be submitted
  through the same evidence-first path already used by Sentinel.
- Added a reviewed expert scenario corpus with 200 battlefield labels across
  supported maps and phases, and integrated that corpus into Strategist
  outputs as preferred action, fallback, safest counter, expected enemy
  counter, agreement rate, and review confidence.
- Added a bounded enemy-response planner that classifies likely enemy answers,
  chooses the safest reply, adjusts candidate consequences, and re-sorts
  strategic recommendations from legal reviewed context instead of one-step
  heuristics alone.
- Expanded deterministic offline coverage so smoke assertions now verify the
  expert corpus and enemy-response plan are attached to live strategy output.
- Imported the evaluated KWR design-system brand and icon asset pack into
  production addon paths, added a shared icon registry, switched the minimap
  launcher to the KWR sigil, replaced combat-roster role letters with shared
  role icons, and moved tactical-map markers onto KWR semantic/objective icons.
- Added a repository-owned KWR brand standard and developer UI standard, and
  locked the first canonical design-token contract into `UI/Theme.lua` while
  preserving legacy theme color lookups.
- Added a repository-owned Lua test runner that discovers cached or installed
  runtimes and requires smoke, soak, and replay pass markers.
- Scoped the smoke assertion harness below Lua's active-local limit so offline
  compilation failures can no longer hide later deterministic checks.
- Restored live reviewed/adversarial calibration lookup across the corpus and
  tactical scenario ID schemes, and excluded module metadata from the problem
  signal coverage audit.
- Rebuilt Team and Enemy tracking around one unified roster presentation
  boundary instead of independently anchored compact panes, toolbar chrome,
  and UI-owned truth cleanup.
- Moved published friendly identity normalization into `TeamResolver` and
  defensive enemy truth filtering into `EnemyIntel`.
- Replaced compact row reshuffling with stable battlefield-session enemy slots,
  one root anchor, one integrated command lane, and bounded single-line
  identity/health/action rows.
- Removed the full strategy refresh previously triggered by merely showing the
  compact roster.
- Rebuilt the expanded Team and Enemy pages as ten-row command surfaces with
  stable enemy positions, a single selected-enemy context strip, and less
  repeated source language.
- Made Command Center pages build on first use and added semantic row
  signatures so unchanged Team and Enemy visuals are skipped.
- Routed friendly unit health events directly to visible compact and expanded
  health bars without forcing a strategy rebuild.
- Added a backward-compatible migration from legacy pane, toolbar, and solo
  positions to the unified roster anchor.
- Refit the Tactical Map page to its real command-center content boundary so
  the map, all ten team jobs, Recent Calls, next-call card, and every command
  control stay inside the window at the same time.

## 6.1.0-alpha.28

- Rebuilt the live compact card as `KWR FIGHT NOW`: score plus projected
  result, battleground win path, current and next WHAT/WHO/WHERE/WHEN calls,
  defense/offense posture, and independent KILL/CC lanes now form one
  bottom-line combat read.
- Removed live confidence, source, revision, refresh, reassessment, and other
  maintenance language from the combat card while preserving the full setup
  and expanded planning surfaces.
- Friendly health rows now repaint with each player's synchronized execution
  job and safely fall back to the map assignment when that packet clears;
  enemy rows show KILL, PRESS, or CC only from the reviewed local-fight packet.
- Centralized movement, kill, stop/CC, recovery, carrier, unknown, and stale
  colors so the HUD, combat roster, target reticle, and battlefield identifiers
  use the same crosshair meanings.
- Repaired the combat-roster visual cache so a changed synchronized assignment
  updates its health row immediately even when optional observation fields are
  unavailable.
- Recorded the former suite-scope vision now retained under
  `docs/audits/historical-plans/` after local-to-GitHub version drift was confirmed.
- Classified Commander, Sentinel, Beacon, the Discord bot, Maps, and ScoreCard
  as separate release lanes under one product vision rather than one merged
  runtime, ZIP, or version.
- Removed all external battleground-map detection, recommendations, and
  compatibility code; KWR remains fully standalone.
- Legacy Support View commands now point only to Blizzard's native `Shift-M`
  battlefield map.
- Kept KWR's internal battlefield-intelligence runtime, synchronized command
  HUD, Sentinel routing, and audio unchanged.
- Restored one permanent `LOCAL FIGHT` card to the compact commander HUD with
  independent kill and healer-control lanes plus explicit unknown placeholders.
- Kept confirmed local healers assigned between casts, prioritized active
  free-casters, rejected remote scoreboard-only healers, and cleared actors
  when bounded local evidence expires.
- Prevented synchronized healer-control routing from pulling protected
  defenders or carriers off their objective assignment.
- Hardened package certification to require explicit Fengari smoke and soak
  pass markers instead of trusting its process exit code alone.

## 6.1.0-alpha.27

- Retired the standalone KWR Support HUD from the production load graph after
  consolidating live direction into the synchronized compact command card.
- Kept KWR's internal Reporter intelligence pipeline and the expanded tactical
  board; only the redundant standalone map window was retired.
- Kept battlefield-map presentation outside KWR and routed it to native
  `Shift-M`.
- Updated launcher, slash-command, preview, presentation, and option copy to
  direct battlefield-map use to native `Shift-M`.
- Preserved legacy saved-variable keys for downgrade safety while disabling
  Support HUD restoration.

## 6.1.0-alpha.26

- Unified the existing objective assignments, three-lane healer-control planner,
  kill-target selector, and countdown into one synchronized execution packet.
- Compact battleground HUD now renders that packet in objective, control, kill,
  and trigger order, while hiding redundant Team Plan and Local Target panels.
- SentinelBridge now relays the matched player's synchronized pickup, control,
  protected objective, or kill job and its exact expected target.
- Removed assignment fallbacks that could show another player's job when the
  current player had no matching teamfight assignment.
- Added optional, rate-limited local TTS calls derived from the same packet as
  the visual HUD, plus a `REPEAT` button and command-audio option.
- Added deterministic coverage for stable packet signatures, two and three
  healer-control lanes, orb handoffs, Sentinel routing, and audio deduplication.

## 6.1.0-alpha.25

- Replaced the old opaque all-player battlefield overlay with transparent role/class identifiers.
- Friendly players now show role icon plus short name; enemy players show class icon plus short name.
- Confirmed flag and orb carrier state replaces the normal icon and preserves objective color.
- KWR health now appears only on the current enemy target; active priority casts receive the only cast strip.
- Unknown role/class state degrades to a neutral marker instead of guessing.
- Reduced identifier refresh cadence to 4 Hz and removed non-target health reads.
- Renamed the option to `Show compact battlefield identifiers` without changing the saved setting key.
- Repaired the original release-audit Phase 0 correctness blockers without
  replacing the runtime architecture: Store publication is now exact, objective
  widget truth keeps its reviewed authority, enemy map dots no longer fabricate
  positions from teammate context, and canonical identity no longer merges
  same-short-name players by default.
- Hardened the compact secure-surface suppression path and removed the
  recursion-prone combat-roster visibility loop that previously destabilized
  compact battlefield presentation.
- Added deterministic regression coverage for nested Store publication,
  objective-source authority, enemy coordinate truthfulness, canonical identity,
  Reporter stale-friendly pruning, current-state MemoryBudget sampling,
  post-integrity strategy output, and zero-deficit recovery summaries.
- Upgraded package certification so the extracted distribution addon, not just
  the developer archive, now executes smoke and soak validation during the
  package audit.

## 6.1.0-alpha.23

- Fixed battlefield-side truth so normal battlegrounds no longer let scoreboard
  side noise flip friendly Horde/Alliance ownership; native faction now stays
  authoritative unless WoW explicitly marks the player as mercenary.
- Added stronger post-match settle refreshes and final-state command overrides so
  the commander HUD can swap stale mid-match calls for the real final
  victory/defeat state once the scoreboard finishes settling.

## 6.1.0-alpha.22

- Added independent saved anchors for solo `TEAM` and solo `ENEMY` combat-roster
  layouts, so each mode can keep its own commander-side position instead of
  sharing one generic frame anchor.
- Updated Reset Window Positions to restore the new solo roster anchors along
  with the existing split-pane layout defaults.

## 6.1.0-alpha.21

- Added independent saved drag anchors for the split compact team and enemy
  roster panes in BOTH mode, so each side can be positioned separately for
  commander layouts.
- Added compact-roster reset support for the split pane anchors so Reset Window
  Positions restores the default left/right pane layout cleanly.

## 6.1.0-alpha.20

- Fixed the compact-roster syntax regression that prevented `CombatRoster` from
  loading and cascaded nil-module errors into the War Room and presentation
  layer.
- Added nil-safe compact-surface suppression and restore paths so the main
  window no longer hard-crashes if a compact module fails to initialize.
- Removed protected scale suppression from the presentation layer to avoid
  tainting Blizzard raid-frame edit-mode controls during battleground
  presentation cleanup.
- Cleared stale match/reassessment state on non-PvP world transitions so
  battleground results unwind more reliably when returning to formation/world
  mode.
- Hardened battlefield orb assignment lookups to index both full and short
  player names for more reliable friendly-nameplate mission labels.

## 6.1.0-alpha.19

- Split battleground auto-show from manual compact-roster visibility so the
  roster no longer writes itself permanently "shown" just by entering PvP.
- Tightened battleground presentation cleanup with additional world/zone
  refresh hooks so compact battlefield surfaces restore more reliably on exit.
- Added a first battlefield-orb pass to the existing command reticle package.
  Visible nameplates can now render lightweight KWR ally/enemy orb overlays
  with role/kill/carry meaning instead of relying on the reticle alone.
- Gated target reticle and battlefield orbs to live PvP state so they fall off
  cleanly when returning to world/formation mode.
- Added an options toggle for battlefield orbs on visible nameplates.

## 6.1.0-alpha.18

- Split the compact combat roster into a true two-pane visual layout in BOTH
  mode so team and enemy intelligence read as separate battlefield surfaces
  instead of one large slab.
- Added automatic compact-roster kill-target handoff. When the current target
  dies or drops out, the spotlight now falls through to the active KWR kill
  target or the best local/visible enemy instead of collapsing to empty.
- Added force-refresh on compact roster open and reporter open so field tools
  immediately request current truth instead of waiting for the next passive
  update.
- Expanded transition settling refreshes, including `PLAYER_LEAVING_WORLD`,
  and extended world/zone/roster follow-up windows to better survive slow
  battleground exit and loading transitions without needing `/reload`.
- Canonicalized reporter fallback locations so abbreviations and aliases map
  back to real battleground objectives more reliably.
- Reduced compact reporter-map marker bulk and converted routine player tracks
  toward cleaner dot-like markers while preserving kill/carry emphasis.
- Removed synthetic `Team Engagement` labels from enemy last-seen location
  output when no real battleground location is known.
- Reduced KWR window opacity across the theme so battlefield visuals remain
  visible behind the commander surfaces.

## 6.1.0-alpha.17

- Added battleground presentation mode as a first-class KWR package instead of
  scattered per-window tweaks.
- Presentation mode now suppresses redundant Blizzard battleground clutter
  while inside battleground instances, including top widget/timer surfaces,
  minimap/minimap cluster, objective tracker, status tracking bars, and
  Blizzard raid frames.
- Added safe restore behavior so suppressed Blizzard UI returns when leaving
  the battleground or disabling presentation mode.
- Added battleground presentation controls to the KWR options window.
- Added `/kwr presentation` and `/kwr bgui` to quickly toggle the new
  presentation package during testing.
- Field test arming now enables presentation mode so battleground verification
  uses the intended commander-facing layout.

## 6.1.0-alpha.15

- Replaced abbreviated mover counts with complete spoken command rosters.
  Scout HUD objective calls now list every named mover and any named defenders
  by compact objective, without `+3` or other numeric shorthand.
- Enlarged the Scout HUD command area and separated the full call, personal
  assignment, mover roster, timing, confidence, and kill target into readable
  sections suitable for voice leadership.
- Made qualified execution responses bypass the short command-stability hold
  so an evidence-supported emergency pivot is displayed immediately.
- Added four bounded post-zone transition truth confirmations and three
  bounded group-roster confirmations. These are finite event responses and do
  not add a polling loop or permanent ticker.
- Added `UNIT_NAME_UPDATE` and `PLAYER_ROLES_ASSIGNED` refreshes so raid names,
  roles, health bindings, and secure roster rows converge after loading.
- Cross-checked raid unit identities against Blizzard's raid-roster records,
  suppressed duplicate identities, and withheld unstable unit bindings until
  the corresponding unit token resolves.
- Expanded deterministic diagnostics to 243 checks and added regression
  coverage for complete spoken commands and bounded transition settling.

## 6.1.0-alpha.14

- Replaced the lossy refresh flag with one bounded, preemptible dirty-state
  scheduler. Simultaneous score, roster, and transition events now produce one
  primary refresh plus at most one newest-truth follow-up.
- Added guaranteed settling refreshes after login, world/zone transitions,
  group roster changes, score-table changes, match activation, and public
  widget updates without adding another ticker.
- Made each map's reviewed score widget authoritative. Dynamically discovered
  widgets are validated fallbacks and cannot silently displace the configured
  source; within-match score regressions are rejected.
- Added widget authority, score-change age, regression state, queue
  coalescing, follow-up, preemption, and settle telemetry to `/kwr verify` and
  `/kwr perf`.
- Replaced duplicate `Team Engagement` location text with source-aware
  descriptions such as `ENGAGED WITH STRIKE -> LM`. Direct positions remain
  authoritative; assignment-derived destinations remain explicitly inferred.
- Kept enemy identities and safely numeric last-observed health visible after
  live tokens disappear, and retained the last local target spotlight for five
  clearly labeled seconds.
- Unified compact assignment terminology across Team, HUD, combat roster, and
  command copy surfaces.
- Corrected the Team table's eight-pixel header/row offset and widened its
  assignment column.
- Replaced the fixed 46-pixel square minimap launcher with a 32-pixel circular
  launcher positioned from the current minimap radius.
- Expanded deterministic diagnostics from 240 to 242 checks, added scheduler,
  score-authority, launcher, and table-alignment regression assertions, and
  retained the 500-refresh bounded-state soak.

## 6.1.0-alpha.13

- Added one normalized battlefield truth contract with source, observation
  time, expiration, confidence, verification state, and conservative gating.
- Added static map-route ETA fallback when exact legal coordinates are not
  available; observed movement remains higher confidence.
- Upgraded every assignment into a monitored contract with issue time,
  expected arrival, evidence source, success condition, abort condition,
  completion state, and value-aware replacement.
- Added an objective coverage ledger that identifies uncovered and
  overcommitted friendly objectives without stripping the sole defender from
  another node.
- Reworked the existing five candidate actions into objective-aware heuristic
  scores with named targets, opportunity cost, reversibility, evidence,
  success, and abort semantics. Scores are explicitly not statistical win
  probabilities.
- Added map-specific reviewed enemy counter and response doctrine to all ten
  supported battleground scenario families.
- Added immediate (5 second), engagement (15 second), and strategic (30 second)
  decision horizons to the existing execution assessment.
- Expanded `/kwr explain`, Commander, Verification, and AAR evidence without
  adding combat HUD lines or a parallel decision engine.
- Expanded deterministic diagnostics from 232 to 240 checks and retained the
  500-refresh bounded-state soak.

## 6.1.0-alpha.12

- Added one complete response package derived from the existing execution
  assessment: action, target, movers, stayers, success, abort, confidence, and
  evidence score.
- Allowed only high-confidence, score-85+ execution responses to arbitrate the
  existing Commander action. No parallel command owner was introduced.
- Made manual reassessment publish a compact changed-assignment summary and
  identify the affected players directly in the command.
- Added response-package agreement across Tactical, Assignments, `/kwr
  explain`, `/kwr verify`, and structured AAR export.
- Propagated reviewed enemy-composition counter directives to relevant
  individual assignments.
- Strengthened assignment audits with roster-identity, priority-range, and
  flag-carrier role validation.
- Added a one-second dirty-state cache for execution assessment and exposed its
  telemetry in `/kwr perf`.
- Throttled carrier-aura scans and added objective truth-quality provenance.
- Expanded deterministic diagnostics from 226 to 232 checks and retained the
  500-refresh bounded-state soak.

## 6.1.0-alpha.11

- Added an optional, always-precreated current-target spotlight to the existing
  compact combat roster. It displays direct target health without storing or
  comparing secret health values.
- Added a small reviewed priority-cast catalog and event-fed `STOP` accents for
  selected must-stop and advantage-swing casts. KWR never claims a cast is
  interruptible and never interrupts automatically.
- Added explicit advisory responses for observed immunity, absorb, and major
  defensive windows. Verified swap-class protection removes that enemy from
  automated kill-candidate ranking but never changes the player's target.
- Added priority-cast and defensive accents to existing enemy rows.
- Extended the optional Cursor Ring with one evidence-driven color state:
  danger, caution, rotation, recovery, uncertainty, or neutral.
- Added an Options toggle for target/cast combat visuals.
- Added priority-cast evidence to live verification and compact AAR state.
- Expanded deterministic diagnostics from 222 to 226 checks and retained the
  500-refresh bounded-state soak.

## 6.1.0-alpha.10

- Added one bounded execution-assessment layer inside the existing Strategist;
  no parallel command brain, timer, or combat window was introduced.
- Added objective commitment, reinforcement advantage, pressure forecast,
  rotation economy, fight-collapse, recovery-window, and organization-entropy
  assessments using already-sanitized Reporter, assignment, resource, and
  confidence evidence.
- Added one ranked action opportunity for explanation and review. It does not
  replace the live three-line command HUD or perform actions automatically.
- Expanded `/kwr explain`, `/kwr verify`, and manual AAR export with the
  assessment evidence so field decisions can be audited.
- Added seven deterministic assessment checks, bringing the suite to 222, and
  retained the 500-refresh bounded-state soak.
- Preserved Alpha 9 as the rollback baseline. Target spotlight, cast accents,
  Combat Clarity controls, and visual rings remain gated for live testing.

## 6.1.0-alpha.9

- Added a bounded manual match-evidence exporter to the existing AAR journal.
- Captures sanitized match metadata, friendly/enemy composition, KWR commands,
  objective transitions, assignment integrity, player locations, safely
  exposed scoreboard statistics, and factual enemy sightings.
- Added `/kwr aar`, `/kwr aar copy`, and `/kwr aar clear`.
- Added `COPY EXPORT` to the existing Command Center Intel/AAR page and the
  existing post-match review surface; both reuse KWR's manual copy dialog.
- Added an option to disable AAR evidence recording.
- Kept unknown information unknown and separated recommendations, supporting
  evidence, observed execution, and known outcomes in the export.
- Added safe optional scoreboard fields that are discarded when Retail marks
  them secret.
- Expanded deterministic diagnostics from 210 to 215 checks and retained the
  500-refresh bounded-state soak.

## 6.1.0-alpha.8

- Added a multi-source confidence budget with evidence, bounded risk, and
  conservative low-confidence behavior.
- Added friendly/enemy objective ETA estimates, enemy-intent prediction,
  battlefield momentum, and match-only rotation memory to Reporter.
- Added short-lived opportunity windows and honest resource-economy estimates
  from permitted observed evidence.
- Added lightweight HOLD, ROTATE, TRADE, TEAMFIGHT, and SPLIT outcome
  simulation without machine learning or a parallel decision engine.
- Added continuous assignment-integrity verification with abandoned,
  impossible, moving, and on-station states plus replacement recommendations.
- Expanded `/kwrwhy` with confidence evidence, candidate outcomes, ETA,
  intent, momentum, opportunity, resources, success/abort criteria, and
  assignment integrity while preserving the three-line combat HUD.
- Added developer-only counterfactual decision review records to AAR; they do
  not automatically modify live strategy.
- Added dirty-state decision caching and performance telemetry.
- Expanded deterministic diagnostics from 199 to 210 checks.

## 6.1.0-alpha.7

- Expanded all fourteen weighted capability categories to at least three
  semantic signals and three documented battlefield effects.
- Added map-family and strategic-state capability profiles so plan selection
  considers objective fit, team readiness, and enemy matchup instead of tags
  alone.
- Added at least three rating inputs to every assignment job family while
  preserving hard role compatibility and the proven semantic-tag model.
- Added explicit objective verb/target, success condition, abort condition,
  weighted focus, and three-step archetype counter sequences.
- Preserved current and last-seen enemy location, observation source, age, and
  coordinate confidence across Enemy Tracker, compact roster, HUD, Reporter,
  tactical map, and verification output.
- Retained coordinate-free observations as intelligence without fabricating
  map dots.
- Added immutable capability caching, reused Formation summaries, skipped
  unchanged HUD/roster rendering, and prevented ordinary friendly health/aura
  events from rebuilding the full strategy pipeline.
- Expanded `/kwr perf` with cache, render-skip, and lightweight-event telemetry.
- Updated the official patch review through Blizzard's 2026-06-22 hotfixes.
- Expanded deterministic diagnostics from 183 to 199 checks and passed the
  500-refresh bounded-state soak.

## 6.1.0-alpha.6

- Integrated a bounded fourteen-rating capability model and nine battlefield
  job preferences into the existing specialization repository.
- Added advisory Hero talent modifiers that refine copied capability results
  without mutating base specialization truth.
- Added centralized Retail 12.0.7 PvP tuning overlays reviewed against official
  Blizzard hotfix notes through 2026-06-17.
- Reclassified Smoke Bomb and added a small reviewed battlefield-ability
  catalog so observed kill, displacement, and capture-denial windows inform
  existing combat intelligence without a new scanner or event loop.
- Refined the existing assignment weights with capped capability preferences;
  role validation and the proven tag model remain authoritative.
- Added explicit confirmed, likely, estimated, and unknown capability coverage.
- Expanded deterministic diagnostics from 176 to 183 checks and passed the
  500-refresh bounded-state soak.

## 6.1.0-alpha.5

- Added the reviewed twenty-composition tier library supplied in the Midnight
  Commander handoff, including roster, tier, map fit, win condition, role
  package, and counterplan.
- Added multiset specialization matching for exact and likely full-roster
  composition detection; incomplete evidence remains labeled partial.
- Integrated qualified friendly composition matches into formation doctrine
  and map-plan scoring.
- Integrated qualified enemy composition matches into reviewed counterplay
  while preserving generic archetype fallback when enemy specs are incomplete.
- Added optional automatic compact combat-roster preparation on battleground
  entry without reopening it after the player manually closes it.
- Expanded deterministic diagnostics from 172 to 176 checks.

## 6.1.0-alpha.4

- Added `/kwr bug`, a single local field-defect bundle containing current
  authoritative truth, assignments, command reasoning, performance, source
  freshness, team/enemy live-unit coverage, the latest AAR state, and the
  bounded match evidence ledger.
- Added explicit friendly/enemy specialization, live-unit, and locally engaged
  coverage counts to `/kwr verify`.
- Expanded deterministic diagnostics from 171 to 172 checks.

## 6.1.0-alpha.3

- Fixed protected Team/Enemy health rendering so client-provided secret text is
  written directly to UI widgets and never read back or compared.
- Removed the retired `UNIT_HEALTH_FREQUENT` registration that blocked
  MatchRuntime startup on Retail 12.0.7.
- Added map-native objective abbreviations and grouped one-line assignment
  exports suitable for practical chat handoff.
- Added build-time guards against secret-backed health-text reads and removed
  Retail event registrations.
- Established Alpha 3 as the distinct field-testing baseline with 171
  deterministic checks and the 500-refresh bounded-state soak.

## 6.1.0-alpha.2

- Bound scoreboard enemy identities to safely observed live unit tokens using
  GUID, name, class, race, sex, and honor evidence without comparing secret values.
- Added direct Blizzard unit-token health rendering for compact and expanded
  Team/Enemy bars and event-driven health refreshes.
- Pre-bound enemy rows to player-click target/focus macros before combat and
  restricted automatic kill recommendations to visible local combatants.
- Corrected node recovery assignments so strike teams attack the missing or
  enemy-controlled objective while named defenders hold existing bases.
- Made manual reassessment publish a visible ten-second result, assignment
  changes, an explicit TAKE/HOLD command, and a local confirmation message.
- Deferred protected expanded/compact visibility changes until combat ends.
- Captured match-complete state so time-limit victories and defeats resolve
  correctly from the final assigned-team score.
- Added `/kwr field` to arm the complete formation-to-AAR test workflow.
- Expanded deterministic diagnostics from 167 to 169 checks.

## 6.1.0-alpha.1

- Added a 400-state scenario matrix: forty deterministic situations for each supported battleground.
- Added explicit opening, stabilization, pressure, recovery, and endgame phases.
- Added manual `REASSESS` command with assignment-change publication.
- Added GUID-based assignment identity and strict role compatibility; non-healers can no longer inherit healer jobs.
- Added bounded current-season encounter history with clearly labeled historical specialization evidence.
- Added safe pre-match group inspection sequencing to verify friendly specializations when inspect data is available.
- Added colored orb and flag-carrier event state, carrier promotion, observable aura stacks, and node assault timers.
- Added carrier-aware map markers, combat-roster state, assignment overrides, and flag-stack strategy.
- Added direct friendly health-bar rendering when numerical health is protected but a safe unit token exists.
- Expanded deterministic diagnostics from 149 to 167 checks.

## 6.0.0-beta.13

- Added reviewed opening doctrines and valid opening assignments for all ten supported battlegrounds.
- Added weighted defense, spin, team-fight, assault, carry, healing, and rotation valuation.
- Added explicit EOTS two-tower sitters, four-player mid control, and four-player tower strike.
- Added AB spinner/defender handoffs, mobile defense floaters, and a six-player minimum decisive-fight core.
- Added safe scoreboard refreshes, event-fed enemy unit observation, observed hostile cooldowns, and live direct health bars.
- Added public POI/vignette/fallback map positions, combat movement pressure, and stronger Reporter coverage.
- Added map art fallbacks, assignment counterplay context, and 149 deterministic diagnostics.
- Reduced enemy polling from all possible raid/nameplate targets to active event-fed unit tokens.

## 6.0.0-beta.12

- Routed the Tactical COPY control and `/kwr copy` through the compact
  single-line dialog while preserving the large dialog for multiline reports.
- Clamped copy, AAR, and Options dialogs to the visible screen.
- Added lead, deficit, tie, assignment-family, location-validity, and
  map-specific node-priority fixtures across all ten supported battlegrounds.
- Added reusable assignment audits for complete coverage, one job per player,
  valid map locations, and prevention of Formation leakage into active PvP.
- Added five-second freshness gates for authoritative score and objective
  evidence so stale values cannot drive a live recommendation.
- Expanded `/kwr verify` with map ID, assigned score faction, source ages,
  command age/TTL, complete assignments, Reporter coverage, and transition
  performance.
- Restricted Quick Calls to an exact six-phrase allowlist and added secure,
  combat-fallback, and rejected-call regression assertions.
- Added explicit impossible-recovery handling instead of recommending an
  objective count that cannot beat the enemy scoring clock.
- Corrected Arathi Basin and Deepwind Gorge standard and Blitz resource rates,
  and replaced the retired Eye of the Storm Blitz scoring model with Midnight's
  restored standard four-base model.
- Expanded deterministic diagnostics from 96 to 138 checks.

## 6.0.0-beta.11

- Replaced the six-step Quick Call copy workflow with fixed secure Instance
  Chat buttons activated by one explicit player click.
- Added immediate CALL ACTIVATED / NOT SENT status feedback and right-click compact-copy
  fallback behavior.
- Kept multiline reports in the full export dialog while giving one-line
  fallbacks a correctly sized single-line field.
- Centralized reviewed communication actions in `UI/QuickCalls.lua`, assigned
  attributes only outside combat, and added deterministic secure-action checks.
- Retained 96 deterministic diagnostics and added secure Quick Call smoke
  assertions.

## 6.0.0-beta.10

- Replaced proportional-font, space-padded headers with anchored columns on
  Objectives, Enemy Intelligence, Assignments, and Match History.
- Preserved specialization and effective role in every assignment record and
  changed the assignment identity column to `Spec Class / Role`.
- Replaced raw numeric assignment priority with PRIMARY, HIGH, SUPPORT, and
  FORMING decision labels.
- Replaced non-actionable Team map coordinates with battlefield assignment
  locations.
- Replaced primary-view widget IDs and source strings with VERIFIED, MAP ONLY,
  or UNKNOWN confidence; raw evidence remains available through `/kwr verify`.
- Added a command-experience doctrine defining always-visible, changed-only,
  and on-demand information for every surface.
- Expanded offline diagnostics to 96 checks.

## 6.0.0-beta.9

- Resolved the player character's specialization and combat role directly from
  the player specialization API instead of depending on inspection.
- Added specialization source metadata while retaining session-cached specs
  for teammates.
- Coordinated expanded and compact workflows: opening the War Room temporarily
  suppresses HUD, combat roster, and Reporter surfaces and restores them on close.
- Routed minimize controls through one surface coordinator so compact windows
  do not open through the expanded dashboard.
- Established explicit frame hierarchy: compact `HIGH`, expanded `FULLSCREEN`,
  and modal editors/reports `FULLSCREEN_DIALOG`.
- Added top-level raise behavior and removed pre-hide calls that prevented
  compact-surface restoration after expansion.
- Expanded offline diagnostics to 95 checks and added expanded/compact
  coordination assertions to the smoke suite.

## 6.0.0-beta.8

- Removed the complete six-page dashboard, tactical maps, compact roster,
  AAR, options, copy dialog, launcher menu, and other optional frames from
  synchronous addon-load initialization.
- Deferred the default HUD and first runtime refresh until the world has
  settled, while coalescing login and world-entry events.
- Stopped requesting group map positions outside PvP when formation mode
  cannot safely use them.
- Added per-module boot timing, world-transition refresh timing, and slowest
  initialization reporting to `/kwr perf`.
- Added a regression gate proving heavy optional UI stays off the
  addon-load critical path.
- Expanded offline diagnostics to 94 checks.

## 6.0.0-beta.7

- Rebuilt compact Team/Enemy rows as readable two-line health bars with
  specialization, role, health, assignment or observation state, and richer tooltips.
- Added persistent TEAM, ENEMY, and BOTH mode selection styling plus clear
  target, focus, local kill target, defensive, trinket, dead, offline, and
  critical-health presentation.
- Enlarged the compact roster while retaining combat-safe frozen secure bindings.
- Added tactical marker badges for friendly, enemy, healer, tank, dead, flag,
  incoming objective, priority objective, and local kill target states.
- Added live command, risk, track coverage, and objective-source overlays to
  both tactical and compact Reporter maps.
- Fixed map tiles and movement paths so they correctly re-layout after resizing.
- Preserved role and observed health context in Reporter tracks and expanded
  preview health coverage.
- Expanded offline diagnostics to 93 checks.

## 6.0.0-beta.6

- Added runtime performance telemetry, a four-refresh-per-second strategic cap,
  allocation-conscious event dispatch, compact AAR features, hidden-view
  suspension, secure-attribute diffing, and a 30 Hz cursor cap.
- Added 40 specialization capability profiles, seven composition archetypes,
  22 map battle plans, counter doctrine, patch overlays, and a knowledge manifest.
- Added contextual plan selection with requirements, alternatives, counterplay,
  switch conditions, stop rules, and explanations.
- Added bounded reviewed learning with patch isolation, Bayesian shrinkage, and
  minimum-sample safeguards.
- Added `/kwr explain`, `/kwr perf`, `/kwr mode`, and Learning-mode guidance.
- Added a pre-match Formation Advisor with 10-player role targets, archetype
  detection, meta/capability-aware recruit recommendations, leadership setup,
  ready checks, and positioning doctrine.
- Replaced the irrelevant city map in formation mode with a central Formation
  Briefing board; the Reporter map returns automatically in battlegrounds.
- Added source authority tiers for Blizzard, Battle.net, Murlok, PvP Basics,
  Wowhead, Warcraft Logs, KWR match evidence, and community signals.
- Added a developer knowledge-update workflow and automated knowledge audit.
- Replaced unsupported Unicode UI symbols with safe ASCII labels, switched to
  Blizzard's locale-safe standard font, and added a glyph validation gate.
- Registered runtime events once at initialization and gated inactive event
  handling, preventing protected event-subscription changes during PvP lifecycle
  transitions.
- Replaced native-faction score assumptions with roster-validated battlefield
  team assignment so cross-faction and mercenary matches normalize scores,
  objectives, enemies, strategy, and AAR results consistently.
- Retained safely observed teammate specializations across inspection changes.
- Added persistent selected styling and saved-value restoration to AAR choices.
- Removed Midnight-blocked combat-log registration and added a release gate
  preventing it from returning.
- Canonicalized live objective labels so POI positions inherit current widget
  ownership while restricted player coordinates remain explicitly unknown.
- Added map-specific prediction fixtures and a live evidence matrix for all ten
  supported battlegrounds.
- Added `/kwr verify` and `/kwr evidence` for reproducible live truth,
  decision, transition, and performance capture.
- Corrected faction-specific home-objective assignments and distinguished open
  formation slots from role replacements.
- Added legacy-database migration coverage and a 500-refresh bounded-state soak.
- Added an automated round-trip package structure, legacy-exclusion, extracted
  validation, knowledge, and SHA-256 audit.
- Added explicit Blitz detection with separate verified node rates, capture
  timing, EOTS tower rates, and flag values.
- Added incoming-objective clock simulation that detects captures which flip
  the projected result and changes the live call accordingly.
- Added score-delta tracking for WSG/Twin Peaks last-capture tiebreak logic.
- Added a hard decision gate preventing incomplete battlefield truth from
  becoming a live strategy call.
- Required qualified assigned-team and score evidence before an AAR can enter
  the learning model.
- Expanded offline diagnostics to 91 checks, including missing orb/cart
  telemetry truth handling.

## 6.0.0-beta.5

- Added the knowledge, contextual strategy, formation-advisor, performance,
  safe-glyph, and bounded-learning foundation used by Beta 6.
- Expanded the initial offline diagnostics to 69 checks.

## 6.0.0-beta.4

- Added one compact Team/Enemy combat roster with class-colored live health
  bars, tank/healer role symbols, and combined/team/enemy modes.
- Added combat-safe secure rows: left-click targets and right-click focuses;
  enemy name macros are prepared out of combat and never changed during combat.
- Added observed defensive and PvP-trinket tracking from the combat log.
- Added a local kill-target model that requires safe visibility and local-range
  evidence, then weighs role, available health, observed trinket/defensive use,
  manual priority, and a modest RBG-meta tie breaker.
- Corrected Retail 12.0.7 defensive cooldown baselines against the field-tested
  reference addons and removed unsupported racial-as-trinket assumptions.
- Added cross-faction scoreboard team detection from actual group-name matches.
- Added the dated Murlok RBG specialization snapshot and explicit provenance.
- Kept Team, Enemy, Reporter, and combat processing active while detailed pages
  are closed; detailed tables now render only when opened.
- Expanded deterministic diagnostics to 54 checks.

## 6.0.0-beta.3

- Reframed Reporter as the always-running battlefield movement-intelligence domain.
- Added friendly and safe enemy movement tracks with bounded path history.
- Added objective-pressure analysis, hotspot detection, movement risk, and call hints.
- Fed Reporter evidence into Predictor urgency/action and Commander reasoning.
- Added a clean minimized Reporter dot map that expands into the primary Tactical Command Board.
- Added movement paths and Reporter status to the expanded tactical map.
- Added Reporter events to the After Action Review timeline.
- Kept all Reporter processing independent of whether either Reporter view is visible.
- Expanded deterministic diagnostics and smoke coverage from 40 to 45 checks.

## 6.0.0-beta.2

- Restored the endgame commander-dashboard direction from the approved mockups.
- Replaced the four austere test pages with one integrated Tactical Command Board: Tactical Map, Objectives, Team, Enemies, Assignments, and Intel/AAR.
- Rebuilt the compact HUD as the live Scout command window.
- Added reusable Blizzard map-art rendering with objective, friendly, enemy, and flag overlays.
- Added a sanitized enemy-intelligence repository using scoreboard and visible-unit evidence.
- Added manual enemy priorities and persistent field notes.
- Added a persistent match journal, command/event timeline, learning summary, and After Action Review form.
- Added an explicitly labeled preview mode for reviewing the complete interface outside PvP.
- Kept the single Store, single runtime ticker, one command pipeline, and display-only safety boundary.
- Added Beta 1 database migration for the new navigation and HUD placement.
- Expanded deterministic diagnostics and smoke coverage from 31 to 40 checks.

## 6.0.0-beta.1

- Rebuilt KWR around one authoritative Store and one match lifecycle.
- Added map-specific predictors and deterministic assignments.
- Removed automatic communication, targeting, keybinding writes, and protected actions.
- Added validation, packaging, hashes, and release documentation.
## 6.1.0-alpha.29

- Added resolution-aware KWR window clamping and Blizzard Options collision avoidance.
- Added a scroll viewport for lower Command Center content at compact heights.
- Removed the redundant quick-call secondary label that collided with action text.
