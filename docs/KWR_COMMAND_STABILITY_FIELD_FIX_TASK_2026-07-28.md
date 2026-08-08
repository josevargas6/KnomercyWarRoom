---
id: KWR-033
title: Repair live flag-match command churn and stability reporting
owner: unassigned
priority: high
risk: high
status: LIVE_ONLY_REMAINDER
dependencies:
  - docs/field-evidence/2026-07-28-twin-peaks/README.md
affected_modules:
  - Runtime/Commander.lua
  - Runtime/AAR.lua
  - UI/AARWindow.lua
  - Core/Diagnostics.lua
  - tests/smoke.lua
  - tests/soak.lua
---

# Objective

Bring live Twin Peaks command publication inside the existing stability budget
and make the AAR distinguish total command activity from bounded journal
retention.

# User outcome

The commander receives stable, actionable calls rather than rapid replacements,
and the AAR accurately explains how many commands were issued, replaced,
suppressed, and retained.

# Current behavior

The 14:20 Twin Peaks defeat records:

- `SWAPS 58`;
- `STABILITY REVIEW`;
- `AVG LIFE 0:00`;
- `OVERRIDES 65`;
- `CALLS 18`.

Code inspection confirms:

- `SWAPS` is `Commander`'s published-command replacement count;
- `STABILITY REVIEW` means the existing churn budget failed;
- `OVERRIDES` counts ActivePlay replacements, not manual assignment overrides;
- `CALLS 18` is the bounded `AAR.maxCommands` history size, not the total
  issued-command count.

# Required behavior

- Identify which command-signature, active-play, invalidation, or event fields
  caused rapid replacement during the flag match.
- Suppress publication when the actionable command contract did not materially
  change.
- Preserve emergency, decisive invalidation, match-complete, and explicit
  reassessment bypasses.
- Keep the current persistence, superiority, reversal, and pre-arrival budgets
  visible; do not pass by clearing or hiding metrics.
- Persist total evaluations, issued commands, replacements, suppressions,
  reversals, and ActivePlay switches in the AAR.
- Label bounded command records separately from total issued commands.
- Rename or qualify `OVERRIDES` so it cannot be mistaken for manual assignment
  overrides.

# Non-goals

- No slower response to a real carrier pickup, score change, objective loss,
  match completion, or manual reassessment.
- No removal of ActivePlay.
- No larger unbounded journal.
- No unrelated strategy or UI redesign.

# Technical constraints

- One `Commander` remains the command authority.
- Existing persistence and superiority gates remain data-driven.
- Refresh work remains bounded.
- Metrics must retain the failing sample until a new match begins.
- AAR retention may remain bounded, but the UI must state that boundary.

# Acceptance criteria

- [x] A deterministic noisy flag-event replay does not republish an unchanged
  actionable command.
- [x] Decisive carrier, score, and match-complete changes still bypass
  retention immediately.
- [x] Reversal rate is at or below 5% in the qualifying replay.
- [x] Pre-movement invalidation rate is at or below 10%.
- [x] Median objective-command lifetime is at least 20 seconds unless a
  documented decisive bypass applies.
- [x] AAR distinguishes total issued commands from retained command records.
- [x] ActivePlay switches are not labeled as manual commander overrides.
- [x] `/kwr verify`, `/kwr perf`, and AAR show the same stability totals.
- [x] Validate, knowledge audit, smoke, soak, build, and package audit pass.
- [ ] A complete live flag match reports `STABILITY PASS`.

# Offline implementation result

Reopened on 2026-08-03 as an offline implementation blocker. Stability totals
now expose evaluations, issued commands, replacements, suppressions, and
bounded retained records from the same Commander metrics source. AAR labels
ActivePlay switches explicitly and reports unavailable lifetimes as unknown;
the complete-match result remains live-only.

# Verification

1. Add a deterministic Twin Peaks event/noise replay.
2. Run `tools/validate.ps1`.
3. Run `tools/knowledge-audit.ps1`.
4. Run `fengari tests/smoke.lua`.
5. Run `fengari tests/soak.lua`.
6. Run `tools/build.ps1`.
7. Capture `/kwr verify`, `/kwr perf`, and AAR from one complete flag match.

# Rollback

Restore the prior publication and AAR labels together. Do not retain new labels
against old metric semantics.
