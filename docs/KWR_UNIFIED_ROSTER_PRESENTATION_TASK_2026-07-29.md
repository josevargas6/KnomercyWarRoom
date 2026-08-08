---
id: KWR-047
title: Rebuild Team and Enemy tracking as one roster presentation system
owner: codex
priority: critical
risk: high
dependencies:
  - KWR-028
  - KWR-032
  - KWR-035
affected_modules:
  - Core/Addon.lua
  - Runtime/TeamResolver.lua
  - Runtime/EnemyIntel.lua
  - UI/CombatRoster.lua
  - UI/CombatRosterState.lua
  - UI/CombatRosterVisuals.lua
  - UI/RosterPresentation.lua
  - UI/MainWindow.lua
  - UI/MainWindowPages.lua
  - UI/MainWindowReports.lua
  - UI/Options.lua
  - Runtime/MatchRuntime.lua
  - tests/smoke.lua
  - tools/build.ps1
  - tools/build-starter-corpus.ps1
  - tools/validate.ps1
  - docs/ADR_2026-07-29_UNIFIED_ROSTER_PRESENTATION.md
---

# Objective

Replace the fragmented Team/Enemy tracker presentation with one coherent roster
system that preserves the proven live truth, secure interaction, assignments,
enemy intelligence, and combat behavior.

# User outcome

The player sees one recognizable KWR roster surface, can locate a teammate or
enemy immediately, experiences stable rows instead of visual reshuffling, and
does not pay for full pipeline refreshes or complete page construction merely
to open a tracker.

# Current behavior

- Compact BOTH mode is composed from separately anchored Team, Enemy, and
  toolbar surfaces around a transparent one-pixel parent.
- The target spotlight is another visually independent card and repeats row
  information.
- Compact rows expose too many simultaneous fields for combat scanning.
- The expanded Enemy page repeats its column language and permanently gives a
  large portion of the page to instructions and data-limit prose.
- The expanded Team page reserves fifteen rows even in eight- or ten-player
  battlegrounds.
- MainWindow constructs every page and the enemy-note editor on first open.
- Showing CombatRoster forces the entire runtime decision pipeline to refresh.
- MainWindow redraws the active page on every Store revision; compact rows
  partially diff their bodies but headings, spotlight, ordering, and binding
  work still wake on every revision.
- Shared friendly/enemy truth cleanup is incorrectly owned by compact UI code
  and consumed by the expanded page.

# Required behavior

- Use one compact frame, one backdrop, one toolbar, one saved anchor, and one
  layout owner.
- Present Team and Enemy as lanes inside the same frame in BOTH mode.
- Integrate the local-fight command lane into the roster chrome instead of
  presenting another detached card.
- Keep compact row content bounded to identity, health truth, and one current
  job/action state. Move secondary details to tooltips.
- Preserve all ten pre-created secure Team and Enemy rows, target/focus clicks,
  and combat-lockdown behavior.
- Keep published player identity and enemy truth cleanup in TeamResolver and
  EnemyIntel rather than presentation code.
- Keep enemy row slots stable for the battlefield session; transient
  visibility and age change emphasis, not row identity.
- Build expanded pages on demand and build the enemy-note editor only when
  first requested.
- Make the expanded Team/Enemy pages use roster-size-aware geometry and one
  selected-row detail workflow instead of permanent instructional sidebars or
  one large note button per enemy.
- Remove presentation-owned full runtime refreshes. Visible surfaces render
  the current Store state and wait for the established runtime event/pulse
  pipeline.
- Diff page sections and rows so unchanged Store publishes cause no row text,
  texture, backdrop, or visibility mutations.
- Expose render-update and render-skip diagnostics for compact and expanded
  roster surfaces.
- Migrate legacy split-pane and solo anchors to the unified root anchor without
  losing the user's existing approximate screen position.

# Non-goals

- Do not rewrite Sensors, prediction, strategy, assignments, combat
  intelligence, Reporter, or synchronized execution commands.
- Do not add another state model, tracker, event frame, ticker, or polling loop.
- Do not remove priority marks, notes, historical spec provenance, safe
  last-seen evidence, legal health, carrier states, or KILL/PRESS/CC truth.
