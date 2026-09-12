---
id: KWR-298
title: Rebuild the fight and mini-command surfaces as one complete verbal callout card
owner: Astra
priority: high
risk: high
status: in_progress
dependencies: [KWR-296]
affected_modules: [UI/HUD, UI/TeamfightCommandCard, Core/CommandView, Intelligence/ExecutionCommandBuilder, UI/CombatRoster, UI/Options, tests]
authority_references: [AGENTS.md, PRODUCT_ROADMAP.md, RELEASE_READINESS.md, DESIGN_CONTRACT.md]
---

# Objective and user outcome

The owner reports clipped commands caused by long player names and difficulty
distinguishing current action/location, next movement, movers/stayers, desired
position, local fight target and CC assignments. Rebuild the presentation and
information hierarchy completely so one commander card supports complete verbal
calls without opening other panels or hovering to recover essential words.

This is **P13** of [KWR-297](KWR-297-s-tier-completion-packages.md), an Astra-led
visual/information-design rebuild, not Terra Medium cosmetic cleanup. P09 retains
other application UX work. There is no need to replace the tactical planner or
duplicate Store to rebuild the card. Source implementation is authorized and
in progress. Preserve the current installed field candidate.

# Confirmed source seams and reported symptoms

- `UI/HUD.lua` owns the actual frame: fixed 432-unit width, fixed section heights,
  `localFightText`, `focusFightText`, `applyFightNowLayout`, `Create` and `Update`.
  Target and CC strings pass through 20/24-character clipping paths. A fixed
  72-unit fight section receives a kill line plus several CC lines.
- `Core/CommandView.lua` has `compactNames`, `callModel`, `localFightCall` and
  `FightNow`. Local fight can replace the displayed strategic current call while
  strategic current becomes NEXT/AFTER FIGHT. That mixes tactical and movement
  concepts which the rebuilt card must present separately.
- `UI/TeamfightCommandCard.lua` is currently a small projection builder, not the
  full rendered card. Editing that file alone will not rebuild the visible HUD.
- `Intelligence/ExecutionCommandBuilder.lua` owns structured local fight, control
  and personal assignments; preserve GUIDs/full identities before formatting.
- CombatRoster mini surfaces include fixed single-line font strings. Identify
  which duplicated call fragments should consume the new projection and which
  remain separate secure target/roster controls.

The user's clipping report is direct field feedback. These source seams support
the need for investigation; exact pixel failures require reproduction/rendering.
Do not claim a screenshot review that has not occurred.

# Required information architecture

Use stable labeled zones. NOW is the strategic order; LOCAL FIGHT is a separate
tactical layer. NEXT is conditional movement, not an order already being executed.

| Zone | Always answer | Required behavior |
| --- | --- | --- |
| Context | Which map/bracket, live/preview/unknown, command freshness? | Compact stable header; no stale data represented as live |
| NOW | What are we doing and where should we be now? | Action, ordered objective/location and named current duties |
| POSITION | Where are we actually observed versus ordered to be? | Distinct observed/estimated/unknown location; never equate assignment with presence |
| NEXT MOVE | What happens next, where, and on what trigger? | Destination, movers, trigger/deadline, hold/abort condition |
| MOVE / STAY | Who leaves and who remains, at which objective? | All issued actors, protected defenders/support and reserve, grouped by actual duty |
| LOCAL FIGHT | Pressure/kill/peel, which exact target, where and when? | Truthful intent, distinguishable identity, supported condition/countdown |
| CC / CONTROL | Who controls which target, with what job and trigger? | Actor -> verb -> target; location, timing and unavailable/unknown state |
| SAY NOW | What complete sentence should I say aloud? | Copyable, wrapped speech bundle from the same structured revision |
| FEEDBACK | Did the team follow this specific current call? | Left Not followed / right Followed, explicit focus and undo; KWR-299 |

The strategic card must not claim that a team has arrived because its assignment
points there. When location cannot be observed, show `Position unconfirmed`.
Local combat target changes must not silently rewrite strategic destination.

# Proposed wireframe — synthetic content, not tactical doctrine

This demonstrates hierarchy, not a frozen pixel design or an actual game state.
Replace the names and layout with stress fixtures before accepting the design.

