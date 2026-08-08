# External Test Plan

## Purpose And Restrictions

This plan certifies a single hashed candidate for controlled external testing. It does not authorize broad distribution. Testing must not begin until R0-001 through R0-005 are repaired, offline gates are rerun, and the release owner approves the locale, SavedVariables, performance, and secure-UI decisions in `RELEASE_GATE_CHECKLIST.md`.

Current recommendation: **CONDITIONAL GO — external testing allowed after listed blockers are repaired**.

## Prerequisites

- Use the exact distribution archive and SHA-256 recorded by the release owner; do not test a developer-folder checkout as the candidate.
- Confirm Retail interface compatibility against the installed client and both TOCs before launch.
- Back up `WTF/Account/<account>/SavedVariables/KnomercyWarRoom.lua` and the Sentinel SavedVariables file before upgrade testing.
- Start from a client with no Lua errors and enable error display with `/console scriptErrors 1`.
- Enable taint logging for secure-UI scenarios with `/console taintLog 1`; archive only the relevant sanitized lines.
- Record client build, locale, OS, resolution, UI scale, addon version/hash, enabled addon list, test character role, group size, battleground, and scenario ID.
- Run War Room alone first. Run Sentinel, Cursor Ring, and other optional configurations only after the base candidate passes.
- Do not enable or add addon-message transport. Current release behavior is local-client only.
- English-only testing is permitted only if the owner explicitly accepts that restriction and the package communicates it.

## Installation Profiles

**Clean profile:** Remove the addon folder, install the candidate archive, and start with no KnoMercy War Room SavedVariables. Do not reuse a developer package.

**Upgrade profile:** Copy a sanitized real prior SavedVariables file and each supported fixture into separate profiles. Preserve the original backup. Test at least the most recent public/controlled version and the oldest schema the migration claims to support.

**Recovery profile:** Prepare malformed-but-parseable fixtures: wrong root scalar/table types, missing nested branches, invalid list elements, unknown future schema, partially populated opponent/assignment data, and missing optional module state. Never use live account identifiers in shared fixtures.

## Required Scenario Matrix

