# Commander Blocker Reconciliation and Luna Completion Addendum

Date: 2026-08-03  
Candidate: `6.1.0-alpha.33`  
Owner: GPT-5.6 Luna for Commander work; repository owner for external release actions

This is the completion addendum to
[`KWR_032_034_LUNA_HANDOFF_2026-08-03.md`](KWR_032_034_LUNA_HANDOFF_2026-08-03.md).
It separates Commander work that Luna can complete in this checkout from
Retail proof that requires the live client and from external release work that
requires owner authorization.

## Current offline result

The generated offline corpus and reports were repaired on 2026-08-03:

- production validation: PASS, 131 Lua files, zero errors/warnings;
- knowledge audit: PASS;
- Lua smoke: PASS, 275 checks;
- Lua soak: PASS, 500 refreshes, p95 `0.80 ms`, maximum `3.20 ms`;
- replay suite: PASS;
- automation contract tests: PASS, 52 checks;
- security audit: PASS, with the expected no-Git-metadata warning;
- corpus audit: PASS, 1,003 replay fixtures, 1,001 labels, 1,000 replay
  results, 1,000 outcome reviews, and 201 adversarial cases;
- decision benchmark: PASS, 1,000 primary matches, 1,000 fallback matches,
  zero forbidden failures;
- scenario calibration and adversarial calibration: regenerated for 200
  scenarios each;
- offline completion audit: `offlinePrepared: true`, `fieldTestingPrepared:
  true`.

The four corpus-directory README markers required by the corpus validator are
now present under `tests/replays/`, `tests/golden/`, `tests/replay-results/`,
and `tests/outcomes/`.

Package audit has now passed on the Alpha 33 archive: distribution 129
entries, developer 4,923 entries, hashes verified, and extracted smoke/soak
passed. Reproducibility is `PASS_WITH_DOCUMENTED_EXCEPTION`: staged payload
digests match, while PowerShell ZIP containers are not byte-identical.

If the final build regenerates the ZIPs after this record is updated, rerun
`tools/package-audit.ps1` and take the final artifact hash from that last pass.

## Canonical Commander status ledger

Use only the following statuses when closing the lingering work inventory:

- `PASS`: current candidate has deterministic and required live evidence;
- `OPEN`: work or required proof remains;
- `SUPERSEDED`: replaced by a newer authoritative task or candidate, with a
  link to the replacement;
- `NOT A COMMANDER BLOCKER`: belongs to external publication, Sentinel,
  Beacon, bot, Maps, ScoreCard, or future expert-tier expansion and cannot
  block Commander field certification.

Never infer `PASS` from a checked box in a stale document. Every `PASS` needs a
current artifact, test output, or Retail evidence link.

### Must remain OPEN until Luna closes them

| Item | Required closure |
| --- | --- |
| `KWR-032` | Repaired expanded Team health and cross-surface specialization provenance, plus fresh Retail screenshot/evidence. |
| `KWR-033` | Stable command publication, truthful lifetime/AAR semantics, and one complete clean flag match with coherent `/kwr verify`, `/kwr perf`, and AAR totals. |
| `KWR-034` | Canonical flag targets for both assigned sides/locales and fresh pickup/drop/return/capture evidence with raw prose retained only as evidence. |
| `TP-D03` | Supported-resolution/UI-scale matrix, including 1280x720, 1920x1080, and 2560x1440 where available, across all Command Center tabs and active scenes. |
| `KWR-035` live proof | Compact combat HUD and current/next/kill/CC readability at real combat pace; keep code status separate from live proof. |
| `KWR-047` live proof | Unified roster lifecycle, stable rows, legal health, target/focus behavior, roster hydration, death/rez, reconnect, and combat enter/leave. |
| Lifecycle | Clean install, upgraded SavedVariables, login/reload/logout, relog/reconnect, disable/re-enable, queue entry, battleground entry, death/rez, completion, exactly-one AAR entry, and instance exit. |
| Group/authority | Solo/partial group, 8-player Blitz, 10-player battleground, leader/role changes, assigned-team changes, and cross-faction/mercenary orientation. |
| Safety/performance | Taint/blocked-action log, protected-row deferral, Quick Calls, CPU, memory, FPS, no forbidden transport, and matched enabled/disabled performance evidence. |
| Map certification | Winning and losing evidence for all supported map families and required Standard/Blitz variants, tied to the final candidate hash. |

## Task-inventory audit Luna must finish

Luna must scan every Markdown task contract under `docs/` and `docs/tasks/`,
including duplicate numeric IDs, and append a row to the final handback with:

`path | task ID | status | Commander impact | evidence/replacement | owner`.

The classification rules are:

- The dated field-fix contracts for `KWR-032`, `KWR-033`, and `KWR-034` are
  authoritative over same-numbered later UI task files.
- `KWR-048`, `KWR-049`, and `KWR-050` are offline-readiness/tooling work and
  are `PASS` only when their regenerated JSON and audits pass.
- Unified roster and visual tasks with unchecked live criteria remain `OPEN`
  even when their offline implementation sections are complete.
- Expert-tier corpus/doctrine expansion after the current field-certification
  gate is `NOT A COMMANDER BLOCKER` unless it changes Commander runtime code or
  reopens a safety/truth gate.
- Sentinel, Beacon, Discord bot, Maps, ScoreCard, GitHub publication,
  CurseForge uploads, webhook receipts, and branch reconciliation are
  `NOT A COMMANDER BLOCKER` for Luna's local Commander field handoff, but must
  be listed as owner-phase work rather than silently discarded.
- Any task whose acceptance criteria are stale, duplicated, or contradicted by
  the current candidate must be marked `SUPERSEDED` with the replacement path;
  do not delete the record.

## Owner-authorized release phase

This phase starts only after Commander code and field gates pass. It is outside
Luna's local completion authority:

1. Use a real Git worktree and reconcile the intended release branch.
2. Resolve CI/workflow, branch-protection, tag-provenance, metadata, social
   receipt, and public-package parity tasks (`KWR-040` through `KWR-046`) using
   protected review.
3. Review stale issues and open PRs; close or supersede them intentionally.
4. Confirm protected environments, CurseForge IDs, webhooks, and exact public
   SHA-256 receipts without exposing credentials.
5. Publish only the exact candidate bytes that passed Commander field gates.
6. Treat Sentinel as a separately versioned component unless an owner-approved
   synchronized release decision exists.

Luna must not claim these actions are complete without authenticated external
   evidence. The final Commander handback must say `OWNER PHASE PENDING` when
   they remain.

## Completion gate

Commander is ready for the user's field-testing phase only when:

1. the offline audits above pass on the final candidate;
2. the full package audit passes;
3. the task-inventory audit has no unclassified task;
4. all Commander items above are either `PASS` or explicitly `OPEN` with a
   concrete field capture procedure;
5. no unsupported `PASS` appears in the evidence matrix; and
6. owner-phase release operations are clearly separated from field readiness.

The correct handback states the exact candidate hash, offline pass outputs,
remaining live cells, and owner-phase items. It does not equate “field testing
prepared” with “field certified” or “publicly promoted.”
