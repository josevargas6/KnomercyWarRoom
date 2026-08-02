# Public Readiness and Automation Audit — 2026-08-01

## Verdict

**NOT READY for stable public promotion.** The current Alpha 30 artifact is a
valid prerelease candidate, but stable/public readiness is blocked until the
repository workflow and field-evidence gaps below are closed.

## Verified evidence

- Live `6.1.0-alpha.30` validation, security audit, knowledge audit, smoke,
  soak, replay, automation-contract tests, package audit, checksum verification,
  and reproducibility check passed on 2026-08-01 local time.
- The live build produced the Commander distribution and developer archives;
  the distribution contains 129 entries and the developer package 4,942.
- The clean Git source build also passes reproducibility and package audit. Its
  distribution contains the same 129 entries; its developer package contains
  835 tracked-source entries, excluding live-only development material.
- GitHub publishes Commander `v6.1.0-alpha.30` and Sentinel
  `v6.1.0-alpha.25` as prereleases.
- Standalone Sentinel `main` CI is green.
- The Discord bot syntax checks and two deterministic formatting tests pass;
  its production dependency audit reports zero known vulnerabilities.
- Clean clones now exist outside the WoW directory under
  `C:\Users\josev\source\repos\` for all four GitHub repositories.
- Codex automation `kwr-weekly-security-audit` is active, read-only, and runs
  weekly on Monday at 09:17 local time.

## Repository blockers

1. Commander `main` CI fails at `Test public social copy` because the workflow
   references files that were present only in the live workspace, not Git.
2. The daily Discord workflow fails before creating a job because secret
   contexts are used directly in step `if` expressions.
3. `develop` and `main` are materially divergent: `develop` has five unique
   commits while `main` has 787 unique commits. Draft PR 20 proves a direct
   merge is not mergeable and exposes 29 content conflicts. Do not delete or
   force-update either branch; reconcile them through an owner-reviewed branch.
4. Four generated Lua/test files use committed CRLF bytes despite the
   repository's `*.lua eol=lf` rule, so a fresh Windows checkout appears dirty.
5. KWR Beacon remains private and its release gate is manual Retail testing;
   it cannot be described as a publicly available, fully certified addon.
6. Two documentation/operations PRs remain open: KWRSentinel PR 5 and the
   private Sentinel bot PR 4.

## Remediation in KWR-039

- Restore the missing social-copy, daily-update, workflow-status, and local Lua
  runner files to the Git source branch.
- Move webhook secret values to job environment entries and gate steps through
  the `env` context.
- Extend automation tests so missing workflow dependencies and direct secret
  use in `if` expressions fail locally.
- Make scheduled copy identify Alpha 30 as the current build while separately
  disclosing that live field evidence is still based on Alpha 29.
- Keep the weekly Codex task read-only. GitHub Actions remains the durable
  package/release scheduler and production authority.

## Owner actions before stable promotion

1. Review and merge the KWR-039 repair through the protected repository flow.
2. Reconcile `main` and `develop`, then require green CI on the reconciled head.
3. Review the two open PRs; merge or close them intentionally.
4. Confirm protected environments, required reviewers, and external release
   credentials without exposing secret values.
5. Complete and record current Retail field validation, including clean and
   upgraded SavedVariables, in/out-of-combat, taint, group-state, and rated
   battleground evidence.
6. Promote the exact certified bytes only after all public URLs and receipts
   identify the same version and checksum.

## Rollback

Disable `kwr-weekly-security-audit` if it generates unsafe or noisy work.
Revert the KWR-039 workflow repair to return to the prior prerelease-only state.
Do not roll back by copying the live WoW directory over Git source.
