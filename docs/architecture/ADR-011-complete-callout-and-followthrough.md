# ADR-011: Complete commander callouts and reversible adherence

Status: source implementation in progress, September 10, 2026.
Owners: KWR-298/P13 and KWR-299/P14 under KWR-297.

## Decision

`Core/CommanderCardView.lua` extends CommandView with a lossless structured
projection. It does not select tactics. Strategic NOW, unissued NEXT, named
duties, local pressure/kill and control assignments are separate. SAY NOW is
built from current fields only. Full GUID/name pairs are retained; no byte
clipping or ambiguous short-name lookup is used by this projection.

Assignments emits full actor/duty records alongside its existing compact
strings. Commander copies these onto the retained play, preventing later
candidate assignments from rewriting a current call. Existing consumers retain
their compatibility fields until P05/P09 integration is complete.

`UI/CommanderCard.lua` owns measured presentation and nonsecure input. HUD
selects it through `hud.cardLayout = COMPLETE`. Legacy presets remain an explicit
development rollback, not acceptance of the old clipping defect. Actual engine
font height determines sections; compact expands to wide, then available width.
An unsupported fit disables feedback and reports the limitation. The baseline
body font is 13 effective pixels, NOW 16 and local fight 15; owner readability
approval remains a field/design gate. Score evidence reuses TruthContract.

Position stays unconfirmed until independently timestamped location evidence
is available. Roster `lastSeenAt` cannot certify cached position age. P01 owns
that missing contract; no arrival is inferred from an assignment.

## Call identity and ownership

The projection's exact, length-prefixed, case-preserving key includes candidate,
session, strategic command/revision, actor and target identities, current speech
and countdown identity. It excludes unissued NEXT, health changes and countdown
ticks. The legacy 160-byte normalized signature is not suitable for this key.

AAR captures semantic changes before its unchanged-record throttle. Its retained
commands own version-1 callouts and events; there is no separate feedback database.
Match IDs include epoch, monotonic time and an owner sequence to distinguish
same-second rematches. P01 still owns broader generation identity across facts,
transport and every command consumer.

Mouse-down captures the exact reference. Mouse-up rejects a changed reference,
drag or pointer travel. AAR rechecks current Store state and the retained snapshot.
Child controls consume their interaction separately. No feedback input targets,
casts, moves, sends chat, attests delivery or forces a strategy refresh/checkpoint.

## Persistence and corrections

Each callout retains schema/clock, candidate/match/session/command/callout identity,
creation time, original review context, complete speech, an event sequence and
bounded correction history. Events use UNIX_SECONDS and LEADER_ATTESTATION.
FOLLOWED, NOT_FOLLOWED and UNMARKED are separate from delivery/public outcome.

Producer bounds currently retain six callouts per command and eight events per
callout. Evicted NOT_FOLLOWED records leave a conservative command exclusion.
These count bounds are **not** evidence of P08's <=1 MB default serialized budget;
cross-match byte budgeting and load-time normalization remain required work.

Undo requires the exact last event ID and appends a compensating event restoring
its previous state. It cannot erase evidence or undo a newer correction. Existing
TEAM compaction/checkpoints preserve the new records. Future callout schemas are
not accepted for mutation.

## Learning

FOLLOWED creates no success. An otherwise qualified public episode remains eligible
when unmarked. NOT_FOLLOWED excludes execution-effectiveness credit. New learning
contributions carry a reversible ledger, separate from the existing numeric dedup
ledger. Finalized corrections are reconciled by AAR's deferred owner batch; no UI
handler changes aggregate counters. Pending correction suppresses adjustments.
Evicting a new contribution also removes its aggregate credit, so no irretractable
new credit survives loss of its identity. Old aggregates without this ledger cannot
receive qualifying corrections. P06/P08 must complete corruption/load/byte policies.

## Evidence and remaining obligations

Focused production-path suite: `tools/test-lua.ps1 -Suite Card`. Tests cover
long names, strategy/local separation, control revision identity, manual-state
separation, duplicates, Undo, rematches, diagnostic rejection, checkpoints,
post-intake retraction/reconstruction and 18 conservative font-mock layout cases.
The full Lua suite passes after the current changes in
`artifacts/full-lua-suite-20260912-r7.log`; the automation suite passes 241
checks in `artifacts/automation-suite-20260912-r7.log`. The r7 Card render
receipt is `artifacts/kwr297-card-render-20260912-r7/`; it records actual
projection/bounds/input hashes and produces HTML inspection artifacts,
explicitly not native WoW screenshots. The Card fixture now covers corrupt
persisted follow-through events and a future callout schema; the SavedVariables
audit regression verifies the 1 MiB guard both below and above budget. These
tests do not substitute for a representative maximum-writer receipt.

Still open: full localization, all mini/audio/Sentinel consumer integration,
native font/viewport/taint proof, representative cross-match byte budgets,
full P07 performance evidence, and all other package obligations.
No S-tier, whole-program completion, clean release or installed parity is claimed.

## Rollback

Choose an explicit legacy preset for source development, or restore the prior
reviewed source/package. Preserve callout history read-only. The diagnostic r7
candidate is installed only after package audit, reproducibility,
source/install reconciliation and complete replay parity passed; it is not a
clean-provenance release or field certification.
