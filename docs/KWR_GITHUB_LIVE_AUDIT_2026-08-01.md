# GitHub Live Audit — 2026-08-01

## Evidence reviewed

- Public repository: [josevargas6/KnomercyWarRoom](https://github.com/josevargas6/KnomercyWarRoom)
- Screenshot evidence supplied by the owner showing the public Issues view and
  the `main` branch banner.
- Read-only GitHub API inspection of issue `#4`, repository branches, open pull
  requests, and `main...develop` comparison.

## Findings

### Issue #4 is stale, not a current Alpha 30 blocker

Issue [#4 — Alpha 15 spoken-command and transition certification](https://github.com/josevargas6/KnomercyWarRoom/issues/4)
is still open with labels `field-test` and `release-blocker`. It was created on
2026-07-02, last updated on 2026-07-03, has no comments, and its checklist is
explicitly for `6.1.0-alpha.15` and branch `feature/alpha15-spoken-transition`.
It should be closed as superseded or rewritten as a current Alpha 30 field
verification issue before anyone treats the open-issue count as release truth.

### Public `main` is behind the active development line

The default branch is `main`. Read-only comparison reports:

- status: `diverged`
- `develop` ahead of `main`: 5 commits
- `develop` behind `main`: 783 commits

The public README on `main` still presents Alpha 29. The current social-copy
repair is staged on `develop` through [PR #14](https://github.com/josevargas6/KnomercyWarRoom/pull/14)
and is not yet visible on the default public branch.

### `main` protection needs owner action

The supplied screenshot shows GitHub's `Your main branch isn't protected`
banner. The unauthenticated API cannot read branch protection policy, so this
report does not infer settings hidden behind authentication. Treat the banner
as direct evidence: protect `main` with pull requests, required CI, and an
explicit review requirement before promoting `develop` or any hotfix.

## Required repair order

1. Protect `main` and require the KWR CI status check.
2. Decide whether to close issue #4 as superseded or replace its body with an
   Alpha 30 field-test checklist; preserve the old evidence in history.
3. Review and merge PR #14 only after its CI completes.
4. Promote only the intended social-copy commit(s) to `main`; do not merge the
   full `develop` line because the branches are heavily divergent.
5. Recheck anonymous README, issue, PR, and release pages after promotion.
