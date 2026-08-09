# Knomercy War Room

Knomercy War Room is a player-controlled Rated Battleground command system for World of Warcraft Retail.

The suite release direction, component boundaries, recovery state, and ordered
backlog are defined in `PRODUCT_ROADMAP.md`. Release status is defined solely
by `RELEASE_READINESS.md`.
All versioned recovery and Alpha 29 descriptions below are historical feature
context. The TOC-aligned release decision is solely `RELEASE_READINESS.md`.
The complete path from this candidate to an expert-tier, competitively
benchmarked release is recorded in the changelog and dated evidence.
The offline Decision Lab schema contract now begins in
`knowledge/schemas/replay-schema.json`,
`knowledge/schemas/golden-label-schema.json`,
`knowledge/schemas/replay-run-result-schema.json`,
`knowledge/schemas/benchmark-report-schema.json`,
`knowledge/schemas/corpus-manifest-schema.json`,
`knowledge/schemas/outcome-review-schema.json`,
`knowledge/schemas/rbg-foundation-schema.json`,
`knowledge/corpus-manifest.json`,
`knowledge/rbg-foundation.json`,
`tools/corpus-audit.ps1`,
`tools/decision-benchmark.ps1`, and `tools/outcome-report.ps1`.
The authoritative all-RBG base profile also lives in
`Data/RBGMapProfiles.lua`.
The starter offline corpus now includes one replay/label/result/outcome slice
for every currently supported RBG map.
The next fixed collection target is five common scenario families per supported
RBG map, defined in `knowledge/rbg-scenario-matrix.json`.
Progress against that deliberate target can be measured with
`tools/deliberate-system-report.ps1`.
The full offline foundation-depth pack can be generated with
`tools/build-foundation-depth-corpus.ps1`.
Reviewed scenario calibration for the live strategist can be generated with
`tools/build-scenario-calibration.ps1` and audited through
`knowledge/scenario-calibration.json` plus `Data/ScenarioCalibration.lua`.
Adversarial scenario calibration for fail-closed strategy can be generated with
`tools/build-scenario-adversarial-calibration.ps1` and audited through
`knowledge/scenario-adversarial-calibration.json` plus
`Data/ScenarioAdversarialCalibration.lua`.
The final offline bridge into live Retail testing can be generated with
`tools/field-readiness-report.ps1` and reviewed through
`knowledge/field-test-readiness.json` plus the documents under `docs/` starting
with `FIELD_READINESS_PACK_2026-07-29.md`.
The current-candidate blocker and capture plan can be generated with
`tools/field-blocker-report.ps1` and reviewed through
`knowledge/field-blocker-report.json` plus
`docs/CANDIDATE_FIELD_CAPTURE_MATRIX_2026-07-29.md`.
The fastest first live Twin Peaks blocker-clearing run is documented in
`docs/KWR_TWIN_PEAKS_FIRST_SESSION_OPERATOR_SHEET_2026-07-29.md`.
The local deterministic Lua runtime machine-state can be checked with
`tools/runtime-preflight.ps1` and reviewed through
`knowledge/runtime-preflight.json` plus
`docs/FIELD_MACHINE_PREP_2026-07-29.md`.
The exact package receipt for the active candidate can be generated with
`tools/candidate-package-report.ps1` and reviewed through
`knowledge/candidate-package-report.json` plus
`docs/CANDIDATE_PACKAGE_TRUTH_PACK_2026-07-29.md`.
The final offline status line can be generated with
`tools/offline-completion-audit.ps1` and reviewed through
`knowledge/offline-completion-audit.json` plus
`docs/OFFLINE_COMPLETION_AUDIT_2026-07-29.md`.

The expanded Tactical Command Board is the primary interface and its compact
view is the synchronized command HUD. Reporter, team intelligence, enemy
intelligence, and combat evidence continue collecting in the background.
Native `Shift-M` remains the battlefield map.

Outside a battleground, the board becomes the Formation Advisor: it evaluates
the current group against a 10-player RBG roster, identifies missing roles,
recommends best-fit specializations, explains the emerging composition
archetype, and presents leadership, ready-check, and positioning guidance.

