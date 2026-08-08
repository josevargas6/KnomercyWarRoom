# KWR Current-State Handoff

Date: 2026-07-06  
Addon version: 6.1.0-alpha.23  
Workspace root: `D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom`

## Purpose

This is the clean restart handoff for continuing KWR work in a fresh Codex
thread without dragging the full historical conversation, screenshots, and
interrupted experiments forward.

Use this file as the primary source of truth for:

- current addon status;
- active stabilization priorities;
- known working areas;
- known broken/provisional areas;
- immediate next tasks.

For the live working queue, see `docs/WORKFLOW_NOW.md`.

## Product intent

KWR is a player-controlled Rated Battleground command system for World of
Warcraft Retail.

Its core job is to transform safe public game information into:

- one battlefield truth;
- one commander recommendation path;
- clear assignments;
- compact commander surfaces;
- explainable reasoning;
- bounded AAR evidence.

KWR is not supposed to be:

- an automation addon;
- a chat bot;
- a spell-rotation helper;
- a wall of icons;
- a collection of disconnected mini-addons.

The standard remains:

> Does this feature consistently improve a team’s probability of winning
> without increasing cognitive load?

## Architecture guardrails

Keep these intact:

- one Store;
- one MatchRuntime ticker;
- one truth pipeline;
- one Strategist;
- one Commander;
- one assignment system;
- one AAR evidence path.

Do not introduce:

- a second command brain;
- a parallel battlefield truth owner;
- duplicated reporter logic;
- duplicated map logic;
- a second compact HUD path.

## Completed since this handoff was first written

These items are done enough to remove from the main active task list, though
live validation may still continue.

1. `Runtime/EnemyIntel.lua`
   - enemy truth presentation now promotes consistently through `LOCAL` and
     `ENGAGED` instead of collapsing to generic visible state.

2. `UI/CombatRoster.lua`
   - enemy pane height now reserves space for the target spotlight so the
     spotlight no longer consumes a combat row.

3. `tests/smoke.lua`
   - deterministic checks now cover the updated enemy truth language and new
     roster geometry expectations.

4. `Runtime/CombatIntel.lua` and `Runtime/ObjectiveIntel.lua`
   - legacy session-key paths now reconcile with current battlefield session
     keys so preview/manual diagnostics no longer clear valid truth records.

5. `Runtime/Commander.lua` and `UI/MainWindow.lua`
   - command stabilization now refuses unrelated recent command reuse.
   - launcher geometry is reconciled with the deterministic smoke path again.

6. Offline verification
   - `tests/smoke.lua` currently passes again with `244` checks.

7. `Runtime/MatchRuntime.lua`
   - post-match refreshes now preserve the last qualified battleground side,
     score, and objectives if widget authority decays before battleground exit.

8. `UI/CombatRoster.lua`, `UI/MainWindow.lua`, `UI/Options.lua`, and
   `Core/Addon.lua`
   - split roster controls now anchor independently from the split panes.
   - expanded-window suppression now routes through the roster request path
     instead of direct secure-frame visibility changes.
   - split-toolbar defaults are now part of the combat-roster profile.

9. `UI/CombatRoster.lua` and `UI/MainWindow.lua`
   - enemy filtering now also prunes same-faction scoreboard rows using the
     resolved battlefield score faction so friendly bleed-through is less
     likely during unstable roster moments.

10. `Data/BattlePlans.lua`
   - reviewed node, flag, and cart plans now speak more explicitly in terms of
     who moves, who stays, and what remains covered.

11. `tests/smoke.lua` and `Runtime/Verification.lua`
   - deterministic coverage now proves next-best-target promotion when one
     engaged enemy drops and another remains live.
   - live verification output now includes clearer enemy-truth and kill-target
     lines for field testing.

### Pillar 1 - Truth

Partially complete, still active.

Improved recently:

- team-side resolution bug identified and patched in `Runtime/TeamResolver.lua`
  so scoreboard self row wins over native faction fallback;
