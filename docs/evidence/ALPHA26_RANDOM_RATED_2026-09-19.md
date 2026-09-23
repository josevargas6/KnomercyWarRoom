# Historical evidence: alpha26 random-rated captures - September 19, 2026

Point-in-time evidence record; RELEASE_READINESS.md owns current promotion status.

User-supplied captures are accepted regardless of battleground family. They do
not need to be flag or base-defense matches. No additional random queues are
needed to establish the observed performance failures below.

## Sources

- NODE performance: `C:/Users/josev/.codex/attachments/e6720310-3980-44ad-ace5-e823263646cb/Pasted text.txt`
- CART performance: `C:/Users/josev/.codex/attachments/c1dddfc3-5f39-4d7f-aef8-4a6c13ce1b15/Pasted text.txt`
- Silvershard verification: `C:/Users/josev/.codex/attachments/8041a161-b7c4-4152-aebc-2e9509a2f598/Pasted text.txt`

Verification reports `6.1.1-alpha.26`, candidate
`alpha26-runtime-clock-ownership-20260919-1`, Silvershard Mines, COMPLETE,
score 821-1500. CART telemetry matches its boot time, refresh P95 and command
counts. Standalone NODE telemetry lacks an embedded version/match ID: accept
it as supplied diagnostic evidence, not an independently hash-bound match.

## Observed results

| Measurement | NODE capture | Silvershard/CART capture | Requirement |
| --- | ---: | ---: | --- |
| Strategic P95 | 22.415 ms | 33.962 ms | <2 ms |
| Strategic maximum | 40.073 ms | 34.229 ms | routine <4 ms |
| Tactical P95 | 6.087 ms | 7.095 ms | <2 ms |
| Tactical maximum | 11.000 ms | 7.750 ms | routine <4 ms |
| Session sampled memory peak | 35.83 MB | 38.12 MB | <=32 MB hard limit |
| Runtime errors | 0 | 0 | 0 |
| Capability hits / misses / entries | 95026 / 20 / 20 | 73078 / 22 / 22 | bounded cache |
| Newest-truth followups | 0 | 0 | avoid redundant followups |

CPU and sampled peak memory FAIL. Lower memory after the match does not erase
the peak failure or by itself prove a retained leak. No continuous peak is claimed.
Cache statistics and no redundant followups support the specific alpha26 repairs,
but do not prove the whole pipeline is within budget or a controlled speedup.

Silvershard audit and assignment audit report PASS, with 10/10 known team specs
and units; all ten assignment locations remain unknown. Command delivery remains
DELIVERY_UNVERIFIED despite four acknowledgements. These are separate from
runtime error absence and must not be silently promoted to full certification.

## Engineering handoff

Latest slow stages span Sensors, Strategy, Battlefield and Truth. Widget updates
account for 440/568 and 244/391 strategic executions. Profile repeated snapshot
construction, allocation and invalidation across these owners; latest-stage
snapshots alone cannot establish total stage cost or the cause of the P95 tail.

The completed Silvershard verification still exposes an older response package
and assignments beside a terminal review command. Reproduce whether this is only
post-match diagnostic residue or reaches a live command surface; do not infer
an in-combat ordering defect from a COMPLETE capture alone.

Missing flag/carrier events are NOT_OBSERVED, not a failed random-rated session.
No wrong-map penalty, no requirement to win, and no further random-game grind.
Map-specific unobserved behavior remains a replay/targeted reproduction or scope
decision owned by engineering. This evidence does not authorize a stable release.
