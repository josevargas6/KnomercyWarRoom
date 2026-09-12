# P09 — Calm commander UX, accessibility and localization

Parent: [KWR-297](../KWR-297-s-tier-completion-packages.md).
Read [execution standard](execution-standard.md). OVR-19.
Lead: Terra Medium after approved contracts; High reviews semantic consistency.
Dependencies: P05 command/secure projection, P03 jobs, P06 review labels.

The owner's subsequent request makes the primary fight/mini-command card a
dedicated **Astra** rebuild in [KWR-298 / P13](../KWR-298-commander-callout-card-rebuild.md).
That task owns HUD/card information hierarchy, long-name layout and primary
CommandView projection changes. P09 supplies surrounding application UX and
shared verification only; Terra must not run a competing card restyle or edit
the same files concurrently. Click feedback is [KWR-299 / P14](../KWR-299-command-followthrough-feedback.md).

## What and why

The commander should see the current call, personal/team responsibilities,
location, deadline and uncertainty at a glance. More panels, louder audio or
more numbers do not establish usefulness. Improve the existing surfaces first.

## Existing surfaces

`UI/MainWindow.lua`, `MainWindowCommands.lua`, `MainWindowPages.lua`,
`MainWindowReports.lua`, HUD, CombatRoster, ReporterMap, TeamfightCommandCard,
Options, AARWindow and `Core/CommandView.lua`. Use existing themes/components
and locale mechanisms. Inspect real callers before deciding whether DebugReasonPanel
or ReporterMap belongs in player runtime or DevTools.

## In-progress implementation evidence (2026-09-11)

The complete Commander card speaks and ordinarily displays player short names
only. If multiple retained canonical identities share the same short name, the
visual card uses stable non-realm ordinals (for example `Alex [1]` and
`Alex [2]`) while speech remains `Alex`; GUID/full identity remains internal to
the call key and review boundary. The Commander-card projection fixture proves
the two visual labels, realm-free speech and rendered-content propagation. This
does not replace the remaining client accessibility/localization matrix.

## Implementation instructions

1. Inventory each existing command display/copy/audio/help surface and its source
   fields. Map them to P05's current revision. Render a consistent compact core:
   next call, objective/place, who moves, who stays, personal job, when and trust.
Secondary explanations and alternate plans are expandable, not always visible.
2. Represent pressure versus kill commit, observed versus inferred, unknown
   score, stale evidence, conditional route, shortages and local-only transport
   with concise text and non-color cues. No unknown value displayed as zero.
   Error and unavailable states must state a practical recovery action.
3. Keep command help accurate. `/kwr field` starts Diagnostic context; leadership
   evidence uses `/kwr commander` and per-call delivery attestation. Explain any
   explicit transport opt-in. DevTools disabled means capture off; loaded code
   remains until reload. No button changes evidence context retroactively.
4. Use stable IDs for logic and localizable strings for labels. Truncate UTF-8
   safely, retain full canonical identity internally, and disambiguate duplicate
   short names visibly. Do not parse localized display prose back into decisions.
5. Layout against supported resolution/UI-scale combinations, long translations,
   unknown/empty/overflow states and large accessibility text. Preserve a usable
   compact layout; do not hide mandatory information merely to remove clipping.
6. Gate optional controls dynamically when DevTools loads/fails/disables/re-enables.
   No stale buttons or layout overlap when capability availability changes.
7. Audio is opt-in, bounded and revision-aware. Cancel obsolete cues, prevent
   duplicate terminal announcements and provide a visual equivalent. Do not add
   automatic gameplay or communication as a convenience shortcut.
8. Rendering does not mutate Store/domain state. Hidden panels skip expensive
   rendering but show the latest valid revision when reopened. P07 measures the
   real subscriber/display tail, including the options and AAR screens.

## Verification

Create deterministic layout/state fixtures with the existing UI mocks or a
bounded projection harness. Compare each surface's semantic command fields and
revision; screenshot similarity alone cannot prove semantic consistency.

Exercise world/empty, missing widget, lead, emergency, no feasible assignment,
two same short names, long locale, companion missing/load failure, companion
toggle, transport blocked and interrupted old AAR. Run every help-listed command
with and without DevTools; unavailable commands must explain recovery.

Review layouts at 1080p/1440p/4K and UI scales 0.65/0.8/1.0 using offline artifacts
where feasible. Actual WoW font/frame/scaling proof stays FIELD. Save reviewable
screenshots or coordinate/bounds assertions; do not claim visual QA from merely
creating files. Test keyboard/tab interactions where supported and non-color
indicators. Audio fixtures must prove cancellation by generation/revision.

P12's user test asks a commander to identify the next call, who moves/stays and
their job within five seconds. A model reading source is not that usability test.

## Acceptance criteria

- [ ] All surfaces present one current, truthful command and clear degraded states.
- [ ] Supported commands, companion states and localization fixtures pass.
- [ ] Offline layouts show no essential clipping; actual client matrix stays open.
- [ ] Audio/visual cues cancel consistently and rendering never mutates truth.
- [ ] Five-second comprehension is prepared and measured only in P12.

## Rollback and handoff

Make bounded component edits and retain existing layout preferences/migrations.
Do not overwrite user settings. Handoff before/after layouts, tested state/locale
matrix, command-help coverage, projection assertions and known client-only checks.
