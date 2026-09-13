# Alpha.17 two-match field standard

Candidate: `alpha17-bounded-field-safety-20260913-1` / `6.1.1-alpha.17`.
This is a diagnostic safety standard, not a stable-release certification. It
exists to decide whether the previously reported blocking UI behavior is fixed
without turning two convenient matches into evidence for unrelated release gates.

## Required identity and capture for each match

Before queueing, run `/kwr verify` and retain its output. The candidate ID and
version must be alpha.17. A different version, an unbound export, or a reload
that loses the capture makes that match `INSUFFICIENT`, not a pass.

For each complete match, retain:

1. one opening screenshot after the battleground loads;
2. one in-combat screenshot after a current call is shown;
3. `/kwr perf` during a representative fight and again at match end;
4. `/kwr aar copy` after the match; and
5. a screenshot of the AAR after it has remained open for ten seconds without
   dragging, resizing, changing UI scale, or opening another KWR surface.

If a KWR surface blocks play, capture it if safe, type `/kwr bug`, then stop
that match's test. Do not fight through a blocking UI issue.

## Alpha.17 UI-safety decision rule

The `LIVE-READABILITY` and AAR-anchor portions of the field blocker can be
lifted only when **both** complete matches meet every condition below:

- the live KWR surface is the lower-right compact HUD, never the full Commander
  board;
- its height is bounded to the focus card (358 px without a local action, 436 px
  with one) and it does not cover the player/action-bar play area;
- Reset Window Positions restores that lower-right compact surface;
- live right-click does not open the tactical board;
- the `HIDE` control removes the HUD immediately and it stays hidden for the
  remainder of that session unless explicitly re-enabled;
- the AAR remains at one fixed saved anchor for the ten-second observation; and
- the capture reports no KWR Lua error, blocked action, or taint evidence.

One observed violation is a `FAIL` for the affected blocker. Do not average
away a blocking event with a clean game. A missing screenshot/export, a match
that ends before the observed surface appears, or a different candidate is
`INSUFFICIENT` and cannot lift the blocker.

## What two matches may and may not clear

Two complete, bound matches may clear a narrowly scoped UI regression only.
They can also prove that a performance, memory, delivery, truth, or carrier
target requirement **fails**. They cannot pass those wider gates unless their
own minimum evidence standard is also satisfied:

| Blocker | Two-match outcome needed to lift it | Otherwise after match two |
| --- | --- | --- |
| `LIVE-READABILITY` / AAR anchor | both-match UI-safety rule above | targeted surface/reproduction contract |
| `LIVE-STABILITY` | full accepted samples meet all declared P95/max budgets in both exports | performance capture contract: representative event counts, DevTools state, stage timings, and no dropped samples |
| memory budget | measured peak <=32 MB and comparable warm-state growth <1 MB over a 30-minute interval | 30-minute warmup/GC memory-growth contract |
| command delivery | distinct generated, delivered/acknowledged, and observed records for the tested calls | delivery-path contract with explicit sender/receiver capability and acknowledgement evidence |
| team truth / carrier target | authoritative source and observed carrier/target state appear when the map provides them | map-family trigger contract; do not treat an absent carrier event as a pass |
| replay adjudication / package P01–P14 | not a field-only gate | retain its offline CODE/REVIEW contract; games cannot close it |

## Mandatory escalation after game two

For every blocker that is neither `PASS` nor `FAIL` after two matches, create a
named **Targeted Test Contract** before scheduling another general match. The
contract must contain all of the following:

- blocker ID and alpha.17 archive hash;
- one deterministic setup and trigger, including map/family if required;
- exact observation to capture and the command/screenshot/export that records it;
- pass threshold, fail threshold, and minimum sample count or duration;
- what result is `INSUFFICIENT` and why;
- a rollback/safety stop rule; and
- the code owner and the external evidence owner.

The next match is then run against that contract. “Play another match and see”
is not an acceptable test standard.

## Session closeout

Paste the two `/kwr verify`, four `/kwr perf`, and two `/kwr aar copy` outputs,
plus the labeled screenshots. I will bind them to the candidate, classify each
blocker as `PASS`, `FAIL`, or `INSUFFICIENT`, and create the required targeted
contract for every insufficient blocker.