- Do not automate targeting, focus, communication, or combat actions.
- Do not claim unavailable enemy health, specialization, cooldown, trinket, or
  location data.
- Do not redesign unrelated KWR surfaces.

# Technical constraints

- Secure unit and macro attributes are created and bound only out of combat.
- Protected row visibility, hierarchy, and anchors are not mutated in combat.
- Direct secret health values may be passed only through the existing safe
  display boundary and are never compared, divided, rounded, or persisted.
- Store remains the only published live-state authority.
- Layout runs only on creation, explicit mode/scale changes, or migration.
- All loops remain bounded to the supported battleground roster size.
- Color reinforces state but every important state retains a short text label.
- User-facing strings introduced or consolidated by this work must be routed
  through the existing localization boundary when one exists, or isolated for
  the planned localization pass.

# Acceptance criteria

- [x] Compact BOTH mode is one frame with one drag anchor and no independent
      pane or toolbar movement.
- [x] TEAM, ENEMY, and BOTH retain secure target/focus behavior.
- [x] Compact rows show no more than identity, health, and one job/action lane.
- [x] Local-fight action is clear without duplicating spec, truth, and status
      across multiple badges.
- [x] Friendly and enemy row identity remains stable through visibility and
      last-seen churn.
- [x] Showing CombatRoster performs no `MatchRuntime:ForceRefresh`.
- [x] MainWindow builds only the requested page; the note editor is on demand.
- [x] Expanded Team and Enemy rows use signatures and skip unchanged updates.
- [x] Expanded Team legal direct health is visibly distinct from unknown.
- [x] Historical specialization provenance agrees across compact and expanded
      surfaces.
- [x] The expanded Enemy page has no permanent instruction sidebar or repeated
      column legend.
- [x] No unchanged semantic Store publish mutates non-health roster visuals.
      Legal direct health remains independently live.
- [x] Legacy roster positions migrate to one valid on-screen root position.
- [x] No new OnUpdate, ticker, duplicate event registration, or parallel live
      state is introduced.
- [ ] Validate, knowledge audit, smoke, soak, and build gates pass.
- [ ] Live 1280x720, 1920x1080, and 2560x1440 captures prove readability over
      bright, dark, and active-combat scenes.

# Verification

1. Run `tools/validate.ps1`.
2. Run `tools/knowledge-audit.ps1`.
3. Run `fengari tests/smoke.lua`.
4. Run `fengari tests/soak.lua`.
5. Run `tools/build.ps1`.
6. Enter an eight-player Blitz and a ten-player battleground with clean saved
   variables and with an upgraded split-pane profile.
7. Exercise TEAM, ENEMY, BOTH, expand, close, target, focus, death, reconnect,
   roster hydration, target change, priority change, note editing, and combat
   enter/leave.
8. Capture `/kwr perf`, `/kwr verify`, taint evidence, and supported-resolution
   screenshots.

## Implementation verification

- `tools/validate.ps1`: passed with 123 Lua files, zero errors, and zero
  warnings.
- `tools/knowledge-audit.ps1`: passed with zero errors.
- `tools/build.ps1 -SkipPackageAudit`: passed, including the reproducibility
  build, and produced the alpha.29 distribution and developer packages.
- The roster-specific Fengari checks pass, covering runtime truth ownership,
  migration, stable enemy slots, lazy page construction, unchanged-row skips,
  unified geometry, retained target/focus bindings, and no refresh-on-open.
- The complete `tests/smoke.lua` passes all six lazy-page and roster render
  sections (`20` row updates and `110` semantic skips), then reaches the
  pre-existing runtime queue assertion and fails because the newest coalesced
  truth update is discarded. `tests/soak.lua` stops on the smoke prerequisite
  before its 500-iteration loop.
- The full package-audit script still requires a shell-visible Node.js
  executable; the build was therefore run with `-SkipPackageAudit`.
- Live battleground, combat-lockdown, taint, upgrade-position, and resolution
  capture verification remains required before field promotion.

# Rollback

Restore the prior split-pane CombatRoster construction, eager MainWindow page
construction, and revision-driven page rendering. Retain a schema migration
guard capable of reading the unified anchor when rolling back, or restore the
pre-migration SavedVariables backup before loading the older build.
