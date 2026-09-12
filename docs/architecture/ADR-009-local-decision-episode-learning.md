# ADR-009: Local decision episodes and versioned learning preservation

Status: Accepted, September 9, 2026. Implements the persistence/consumer portion
of REC-09 and OVR-18; public execution producers remain a separate open dependency.

The old map/plan aggregates cannot prove delivery or execution. Learning schema
2 transfers the entire previous learning branch into one `legacy.data` archive.
It never reads that archive for tactical adjustments. Reinitialization does not
copy it again. Unknown future schemas stay intact and produce no adjustment.
Malformed current buckets move into `quarantinedPlans`; damaged deduplication
records remain intact and disable training rather than risk counting twice.
The bootstrap preserves malformed legacy payloads for this migration instead of
discarding them. Preserved historical data is not a growing runtime cache.

Learning samples now represent explicitly observed decision outcomes, not match
wins. An eligible episode needs matching delivery/execution provenance, a public
SUCCESS or FAILURE observation no later than match end, a complete truth-qualified
match and Commander review feedback. A successful objective episode may occur in
a lost match. A victory with no observed episode earns no credit. Mixed AARs train
only eligible episodes; unissued recommendations do not invalidate other evidence.
The public-observation producer is still required; synthetic fixtures are not
field evidence, and no execution facts are inferred from the match result.

Buckets are partitioned by exact sorted friendly GUID roster, eight/ten-player
rated bracket, map, patch, product/plan revision and plan ID. Missing/duplicate
GUIDs, incomplete roster, unrated or preview context cannot form a training scope.
Product version is the conservative doctrine revision: every released doctrine
change must change product version. This favors precise local-team evidence over
pooling strangers or incompatible tuning. Stable call identity changes when its
learning scope or plan changes; attestation cannot transfer across that change.

The persistent episode key binds AAR ID, command ID and command revision.
`entry.learned` is a display compatibility flag, not duplicate protection.
The processed ledger retains at most 120 episodes by default; pruning advances
`retiredThrough` to the newest evicted end timestamp. Episodes at or before that
watermark remain rejected even after their individual keys are gone. This may
exclude a late review of an older match, which is preferable to double counting.
Clearing learned adjustments preserves the ledger and watermark. Bucket caps
remain governed by MemoryBudget. Existing minimum-five-sample and bounded
adjustment limits remain; learning does not bypass feasibility enforcement.

The deterministic fixture `tests/fixtures/learning_episodes.lua` covers legacy
and future schemas, repeated migration, malformed buckets/ledger, roster order,
duplicate/incomplete roster, context isolation, observed-success/lost-match,
unobserved outcomes, reconstructed entries after reload, bounds, eviction replay
and reset behavior. Full producer-to-package and real-client validation remain
part of the full release gate.