| ID | Scenario and method | Expected outcome | Required evidence | Stop condition |
|---|---|---|---|---|
| XT-001 | Fresh install: launch clean profile, inspect defaults, open/close every surface, enter staging and a match | No Lua error; defaults are usable; no stale match; all required modules report healthy | Startup diagnostics, `/kwr verify`, screenshots of core surfaces | Init error, missing required module, corrupt default, or blocked action |
| XT-002 | Prior SavedVariables upgrade: repeat for every supported fixture and one sanitized real file | Migration is idempotent; settings/history/notes/overrides survive according to policy; ambiguous identity is preserved safely | Before/after schema summary and fixture assertions without player data | Data loss, wholesale reset, repeated migration, identity merge, or write error |
| XT-003 | `/reload`: test idle, staging, active match, and after match | One runtime/ticker/callback set; UI and state recover; interrupted AAR follows policy; no duplicate calls | Diagnostics before/after, callback/ticker counts, AAR result | Duplicate registration, error, stale secure state, duplicate AAR, or unexplained loss |
| XT-004 | Relog: exit to character selection and return during idle and between match phases where feasible | Persistent data survives; process-only caches reset safely; no stale group/match state | SavedVariables diff summary and diagnostics | Corrupt write, stale active match, missing persistent user data |
| XT-005 | Enable/disable: disable addon, reload, re-enable, reload; repeat optional modules independently | Disabled addon performs no runtime work; re-enable initializes once; optional absence degrades explicitly | Addon list/config record, startup health, Lua error log | Residual ticker/frame, duplicate init, required dependency hidden as ready |
| XT-006 | Combat enter/leave: toggle MainWindow/QuickCalls/CombatRoster before and during lockdown; trigger Store/context visibility changes | No taint or blocked action; protected changes defer; final requested state applies once after combat | Sanitized taint log, video or timestamped action notes | Any taint, blocked protected action, secure click failure, or stuck UI |
| XT-007 | Group content enter/leave: solo to party/raid/battleground and back; queue accept, zone transitions, disband | Runtime activates only in intended context, settles finitely, and clears roster/objective state on leave | Runtime reason counters, snapshots at each transition | Sustained refresh after leave, stale roster/objectives, duplicate settle loop |
| XT-008 | Leadership/role changes: leader transfer, assistant change, role/spec update, defender/assignee changes | Authority and assignments update once; no unsupported command authority is inferred | Assignment/Commander evidence and role snapshots | Wrong leader authority, duplicate assignment, stale role, false urgent call |
| XT-009 | Reconnect: disconnect/reconnect during staging and active match where safe | State rehydrates from authoritative APIs; stale observations expire; no duplicate runtime or completed AAR | Reconnect timeline, diagnostics, AAR status | Duplicate callbacks/tickers, fabricated locations, permanently stale state |
| XT-010 | Malformed/missing data: use test seams where available and live API absence during loading/zone transitions | Defensive fallback; no error cascade; no false precision; recovery occurs on next valid observation | Fixture result and relevant diagnostic reason | Lua error, silent required-module failure, fabricated ownership/location |
| XT-011 | Optional modules disabled: Cursor Ring off, Sentinel absent/off, each commander surface hidden | Core strategy remains functional; inactive module has no update loop or error | Module health and performance counters | Core dependency on optional module, residual polling, missing required feature |
| XT-012 | UI scales/resolutions: 1920x1080, 2560x1440, ultrawide if available; UI scale minimum/typical/maximum; windowed/fullscreen | Frames remain reachable, readable, clipped safely, and retain positions within bounds | Screenshots for every configuration | Unreachable controls, severe overlap/clipping, protected layout error |
| XT-013 | Low/full groups: solo/partial group, 10-player rated-size group, and 40-player/nameplate stress simulation where available | No nil assumptions; identity remains distinct; refresh/memory remains within budget | Group-size diagnostics and performance export | Error, identity merge, unbounded cache, budget breach |
| XT-014 | Recovery: inject optional module init failure, transient API nil, corrupt field, and UI creation rejection through test seams | Required failure blocks readiness; optional failure is explicit; system recovers after cause removal | Health status and recovery trace | Reports ready while required module failed, cascading errors, unrecoverable UI |
| XT-015 | Worst-case performance: full supported group, dense fight/nameplates, health/roster/objective bursts, all surfaces; repeat with Cursor Ring and Sentinel | p95 <=2 ms, routine max <4 ms, no sample >10 ms, median FPS loss <1%, 1% low loss <3%, retained memory growth <1 MB/30 min | Raw bounded perf export, FPS capture, memory samples, exact config | Any >10 ms addon refresh, sustained >4 ms stage, FPS/memory threshold failure |
| XT-016 | Objective authority: create/observe widget and map-POI disagreement, transitions, stale widget fallback | Fresh authoritative widget state cannot be downgraded; stale state yields to supported source | Sensor provenance/evidence and screenshot | Wrong owner/state or nondeterministic merge |
| XT-017 | Enemy coordinate truth: assignment-only, teammate-near-enemy, direct observed enemy, stale direct observation | Only direct supported observation renders a dot; semantic association stays text-only | Provenance export and ReporterMap screenshots | Any inferred/fabricated dot or non-expiring stale dot |
| XT-018 | Identity collision: two players with same short name from different realms/GUIDs | Separate records, assignments, notes, and display rows | Sanitized IDs or deterministic fixture trace | Merge, overwrite, or ambiguous migration silently assigned |
| XT-019 | Complete match by each supported map family | Calls, assignments, objectives, win conditions, end transition, and AAR remain coherent | `/kwr verify`, evidence, AAR, tester notes | False high-confidence call, state lockup, missing end cleanup |
| XT-020 | Cross-faction/mercenary and unknown spec/class cases where available | Display and identity remain correct; unknown data degrades without invented values | Sanitized roster snapshot and screenshot | Team inversion, merged identity, nil error, fabricated spec |

## Execution Order

1. Run XT-001, XT-002, XT-005, XT-010, XT-011, XT-012, XT-014, and XT-018 on isolated profiles before inviting match testing.
2. Run XT-003, XT-004, XT-006, XT-007, XT-008, and XT-009 with one internal tester and taint/error logging enabled.
3. Run XT-016 and XT-017 to certify the repaired truth/authority blockers.
4. Run XT-013 and XT-015 with instrumentation enabled and stable graphics/configuration.
5. Run XT-019 and XT-020 with a small named tester cohort. Expand only after two complete error-free matches and acceptable performance traces per major map family available.

