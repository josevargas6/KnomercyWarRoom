# KWR Alpha.17 field capture checklist

Candidate: `alpha17-bounded-field-safety-20260913-1` / `6.1.1-alpha.17`.
Use one copy of this checklist per match. It collects useful evidence without
asking you to manufacture every map scenario.

## Before each match

- [ ] Confirm the AddOns screen shows **Knomercy War Room 6.1.1-alpha.17** and
  **KWR Sentinel 6.1.1-alpha.17**.
- [ ] In the world, type `/kwr verify`; copy its complete output.
- [ ] Record the map, bracket, faction, UI scale/resolution, and whether
  Sentinel is enabled.
- [ ] Take one screenshot after the battleground loads. The KWR card must be a
  compact lower-right card, never the full `KWR / COMMANDER` board.

## During each match

- [ ] When a current call appears, take one screenshot showing the player,
  action bars, and KWR card together.
- [ ] If a flag pickup, drop, return, or cap occurs, take one screenshot and
  note the event. This is evidence for `LIVE-CARRIER-TARGET`; no flag event is
  not a failure, but it cannot clear that gate.
- [ ] Open compact and expanded Team views only when safe; take a screenshot of
  the same player in each view. If possible include a `HIST` observation. This
  supports `LIVE-TEAM-TRUTH`.
- [ ] Type `/kwr perf` during one representative team fight; copy all output.
- [ ] If the card blocks play, shifts, grows, or opens a full board: screenshot
  it, type `/kwr bug`, copy the result, press `HIDE` if needed, and stop testing
  that match. Mark the blocker `FAIL`.
- [ ] Optional safety check outside a critical fight: right-click the compact
  card. It must **not** open the full tactical board.

## At match end

- [ ] Type `/kwr perf`; copy all output.
- [ ] Type `/kwr aar copy`; copy all output.
- [ ] Open the AAR and take a screenshot immediately, then another after ten
  seconds without dragging, resizing, changing UI scale, or opening another
  KWR window. Its anchor must not shift.
- [ ] Check the AAR for runtime errors, blocked actions, taint, command
  stability, and assignment integrity. Record any nonzero error count or WARN.

## After the second match

- [ ] Paste both `/kwr verify` outputs.
- [ ] Paste all four `/kwr perf` outputs.
- [ ] Paste both `/kwr aar copy` outputs.
- [ ] Attach or label the opening, fight, Team, carrier-event (if present), and
  two AAR screenshots for each match.
- [ ] State whether either match had a blocking UI issue, runtime error, taint,
  blocked action, or AAR movement.

## Evidence classification

| Evidence | May clear after two matches? | Minimum result |
| --- | --- | --- |
| `LIVE-READABILITY` and AAR anchor | Yes, narrowly | both matches show compact lower-right HUD, no clipping/obstruction, stable AAR, no errors/taint |
| `LIVE-TEAM-TRUTH` | Only if observed | same-player compact/expanded agreement with trustworthy health/spec provenance |
| `LIVE-CARRIER-TARGET` | Only if a flag event occurs | canonical carrier/route/target is shown, not raw event prose |
| `LIVE-STABILITY` | Usually diagnostic only | complete bound match, no churn/error, and all declared timing sample requirements met |
| memory / 30-minute growth | No, unless session spans the required warm interval | measured <=32 MB peak and <1 MB comparable warm growth over 30 minutes |
| delivery / Sentinel transport | No, unless an actual acknowledged delivery occurs | generated, delivery/acknowledgement, and observed outcome remain distinct |

Anything not observed after game two is `INSUFFICIENT`, not a pass. It will
receive a precise targeted test contract before another general-match session.