- compact HUD now performs bounded refresh invalidation after transitions,
  suppression restore, post-combat release, enable, and match completion;
- some location abbreviation alignment work exists across command surfaces.

Still unstable / incomplete:

- faction truth still needs live verification after the resolver fix;
- some battlegrounds still show stale or wrong side/pathing in live play;
- enemy truth promotion improved, but still needs live verification and
  next-target follow-through after a kill target disappears;
- compact HUD refresh hardening is in, but live transition/match-end verification
  is still required;
- some map-specific win condition paths still feel generic or incorrect.

### Pillar 2 - Stability and Safety

Improved but not certified complete.

Improved recently:

- recursion loop around minimize/show was previously addressed;
- several protected-action and secure-surface issues were identified and
  reduced;
- `Runtime/EnemyIntel.lua` was fixed so `friendlyIdentityMaps` no longer
  resolves nil in `PruneFriendlyRoster`.

Still unstable / incomplete:

- intermittent runtime faults still appear under heavy live usage;
- split combat roster now separates pane anchoring from split-toolbar
  anchoring, but still needs live `/reload` certification;
- pane/header movement behavior is improved in code, but not yet field-certified;
- some reload-time surface restoration bugs remain possible;
- protected suppression behavior in presentation paths was reduced again, but
  still needs live confirmation under combat transitions.

### Pillar 3 - Decision Quality

Core engine exists. Doctrine depth is still behind the product goal.

Good foundation exists:

- candidate scoring;
- confidence budget;
- assignment integrity concepts;
- momentum / intent / opportunity foundations;
- per-map scenario structure.

Still incomplete:

- opener doctrine is not yet deep enough for real RBG leadership;
- several calls still feel generic instead of map-family / comp-aware;
- recovery and audible logic is not reliable enough yet;
- flag-map and cart-map doctrine especially need deeper reviewed playbooks;
- “who moves / who stays / what remains covered” needs to be stronger and more
  consistent.

### Pillar 4 - Presentation and Commander Usability

Strong direction exists, but the surfaces are not fully locked down.

Improved recently:

- split team/enemy combat roster concept is active;
- compact HUD now carries richer command groups and fuller call text;
- reporter minimization direction is established;
- crosshair / orb system exists in the codebase.

Still incomplete:

- reload drifts pane positions even when lock should preserve them;
- combined/split roster layouts still produce overlap/duplication edge cases;
- opacity/transparency tuning is not finished;
- compact HUD freshness code-path improved, but live validation is still needed;
- nameplate/orb/crosshair presentation is not yet production-ready.

### Pillar 5 - Verification and Learning

Foundation exists, but the evidence workflow still needs discipline.

Good:

- `/kwr verify` exists and is already useful;
- AAR evidence/export path exists;
- multiple project docs already describe constraints and readiness gates.

Still needed:

- unify current status into fewer authoritative docs;
- keep fresh thread handoffs lightweight and current;
- continue using live testing to validate truth before adding more doctrine;
- tighten known limitations and open-issues tracking.

## Known good / reasonably stable areas

These areas appear directionally sound enough to keep:

- overall repo structure;
- one-authority architecture;
- current TOC/module load order;
- AAR export concept and evidence-only philosophy;
- command HUD design direction;
- assignment-integrity emphasis;
- verification-first workflow;
- doctrine/data separation from runtime/UI layers.

## Known broken or provisional areas

These still need active engineering attention:

1. Battleground side/faction truth
   - especially Horde/Alliance perspective on live battleground entry and
     cross-faction scenarios.

2. Compact HUD freshness
   - bounded refresh support was added, but live validation is still needed
     through transitions and match end.

3. Combat roster split layout
   - independent panes and an independent split-toolbar anchor now exist, but
     live reload persistence and field certification still remain.

4. Enemy ingestion/truth promotion
   - promotion is better, but live verification and target-loss follow-through
     still need work.

