---
id: KWR-257
title: Delay battlefield roster presentation until identity settles
owner: KWR
priority: high
risk: low
status: completed
authority_references: [ARCHITECTURE.md, DESIGN_CONTRACT.md]
dependencies: [KWR-255]
affected_modules: [Runtime/MatchRuntime.lua, UI/CombatRosterState.lua]
---

# Objective

Prevent transient battleground entry rows from being shown in the Team and Enemy panels.

# User outcome

The visible lists populate together after the local team roster is complete and identity-stable, rather than showing provisional or duplicate entries while players enter the battleground.

# Current behavior

The runtime correctly schedules roster settlement refreshes, but publishes the first capture to the compact panels immediately.

# Required behavior

Keep strategic capture active while the UI waits for the expected roster count with stable unit bindings. Show both panels together when ready. After eight seconds, show the best available truth so a disconnect or late join cannot leave the panels blank.

# Non-goals

Do not delay assignments, strategy, Sentinel relays, or infer unobserved enemy identity.

# Technical constraints

Use the existing MatchRuntime lifecycle and CombatRoster presentation boundary. Do not add event frames, saved variables, or protected-frame operations.

# Acceptance criteria

- [x] Team and Enemy panels do not render provisional roster rows during battleground entry.
- [x] Panels render once the expected roster is complete and unit-stable.
- [x] A bounded timeout renders available information after eight seconds.
- [x] Strategy capture continues while presentation is gated.

# Verification

1. Run `tools/validate.ps1`.
2. Run `tools/test-lua.ps1`.
3. Field-test a fresh battleground entry and confirm the panels populate without duplicate entries.

# Rollback

Revert this task's single commit; capture and assignment logic are unchanged.
