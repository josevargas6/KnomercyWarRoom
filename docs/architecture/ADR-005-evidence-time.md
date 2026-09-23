# ADR-005: Validate evidence time at construction and use

Status: Accepted, September 6, 2026

The existing Util evidence primitive remains the shared time contract used by
production TruthContract. A record requires finite nonnegative observation time,
TTL and clock; a future observation is unverified. Missing or invalid TTL cannot
silently become the explicit zero-TTL unbounded-reference case. False and zero
are observed values, not missing data.

EvidenceUsable checks current age as well as the construction-time fresh flag.
It does not mutate retained records, whose age/state describe their construction
time. Previously rejected evidence requires a new valid construction before use.
This preserves traceability while preventing a cached fresh flag from keeping
aggressive-commit permission open after expiry.

No mutable store or saved schema is added. Per-field source/conflict projection
through FactStore and BoardState still requires the remaining OVR-02 work.
