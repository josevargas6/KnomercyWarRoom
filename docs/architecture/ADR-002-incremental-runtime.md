# ADR-002: Incremental live runtime

Status: accepted for alpha engineering validation, 2026-09-27.

The runtime keeps one published immutable state in Store. Sensors owns reads
of Blizzard public widgets. A widget event first classifies its observed
score or objective fingerprint. Duplicate and unrelated events stop there.
Changed public facts enter a bounded capture that reuses the current roster
and enemy branches. Status pulses compare native widget facts before reading
map overlays. Full captures remain mandatory for scoreboard, roster, world,
match phase, manual, and periodic heartbeat events; an unchanged full capture
can skip downstream work.

The strategic pipeline reuses battlefield and assignment stages when their
declared inputs are unchanged. Store owns branch-specific publication and
skips equal state. Tactical capture uses enemy and combat-evidence fingerprints
before rebuilding combat presentation; a short expiry prevents stale casts
from being retained. Public pulses cannot swallow queued roster/lifecycle
invalidations or pending tactical work. Time-based observations retain
explicit expiry, so reuse cannot silently extend stale facts.

This preserves the existing sensor, strategy, assignment, and Store ownership
boundaries. It avoids a second state model and does not change SavedVariables.
The principal risk is a missed invalidation. Deterministic change and expiry
tests plus live field verification are required before release promotion.
