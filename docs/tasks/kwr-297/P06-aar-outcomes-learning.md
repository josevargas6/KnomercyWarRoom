# P06 — Observed decision outcomes, useful AAR and conservative learning

Parent: [KWR-297](../KWR-297-s-tier-completion-packages.md).
Read [execution standard](execution-standard.md). OVR-18; REC-07/08/09.
Lead: Terra High. Medium implements approved migrations/fixture/report slices.
Dependencies: P01 facts, P02 objective predicates, P05 identity/lifecycle;
P04 doctrine revisions for final context partitioning. Coordinate bounds with P08.

Integrate [KWR-299 / P14](../KWR-299-command-followthrough-feedback.md): manual
FOLLOWED/NOT_FOLLOWED marks are adherence attestations, not delivery or success.
Their correction/undo semantics must not duplicate learning credit or silently
upgrade old episodes. Unmarked feedback is unknown, not evidence of nonadherence.

## What and why

Explain which call was generated, actually communicated, publicly observed and
resolved. Never train the system as if every displayed recommendation was acted
on or every match win validates its advice. Preserve useful personal history
while quarantining unproven legacy aggregates.

## Existing owners and completed behavior to retain

Extend `Core/CommandReview.lua` (`DeliveryEligible`, `ExecutionEligible`,
`OutcomeObserved`), Commander observation/attestation, `Runtime/AAR.lua`
(`Start`, `Record`, `PersistActive`, `CommitInterrupted`, `Finish`, `Export`),
`Runtime/Learning.lua` (`ContextKey`, `RecordReviewed`, `Adjustment`, `Prune`),
and existing OpponentModels/EncounterHistory persistence.

Current code includes wall-clock review records, explicit leader confirmation,
context partitioning, migration/deduplication safeguards and candidate-bound
exports. Preserve these tested features. Complete public family-specific outcome
production rather than treating a nonempty evidence-ID list as sufficient proof.

## In-progress implementation evidence (2026-09-11)

The current source now treats `sessionKey` as part of command continuity and of
the public-execution observation contract. A stable command can retain its
review identity only within the same battlefield session; a rendered stale
command cannot receive a delivery attestation after the session changes; and
an observation whose session differs from the command is ineligible. The
`delivery_provenance` and `public_execution_observation` fixtures cover these
rejections. The same public-execution boundary now accepts an exact,
post-delivery `FLAG_CAPTURE` of the commander's opponent flag for an explicit
enemy-flag capture command, recording `SUCCESS`; a friendly-flag capture is
rejected. The focused learning fixtures retain their independently observed,
reversible-credit behavior. This is bounded outcome production only. It does
not satisfy the package's still-open family outcome predicate, post-delivery
window, or audit-detail acceptance criteria.

## Required logic

1. Define a versioned episode for a command revision: generation, candidate,
   doctrine/ruleset/patch/team/bracket context, generated/delivered times, evidence
   dependencies, expected success/failure/abort predicates and review eligibility.
   Keep unobserved and interrupted explicit; map existing schemas through P08.
2. Record delivery only via the current explicit qualified attestation path.
   UI mode, sent addon packet, copied text or match result does not prove team
   receipt. Label leader attestation as attestation, not verified execution.
3. Implement bounded outcome evaluators in the existing CommandReview/Commander
   ownership boundary. Match objective/actor identity, command revision, session,
   source authority and a valid post-delivery observation window. Retain enough
   supporting event detail to audit the conclusion, not merely opaque IDs.
4. Distinguish action observation from success. An assault start can observe an
   attempted assault; it cannot prove a cap. A kill elsewhere cannot prove the
   selected target died. A whole-team score gain cannot prove assigned players
   followed their jobs. Missing evidence at timeout means UNKNOWN/INTERRUPTED,
   not FAILURE, unless a reviewed observed failure predicate is actually met.
5. Finish family predicates: retain/lose required node coverage; verified return/
   capture with proper flag prerequisites; orb/cart/resource outcomes supported
   by P02 facts. Where no legal public evidence can prove execution, retain the
   episode for human review and do not invent an execution producer.
6. Make Learning consume the same eligibility and observed outcome contract as
   AAR/UI/export. Require compatible context, minimum samples and conservative
   clamped adjustments. Unknown delivery, generated-only, interrupted or
   unsupported outcomes cannot train. Learning cannot override P03 hard gates.
7. Deduplicate with stable episode identity across copies, reloads and repeated
   finalization. A bounded dedup ledger needs a documented acceptance window so
   an evicted old ID cannot be replayed indefinitely for new credit. Preserve or
   quarantine unsupported future schemas; never silently replace them with {}.
8. Retain useful compact TEAM history by default and opt-in DEVELOPMENT detail.
   Bound capture at insertion; persist initial/final and controlled checkpoints.
   Export consistent anonymized aliases across relationships, offer a preview,
   and send nothing automatically. Preserve candidateID and UNBOUND old exports.

## Verification — decisive regression matrix

| Input episode | Required result |
| --- | --- |
| Generated command followed by win | No delivery/execution/outcome training credit |
| Attested command, unrelated cap | No matching outcome |
| Attested assault, matching assault-start event | Action OBSERVED, not cap SUCCESS |
| Matching authoritative completed objective after delivery | Matching observed result, no causal-win claim |
| Same event before delivery, wrong actor/revision/session | Reject qualification |
| Unknown observation at deadline | Unknown/interrupted, not invented failure |
| Same episode reconstructed after reload | At most one eligible learning update |
| Different bracket/patch/team/doctrine revision | Separate or ineligible bucket |
| Malformed history, old schema, future schema | Valid data retained; bad data bounded/quarantined |
| TEAM/DEV switches and repeated finish | Useful bounded final AAR, no duplicate result |

Test known FAILURE predicates as well as SUCCESS; otherwise a system can appear
conservative by never recording losses. Test clock reversal, epoch/uptime mixing,
missing source events and ledger eviction. Verify AAR UI/export/learning agree
for every eligibility case. Measure checkpoint counts and serialized sizes in P08.

## Acceptance criteria

- [ ] Each trained episode has auditable qualified delivery and observed outcome.
- [ ] All family predicates distinguish attempts, outcomes and causation.
- [ ] Migrations, duplicate intake and future data preserve safety and history.
- [ ] Retention, aliases and exports satisfy P08 bounds and candidate identity.
- [ ] Unsupported observations remain explicit limitations, not fake success.

## Rollback and handoff

Disable new learning intake while retaining read-only history if qualification
regresses. Never destructively downgrade a database after rollback; preserve raw
records and migration receipts. Handoff the schema/ADR, predicate table, malformed
and reload fixtures, eligibility counts and any intentionally unobservable cases.