The historical Alpha 29 candidate kept one synchronized command
packet across the compact HUD, Sentinel, and optional local speech; reserves a
persistent `LOCAL FIGHT` card for kill and healer-control truth; reconciles
friendly identities while raid tokens settle; and uses native `Shift-M` instead
of a redundant support-map window. It adds no second command brain, polling
loop, combat window, external map dependency, or automatic action.

Alpha 29 includes the enhanced compact Team/Enemy combat roster specified by the endgame
design: independently movable Team and Enemy trackers, class-colored health
bars, role symbols, secure click targeting/focus, semantic KWR icon cues, and
a local target spotlight driven only by safely available evidence and manual
priority. Retail 12 blocks addon combat-log subscriptions, so live trinket and
defensive state is updated only from safely observed unit events.

The Alpha 29 strategy layer contains forty deterministic scenario combinations
per supported battleground. It evaluates opening, stabilization, pressure,
recovery, and endgame phases against objective pressure and composition shape.
Encounter history may supply a current-season likely specialization, but it is
always labeled `HIST` until live evidence verifies it.

The reviewed Midnight Commander handoff contributes twenty optional composition
shells with win conditions, role packages, map fit, and counterplans. KWR calls
a shell exact only when all ten specializations match. Eight or more matching
verified/likely specializations may produce a clearly labeled likely match;
otherwise the generic capability archetype remains authoritative.

Alpha 29 strengthens that archetype with fourteen bounded specialization
ratings, nine preferred battlefield jobs, optional advisory Hero talent
modifiers, and a small reviewed catalog of battlefield-defining abilities.
These are inputs to the existing assignment and combat-intelligence engines,
not replacement engines or additional UI pages.

Alpha 29 also adds knowledge freshness gating. KWR now scores patch alignment,
review age, live enemy specialization certainty, and historical-spec dependence
before composition-specific or meta-assisted calls are allowed to influence the
strategist or kill-target engine. When enemy truth is incomplete, KWR is now
required to fall back to map fundamentals instead of overstating certainty.

Every weighted category now has at least three semantic inputs, three stated
battlefield effects, and objective-plan influence. Calls identify what to take,
hold, escort, return, deny, or cap; what success looks like; and what observable
condition should abort the play. Visible and last-seen locations retain their
source even when Blizzard does not expose coordinates.

Alpha 29 retains manual structured AAR export in the existing match journal. It
records bounded factual evidence and does not generate prose, send chat, or
alter command decisions. After a completed match use `/kwr aar` to open the
Intel/AAR page, `/kwr aar copy` to open the existing manual copy box, or
`/kwr aar clear` to delete completed exports. A live recording cannot be
cleared. Recording can be disabled in KWR Options.

Alpha 29 introduced the internal execution assessment in the existing Strategist.
It evaluates objective commitment, reinforcement advantage, pressure forecast,
rotation cost, collapse risk, recovery windows, and assignment organization.
The compact HUD shows one synchronized command plus one local-fight card.
Detailed evidence appears in
`/kwr explain`, `/kwr verify`, and the manual AAR export.

Alpha 29 retains the optional current-target spotlight in the compact roster,
reviewed accents for selected high-value casts, and explicit responses to
observed immunity or major defensive windows. These visuals never interrupt,
swap targets, or claim an unavailable fact. The optional Cursor Ring now uses
one evidence-driven color state instead of adding another alert window.

Alpha 29 converts qualified execution evidence into one complete response
package: what to do, who moves, who stays, the target, success condition, and
abort condition. Only medium/high-confidence responses scoring at least 85 may
override the ordinary command. Reassessment, Tactical, Assignments,
explanation, verification, and AAR all consume the same package.

Alpha 29 adds a normalized truth contract to every decision cycle and records
source, age, expiration, confidence, and verification state. Assignments now
carry expected arrival, success, abort, and replacement semantics, while the
coverage ledger protects friendly objectives from accidental abandonment.
Candidate actions name a target and compare opportunity cost, reversibility,
arrival evidence, and objective impact. Their 0-100 values are heuristic
decision scores, not fabricated statistical win probabilities.

## Sentinel team transport

