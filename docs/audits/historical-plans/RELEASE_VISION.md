# Historical: KWR 6.1 Field-Test Release Vision

Status date: 2026-07-29  
Release-train status: recovery alignment  
Commander candidate: `6.1.0-alpha.28`

This is the single authority for KWR product scope, component ownership,
release sequencing, and promotion direction. Detailed engineering and QA files
remain authoritative inside the boundaries assigned to them below, but they
may not redefine this release vision.

## Release outcome

Ship a trustworthy Rated Battleground command suite led by Knomercy War Room:

- one Commander owns battlefield truth, strategy, assignments, and calls;
- each player-facing surface shows a bounded view of that same command;
- optional utilities remain useful without becoming hidden dependencies;
- offline evidence is reproducible before any build reaches field testing;
- live Retail evidence, not optimism, decides promotion.

The first milestone is a focused field-test train, not a stable public
release. It proves the recovered Commander candidate and the optional Sentinel
client through real battleground use before wider promotion.

## Product contract

| Component | Current local version | Release role | Dependency contract |
| --- | --- | --- | --- |
| Knomercy War Room | `6.1.0-alpha.28` | Flagship Commander and sole strategy authority | Standalone. Default release package. |
| KWR Sentinel | `6.1.0-alpha.25` | Optional compact player execution client | Same-client Commander bridge in the current alpha; safe standalone fallback; no live cross-player relay. |
| KWR Beacon | `1.0.0-beta.1` | Optional secure teammate/healer utility | Separate addon and release lane; never required by Commander or Sentinel. |
| KWR Sentinel Bot | `0.1.0` on GitHub | Discord support, intake, diagnostics, AAR, and reviewed issue routing | External service; no live WoW connection and no source-of-truth authority over doctrine or releases. |
| KWR Maps | `1.1.1` | Independent map experiment/utility | Not a Commander dependency. Commander uses Blizzard's native `Shift-M` battlefield map. |
| KWR ScoreCard | `1.2.0` | Independent score/prediction experiment | Not a Commander dependency and not an authority for Commander battlefield truth. |

One release vision does not mean one runtime, repository, ZIP, or semantic
version. Components keep independent versions and packages. They align through
documented contracts, compatible field-test milestones, and reviewed evidence.

## Authority hierarchy

1. `RELEASE_VISION.md` owns product scope, component boundaries, recovery
   policy, release sequencing, and promotion direction.
2. `EXPERT_TIER_BATTLEFIELD_MASTER_PLAN.md` owns the forward execution path
   from the recovered Commander alpha to an expert-tier, offline-benchmarked,
   battlefield-validated release. It cannot redefine suite scope or bypass the
   current candidate's release gates.
3. `ALPHA_S_TIER_MASTER_PLAN.md` owns the historical and current Commander
   alpha engineering-quality baseline.
4. `PILLAR_EXECUTION_SHEET.md` and `S_TIER_EXECUTION_SCORECARD.md` own work
   order and subsystem evidence scoring.
5. `WINNING_STATE_RELEASE_GATES.md` and `RELEASE_READINESS.md` own the current
   Commander gate decision.
6. `QA_CHECKLIST.md` owns the field-evidence ledger. An unchecked evidence item
   is not automatically a release blocker unless a release gate classifies it
   as one.
7. Dated handoffs and imported planning packages are historical evidence. They
   do not override current authority.

When two files conflict, the higher item in this hierarchy wins. The conflict
must then be corrected rather than allowed to become a second plan.

## Recovered source authority

The in-game addon folders are newer than several GitHub branches and must be
treated as recovery sources until their full diffs are reviewed.

| Repository | Inspected GitHub state | Recovered in-game state | Recovery decision |
| --- | --- | --- | --- |
| `josevargas6/KnomercyWarRoom` | `main` `alpha.9`; `develop` `alpha.12` | `alpha.28` | Preserve local source. Import to a dedicated recovery branch, audit the complete diff, then open a PR. Do not replace it from `main` or `develop`. |
| `josevargas6/KWRSentinel` | `main` `alpha.25` | `alpha.25`; standalone and embedded copies match | Use GitHub as the shared baseline after a complete manifest comparison. Finish the open polish verification before promotion. |
| `josevargas6/KWR-Beacon` | `main` `0.1.0` | `1.0.0-beta.1` | Preserve local source. Recover through a dedicated branch and validate secure-action changes before PR review. |
| `josevargas6/kwr-sentinel-bot` | `main` `0.1.0` | No recovered local checkout in the supplied addon roots | GitHub remains authoritative. Stage and test separately from the WoW addon release. |