## Performance Capture

- Warm the UI for five minutes before recording memory growth.
- Record addon-disabled baseline, base War Room, all War Room surfaces, Cursor Ring, Sentinel, and all enabled together.
- Record p50, p95, p99, maximum, execution count, coalesced count, queue delay, and stage totals by refresh reason.
- Sample Lua memory at start, after warm-up, and each minute for 30 minutes. Record both high-water and post-natural-GC retained values.
- Use the same character, graphics settings, resolution, nameplate settings, combat-log settings, and battleground conditions for comparative FPS runs.
- Do not upload names, realms, GUIDs, chat, account paths, or raw combat logs. Redact before sharing.

## Functional Evidence Commands

- `/kwr verify`: capture bounded strategy, assignment, objective, and evidence state after each critical scenario.
- `/kwr bug`: capture the addon-provided diagnostic bundle only after privacy review.
- `/kwr perf`: capture timing/memory summaries after instrumentation is repaired and validated.
- `/kwr evidence`: capture only if the command output is bounded and scrubbed of identity data.
- `/console scriptErrors 1`: keep Lua errors visible.
- `/console taintLog 1`: use for secure UI scenarios; reset after testing if desired.

Command names and output formats must be confirmed against the candidate because documentation is not treated as proof. If a command is unavailable, record that as a failed or blocked evidence step rather than substituting an undocumented claim.

## Tester Report Template

```text
Scenario ID:
Candidate version and SHA-256:
WoW build / locale / OS:
Resolution / UI scale / graphics preset:
Enabled addons and optional KWR modules:
Character role / group size / battleground:
Exact starting state:
Exact steps and timestamps:
Expected result:
Actual result:
Frequency (first / intermittent / every time):
Lua error or taint line, sanitized:
/kwr verify or diagnostic excerpt, sanitized:
Performance p50/p95/p99/max and memory, if relevant:
Screenshot/video filename:
SavedVariables fixture class (never account path):
Recovery attempted and result:
Privacy review completed by:
```

## Privacy And Trust Rules

- Treat character names, realms, GUIDs, group composition, chat, and SavedVariables as user data.
- Share the minimum diagnostic excerpt needed to reproduce. Replace identities consistently so relationships remain debuggable.
- Do not ask testers to share complete `WTF` folders, raw combat logs, or account directory names.
- Do not transmit diagnostics automatically. All exports remain explicit and local.
- Reject any candidate that introduces undeclared addon-message traffic or accepts remote authority without a separately approved security review.

## Rollback

1. Exit the client before changing addon files or SavedVariables.
2. Remove the candidate folder and restore the previous known-good folder as a complete unit; do not mix files across builds.
3. Restore the pre-test SavedVariables backup if a migration or write defect occurred.
4. Record the candidate hash, failed scenario, last known valid state, and rollback result.
5. Do not reissue the same hash after a code change. Build and certify a new candidate.

## Stop Criteria

- Any P0 event: data destruction beyond the test fixture, broad security/privacy breach, client instability attributable to the addon, or unusable core operation.
- Any open or reproduced P1: Store suppression, objective downgrade, fabricated enemy coordinate, secure-frame taint/blocked action, or equivalent release blocker.
- SavedVariables loss, non-idempotent migration, or distinct-player identity merge.
- Any addon refresh over 10 ms, sustained stage over 4 ms, retained memory growth over 1 MB/30 minutes, or FPS loss beyond the adopted budget.
- Duplicate tickers/callbacks after reload/reconnect, unbounded refresh after leaving content, or error cascade.
- Any undisclosed outbound addon communication or diagnostic identity leak.
- Three reports of the same P2 across different profiles, or one deterministic P2 affecting core match recommendations, until triaged and dispositioned.

## External Release Acceptance

Controlled external testing may begin only when every Phase 0 item is accepted, all offline commands pass on the exact source, the distribution artifact runtime test passes, and the clean/upgrade/combat truth scenarios XT-001, XT-002, XT-006, XT-016, XT-017, and XT-018 pass.

Expansion beyond controlled testers requires all mandatory release gates to pass, no open P0/P1, explicit owner disposition for every P2, two clean lifecycle cycles, representative complete-match evidence, adopted performance thresholds met, privacy review complete, and rollback restoration proven.
