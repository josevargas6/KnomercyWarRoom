---
id: KWR-288
title: Tie local execution countdowns to an explicit start and deadline
owner: Codex
priority: high
risk: medium
status: completed
dependencies: [KWR-281, KWR-287]
affected_modules: [CountdownState, TeamfightCommandPlanner, ExecutionCommandBuilder, MainWindowCommands, CombatRosterVisuals, MatchRuntime, CommandAudio, tests]
authority_references: [AGENTS.md, PRODUCT_ROADMAP.md, RELEASE_READINESS.md]
---

# Objective

Implement the genuine-countdown portion of OVR-05. Current planner refreshes
generate a new five-second cue without any leader start or execution deadline.

# User outcome

Calls remain on leader call until the local group leader starts a countdown.
Refreshing never restarts it, and changed target/assignment/objective/match truth
cancels it.

# Required behavior

Add `/kwr countdown 1..10` and `/kwr countdown cancel`. Starting requires live,
non-preview match identity, group leadership and an eligible GUID-identified
target. Record a transient cue ID/start/deadline against sorted semantic plan
inputs. GO lasts at most one second. All local cards, assignment windows and
execution text use the same deadline. Copied stale records cannot display or
speak a GO after cancellation/expiry. Runtime reset cancels the cue.

# Non-goals

Remote clock synchronization, canonical ActivePlay revision reconciliation,
public-event deadline adapters and broader target/coverage truth remain separate
OVR work. No combat automation, transport changes or persistence.

# Technical constraints

Extend CountdownState; do not create another play service. Use existing refresh
cadence rather than new per-frame work. Preserve KWR-280 terminal-play behavior.

# Acceptance criteria

- [x] Untimed plans never invent numeric countdowns or GO.
- [x] A start at 100+5 projects 5,4,1,0 at 100,101,104,105 without refresh resets.
- [x] Invalid starts are rejected; cancel, expiry, clock rollback, runtime reset
  and semantic target/assignment/objective/session changes prevent stale cues.
- [x] All local surfaces share timing, including stale-record audio protection.
- [x] Source and extracted-package checks pass with evidence.

# Verification

Use controlled clocks and actual planner/presentation modules; test slash-command
and reset integration. Run source smoke and package extraction. These do not
prove live latency, multiplayer synchronization or physical-client restrictions.

September 6 source checkpoint: Smoke passes with
`tests/fixtures/explicit_countdown.lua`. It tests actual planner, execution packet,
card/HUD model, slash routes, isolated runtime reset/stop and queued audio callback.
The existing one-second runtime ticker requests tactical projection only while a
cue is active. No fixed five-second presentation remains in runtime source.
Cue eligibility also requires the target to remain known alive and locally
observed; broader vulnerability/capability evidence requirements remain open.

Package closure: `artifacts/explicit-countdown-20260906-package/` passes extracted
player/developer smoke and 500-refresh soak, knowledge regeneration, Sentinel
transport, DevTools lifecycle and four ZIP hashes. Source hashes are recorded in
`artifacts/explicit-countdown-20260906/source-checks.json`. The default source replay
passes via fallback only. This dirty interim package skipped clean reproducibility
and was not installed. OVR-05 canonical lifecycle/relay and real-client gates remain.

# Rollback

Disable explicit starts while retaining untimed on-leader-call presentation,
existing objective commands and user settings.
