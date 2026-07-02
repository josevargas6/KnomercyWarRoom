# KWR 6.1 Alpha 12 QA Checklist

## Alpha 12 intelligence checks

- [ ] Own and friendly health bars render immediately when a legal unit token exists.
- [ ] Friendly specializations are verified during formation and remain cached.
- [ ] Historical specialization evidence is visibly labeled `HIST`.
- [ ] A non-healer never receives a healer assignment.
- [ ] Colored orb pickup/return events update carrier identity and map state.
- [ ] Flag-carrier health and observable assault stacks update.
- [ ] Node assaults create a visible capture/spin timer.
- [ ] `REASSESS` produces sensible assignment changes without automatic chat.
- [ ] Commands remain stable across minor one-second evidence fluctuations.
- [ ] Observed Smoke Bomb is shown as a tactical threat rather than a personal defensive.
- [ ] Capability confidence changes from historical likely evidence to confirmed live evidence.
- [ ] Visible enemies show current location and source; hidden enemies retain
  last-seen location, source, and age without receiving a fabricated dot.
- [ ] `/kwr explain` states objective success and abort conditions.
- [ ] `/kwr perf` reports capability-cache hits and skipped compact renders.
- [ ] Completing a battleground prints one local "AAR evidence ready" notice.
- [ ] `/kwr aar` opens the existing Intel/AAR page without opening chat.
- [ ] `/kwr aar copy` produces all structured export sections in a selectable box.
- [ ] `/kwr aar clear` clears completed history but refuses during a live recording.
- [ ] Disabling "Record manual AAR evidence exports" prevents match collection.
- [ ] Unavailable scoreboard statistics, rating, locations, and specs export as Unknown.
- [ ] `/kwr explain` reports one execution action and its commitment,
  pressure, reinforcement, rotation, collapse, recovery, and organization evidence.
- [ ] Low-evidence execution assessments remain `UNKNOWN` or conservative.
- [ ] Execution assessment adds no line to the three-line combat HUD.
- [ ] Current enemy target remains visible in the enlarged spotlight through
  target changes, nameplate churn, and combat.
- [ ] Direct target health updates without a secret-value comparison error.
- [ ] Reviewed must-stop casts show `STOP`; ordinary rotational casts do not.
- [ ] KWR never labels a cast interruptible from incomplete evidence.
- [ ] Divine Shield, Ice Block, Turtle, Burrow, and similar observed protection
  remove kill glow and show an advisory response without changing targets.
- [ ] Disabling target/cast combat visuals restores the original compact layout.
- [ ] Cursor Ring uses only one color state and does not flicker between states.
- [ ] A qualified response names movers, stayers, success, and abort.
- [ ] A low-confidence or sub-85 response cannot override the ordinary command.
- [ ] `REASSESS` prefixes the command and lists changed players and jobs.
- [ ] Tactical, Assignments, HUD, Why, Verify, and AAR agree on the response.
- [ ] Composition counter directives appear only on relevant assignments.

## Automated gates

- [x] `tools/validate.ps1` passes.
- [x] All runtime Lua parses as Lua 5.1.
- [x] Offline boot and pipeline smoke test passes 232 checks.
- [x] Knowledge audit passes.
- [x] Runtime Lua contains no unsupported non-ASCII UI glyphs.
- [x] Distribution ZIP contains one `KnomercyWarRoom` root and round-trips without mismatch.
- [x] Developer ZIP revalidates and passes the smoke test after extraction.
- [x] Extracted developer ZIP survives the 500-refresh bounded-state soak.
- [x] SHA-256 hashes are recorded.

## Clean-client checks

- [ ] Fresh install loads without enabling Load out of date AddOns.
- [ ] Existing Beta 1 database migrates to Tactical navigation without error.
- [ ] Login, `/reload`, logout, and login produce no Lua error.
- [ ] Window positions, notes, options, history, and AAR feedback persist.
- [ ] `/kwr test` reports zero failures.

## Visual contract

- [ ] `/kwr preview` is visibly labeled DESIGN PREVIEW - NOT LIVE.
- [ ] Scout HUD presents score, win condition, next objective, assignment, caller, and kill target.
- [ ] Tactical page is map-centered and remains readable at supported UI scales.
- [ ] Objective, friendly, enemy, and flag markers align with map coordinates.
- [ ] Objective markers change ownership from live widgets during combat.
- [ ] Restricted instanced-player coordinates remain explicitly unavailable
  rather than becoming fabricated movement dots.
- [ ] Enemy Tracker columns remain aligned with ten or more players.
- [ ] Team, Assignment, Intel/AAR, Options, note editor, and copy dialog have no clipping.
- [ ] No generic diagnostic page is exposed as a primary product view.

