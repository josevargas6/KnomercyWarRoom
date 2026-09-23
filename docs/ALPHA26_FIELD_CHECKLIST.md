# Alpha26: bounded field evidence

Candidate: `alpha26-runtime-clock-ownership-20260919-1`.
Purpose: measure the remaining Retail-only limits, not repeat every scenario.

## Any random rated battleground counts

Use the next battleground the queue gives you. No flag map, base-defense map,
particular objective event, win, or different second map is required. Two games
on the same map count. Do not leave/requeue to obtain a testing map.

The common test is CPU/memory, errors and blocked actions, card visibility and
controls, agreement between calls and assignments, timing when displayed, and
match-end/AAR behavior. These checks apply across battleground types.

Flag/carrier changes, base defense, carts and other mechanics are opportunistic:
capture them only if they occur naturally. If they do not occur, record
NOT_OBSERVED (or NOT_APPLICABLE for that map). This neither fails the game nor
awards that mechanic a pass. Map-specific coverage gaps belong to engineering
replay/targeted reproduction, not extra random queues for you.

## Before queueing

- Confirm Commander, Sentinel and Developer Tools all show `6.1.1-alpha.26`.
- Capture `/kwr verify` once; confirm the candidate above. Do not use preview.
- Check the small card stays in your corner, Hide stays hidden, and Esc/menu
  remains usable. Stop testing immediately if battlefield visibility is obstructed.

## Game 1

- Play normally. At a safe moment after a sustained fight, save `/kwr perf`.
- If a timer expires or a call changes, note whether the named player/location
  agrees with MY JOB and whether an expired timer says REASSESS (not BY 0:00).
- After the match, save `/kwr aar copy`, `/kwr verify`, and `/kwr perf`.
- For a visible defect only: one screenshot plus `/kwr bug`. No screenshot tour.

## Game 2, only if needed

- Repeat the performance and end-of-match exports to distinguish a repeatable
  failure from a loading spike. Whatever map is offered counts, including a repeat.
- Confirm manually opened AAR/Options keep their position and contents fit.

## Decision after two games

Collection is complete after at most two games regardless of which maps appeared.
Completion of collection is separate from whether an observed check passed.
No open-ended match grind. A repeated defect becomes a deterministic replay or
instrumented reproduction. An unobserved scenario stays explicitly unverified
and requires an engineering-owned targeted test or restricted feature scope;
it does not become PASS and does not require you to queue for a particular map.
Timing correctness is already tested offline with long uptime and event bursts.

Live CPU goals remain P95 <2 ms and routine max <4 ms. Memory target is 25 MB,
warning 28 MB, hard limit 32 MB. A cached combat reading is not a fresh sample;
the reported session sampled peak is a lower bound, not continuous peak proof.
Zero runtime errors and a win do not prove call delivery, execution or causality.
