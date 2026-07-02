# Knomercy War Room 6.1 Alpha 13

Knomercy War Room is a player-controlled Rated Battleground command system for World of Warcraft Retail.

The expanded Tactical Command Board is the primary interface and its compact
view is the Scout HUD. Reporter, team intelligence, enemy intelligence, and
combat evidence continue collecting in the background. Their detailed pages
render on demand instead of behaving like separate mini-addons.

Outside a battleground, the board becomes the Formation Advisor: it evaluates
the current group against a 10-player RBG roster, identifies missing roles,
recommends best-fit specializations, explains the emerging composition
archetype, and presents leadership, ready-check, and positioning guidance.

Alpha 13 includes the enhanced compact Team/Enemy combat roster specified by the endgame
design: class-colored health bars, role symbols, secure click targeting/focus,
and a local kill-target glow driven only by safely available evidence and
manual priority. Retail 12 blocks addon combat-log subscriptions, so live
trinket and defensive state is updated only from safely observed unit events.

The Alpha 13 strategy layer contains forty deterministic scenario combinations
per supported battleground. It evaluates opening, stabilization, pressure,
recovery, and endgame phases against objective pressure and composition shape.
Encounter history may supply a current-season likely specialization, but it is
always labeled `HIST` until live evidence verifies it.

The reviewed Midnight Commander handoff contributes twenty optional composition
shells with win conditions, role packages, map fit, and counterplans. KWR calls
a shell exact only when all ten specializations match. Eight or more matching
verified/likely specializations may produce a clearly labeled likely match;
otherwise the generic capability archetype remains authoritative.

Alpha 13 strengthens that archetype with fourteen bounded specialization
ratings, nine preferred battlefield jobs, optional advisory Hero talent
modifiers, and a small reviewed catalog of battlefield-defining abilities.
These are inputs to the existing assignment and combat-intelligence engines,
not replacement engines or additional UI pages.

Every weighted category now has at least three semantic inputs, three stated
battlefield effects, and objective-plan influence. Calls identify what to take,
hold, escort, return, deny, or cap; what success looks like; and what observable
condition should abort the play. Visible and last-seen locations retain their
source even when Blizzard does not expose coordinates.

Alpha 13 retains manual structured AAR export in the existing match journal. It
records bounded factual evidence and does not generate prose, send chat, or
alter command decisions. After a completed match use `/kwr aar` to open the
Intel/AAR page, `/kwr aar copy` to open the existing manual copy box, or
`/kwr aar clear` to delete completed exports. A live recording cannot be
cleared. Recording can be disabled in KWR Options.

Alpha 13 retains the internal execution assessment in the existing Strategist.
It evaluates objective commitment, reinforcement advantage, pressure forecast,
rotation cost, collapse risk, recovery windows, and assignment organization.
The combat HUD remains three lines. Detailed evidence appears in
`/kwr explain`, `/kwr verify`, and the manual AAR export.

Alpha 13 retains the optional current-target spotlight in the compact roster,
reviewed accents for selected high-value casts, and explicit responses to
observed immunity or major defensive windows. These visuals never interrupt,
swap targets, or claim an unavailable fact. The optional Cursor Ring now uses
one evidence-driven color state instead of adding another alert window.

Alpha 13 converts qualified execution evidence into one complete response
package: what to do, who moves, who stays, the target, success condition, and
abort condition. Only medium/high-confidence responses scoring at least 85 may
override the ordinary command. Reassessment, Tactical, Assignments,
explanation, verification, and AAR all consume the same package.

Alpha 13 adds a normalized truth contract to every decision cycle and records
source, age, expiration, confidence, and verification state. Assignments now
carry expected arrival, success, abort, and replacement semantics, while the
coverage ledger protects friendly objectives from accidental abandonment.
Candidate actions name a target and compare opportunity cost, reversibility,
arrival evidence, and objective impact. Their 0-100 values are heuristic
decision scores, not fabricated statistical win probabilities.

## Install

Place the `KnomercyWarRoom` folder in:

`World of Warcraft/_retail_/Interface/AddOns/`

Restart World of Warcraft or reload the UI.

## Commands

- `/kwr` - Open or close the expanded Tactical Command Board.
- `/kwr field` - Arm the complete live test workflow: HUD, combined combat roster, Command mode, live truth, and automatic AAR.
- `/kwr tactical` - Open the tactical map board.
- `/kwr reporter` - Toggle the minimized Reporter dot map.
- `/kwr roster` - Toggle the combined compact Team/Enemy roster.
- `/kwr teammini` - Toggle compact friendly health bars.
- `/kwr enemymini` - Toggle compact enemy health bars.
- `/kwr objectives` - Open objective control.
- `/kwr team` - Open the team roster.
- `/kwr enemies` - Open the Enemy Tracker.
- `/kwr assignments` - Open smart assignments.
- `/kwr intel` - Open the learning library and match history.
- `/kwr aar` - Open the latest After Action Review.
- `/kwr preview` - Toggle a clearly marked, non-live design preview outside PvP.
- `/kwr hud` - Toggle the compact Scout HUD.
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
- `/kwr test` - Run deterministic diagnostics.
- `/kwr status` - Print the compact current status.

## Truth and safety

KWR:

- never sends chat or addon-channel messages automatically;
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

Alpha 13 passes 240 offline architecture, syntax, movement, combat-intelligence,
cross-faction, preview, journal, and packaging tests. It still requires live
Retail 12.0.7 field validation before stable release.
