---
id: KWR-281
title: Reconcile release source and preserve installed improvements
owner: Codex
priority: critical
risk: high
status: in_progress
dependencies: []
affected_modules: [Core, Runtime, Features, Data, UI, tools, KWR_DevTools]
authority_references: [AGENTS.md, PRODUCT_ROADMAP.md, RELEASE_READINESS.md, RELEASE_POLICY.md]
---

# Objective

Complete OVR-01 source recovery and its offline package prerequisites while
preserving existing fixes and useful installed improvements. The owner requires
all offline work to finish before field testing.

# User outcome

One reviewed source can reproduce the Commander, Sentinel and optional DevTools
package that will be handed over for field testing. Missing live evidence does
not suspend source repair.

# Current behavior

The source branch is `codex/kwr-278-alpha11-field-blockers`, based on `bcce7f5`,
with existing uncommitted work. The September 8 comparison has 62 non-matching
loaded entries: Commander 47 changed/11 source-only/two installed-only; Sentinel
two changed. It also records 83 exact matches across both addons.

The corrected review ledger has **38 closing decisions, nine pending code
records marked DEFER, 15 missing reviews, zero invalid records**.
DEFER is accounting for an unresolved decision, not permission to stop work.

Three earlier closing reviews were factually wrong. At the September 8 comparison,
source Commander lacked delivery-qualified metrics, AAR lacked installed compact
capture, and Learning lacked provenance quarantine. The September 9 code below
implements bounded capture and scoped quarantine; public execution producers
and final recovery closure remain open. The corrected records preserve
the earlier explanations and reopen those code requirements. A Commander context
label in installed code also does not prove delivery of an individual call.

# Required behavior

