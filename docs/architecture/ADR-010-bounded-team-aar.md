# ADR-010: Bounded team AAR and explicit development capture

Status: Accepted, September 9, 2026. REC-08 / OVR-18.

New matches default to TEAM capture. Full DEVELOPMENT capture requires both the
profile's explicit development opt-in and BuildInfo's authorized development
mode. Mode is fixed at match start; changing settings cannot retroactively turn
coaching history into development evidence. Export is always local/manual.

TEAM retains at most ten command records, twelve chat/event records, twenty-four
objective timeline records, six decision reviews, four locations and three notes
per player, and five review queue items. Smaller MemoryBudget caps take priority.
Command retention preserves the first two and latest eight calls to retain both
the opening and endgame. DEVELOPMENT retains the existing larger bounded limits.
The latest call remains last, preserving final-command and delivery update logic.

TEAM omits simulation packages, detailed execution assessments, enemy response
packages and active-play trend/decision diagnostics. It retains action, assignment,
public evidence, delivery/execution provenance, learning scope, active play/outcome,
manual overrides and local coaching history. It omits detailed performance samples
but keeps compact safety counts. Missing performance is displayed as unavailable,
not zero. This does not replace separate client performance instrumentation.

The previous append helper returned a trimmed replacement list that its callers
ignored. The active original list could grow until a checkpoint was compacted.
It now trims the owned list in place at every write. Objective-event deduplication
also has a bounded FIFO index (128 IDs at default caps). Checkpoints keep active
working indexes intact; no collector state is stripped from the live entry.

Initial state is checkpointed immediately, and the first recorded call forces an
updated checkpoint. Later copies occur every thirty seconds unless explicitly
forced. Finalization writes the final entry and clears the interruption slot;
calling finalization again cannot duplicate a match. A crash can lose changes
since the last checkpoint, but cannot silently lose the opening call because it
was sampled just after an empty initial checkpoint.

Legacy PLAYER mode normalizes to TEAM. Unlabeled history with performance payloads
is labeled LEGACY_DEVELOPMENT and retains those diagnostics. Unknown future
capture schema versions remain untouched. Existing delivery-provenance migration
continues independently; changing a capture label never qualifies delivery.

The aar_retention fixture exercises 150 active writes, per-write limits, opening/
latest-call preservation, deduplication, checkpoint ownership, initial/final writes,
repeated finalization, explicit opt-in and mid-match setting changes, export labels,
and legacy/future capture formats. Source/extracted package parity, broader malformed
SavedVariables fixtures, serialized-size benchmarks and field evidence remain
separate full-overhaul gates.