## Compact Team/Enemy roster

- [ ] `/kwr roster`, `/kwr teammini`, and `/kwr enemymini` show the correct mode.
- [ ] Friendly and enemy bars show name, class color, and tank/healer symbol.
- [ ] Left-click targets and right-click focuses the intended row in combat.
- [ ] Enemy clicks still work after nameplates churn or disappear.
- [ ] Secure bindings and layout are unchanged during combat; queued changes
  apply after `PLAYER_REGEN_ENABLED`.
- [ ] The selected local kill target is the only glowing row.
- [ ] A target outside safely observed local range is never selected.
- [ ] Active defensives lower kill priority; observed trinket/defensive use
  raises it only for the documented observation window.
- [ ] Unobserved trinkets and defensives remain UNKNOWN.
- [ ] Cross-faction/mercenary matches separate the assigned teams correctly.
- [ ] Horde-assigned score, objectives, strategy, enemies, and AAR result all
  remain Horde-relative even when the character's native faction differs.
- [ ] Inspected teammate specializations remain known after inspecting another
  teammate.

## Strategy and performance

- [ ] `/kwr explain` identifies plan, both composition archetypes, counterplay,
  switch condition, stop rule, and alternatives.
- [ ] `/kwr perf` reports P95 below 2 ms and routine maximum below 4 ms.
- [ ] Thirty-minute matches show less than 1 MB post-GC growth.
- [ ] Command and Learning modes remain readable without clipped text.
- [ ] Community monitor signals never become live calls without reviewed doctrine.
- [ ] Reviewed AAR samples do not influence a plan before five samples.
- [ ] No square or missing glyph appears at supported locales and UI scales.
- [ ] City/formation mode replaces the map with the Formation Briefing board.
- [ ] Open slots, missing roles, recruit labels, archetype and positioning match
  the actual group roster.

## Reporter movement intelligence

- [ ] Reporter continues updating when its mini-map and the Tactical Command Board are hidden.
- [ ] `/kwr reporter` opens a clean map-only view with friendly/enemy dots.
- [ ] EXPAND opens the primary Tactical Command Board without creating a duplicate window.
- [ ] Friendly paths update from sanitized map positions.
- [ ] Enemy paths appear only from safe observed coordinates and age correctly.
- [ ] Objective pressure, hotspot, and risk reflect the visible movement evidence.
- [ ] Reporter evidence appears in command reasoning without overriding stronger score/objective truth.
- [ ] Reporter path/event buffers remain bounded during a full match.

## Live battleground matrix

Follow `BATTLEGROUND_VERIFICATION.md`. For every supported map, test lobby,
start, first score, even score, projected win, projected loss, objective
transition, death/resurrection, completion, and instance exit.

- [ ] Arathi Basin
- [ ] Battle for Gilneas
- [ ] Deepwind Gorge
- [ ] Eye of the Storm
- [ ] Warsong Gulch
- [ ] Twin Peaks
- [ ] Temple of Kotmogu
- [ ] Silvershard Mines
- [ ] Deephaul Ravine
- [ ] Seething Shore

## Enemy intelligence

- [ ] Scoreboard enemies populate without forcing score requests.
- [ ] Target, focus, mouseover, nameplates, and ally targets update last-seen safely.
- [ ] Secret or unavailable health/position values remain unknown.
- [ ] Priority marks and notes persist.
- [ ] Cooldown and trinket fields show only observed use and never imply
  unobserved readiness.

## AAR and learning

- [ ] Entering PvP opens one match journal.
- [ ] Match exit creates exactly one history entry.
- [ ] Final score/result is accurate or explicitly unknown.
- [ ] AAR feedback saves and reopens.
- [ ] Preview sessions never enter match history.

## Safety and performance

- [ ] No taint or blocked-action warning.
- [ ] No `COMBAT_LOG_EVENT_UNFILTERED` subscription exists on Retail 12.
- [ ] Entering and leaving PvP does not register or unregister runtime events.
- [ ] No automatic chat or addon-channel communication.
- [ ] No keybinding, target, focus, spell, macro, or action-bar automation.
- [ ] Secure row clicks perform only the player's selected target/focus action.
- [ ] Quick Call left-click sends one fixed phrase to Instance Chat; right-click
      opens the compact copy fallback; neither mutates attributes in combat.
- [ ] Typical refresh remains below 2 ms.
- [ ] Leaving PvP stops active polling.
- [ ] Hidden UI creates no additional refresh loop.
- [ ] Ten-minute full-team stress test shows no escalating memory or errors.
