# P08 — Bounded retained data, safe migration and compact runtime parity

Parent: [KWR-297](../KWR-297-s-tier-completion-packages.md).
Read [execution standard](execution-standard.md). OVR-11; REC-04/08/09.
Lead: High for schemas/ownership; Medium for approved bounds and build fixtures.
Dependencies: P00 inventory, P06 episode schema and P07 measurements. Start the
inventory/bounds tests before final schema integration; avoid circular waiting.

## What and why

Keep the player addon small and predictable without deleting useful history or
shipping a different decision engine than the one tested. Bounds must hold during
combat and on load, not only after an occasional cleanup pass.

## Existing owners

`Runtime/MemoryBudget.lua`, AAR, Learning, OpponentModels, EncounterHistory,
Core's existing SavedVariables initialization, `tools/release-manifest.ps1`,
`tools/build.ps1`, scenario/Nexus generators and current runtime data consumers.
Optional DevTools already owns four development modules; preserve its lifecycle.

## In-progress implementation evidence (2026-09-11)

Current-schema SavedVariables now cap `journal.history` at deserialization,
before AAR module initialization: the newest eight chronological records are
retained deterministically and the normalization is idempotent. The smoke
fixture inserts twelve records through the actual initializer and verifies both
the cap and retained ordering. Future-schema compatibility data remains on its
read-only preservation path; this current-schema bound does not relabel or
rewrite unknown future data. The remaining retained-writer inventory, serialized
size receipt and compact/player-package parity acceptance work remain open.

September 12 adds a fail-closed serialized-file budget to
`tools/retail-savedvariables-audit.ps1`. The audit records exact file bytes,
the 1 MiB default budget, and a pass/fail field; an over-budget record becomes
an explicit missing gate. Its regression covers both a bound small fixture and
an intentionally over-budget fixture. This is an audit/field-evidence guard,
not yet the representative maximum-writer receipt required to close P08.

The read-only pretest of the retained local SavedVariables file is recorded in
`artifacts/p08-savedvariables-audit-r7-pretest.json`. It is intentionally
`UNBOUND` to r7 and measures 1,580,369 bytes, exceeding the 1 MiB budget.
That file predates r7 deployment and therefore neither proves nor disproves
the current candidate's post-load normalization; it does establish that P08
cannot be closed from old persisted data or from the small synthetic fixture.
Capture an r7-bound post-load receipt using the actual bounded writers before
any release claim.

The same audit now emits privacy-safe top-level structural footprints (key,
shallow entry count and approximate serialized weight) without exporting
retained player or match text. In the pretest, the largest structures are
`journal` (~628 KB), `aar` (~266 KB), `learning` (~206 KB), `opponentModels`
(~109 KB) and `fieldIntel` (~100 KB). This is an inventory lead, not permission
to delete history wholesale: each owner must define and test its own retention,
migration and correction behavior before the r7 post-load size gate can pass.

## Correct implementation sequence

1. Inventory every retained collection: owner, insertion/update path, maximum,
   trim order, active-match exception, saved or ephemeral, serialized footprint.
   Include processed-episode ledgers, player/objective timelines, packet caches,
   reporter tracks, diagnostic samples, quarantines and UI pools.
2. Enforce limits at insertion/update and loading through the existing owner.
   Test limit+1 and bursts. Preserve active authoritative state; trim old derived
   diagnostics first. Do not call periodic pruning proof of bounded writers.
3. Complete versioned normalization/migration for clean, Alpha10, Alpha12,
   malformed and future-schema data. Migrations are idempotent. Preserve valid
   history and bounded evidence of rejected records. Future data stays protected
   and read-only/quarantined until supported; do not silently overwrite it.
4. Integrate P06 compact TEAM versus opt-in DEVELOPMENT capture. Persist initial,
   final and documented cadence checkpoints. Test interrupted finalization and
   reload without double counting. Bound both the live working set and its saved
   copy; checkpoint copying must not accidentally double long-term retention.
5. Meet the existing default eight-match history and <=1 MB serialized default
   SavedVariables requirement on a representative worst-case fixture. Specify
   bytes and unit interpretation in the receipt; apply the authority's stricter
   interpretation if ambiguous, or resolve it before closure. Do not erase user
   history silently to make the benchmark green.
6. Inventory runtime consumers before compacting scenario/doctrine corpora.
   Generate the compact projection deterministically from canonical reviewed
   inputs with a schema/digest, retaining every lookup and field used at runtime.
   Never adopt handwritten installed-only compressed indexes as authoritative.
7. Exclude unused diagnostic corpora/full development data from the player ZIP
   using the existing release manifest. Keep matching DevTools optional. Require
   compact-versus-full semantic equality and actual extracted-package execution,
   not only generator byte equality. Coordinate final corpus execution with P11.
8. Throttle expensive memory scans only after writer bounds are proven. Preserve
   unavailable/stale sample status; failed APIs cannot report zero memory. Real
   client memory is a P12 measurement, not a prediction from ZIP size.

## Verification

For each retained collection, insert maximum+1 and at least a burst above the
cap through its real producer, including PvP mode and reload. Assert deterministic
eviction, active-match retention and bounded dedup behavior. Test cyclic/malformed
fixtures where the actual schema permits tables; reject safely before serialization.

Upgrade fixtures must retain explicit historical marker records. Run migration
twice and compare semantic content. Test missing tables, wrong types, impossible
timestamps, unsupported versions and interrupted checkpoints. Restore an older
addon against upgraded data in an isolated sandbox; unsupported schema must
degrade safely, not corrupt it. Preserve original files for recovery.

Compare representative serialized SavedVariables with the actual writer's shape,
not pretty JSON size. Measure maximum fixture size, default history count and
checkpoint copies. Verify private full diagnostics do not enter player archives.

Run compact/full differential tests across the accepted corpus and P11 source/
package parity. Mutations deleting one required compact field or bypassing one
writer cap must fail. Check memory sample unavailable/old/valid paths explicitly.

## Acceptance criteria

- [ ] All retained writers and loaders enforce documented bounds.
- [ ] Migrations preserve valid history and unknown future data safely.
- [ ] Default saved data meets the size/history contract without silent deletion.
- [ ] Compact/full and source/player decisions agree; DevTools remains optional.
- [ ] Client 25/28/32 MB soft/warn/hard targets and <1 MB/30-minute growth remain
      separately measured in P12, not claimed from host/package results.

## Rollback and handoff

Provide schema compatibility and restoration instructions. Never downgrade by
rewriting a future database as an empty old one. Handoff writer inventory,
migration fixtures, byte-size receipts, excluded-content manifests and semantic
comparisons. High reviews data-loss and dedup-eviction risks before integration.
