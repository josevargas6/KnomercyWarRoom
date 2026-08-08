# KWR Alpha.29 Stable Anchor

Date: 2026-07-30

This document records the new stable offline working point for KWR Commander
before the next visual field-testing session.

## What is now anchored

- `tools/validate.ps1` passes
- `tools/knowledge-audit.ps1` passes
- `tools/test-lua.ps1` passes
  - smoke: 275 checks
  - soak: 500 refreshes with bounded refresh cost
  - replay: strict pass
- the reviewed doctrine library is live
- the scenario calibration library is live
- the adversarial calibration library is live
- the expert review corpus is live
- the bounded enemy-response planner is live
- strategist output now carries:
  - reviewed scenario calibration
  - adversarial scenario calibration
  - expert scenario review
  - bounded enemy-response planning
  - consequence score adjustment

## What this means

KWR is no longer just a tactical UI candidate with baseline heuristics. It now
has a reviewed offline decision layer that:

- compares reviewed scenario lines
- carries expert preferred actions and counters
- predicts a likely enemy answer from legal battlefield facts
- adjusts consequences before presenting the recommended line

That is a meaningful step toward expert-tier command support. It is still a
human-command product, not an automated battleground player.

## What is still not proven

These items still require live field evidence:

- visual clarity at live resolutions and real combat pace
- command stability under noisy battleground transitions
- taint and blocked-action safety through a full match cycle
- match-end AAR truth and command-life stability
- exact readability of current call, next call, posture, kill, and CC lanes
- supported-map live capture across the full battleground matrix

## Best immediate use of the next field session

1. Verify the compact combat HUD is readable in motion.
2. Verify the split Team and Enemy trackers feel clean and useful.
3. Verify current and next calls always answer who, when, where, and what.
4. Verify no numeric shorthand, clipped names, or wrapped commander text remains.
5. Capture `/kwr verify`, `/kwr perf`, screenshots, and the AAR after each test match.

Important interpretation note:

If the session is mainly for observation, screenshots, or passive testing while
another player leads, the result and AAR are still useful but should be read as
UI, truth, and decision-surface evidence first, not as a pure command-win-rate
verdict.

## Promotion truth

Alpha.29 is a strong offline field candidate.

It is ready for focused live validation and packaging.

It is not yet ready for broad public promotion until the remaining live gates
are proven with fresh evidence.