KWR Sentinel supports the reviewed `KWRSync1` addon-message bridge for members
of the same battleground group. Commander remains the only strategic brain.
Sentinel clients send only bounded legal observations and receive compact
personal assignment, control, and action relays. Traffic is limited to
`INSTANCE_CHAT`, `RAID`, or test `PARTY`; it never uses visible chat and never
targets, focuses, casts, moves, or changes secure controls. The exact protocol,
limits, expiry, and security rules are in `SENTINEL_TRANSPORT_SPEC.md`.

## Install

Place the `KnomercyWarRoom` folder in:

`World of Warcraft/_retail_/Interface/AddOns/`

Restart World of Warcraft or reload the UI.

## Commands

- `/kwr` - Open or close the expanded Tactical Command Board.
- `/kwr field` - Arm the complete live test workflow, then run `/kwr verify` immediately.
- `/kwr tactical` - Open the tactical map board.
- `/kwr reporter` - Legacy alias that reminds you to use native `Shift-M`.
- `/kwr roster` - Toggle both compact Team and Enemy trackers together.
- `/kwr teammini` - Toggle the compact Team tracker.
- `/kwr enemymini` - Toggle the compact Enemy tracker.
- `/kwr objectives` - Open objective control.
- `/kwr team` - Open the team roster.
- `/kwr enemies` - Open the Enemy Tracker.
- `/kwr assignments` - Open smart assignments.
- `/kwr intel` - Open the learning library and match history.
- `/kwr aar` - Open the latest After Action Review.
- `/kwr preview` - Developer build only. Toggle a clearly marked, non-live design preview outside PvP.
- `/kwr hud` - Toggle the compact synchronized command HUD.
- `/kwr copy` - Prepare an abbreviated one-line current call for manual copying.
- `/kwr explain` - Show plan, composition, counterplay, alternatives, and switch rule.
- `/kwr perf` - Show live CPU-duration and memory telemetry.
- `/kwr verify` - Capture the complete current truth, decision, and performance report.
- `/kwr bug` - Export one complete local defect bundle for field-test reporting.
- `/kwr evidence` - Export the bounded match-transition evidence ledger.
- `/kwr mode` - Toggle compact Command and expanded Learning guidance.
- `/kwr refresh` - Request one authoritative refresh.
- `/kwr reassess` - Rebuild the battlefield plan and publish assignment changes.
- `/kwr options` - Open settings.
- `/kwr cursor` - Toggle the optional Cursor Ring.
- `/kwr test` - Developer build only. Run deterministic diagnostics.
- `/kwr status` - Print the compact current status.

## Truth and safety

KWR:

- never sends visible chat automatically; reviewed `KWRSync1` addon messages
  are limited to Commander/Sentinel battleground transport;
- never targets, focuses, casts, or runs macros automatically;
- exposes target/focus only through pre-bound secure rows activated by the player's hardware click;
- exposes six fixed Instance Chat quick calls through pre-bound secure buttons
  activated by the player's hardware click;
- queues secure binding or layout changes until combat ends;
- never casts abilities or changes keybindings;
- never replaces live battleground truth with preview data;
- sanitizes secret or unavailable values before publication;
- labels unknown health, cooldown, aura, trinket, and position data as unknown;
- keeps dynamic commands manual; right-clicking a fixed quick call opens a
  compact copy fallback.

Enemy roster knowledge comes from Blizzard's PvP scoreboard when available.
Last-seen, health, and position are only shown when a safe visible unit source
exposes them. Health values protected by the client may be drawn directly on a
bar but are not stored, compared, or used to score a target.

The bundled Murlok RBG snapshot is dated advisory data. It cannot identify an
individual player's gear or talents and has only a small tie-breaking influence
after live evidence. See `META_SOURCES.md`.

## Supported battlegrounds

Arathi Basin, Battle for Gilneas, Deepwind Gorge, Eye of the Storm, Warsong Gulch, Twin Peaks, Temple of Kotmogu, Silvershard Mines, Deephaul Ravine, and Seething Shore.

Alpha 29 passes 275 deterministic diagnostics, the 500-refresh bounded-state
soak, architecture and safety validation, knowledge audit, and package
certification. It still requires live Retail field validation before stable
release.

For live capture steps, use
`docs/LIVE_TEST_OPERATOR_GUIDE_2026-07-29.md`.
