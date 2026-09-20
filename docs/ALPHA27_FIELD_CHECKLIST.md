# Alpha27: short field check

Installed version: **6.1.1-alpha.27** on Commander, Sentinel and Developer Tools.
Candidate: `alpha27-bounded-runtime-projections-20260920-1`.

Use whatever rated battleground is offered. Repeated maps count. No flag-map or
base-defense requirement and no more than two games for this collection.

- Before queueing: `/kwr verify` confirms the version/candidate; preview must be off.
- Play normally. When safe after sustained combat, save `/kwr perf`.
- After the match: save `/kwr aar copy`, `/kwr verify`, and `/kwr perf`.
- Only for a visible problem: one screenshot and `/kwr bug`. Stop immediately if
  a window obstructs play or prevents closing/using the game menu.
- A second game is optional if needed to distinguish a repeated issue from a
  loading spike. After two games, remaining reproduction belongs to engineering.

Absent mechanics are NOT_OBSERVED, not a failed game and not a pass. No extra
queues to hunt scenarios. Known alpha26 failures need no further proof.
Alpha27 live CPU and sampled peak memory remain unverified. Runtime timing now
includes state projection before notification; it excludes UI listeners/audio/
communications. Offline improvements do not certify Retail P95 or peak MB.