```text
KWR COMMANDER     [map / bracket]       LIVE · current revision

NOW                 HOLD · Blacksmith
Ordered position    Defend Blacksmith and retain Farm coverage
Observed position   Main group at Blacksmith · Farm position unconfirmed

NEXT MOVE           REINFORCE · Lumber Mill
Trigger             On the verified release call; otherwise hold
MOVE                FullMoverName, SecondMover
STAY / AT           FullDefender — Farm
                    FullAnchor — Blacksmith
ABORT / FALLBACK     Cancel movement if required coverage is lost

LOCAL FIGHT         PRESSURE · FullEnemyName
Where / when        Blacksmith · now · kill window not confirmed

CC / CONTROL        WHO                   JOB → TARGET
                    FullController  Subdue → FullHealer
                    BackupName      Disrupt → SecondHealer
                    Timing/conditions visible beneath each assignment

SAY NOW             Complete current verbal call, naturally wrapped.
                    No names, action words or locations clipped.

FOLLOW-THROUGH       Unmarked · this NOW call only
Left: Not followed   Right: Followed       Undo     Review last call
```

Use typography/spacing and text labels before decorative color. Target/CC may
use a side column in a wide mode, but NOW, NEXT and local responsibilities retain
the same scan order. A compact mode cannot secretly become a player-only view
that omits the commander’s other assignments.

# Proposed structured view contract

Extend the existing CommandView/projection owner with structured rows before
formatting. Fields are requirements, not current APIs:

- Candidate/session, strategic command ID/revision, tactical revision and stable
  verbal-call identity for feedback; live/unknown/stale reason.
- `now`: action ID, ordered location/objective ID, current duties and conditions.
- `position`: actually observed actor/group locations with evidence age, or unknown.
- `next`: destination, movers, stay/reserve duties, trigger, deadline and abort.
- `localFight`: intent, target GUID/canonical identity, player-facing name, location, observed status and
  supported timing; local-control rows with actor and target identity separately.
- `speech`: complete current-call text/segments generated from those same fields,
  preserving conditional words and excluding speculative NEXT from issued NOW.
- `feedbackFocus`: exact eligible current verbal-call reference, not a mutable
  pointer to whatever global command happens to be current at click handling.

Keep full identities in the model. The owner chose player-name-only commander
speech and card labels, so realm suffixes must not consume callout space.
Retain canonical full identity and GUID internally for matching, feedback and
review; never use a displayed player name to bind an actor or target. No
ambiguous invented initials, partial names, silent `+3` or tooltip-only required
actors.

# Correct layout and rendering implementation

1. Reproduce the old clipping with fixture names/commands before changing it.
   Separate loss in source/projection formatting from loss in rendering; wrapped
   text cannot restore characters already discarded by `TextClip`.
2. Replace shared fixed-height paragraph blocks with structured, measured rows.
   Allocate action/location and actor lists independent layout space so long
   names cannot squeeze out verbs/destinations. Measure actual font/glyph width,
   stripping/handling supported color escapes correctly; character count is not
   pixel width. Use actual engine text height after width/font assignment.
3. Render player names without realm suffixes at safe boundaries. Keep their
   canonical identity for review/matching without inserting it into operator
   prose. Allow unbroken long glyph runs to wrap safely without corrupting UTF-8.
   Do not solve clipping by lowering font size below the agreed readable minimum
   or replacing the entire call with vague role text.
4. Content measurement determines row and section heights. Anchor following zones
   after measured previous bounds, not hardcoded Y positions. Relayout only when
   content/font/width changes; an updating timer uses reserved width and does not
   make the card jump every frame.
5. Define and test a finite supported content envelope: full 10/8-player duties,
   every emitted valid local control row, longest permitted full identities,
   long destinations, condition strings and supported locales. The current
   three-control producer cap must not be confused with UI permission to drop
   additional valid rows after future changes.
6. Provide minimum width and content-driven height, clamped to available viewport.
   If compact cannot fit all essential content, automatically offer/use a readable
   wide two-column commander layout within the supported viewport. For unsupported
   extreme scale/size, show an explicit fit failure and recovery; do not claim
   zero-clipping certification. Never solve required live-call overflow with
   hidden scroll pages, tooltips or a collapsed assignment list. Secondary
   diagnostics/history may scroll or collapse; live call essentials may not.
7. Establish a readable effective-pixel font floor with owner preview rather
   than assuming an 8-unit font at 0.65 scale is readable. Test 1080p/1440p/4K and
   0.65/0.8/1.0 UI scales, long locale strings and wide glyphs. Define supported
   minimum viewport/card size explicitly; there is no infinite-content guarantee.
8. Build normal, emergency, no-target, unassigned-control, expired, ended-match,
   world/setup, DevTools-off and local-only states deliberately. Preserve layout
   landmarks. Emergency emphasis must not erase the route or defender duties.
9. Reuse existing movable/lock/profile behavior, clamp saved offscreen positions,
   and migrate layout settings without overwriting unrelated preferences.
   Preserve safe combat behavior. Keep callout presentation nonsecure and separate
   from existing secure roster/target buttons and their protected ancestors.
