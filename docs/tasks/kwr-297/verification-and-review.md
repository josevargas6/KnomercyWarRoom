# KWR-297 verification and Astra review contract

Read the [parent task](../KWR-297-s-tier-completion-packages.md) and
[execution standard](execution-standard.md). This file specifies how to prove
implementation; it does not contain pre-awarded passes.

## Evidence required for each package

Keep one package evidence directory under a fresh run folder in `artifacts/`.
Reuse existing receipt schemas where available. If adding a structured receipt,
implement its writer/validator and negative tests; do not handwrite success JSON.
Record:

1. Package and acceptance IDs; scope CODE/REVIEW/FIELD/RELEASE; actual reviewer role.
2. Base commit, dirty status and content hashes of all relevant executable inputs,
   doctrine/rulesets, fixtures, expected labels, runner and tools.
3. Failing pre-fix reproduction and passing post-fix case, or precise evidence why
   an existing implementation already satisfies that acceptance requirement.
4. Exact commands, working directory, runtime versions, timestamps, exit statuses,
   required markers, raw outputs and result-file hashes.
5. Full denominators: executed/expected IDs, primary/fallback/unmatched/forbidden,
   missing/duplicate/stale cases, sample counts and unknowns where applicable.
6. Changed-file list, public contract/schema changes, rollback path and residual
   obligations. Each remaining CODE obligation has an owner and concrete next edit.

Do not use the hash of the test runner alone to identify the code tested. After
source changes, old receipts are historical unless their full input digest still
matches. Never replace a baseline test or raw failed receipt with a newer pass.

## Available commands verified from current scripts

Run from canonical source, not Retail AddOns. These commands do not authorize
publication or a live install. Use a new run name to preserve previous evidence.

```powershell
Set-Location 'C:\Users\josev\source\repos\KnomercyWarRoom'
powershell -NoProfile -ExecutionPolicy Bypass -File tools\validate.ps1 -Channel development
powershell -NoProfile -ExecutionPolicy Bypass -File tools\test-lua.ps1 -Suite All -ReceiptFile artifacts\kwr297-run01-lua.json
powershell -NoProfile -ExecutionPolicy Bypass -File tools\security-audit.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\test-automation.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\knowledge-audit.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\performance-benchmark.ps1
```

Run focused fixtures during edits; run integrated gates after coherent slices.
All current Lua stages are developerTools, smoke, sentinel, soak and replay;
Host is a separate suite. A new focused suite/parameter must be implemented and
tested before documenting it as an executable command.

After bounded replay repairs, a full fresh source run uses:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\fresh-replay-benchmark.ps1 -OutputDirectory artifacts\kwr297-run01-source-replays
```

The default full strict gate may currently fail; that is evidence to repair,
not permission to add `-SkipDecisionBenchmark` to a final certificate. Partial
runs with `-MaxReplays`/`-StartIndex` are diagnostic only unless all shards are
validated/merged with exact expected ID and input coverage.

After the normal review/commit process yields clean approved source:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build.ps1 -Channel production -RequireCleanGit -IncludeSentinel -OutputDirectory artifacts\kwr297-run01-package
```

Use a fresh extraction directory, inspect safe archive roots, and provide its
actual Commander root to `fresh-replay-benchmark.ps1 -AddonRoot` with a separate
output directory. Compare the actual two result directories using:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\replay-semantic-parity.ps1 -SourceResultsDir artifacts\kwr297-run01-source-replays\results -PackageResultsDir artifacts\kwr297-run01-package-replays\results -OutputFile artifacts\kwr297-run01-parity.json
```

The second command assumes that package replay directory was actually generated;
never create an empty folder to satisfy it. P11 must strengthen the current
comparator's provenance/semantic scope and fail-empty behavior before using it
as full release proof. Reproducibility/package audits are part of `build.ps1`.

`certify-offline.ps1` exists but is not yet the entire KWR-297 gate. P11 wires and
tests its missing requirements. Do not describe its current success marker as
all OVR acceptance complete. Run document-authority audit after task/readiness
edits; move actually completed KWR task files into `docs/tasks/completed/`.

## Cross-package negative and metamorphic tests

| Invariant | Required adversarial check | Owning packages |
| --- | --- | --- |
| Evidence never improves by omission | Remove/future-date/conflict a mandatory fact | P01/P04 |
| Canonical identity | Rename/reorder rows; duplicate short names; rematch | P01/P03/P05 |
| Legal objective state | Duplicate/missed/out-of-order/wrong-generation transition | P02 |
| Collective feasibility | Last defender, impossible arrival, unknown capability, low search budget | P03/P04 |
| One live command | Repaint, delayed old callback, cancel, target loss, same-map rematch | P05 |
| Honest outcomes | Generated win, unrelated event, pre-delivery event, duplicate reload | P06 |
| Immutable publication and latest event | Producer mutation, stale cache, burst ending with critical fact | P07 |
| Retention and compatibility | Limit+1, repeated migration, future DB, compact field omission | P08 |
| Full verbal call visibility | Long names, multibyte glyphs, duplicate names, 10 actors, 3+ CC rows | P09 and P13/Astra |
| Protocol authority and bounds | Spoofed payload identity, flood unknown senders, OFF race | P10 |
| Fail-closed certification | Empty/stale/mismatched/skipped corpus or tampered artifact | P11 |
| Honest field quality | Duplicate/unbound match, missing reviewer, incomparable baseline | P12 |

Use reversible test-process mutations or isolated copies; never mutate production
source in place and forget to restore it. Tests must fail when the original
defect is reintroduced. A test that only checks no exception is insufficient for
identity, decision, clipping, timing and outcome assertions.

## Astra engineering review

The reviewer receives the exact diff, package contracts and evidence index. It
must inspect actual code/loaded paths and rerun targeted checks. Review output:

- **ACCEPT CODE:** all scoped implementation criteria proven; external gates named.
- **CHANGES REQUIRED:** specific file/function, failure, impact, expected fix and
  decisive regression. Severity follows safety/data loss before polish.
- **INSUFFICIENT EVIDENCE:** exact missing/stale input or test, not a vague opinion.

Questions the reviewer must answer:

1. Does this solve the real caller-path behavior rather than a helper-only example?
2. Are identity, clock, unknowns, source authority and immutable ownership intact?
3. Can a manual override, score, cache, projection or alternate entrypoint bypass it?
4. Do negative cases fail before the fix and mutations fail after it?
5. Is performance measured with the right clock, scope and complete samples?
6. Are retained data and schema rollback safe? Are defaults and public APIs preserved?
7. Is every required command/callout visible, complete and consistent, including
   long identities, emergency cancellation and the P13 multi-column fallback?
8. Are package/source hashes current and are completed CODE items truly complete?
9. Are tactical review, actual client proof and release authorization still honest?

Do not award S-tier from a code review. Use a separate evidence-backed product
assessment after P12. Review can approve an independently useful bounded package
without falsely closing the whole program.
