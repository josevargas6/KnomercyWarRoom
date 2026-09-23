---
id: KWR-299
title: Record reversible command-followthrough feedback without inventing outcomes
owner: unassigned
priority: high
risk: high
status: in_progress
dependencies: [KWR-296]
affected_modules: [Core/CommandReview, Runtime/Commander, Runtime/AAR, Runtime/Learning, UI/HUD, UI/AARWindow, tests]
authority_references: [AGENTS.md, PRODUCT_ROADMAP.md, RELEASE_READINESS.md, DESIGN_CONTRACT.md]
---

# Objective and user outcome

The owner proposes left-click = **command not followed**, right-click =
**command followed** on the commander card. Implement fast, reversible feedback
bound to the exact verbal call being evaluated. The addon may then distinguish
adherence from result; it must not conclude that a followed command worked.

This is **P14** of [KWR-297](KWR-297-s-tier-completion-packages.md), integrated
with [Astra card rebuild KWR-298](KWR-298-commander-callout-card-rebuild.md).
High owns feedback schema/qualification; Astra owns the card interaction design.
Medium may implement explicit regression/report slices after the contract is set.
Source implementation is authorized and in progress. The installed field
candidate and live SavedVariables are not implementation targets.

# Current behavior

Commander already supports qualified per-call leader delivery attestation;
CommandReview validates that separately from public execution observations.
AAR preserves command revisions and candidate identity; Learning consumes
qualified episodes. Do not replace these with one ambiguous success Boolean.

# Required state distinctions

| Question | Values / evidence | Effect |
| --- | --- | --- |
| Was the call communicated? | Unknown or explicit leader delivery attestation | Existing delivery contract; clicking Followed must not silently invoke it |
| Did the team follow it? | UNMARKED / FOLLOWED / NOT_FOLLOWED; source LEADER_ATTESTATION | New manual adherence record |
| Did the objective/result occur? | UNKNOWN / OBSERVED_SUCCESS / OBSERVED_FAILURE / INTERRUPTED from qualified facts | Existing P06 outcome contract |
| What does the leader think happened? | Optional separately labeled manual outcome during review | Human feedback, not verified public observation |
| Did the addon cause the result? | Not established by the above alone | Never award causal match-win credit |

Unknown is the default. NOT_FOLLOWED is not equivalent to a bad strategy or
failed objective. FOLLOWED is not SUCCESS. A team can follow a call and lose,
ignore a call and win, or partially act with no verifiable result. Keep a later
review option for partial/uncertain notes without forcing them into positive
execution credit; the two requested quick clicks remain the primary controls.

# Correct data and ownership design

Extend the existing CommandReview/AAR boundary, not a separate feedback database.
Proposed record semantics, to map into a versioned schema:

```lua
-- Specification only; not an implemented API or a success receipt.
followthrough = {
    schemaVersion = 1,
    eventId = "stable-local-feedback-event",
    candidateId = "bound-candidate",
    matchId = "current-match",
    commandId = "issued-command",
    commandRevision = 1,
    calloutId = "current-spoken-bundle",
    calloutRevision = 1,
    state = "FOLLOWED", -- or NOT_FOLLOWED; absence means UNMARKED
    source = "LEADER_ATTESTATION",
    context = "Commander",
    clock = "UNIX_SECONDS",
    recordedAt = 0, -- real validated timestamp at execution time
    supersedesEventId = nil,
}
```

Keep a bounded append-only correction history and one derived effective mark.
The callout identity includes the relevant spoken action, actors, targets,
location and conditions. Strategic revision alone is insufficient if local CC
or kill assignments changed without changing it. Bind to the exact displayed
issued NOW speech bundle; do not attest an unissued NEXT option or every future
tactical revision. Store canonical identities/compact snapshot needed to review
the reference after the card changes, subject to P08 bounds.

# Card interaction implementation

1. Show persistent hints: `Left: Not followed | Right: Followed`, current target
   call reference and status. Provide explicit labeled buttons as an accessible
   alternative; the requested background clicks remain available.
2. Use a nonsecure card click region. Child buttons, drag/resize handles, text
   selection, tooltips/scroll controls and secure roster clicks are excluded.
   Move the old right-click context menu to an explicit menu button if necessary.
3. Capture eligible call identity at mouse-down; on mouse-up validate same
   generation/callout/revision and no drag/resize movement. If changed, reject
   with a calm `Call changed — mark again` message. No global-current lookup may
   retarget the click to a new command. Suppress double-click duplicates.