10. Route old mini-call displays through the same structured projection. Remove
    conflicting duplicated call wording from the primary commander surface only
    after its responsibilities are present on the new card. Do not delete useful
    roster features or force unrelated windows open to recover missing details.
11. Integrate KWR-299 feedback on noninteractive card areas with labels, visible
    result and undo. Buttons, drag handle, resize controls, text selection and
    protected roster clicks must not create feedback accidentally.

# Interaction and semantic safety

Normal card clicks record local feedback only; never cast, target, move, send
party chat or infer actual execution. Right-click does not conflict with an
existing context menu: relocate that menu to an explicit options control.
Feedback targets SAY NOW/current issued call only, not the unissued NEXT plan or
all future local assignments. See KWR-299 for identity, drag and correction rules.

One safe manual copy action can expose the full current speech bundle; no auto
chat output. Its bytes must preserve all required identities/actions/conditions.
Display rendering cannot mutate tactical/strategic state or issue a new command.

# Verification and acceptance criteria

- [ ] Old long-name truncation reproduced; both projection and rendered causes fixed.
- [ ] NOW/order, observed position, NEXT/movers/stayers and LOCAL FIGHT remain
      semantically distinct and use the same source revision as SAY NOW.
- [ ] Every issued actor, CC target, action, destination and conditional word is
      present and readable on the primary card within the supported content envelope.
- [ ] No essential clipping, overlap, offscreen loss or tooltip/scroll-only recovery
      across the full resolution/scale/locale/long-name matrix.
- [ ] Long names do not reduce action/location width to unusable values; duplicate
      short names remain distinguishable and map to the correct GUIDs.
- [ ] No stale GO, incorrect KILL upgrade, invented position or next move issued early.
- [ ] Current/changed/unknown/terminal states have reviewed native or faithful
      offline renders; actual WoW rendering and five-second comprehension are FIELD.
- [ ] Click feedback, child-control isolation, drag, revision race and undo pass
      KWR-299 tests; no secure mutation or gameplay action is introduced.
- [ ] Measured subscriber/render cost and hidden-view behavior meet P07's contract.
- [ ] Source tests, extracted runtime/DevTools loading and relevant Lua gates pass.

Tests must measure bounds and compare semantic content, not only check that the
font string exists. Add a projection test asserting every original actor/action/
target/location token survives. Add a layout test using long unbroken realm names,
multibyte names, 10 actors and maximum control rows; a deliberately reduced section
height or reintroduced name clip must fail. Capture before/after visual artifacts
and inspect them; screenshots generated but never viewed do not count as review.

User FIELD checklist: without hovering or opening another window, read the full
NOW call, identify current ordered/observed location, name all movers/stayers,
state NEXT and its trigger, and call local target plus CC assignments. Retain
completion time, misreads and missing words; aim for the existing five-second
core comprehension requirement, not five seconds to recite every roster name.

# Implementation order and review

1. Astra traces the actual HUD/projection path and reproduces clipping/confusion.
2. Astra creates deterministic content fixtures and reviews two width modes with
   identical structured semantics; chooses one coherent visual hierarchy.
3. Astra implements structured projection, measured layout and profile migration.
4. Astra integrates exact-call feedback with KWR-299 and routes duplicated mini
   projections consistently. Terra may later add explicitly bounded fixture work,
   but does not own the primary visual or semantic rebuild decision.
5. Run production-path tests, inspect actual visual artifacts, then provide the
   diff, screenshots, bounds matrix, semantic tests and remaining client checks
   for separate review. Do not award S-tier or deploy merely because it looks good.

Contracts from P01/P03/P05 can be adopted incrementally. Layout/projection work
can proceed on the current candidate with explicit unknown states; do not wait
for all strategic overhaul work to start this user-priority rebuild. Final
integration must use the approved shared contracts, not permanent UI heuristics.

# Rollback and non-goals

Keep the existing HUD behind a reversible layout preference during source
development, with migrations preserving its old settings. It cannot be the
accepted final fallback for the known clipping defect. Do not rewrite the
planner, guess missing tactical facts, modify protected action bindings, publish,
or replace the owner's installed field-test copy without a separate request.

Offline status: IN_PROGRESS. The actual HUD and projection are implemented in
the source candidate. The Tactical-page mini-call now consumes the same
structured projection and labels its NEXT field as not issued. Focused tests
cover 18 conservative font-mock cases; normal and four-control HTML renders
were generated and visually inspected in
`artifacts/kwr297-card-render-20260910-c`. Native client status: NOT_TESTED. See
[ADR-011](../architecture/ADR-011-complete-callout-and-followthrough.md)
for remaining CODE obligations; the acceptance checklist is not yet closed.
Release status: NOT_REQUESTED. Installed field copy unchanged.
