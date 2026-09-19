# ADR-034: Runtime work and issued-clock ownership

Status: implemented and regression-tested; live performance certification pending.

## Decision

MatchRuntime consumes coalesced event revisions at execution start, not timer
creation. A later revision must never cancel an earlier critical deadline.
RosterInspector owns INSPECT_READY acceptance; Sensors invalidates only the
identity reported by a specialization change. Read operations must not refresh
the observation timestamp of cached evidence.
Failed reads have a separate retry timestamp, so API throttling cannot falsely
renew observation age. Identity invalidation removes every alias of the shared
record, including short roster names and realm-qualified unit names.

Predictor durations are seconds remaining. Commander converts them to monotonic
absolute times when issuing a play, then retains those times with the issued
plan. Presentations derive remaining time from that plan, never an old label or
an unissued candidate. Display/copy consumers may not invent another assignment
generation. Terminal plays must not advertise an expired deadline as actionable.

Hot-path static capability resolution canonicalizes only reviewed keys and
does not allocate copied tables for read-only access. Unknown input cannot grow
the static cache. Enemy health/aura events already accumulate observed tokens;
capture scans each token once, rather than repeating fixed and observed scans.
Friendly aura events do not repaint unchanged health bars. No extra scheduler
or competing timer owner is introduced.

## Consequences

Tests verify work counts and clock behavior, not only absence of errors. Live
CPU, peak allocation and retained memory remain separate measured gates. No
forced GC or relaxed threshold conceals a failure. Existing safe API boundaries,
explicit copy APIs and manual user controls remain intact.

Pressure recovery is keyed to the successful measurement timestamp. Reusing an
old combat-deferred sample cannot repeatedly erase caches. Current combat records
are protected while stale records are pruned through both GUID and name indexes;
one-result strategy and formation caches remain bounded and useful. Sampled peaks
are labeled as samples, never promoted to continuous peak certification.

The offline-completion schema now requires the writer's existing explicit
`cleanEligibility*` field names. This reconciles the schema with its producer;
it does not turn an unavailable source or live gate into a pass.
