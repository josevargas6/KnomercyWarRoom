# Alpha30 incremental-runtime field check

Use the installed `6.1.1-alpha.30` trio (Commander, Sentinel, Developer Tools).
Any randomly selected rated battleground qualifies. Do not wait for a flag or
base-defense map.

1. Before queueing, confirm the version and candidate shown by `/kwr verify`.
   Capture `/kwr perf` once in the world.
2. In the opening minute, capture `/kwr perf` and `/kwr verify`. Note whether
   the map, score, team, and visible objectives agree with Blizzard's UI.
3. During real fighting or score movement, capture `/kwr perf` twice, at least
   ten seconds apart. Keep the entire output, including incremental-path
   counters, strategic/tactical P95, maximum, runtime errors, and memory.
4. Check that the fight card stays in its corner, WoW's escape menu and
   battlefield remain usable, and calls update after real score or objective
   changes. A duplicate widget pulse should not visibly rebuild the card.
5. After the match, copy `/kwr verify`, `/kwr perf`, and the AAR/match export.
   If anything covers controls or throws an error, also capture `/kwr bug`
   and a screenshot before restarting.

Do not treat offline P95 as Retail proof. The target is strategic and tactical
P95 below 2 ms, no runtime errors, and safe UI. If two completed matches still
cannot exercise a map-specific condition, mark it unobserved and use a focused
deterministic fixture plus an explicit reviewer decision; do not call it a live
pass. The package is diagnostic until these results are reviewed.
