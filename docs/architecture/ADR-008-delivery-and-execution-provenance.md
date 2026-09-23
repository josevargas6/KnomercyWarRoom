# ADR-008: Separate recommendation generation, delivery and execution evidence

Status: Accepted, September 8, 2026

Commander currently counts generated semantic recommendations in its legacy
`issued` counter. Preserve that counter for existing telemetry consumers, expose
`generated` explicitly, and retain churn/sample diagnostics in
`generatorCommandHealth` and `generatorCertificationStatus`. These measurements
cannot certify actual command delivery. Until qualified delivery aggregation is
implemented, certification remains DELIVERY_UNVERIFIED and command health is
NOT_SCORED. A Commander/Spectator/Diagnostic setting does not attest to a call.

CommandReview owns the shared qualification boundary used by AAR and Learning.
A version-one delivery record binds commandId and positive integer commandRevision,
context, generatedAt and deliveredAt. Its clock is UNIX_SECONDS for persistence
across client restarts. LEADER_ATTESTED with EXPLICIT_LEADER_CONFIRMATION is an
explicit claim by the leader, not independently observed receipt by teammates.
Clipboard activity, profile changes and ordinary generation do not qualify.
Future/nonfinite timestamps, identity/revision mismatch and unknown schemas fail.

Delivery alone does not prove execution. A separate version-one
executionObservation binds the same identity/revision, PUBLIC_FACTS source,
observedAt at or after delivery, and one to four public evidence IDs. The producer
must obtain these IDs from actual public observations; this consumer-side
validation does not discover facts, perform gameplay or verify tactical causality.

Legacy AAR records lack this provenance. They retain their historical information
but cannot receive new execution credit or enter learning merely because feedback
was saved or the match was won. Full capture producers, explicit attestation UI,
eligible-episode learning, legacy aggregate migration and retained-history
normalization are tracked in REC-07/08/09. This boundary change is
not completion of those recovery packages or a field certification.

The initial eligibility boundary did not migrate SavedVariables. The capture
checkpoint below adds historical AAR interpretation migration. A separate
versioned migration must still preserve and quarantine unproven learning aggregates.

## Capture and history implementation checkpoint

Commander now assigns an epoch/uptime/process-serial call token and a revision
that survives match resets within the process. These identify local confirmations,
not durable cross-process learning episodes. Stable semantic calls retain their
token; replacement calls receive new tokens and no inherited attestation.
`/kwr delivered` displays the current action and confirmation command. The user
must explicitly submit `/kwr delivered <token>` after calling it to the team.
The handler rejects preview, completed/non-PvP state, wrong context, stale Store
state, replacement calls and duplicate confirmations. It updates a private copy
and requests normal pipeline publication. No team message is sent.

AAR captures the per-call record and updates it on confirmation without adding
another command or waiting for its ordinary sampling throttle. Active checkpoints
are copied at most every 30 seconds, with forced initial/explicit checkpoints;
finalization writes the completed entry directly and clears the interruption slot.
Working indexes are retained. A crash can lose changes since the last checkpoint.

Historical AAR interpretation now migrates once with `provenanceVersion = 1`.
Its previous review/attribution/stability are retained under `legacyReview` for
inspection; displayed interpretations no longer certify undocumented delivery.
Unknown future provenance versions remain intact. This is separate from the
learning aggregate migration now implemented in ADR-009. Compact capture modes
are implemented in ADR-010.

The first public execution producer captures only an exact `ASSAULT` event from
the local `BG_SYSTEM` grammar, at the command's exact objective, after explicit
delivery. ObjectiveIntel assigns a bounded per-session public fact ID and both
epoch observation time and UI uptime time. Commander binds that fact to the same
call identity/revision and labels its outcome `OBSERVED`. Preview, remote,
wrong-target, wrong-kind and pre-delivery facts are rejected.

`OBSERVED` proves activity at a public objective; it does not prove recommendation
causality or a tactical result. AAR reports `OBSERVED` execution but no decision
or match-outcome score, and Learning rejects it. Only a future reviewed public
result contract may emit SUCCESS or FAILURE. That contract must be independently
specified and tested; it must not be inferred from a capture, a scoreboard change
or match victory. Qualified aggregation and final integrated source/package
verification remain open.
