# Historical: KWR-047 baseline provenance record

This dated audit preserves the observed baseline and rollback route.

## Provenance

- Canonical development clone: `D:\Development\KnomercyWarRoom`
- Remote: `https://github.com/josevargas6/KnomercyWarRoom.git`
- Branch at clone: `main` tracking `origin/main`
- Observed upstream commit: `0afcd9ff989419a26568c61125ae51f3b1c11ca7`
- Observed matching tag: none; `v6.1.0-alpha.33` resolves to `55a89f74e2ac8003d73f8f2d54754f63fc57e340` on `develop`.
- Deployment directory: `D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom`
- Read-only rollback snapshot: `D:\KnomercyWarRoom-rollback-snapshots\KnomercyWarRoom-live-20260803-012025`

## Disposition and recovery

`tools/repository-disposition.ps1` generated the complete per-file disposition
at `artifacts/kwr-047-r2/KWR-047-REPOSITORY-DISPOSITION.md`. It records 4,922
observed files with reasons, replacement authority, risk, and the rollback
path. The report retained 4,443 uncertain divergences as `REVIEW_REQUIRED`.

The 258 `Assets/` files were merged only after TOC and `UI/IconRegistry.lua`
callers established their production roles. Four root `tmp_*.txt` extraction
lists had no callers or generator contract and were removed from the deployment
directory after the snapshot; the report and snapshot retain their evidence.

Alpha 9 handoff and Alpha 29 planning/package records are labelled historical.
The document-authority registry assigns each active concern to one owner.

## Package and deployment evidence

The clean build at `artifacts/kwr-047-r3/` passed source manifest, archive
hash, extracted smoke/soak, and reproducibility checks. Its package manifest
comparison against the untouched runtime tree produced 21 differences, so no
deployment action was taken. The comparison log is
`artifacts/kwr-047-r3/KWR-047-LIVE-DEPLOYMENT-COMPARISON.log`.

## Rollback

Restore only from the recorded snapshot or a verified package manifest. Do not
copy arbitrary live-folder differences back into the canonical clone.
