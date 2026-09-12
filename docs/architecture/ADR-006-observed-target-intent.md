# ADR-006: Separate pressure from an observed kill commit

Status: Accepted, September 7, 2026

CombatIntel has two different jobs. Ranking identifies a useful local pressure
or watch target. A coordinated kill requires a current observed vulnerability.
Those concepts use different evidence and therefore cannot share the
`killTarget` field or a KILL presentation.

CombatIntel publishes a bounded target intent: `PRESSURE`,
`OBSERVED_KILL_WINDOW`, `SWAP`, or `NONE`. Only the observed window is commit
eligible. `localTarget` remains the pressure/watch projection for compatible
surfaces; `killTarget` is reserved for the observed commit. BoardState carries
the intent. The problem detector and kill selector independently verify current
killability so an objective carrier, a heuristic score, an overextension flag or
assignment count cannot manufacture a team kill.

Support/control assignments can influence packaging and ordering, but cannot
raise the target evidence confidence. On missing, stale or contradictory
evidence the system withdraws the team commit and may retain a pressure or swap
display. This is transient runtime state only. Manual focus, physical range,
full support coverage and relay authority remain separate work.
