# P00 — Close recovery decisions and preserve the test baseline

Parent: [KWR-297](../KWR-297-s-tier-completion-packages.md).
Read [execution standard](execution-standard.md). Maps to OVR-01 and KWR-281;
this package coordinates existing recovery records rather than opening a second
review ledger. Lead: Terra High for dispositions, Medium for evidence wiring.

## What and why

The dirty source, old installed snapshots and current frozen field candidate are
three different objects. Finish the original 62 source-reconciliation decisions,
including the documented nine REC packages and 15 missing reviews. A verified
installation does not settle an earlier semantic merge or recovery decision.

## Existing owners and inputs

Read `docs/tasks/KWR-281-release-source-reconciliation.md`, its existing source
review ledger/packet, `tools/source-install-review-ledger.ps1`,
`tools/source-install-reconciliation.ps1`, `tools/release-manifest.ps1`, the
KWR-296 completion receipt and current `git status`. Verify paths before use.
The four excluded development modules belong in matching optional DevTools;
their companion namespace transformation is intentional, not source drift.

## Baseline accounting evidence (2026-09-12)

`tools/source-recovery-accounting.ps1` now retains the September 8 historical
ledger without rewriting it and binds each original row to the r7 candidate's
reconciliation, hash-bound source-only review ledger, and passing extracted
package audit. `artifacts/source-recovery-accounting-20260912-r7.json` accounts
for all 62 rows: 55 current source/install matches, four reviewed DevTools-only
source entries, one audited release-manifest exclusion (`UI\\ReporterMap.lua`),
and two unchanged reviewed removals. Twenty-nine source files changed since the
historical baseline, but every changed row is therefore verified against the
current candidate rather than silently inheriting the old decision. The tool
fails closed without the package audit: the ReporterMap exclusion then remains
unresolved. The historical denominator is preserved and the final receipt is
complete; this closes P00 accounting, not the independent tactical review or
Retail field gates.

## How to implement correctly

1. Capture current dirty status and full source-content manifest without changing
   any user files. Identify the historical source and installed sides of each
   original diff; do not use today's repaired AddOns folder as the old baseline.
2. For each row retain old disposition and add the final reviewed decision,
   owning REC/OVR/package, rationale, test case and final file hash. Use existing
   ledger schema; extend its validator only if a real required field is missing.
3. Route REC-01/02/03/05/06 implementation to P07, REC-04 to P08, and REC-07/08/09
   to P05/P06/P08. Route remaining safety/UI/adapter reviews to P01/P05/P09.
   Routing is not closure; a row stays pending until those actual tests pass.
4. Preserve tested safe source where an installed optimization is unsafe or
   unnecessary. Do not import every old difference, delete source-only modules,
   or adopt handwritten compact data in place of canonical generators.
5. Update KWR-281 and RELEASE_READINESS with explicit evidence. Later P11 freezes
   the integrated candidate; HEAD plus a dirty flag alone is never its identity.

## Verification

Run existing source-review-ledger, packet and reconciliation tests; inspect
their parameter definitions before invoking them. Add cases that reject:

- reversed source/installed hashes; missing, duplicate or unknown row IDs;
- a final disposition with no tested behavior or stale final source hash;
- a record that calls planned implementation already merged;
- baseline substitution with a newer installed candidate;
- source-only DevTools treated as unreviewed deleted runtime functionality.

All 62 original rows must remain accounted for, even if multiple rows share a
bounded implementation. New observed differences are additive, not a denominator
replacement. Record intentionally preserved source as a tested decision.

## Acceptance criteria

- [x] Exact baseline sides and dirty work are preserved and identified.
- [x] Every original row has a tested final disposition in KWR-281's ledger.
- [x] No DEFER or absent review hides unfinished CODE work.
- [x] Resulting files/load graphs agree with P11's final source manifest.

## Rollback and handoff

This package never installs, resets or removes user changes. Revert only its
scoped ledger/tool edits if a validator regression occurs. Handoff includes the
62-row accounting, focused negative tests and links to routed implementation
receipts. High reviews disputed dispositions; no need for a WoW session to finish.