The GitHub observations above were recorded on 2026-07-28. They are a recovery
snapshot, not a permanent substitute for repository manifests and PR review.

## Field-test train

### Phase 1 - Freeze recovery truth

- Keep the local Commander `alpha.28` package and build receipt as the recovery
  candidate.
- Preserve remote rollback branches and tags.
- Produce complete source manifests before any repository synchronization.
- Make repository recovery through dedicated branches, never by overwriting
  `main` or `develop`.

Exit: every recovered component has a reviewable local-to-remote diff and a
named source authority.

### Phase 2 - Recover Commander to GitHub

- Create a Commander recovery branch from the appropriate remote integration
  point.
- Import the exact validated `alpha.28` source state.
- Review architecture, TOC load order, release files, and package contents.
- Run validate, knowledge audit, smoke, soak, build, and extracted-package
  audit again from the Git checkout.
- Open a PR with `What changed`, `Why`, `Safety`, `Validation`, and `Rollback`.

Exit: GitHub contains a reviewable Commander candidate whose staged payload
matches the recovered build.

### Phase 3 - Finish Sentinel's open handoff

- Verify the seven acceptance criteria in
  `docs/SENTINEL_POLISH_TASK_2026-07-18.md`.
- Reconfirm standalone/embedded parity.
- Keep cross-player transport out of scope until the transport specification
  gates are implemented and validated.
- Package Sentinel separately or through the explicit
  `tools/build.ps1 -IncludeSentinel` path.

Exit: Sentinel is a verified optional companion, not an assumed dependency.

### Phase 4 - Focused Retail field certification

- Exercise full match lifecycles across supported battleground families.
- Capture Lua error, taint/blocked-action, `/kwr perf`, `/kwr verify`, AAR, and
  screenshot evidence.
- Confirm command stability, assignment integrity, native map workflow, local
  fight truth, Sentinel routing, and safe secure-click behavior.
- Record defects against the owning component and rerun the complete offline
  gate after fixes.

Exit: all release-blocking `LIVE REQUIRED` gates have evidence and no open P0
or P1 defect remains.

### Phase 5 - Promote optional components

- Recover and validate Beacon independently, with combat-lockdown and queued
  secure-attribute changes as its release-critical safety proof.
- Stage the Discord bot independently, keeping manual data intake and reviewed
  GitHub routing between it and the addon.
- Decide whether Maps and ScoreCard remain experiments or receive separate
  public release lanes. Neither decision blocks Commander field testing.

Exit: every promoted component has its own tested package, changelog, support
path, and rollback plan.

## Current decision

Commander `6.1.0-alpha.28` is offline-certified and has entered focused
in-client validation. The first preserved Twin Peaks match found three
release-blocking repair areas: Team health/provenance (`KWR-032`), command
stability/AAR metric clarity (`KWR-033`), and canonical flag-command targets
(`KWR-034`). It is ready for bounded repair and continued evidence collection,
not broader field or stable public promotion.

The package gate currently proves:

- validation: 118 Lua files, 0 errors, 0 warnings;
- knowledge audit: pass;
- smoke: `KWR_SMOKE_PASS checks=275`;
- soak: `KWR_SOAK_PASS refreshes=500`;
- distribution and developer package audits: pass;
- reproducible staged payloads with the documented PowerShell ZIP-container
  exception.

Remaining release blockers are live Retail proof: lifecycle stability,
taint/secure-action safety, field performance, resolution/readability,
supported-map behavior, and evidence-backed decision quality.

Sentinel promotion is also blocked by its open polish acceptance criteria.
Beacon and the bot are separate promotion lanes and do not block the Commander
field test.

## Ordered backlog

1. Preserve and review the Commander `alpha.28` recovery diff on GitHub.
2. Repeat the full Commander gate from the recovered Git checkout.
3. Close Sentinel polish acceptance criteria with deterministic and in-client
   evidence.
4. Run Commander plus Sentinel focused Retail field sessions.
5. Fix only evidenced P0/P1 field defects, then repeat offline and live gates.
6. Recover Beacon `1.0.0-beta.1` to GitHub and execute its secure-action test
   matrix.
7. Stage the Discord bot and verify support/intake workflows without live addon
   coupling.
8. Make an explicit keep/retire/promote decision for Maps and ScoreCard.
9. Promote each component independently when its own gates pass.

## Change control

Any proposal that changes component ownership, adds a required dependency,
introduces cross-player transport, changes a persisted schema across projects,
or moves strategic authority away from Commander requires an Architecture
Decision Record and an update to this file before implementation.