4. On an accepted click, record only the local bounded feedback event through
   its owner. Show `Marked followed` or `Marked not followed`, plus Undo. No
   modal confirmation is required for each reversible mark. Undo explicitly
   supersedes that event; do not silently delete audit evidence.
5. Once the card has moved on, keep the last marked call available in a clearly
   labeled review control. A user reviewing the old call must see its actual
   snapshot, not current text. Do not automatically mark old calls not followed
   merely because time elapsed or a new command appeared.
6. In Diagnostic/Spectator/preview, disable qualifying feedback or label it
   diagnostic-only; never upgrade it after switching context. In combat only
   safe addon-local state/visual updates occur. No forced disk write/full refresh,
   protected attribute change, target/cast/movement or chat send is allowed.
7. Let existing AAR checkpoint cadence persist data; preserve final/interrupt
   flush behavior. Default old records to UNMARKED; no destructive migration.

# Outcome and learning rules

Show adherence and observed outcome side by side in the card review/AAR/export.
An observation must still satisfy P06 identity, source, time and outcome predicate.
Manual-followed-only records cannot enter verified execution-success statistics.
Manual outcome ratings stay in a separate human-review column.

UNMARKED does not mean the call was ignored. Preserve existing independently
qualified public-observation paths; do not retroactively require a click on every
historic episode merely because the optional feedback feature was added.

NOT_FOLLOWED excludes the episode from claims about the strategy's executed
effectiveness. If public facts show an objective happened anyway, retain both
facts with a clear limitation/conflict; do not credit the advice. FOLLOWED with
no result remains unknown. FOLLOWED plus a qualified observed result may support
a labeled attested-adherence outcome sample, subject to explicit delivery/context
eligibility and P06's conservative policy, never causal match-win credit.

Do not mutate already-scored learning counters directly from a UI click. Prefer
evaluating effective marks during finalized, qualified episode intake. Corrections
after intake need a tested deterministic recompute/retraction policy before they
can affect learned aggregates; otherwise keep feedback review-only. Repeated
clicks, Undo, reload and record reconstruction must never add samples twice.

# Verification

Use actual input handlers/owner methods with fake mouse/clock events:

- Left produces one NOT_FOLLOWED; right produces one FOLLOWED; no click leaves
  UNMARKED. Repeated same mark is idempotent or a bounded no-op.
- Drag, resize, child-button click, mismatched mouse-down/up call, new tactical
  revision and same-map rematch cannot mark another call.
- Undo/correction updates the effective mark but preserves bounded audit history.
- Terminal/history review marks the explicitly selected snapshot only; old
  current pointers and wrong candidate/match IDs reject safely.
- Diagnostic/Spectator/generated-only feedback never qualifies as Commander
  delivery or observed execution. Future/invalid/mixed-clock timestamps reject.
- Followed+loss, not-followed+win, followed+unknown, unmarked+observed outcome,
  and conflicting manual/public evidence remain distinct in UI/AAR/export.
- Correction after finalization, duplicate copy/reload and dedup-ledger eviction
  cannot double count or leave stale learning credit.
- Combat mock rejects protected setters; accepted feedback causes no gameplay,
  transport or full strategy work. Producer caps hold for repeated clicks.

# Acceptance criteria

- [ ] Exact requested click mapping is discoverable, safe and reversible.
- [ ] Feedback binds to the immutable displayed verbal call, including tactical revision.
- [ ] Adherence, delivery, observed outcome and manual outcome stay separate.
- [ ] No click manufactures success, causes gameplay or automatically sends data.
- [ ] Persistence/corrections/deduplication and UI/export parity pass all cases.
- [ ] Learning remains review-only for unsupported correction/qualification paths;
      any intended learning feature is not marked complete until those paths pass.

# Rollback and handoff

Disable the input feature while preserving read-only feedback history if a defect
appears. Keep existing delivery/public-outcome semantics untouched. Handoff the
schema/ADR, interaction trace, eligibility matrix and correction tests with the
Astra card review. Actual click ergonomics and operator interpretation are FIELD.

Offline status: IN_PROGRESS. AAR-owned exact-call capture, click mapping,
correction/Undo, checkpoint retention and reversible learning intake are
implemented and covered by the focused Card suite. See
[ADR-011](../architecture/ADR-011-complete-callout-and-followthrough.md) for
remaining CODE obligations. The September 12 Card fixture now also exercises
actual AAR load compaction with corrupt persisted event data and a future
callout schema, proving both are rejected from mutable retained history. The
SavedVariables audit now records and fails closed on the 1 MiB serialized-file
budget; a representative maximum-writer receipt remains open.
Field status: NOT_TESTED. Release status: NOT_REQUESTED.