Execute the concrete REC-01 through REC-09 implementation and regression recipes
in [RELEASE_READINESS.md](../../RELEASE_READINESS.md#close-the-nine-pending-source-recovery-items).
Finish its exact 15-file review list, preserving source fixes and merging
installed behavior only where requirements and tests justify it.

- Keep the source/installed/SavedVariables baseline and existing user changes.
- For each reviewed difference, cite actual source and installed behavior, the
  implementation or rejection decision, regression result and resolved file hash.
- Keep generation under source/build authority. Reject the installed-only
  hardcoded ScenarioRuntimeKnowledge and StrategistNexusRuntimeIndex files.
  Preserve canonical inputs; any compact player projection must prove parity
  under OVR-11 rather than copying those installed files.
- Retain the DevTools source/build split and fail-safe loader behavior.
- Produce a final source manifest and clean candidate through the repository's
  normal review/commit/CI process. A passing baseline review record is not a
  claim that modified candidate files still match its old source hash.

# Dependency and execution order

KWR-280's source fixes are inputs to preserve. Its remaining controlled WSG
session depends on this reconciled candidate, so KWR-280 is not a blocking
dependency for KWR-281. Do not recreate that cycle.

Start REC-07/08/09 delivery/AAR/learning integration; close the 15 source/UI
reviews; implement real host measurement and resolve REC-01..06. Shared work
with OVR-09/10/11/18 can be tested before those OVR rows have field proof.
A required interface or invariant must exist; an upstream live certificate is
not a prerequisite for coding against it.

When an installed optimization violates an invariant, repair it or retain the
safe source implementation with a demonstrated rejection reason. The acceptance
target is correct, measured behavior, not adoption of every installed shortcut.

# Non-goals

No second audit, new tactical expansion, installation, public upload, silent
replacement of user work or stable claim. This offline task does not clear the
controlled WSG field result.

# Technical constraints

Keep existing namespace/module boundaries. Preserve sparse API return positions,
unknown availability, source evidence generation, Reporter identity migration,
terminal suppression, explicit countdowns, combat-safe nameplate/layout behavior,
memory-sample provenance and persistent match deduplication.
Persisted migrations must be versioned, idempotent and preserve malformed/future
data through a documented recovery path. Do not ship diagnostic corpora in the
player runtime or assume a source TOC is the same as the generated player TOC.

# Acceptance criteria

- [x] Pre-change source, installed addons and addon SavedVariables preserved.
- [x] Loaded-file differences captured with hashes.
- [x] Incorrect Commander/AAR/Learning closure explanations corrected.
- [ ] All 62 differences have an accurate final decision plus relevant regression
      evidence; no DEFER or missing review remains for source closure.
- [ ] All nine REC packages meet their stated tests and resulting source hashes
      are recorded without erasing baseline provenance.
- [ ] Final TOC, generator, player, Sentinel and DevTools load graphs agree.
- [ ] A clean reviewed candidate builds reproducibly and extracted-package
      behavior agrees with the source; public docs match actual artifacts.
- [ ] KWR-280 remains explicitly awaiting FIELD evidence after offline closure.

Offline status: IN_PROGRESS. Field status: NOT_STARTED_FOR_FINAL_CANDIDATE.
Release status: NOT_READY.

## Delivery boundary implementation checkpoint

The first REC-07/08/09 source change preserves generator diagnostics separately
from delivery certification. Shared CommandReview qualification requires matching
command identity/revision, an explicitly labeled leader attestation, finite wall
times and separate public execution evidence. New AAR reviews and learning
intake reject generated-only, unobserved and interrupted outcomes.

The new delivery_provenance fixture first failed on the missing boundary, then
passed within smoke after implementation. Existing generator-churn tests still
exercise their original READY/WATCH/FAIL calculations through explicitly named
generator fields. The built-in diagnostic no longer credits a hypothetical call
just because its match result is VICTORY. No installed files or saved data changed.

This was the initial boundary checkpoint. Later September 8/9 checkpoints below
implement attestation, scoped learning migration and compact AAR retention.
Qualified execution producers and final recovery/distribution gates remain open.

Verification: `artifacts/delivery-boundary-checkpoint.json` binds the changed
source/test files and `artifacts/delivery-provenance-all.json`. The All suite
passed Developer Tools, smoke, Sentinel, 500-refresh injected-clock soak and the
default replay (fallback-only). Development validation passed with zero errors
and the expected version/channel warning; document-authority and diff checks
passed. This does not claim full-corpus, clean-package or real-client performance
certification.

# Verification

Latest source-bound receipt: `artifacts/aar-learning-checkpoint-20260909.json`.
The integrated All suite passed Developer Tools, smoke, Sentinel, injected-clock
soak and the default fallback replay. Development validation passed with zero
errors and one expected channel/version warning; document authority and diff
checks passed. The receipt binds current implementation and fixture hashes.
Next: broaden malformed AAR preservation and serialized-size tests, then complete
public execution observations and final source/package reconciliation.

September 9 public-observation checkpoint: ObjectiveIntel now gives each local
BG-system event a bounded ID and epoch timestamp. Commander can bind only a
post-delivery, exact-target ASSAULT event to the current command. The resulting
`OBSERVED` record proves public activity only; AAR cannot score it against the
match result and Learning cannot train from it. The focused fixture rejects
pickup, wrong target, stale, remote and preview facts. See ADR-008 and
`artifacts/public-observation-smoke.json`. Reviewed SUCCESS/FAILURE contracts,
aggregation and final source/package gates remain open.

September 9 REC-05 implementation: encounter records now use GUID identity when
available, migrate readable legacy name keys on live observation, preserve unknown
root/player payloads for recovery, update unchanged records in place and obtain
the PvP season once per capture. It adds `firstSeenAt`/`lastSeenAt`, 90-day expiry,
malformed-record quarantine and newest-first caps. The fixture covers repetition,
role/spec changes, reload/session counts, historical fallback, migration, expiry
and capacity. `artifacts/encounter-history-smoke.json` passes. Real host allocation
comparison and final source/package verification remain open.

September 9 REC-02/06 implementation: Store now copies every producer branch
before reconciliation, so published and prior snapshots cannot alias producer
work buffers; listener delivery follows registration order. The store_ownership
fixture checks nested mutation, removed fields, prior revision integrity, order
and filtered delivery. Formation caching now keys rated/blitz context and smoke
proves nested returned-result mutation cannot contaminate the cache, while
connection/death/bracket changes invalidate it. Store timing and profile-change
coverage remain final-gate work.

September 9 formation ruleset checkpoint: `FormationAdvisor` now uses explicit
RBG 10-player (1/3/6) and Blitz 8-player (1/2/5) slot targets. The active
ruleset determines role gaps, overages, replacement count, completion and the
number of displayed build requirements. Smoke proves a complete Blitz roster
does not ask for ten-player requirements. This does not close OVR-17: the
Assignment and AssignmentOverride availability, defense and duplicate-identity
regressions remain required. The current-source All-suite receipt is
`artifacts/formation-ruleset-all-20260909.json`; it does not clear the final
clean-candidate, extracted-package or field gates.

The source-bound receipt
`artifacts/recovery-checkpoint-20260909-store-encounter-observation.json` records
the final All-suite run for this checkpoint and the implementation/fixture hashes.
It is explicitly limited to dirty development source, injected-clock soak and a
fallback replay. It does not certify a package, real-client performance or field
behavior.

September 9 REC-08 implementation: TEAM capture is now the default; full
DEVELOPMENT payloads require explicit opt-in at match start. Active timeline
writes trim their owned arrays immediately, fixing ignored replacement-list
returns; objective dedup indexes are bounded. Command history keeps the opening
and latest calls. First-call checkpoint, finalization, legacy capture formats,
ownership and 150-write bounds pass the new aar_retention fixture. See ADR-010.
`artifacts/learning-episodes-all.json` passed all five suite stages. The AAR/learning
integrated suite also passed; broader malformed-data and serialized-size
coverage, public execution producers and final candidate parity remain open.

September 9 REC-09 implementation: schema-2 learning preserves legacy aggregates
outside tactical scoring; scopes episodes by exact team, rated bracket, map,
patch, product/plan revision and plan. A persistent bounded ledger plus retired
timestamp watermark prevents replay after reload or eviction. Explicit public
episode SUCCESS/FAILURE replaces match-win training. Malformed buckets are
preserved separately and a damaged ledger disables training. Commander captures
the scope, AAR retains it, Strategist supplies current scope for adjustments,
and MemoryBudget owns the ledger cap. See ADR-009 and the learning_episodes
fixture. Initial smoke and integrated verification passed. This
does not close missing public execution producers or the complete OVR-18 gate.

September 8 capture checkpoint: implemented per-call identity/revision and explicit
`/kwr delivered <token>` confirmation, immutable refresh publication, same-call
AAR confirmation updates, 30-second active checkpoint cadence with forced initial
writes, and idempotent legacy AAR interpretation normalization. Former historical
interpretations are retained in `legacyReview`; future provenance versions are
preserved. The fixture covers stale/duplicate/preview/context rejection, delivery
without execution credit, checkpoint cadence/force, malformed review scores and
repeated migration. `artifacts/delivery-checkpoint-smoke.json` passes smoke.
REC-07/08/09 remain IN_PROGRESS. At this checkpoint the subsequent September 9
capture and learning work was still pending; current evidence is recorded above.
All 22 audited offline requirements remain required before field handoff.
The completed capture checkpoint is bound by
`artifacts/delivery-capture-checkpoint.json`: All suite passed before the final
export/help refinement, followed by final smoke and development validation.
Exports distinguish explicit local attestation from unverified execution.
The compact AAR and scoped learning work proposed here is implemented in the
September 9 checkpoint above; remaining producer and release gates are unchanged.

The preserved pre-mutation snapshot is
`artifacts/release-first-baseline-20260904-203231/` (458 files).
Current comparison, packet and decision records:

- `artifacts/source-install-reconciliation-20260908-live-session.json`
- `artifacts/source-install-review-packet-20260908-live-session.json`
- `artifacts/source-install-reviews-20260908/`
- `artifacts/source-install-review-ledger-20260908-live-session.json`

The review validator checks record shape and packet hashes; it does not prove
that prose is true or that code has been merged. Validate current file behavior
and bind final candidate hashes separately. Run focused tests from the REC
recipes, then the complete offline gate in RELEASE_READINESS.

Historical source-suite and reproducible dirty-package evidence is preserved in
[the prior handoff snapshot](../evidence/readiness-handoff-before-clarification-20260908.md).
These results are useful regression baselines, not final clean-candidate proof.
Do not rebuild a seven-minute interim package for a documentation-only change.

# Rollback

Keep the preserved source diff and addon/SavedVariables backup. Revert only the
bounded change being reviewed when necessary; never reset unrelated work.
Prepare isolated package/DB restoration tests offline. Actual installation and
restore rehearsal happen only after the owner receives the offline-complete
candidate and its instructions.