5. Reporter map truth depth
   - public objective truth is better than movement truth; the map still lacks
     the fully trusted commander-grade presence the product wants.

6. Playbook depth
   - the logic engine exists, but the doctrine depth is still not near the
     “deep reviewed commander playbook” target.

## Highest-priority next tasks

Work these in order.

1. Finish Pillar 1 truth stabilization
   - verify the TeamResolver Horde/Alliance fix in live play;
   - verify the new compact HUD refresh path in live play;
   - live-verify the new post-match final-truth freeze after match end;
   - verify that the new `LOCAL` / `ENGAGED` enemy language stays consistent
     after target changes and combat transitions.

2. Finish Pillar 2 roster/surface stability
   - live-certify split-pane and split-toolbar reload persistence;
   - confirm enemy pane no longer picks up friendly same-faction bleed-through;
   - live-certify expanded-window suppression/restore through combat transitions.

3. Re-verify enemy truth path
   - scoreboard roster ingestion;
   - friendly-prune behavior;
   - local target truth;
   - visible/local/engaged promotion;
   - next-best-target promotion after kill target dies.

4. Deepen battleground doctrine
   - reviewed openers, stabilization, recovery, and endgame states;
   - especially flag maps, node maps, and cart maps;
   - always specify who moves, who stays, and what remains covered.

## Immediate live-test checklist

For the next focused live test, confirm these:

1. Enter a battleground as Horde and verify:
   - command HUD side is correct;
   - reporter side is correct;
   - assignments align with Horde side;
   - flag or node logic matches actual side.

2. Reload in world and in battleground:
   - team pane does not move;
   - enemy pane does not move;
   - split toolbar does not move unless deliberately dragged;
   - headers do not detach;
   - lock truly prevents drift.

3. In split roster mode:
   - no pane overlap;
   - no header or split-toolbar overlap;
   - no duplicated team rows in enemy pane;
   - enemy pane height contains all rows cleanly.

4. During live combat:
   - enemy rows become local/visible/engaged when appropriate;
   - compact HUD updates with main board;
   - target spotlight follows real target truth;
   - no `/reload` is needed to correct normal state.

## Newly discovered since this handoff was written

1. No new blocking offline regression is open right now
   - the smoke suite is green again, so the remaining work should focus on live
     validation and battleground-exit truth cleanup instead of offline breakage.

## Important recent fixes already applied

These are worth preserving and rechecking, not re-arguing:

1. `Runtime/EnemyIntel.lua`
   - fixed `friendlyIdentityMaps` nil-call issue by forward-declaring and then
     defining the helper correctly for earlier use.

2. `Runtime/TeamResolver.lua`
   - changed resolution priority so scoreboard self row is preferred over
     native faction lock, with native faction only as fallback.

3. `UI/CombatRoster.lua`
   - started converting split-pane positioning toward independent screen-space
     anchors instead of hidden-holder-relative drift.
   - enemy pane now reserves spotlight space without consuming a row.

4. `Runtime/CombatIntel.lua` and `Runtime/ObjectiveIntel.lua`
   - now preserve bounded combat/objective truth across legacy and current
     battlefield session-key formats.

5. `Runtime/Commander.lua`
   - stabilization now requires the same derived command signature before it
     reuses a recent decision timestamp.

## Current recommendation

The addon is suitable for continued alpha field testing, but not yet suitable
for trusted leadership without the user expecting wrong/generic calls in some
maps and some surface desync/roster issues.

That means:

- good enough to keep learning from live matches;
- not yet good enough to call “stable commander release candidate”.

## Fresh-thread instruction

If starting a new Codex thread, begin with:

1. this file;
2. `docs/WORKFLOW_NOW.md`;
3. `docs/THREAD_STARTER_2026-07-06.md`;
4. `PILLAR_EXECUTION_SHEET.md`;
5. one or two current screenshots/errors only.

Avoid carrying the full historical chat unless absolutely necessary.
