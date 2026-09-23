# Alpha28: bounded follow-up

Installed version: **6.1.1-alpha.28** on Commander, Sentinel and Developer Tools.
Candidate: `alpha28-bounded-battleground-status-20260920-1`.

Use the next offered rated battleground; repeated maps count. Do not requeue for
a map and do not play more than two games for this collection.

- Before queueing, run `/kwr verify`; confirm the alpha28 version and candidate.
- Play normally. At a safe point in sustained combat, run `/kwr perf`.
- After the match, save `/kwr perf`, `/kwr verify`, and `/kwr aar copy`.
- For an actual visible defect only, take one screenshot and run `/kwr bug`.
  Stop immediately if a KWR surface blocks gameplay or the game menu.

This candidate specifically tests that battlefield-status pulses and local enemy
movement no longer generate strategic refresh storms. The goal is lower strategic
refresh count/P95 and a sampled peak below 32 MB without losing score, flag or
carrier truth. An absent mechanic is NOT_OBSERVED, not a failure or a reason to
hunt a particular map. After two games, remaining gaps belong to engineering.
