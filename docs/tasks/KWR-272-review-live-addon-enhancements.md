---
id: KWR-272
title: Review and integrate 20 live addon enhancements
owner: Codex
priority: high
risk: high
status: blocked
dependencies:
  - KWR-270
affected_modules:
  - Data/KnowledgeManifest.lua
  - Data/PatchData.lua
  - Data/SourceRegistry.lua
  - META_SOURCES.md
  - Runtime/AAR.lua
  - Runtime/Assignments.lua
  - Runtime/Commander.lua
  - Runtime/FormationAdvisor.lua
  - Runtime/MatchRuntime.lua
  - Runtime/MemoryBudget.lua
  - Runtime/ObjectiveIntel.lua
  - Runtime/Sensors.lua
  - Runtime/Strategist.lua
  - Runtime/TeamResolver.lua
  - Runtime/Verification.lua
  - UI/CombatRosterVisuals.lua
  - UI/HUD.lua
  - UI/MainWindow.lua
  - UI/MainWindowPages.lua
  - UI/RosterPresentation.lua
authority_references: [AGENTS.md, DESIGN_CONTRACT.md, QA_CHECKLIST.md, RELEASE_READINESS.md]
---

# Objective

Review the 20 live-addon file variants found during the 2026-08-27 Season 2
cutover audit, decide which behaviors are beneficial and safe, and integrate
only approved enhancements through the canonical source, test, review, and
versioned-release process.

# User outcome

Players receive the useful live improvements without shipping unreviewed code,
losing provenance, weakening combat safety, or representing a modified live
folder as the already-published `6.1.1-alpha.5` package.

# Current behavior

The public `v6.1.1-alpha.5` Commander package is coherent and has 398 entries,
ZIP SHA-256
`EDA0B82F368B39FF7D2D1AECB4D80EB7FD124DA5F0330EC612DB0BE7ABA67268`,
and payload digest
`283044EF873F57337627EDF8CD69D5FA78DC098A231EC7BF7EBB3E0B79A0C176`.

The installed Commander also has 398 entries and no missing or extra files, but
20 files differ and its payload digest is
`B38FABAED4B48A82D879B7E893EA2113B212B77037BD85120A771881CA4A6DBF`.
Only four installed variants currently match the dirty canonical worktree. None
of the 20 variants matches tagged `main`. These files are enhancement candidates,
not approved source or release evidence.

Canonical `main` is already dirty in 18 tracked files plus one untracked Retail
certificate. Versioned deployment certification still binds Alpha 4, and the
untracked Alpha 5 Retail certification is `BLOCKED/UNBOUND` with zero
stability-ready and zero performance-passing matches.

# Enhancement inventory

Each row is a separate review decision. A reviewer must mark it `ADOPT`,
`REWORK`, or `REJECT` and record the validating test or evidence. The hashes
bind this task to the live files audited on 2026-08-27.

| # | File | Live SHA-256 | Proposed enhancement to review |
| --- | --- | --- | --- |
| 1 | `Data/KnowledgeManifest.lua` | `CD67D59BAA797B4836EB41EDF517508E4CFF7140FBEC105950A1D7D8491FA335` | Advance reviewed-source freshness only after the official ledger is complete and human-reviewed. |
| 2 | `Data/PatchData.lua` | `AAC354314A9E3ABF289162B588575516B1045A0F50E8A43710B5187DC008A1B3` | Add the Season 2 hotfix watch while keeping capabilities empty and doctrine fail-closed. Correct the August 25 affected list to include Warlock and review the August 26 Training Grounds lifecycle fix. |
| 3 | `Data/SourceRegistry.lua` | `75C1ADA1731C8E3AA5E800565AEAAF85BFD6449E9EC8B5F5BF696D8B3B2D0FD0` | Point provenance at the canonical Blizzard hotfix ledger without weakening source-authority checks. |
| 4 | `META_SOURCES.md` | `0194A57059534B6B5CAE36DAFA8659133FBD09CB79B390004A836ED3A0AF844C` | Document the exact official review window and advisory-only policy. |
| 5 | `Runtime/AAR.lua` | `85ABF106E48F41BF413D61787B667A3B841283B92C39EED5DA68B2F92FB91C11` | Canonicalize and refresh map identity so AAR records do not retain stale or `UNKNOWN` map labels. |
| 6 | `Runtime/Assignments.lua` | `DCA493E17B1C8DE708A4790B419E4690301335EB9769E68EF2465F08541672D7` | Filter assignments against the current roster and present grouped assignment output without losing provenance. |
| 7 | `Runtime/Commander.lua` | `87A5DBBC1D565303EDA211940E189D702DDFE5BF0EC592262A4727268561F91C` | Add truthful formation/pre-queue state, friendly-node verification, bounded invalidation evidence, and explicit active-play clearing. |
| 8 | `Runtime/FormationAdvisor.lua` | `9182E51E908D12557E82C746FEC018AC63C3F34A0375B10408C93135C543AD60` | Add a bounded formation-signature cache with observable hit/miss behavior and safe invalidation. |
| 9 | `Runtime/MatchRuntime.lua` | `034C93BD0B3517C893FA56050F421E320E43F8F1EAA235A2D67F393BFEFBE744` | Refresh on authoritative PvP widget/score/match events, control scoreboard reuse, clear stale commands at match completion, and provide truthful world standby state. |
| 10 | `Runtime/MemoryBudget.lua` | `26CEB921C5F70662093D5A05B498E800E85ADC90158BC2464453D01EC6655516` | Preserve the bounded strategist cache during active PvP to avoid avoidable p95 recomputation spikes, while clearing it between matches. |
| 11 | `Runtime/ObjectiveIntel.lua` | `A6A15B015F0BE7D7092B097908F4E36F00E82E6007BDBCCE3200DDFBE00C3700` | Normalize strategy targets and hold unverified targets behind an explicit `VERIFY` state. |
| 12 | `Runtime/Sensors.lua` | `C2EC7E1F4FA387B8EC8CEF5D7BDF730CBF7D9473B3DC18FFED33C102936D095C` | Cache bounded widget/position fingerprints, explicitly invalidate scoreboard data, preserve specialization provenance, and identify brawls without inference. |
| 13 | `Runtime/Strategist.lua` | `823571CFD7BBBCFF981C2B15AE126EC84902A27EC10F1F070EB9A3FE5F495E40` | Include connection/carrier truth in strategy signatures and lengthen only the safe bounded cache window. |
| 14 | `Runtime/TeamResolver.lua` | `CE9445ECEF8B8BB676223F039D5B876730A834FB704376D3579A901AA5924425` | Make scoreboard reuse an explicit caller decision during team resolution and capture. |
| 15 | `Runtime/Verification.lua` | `5A73EE4E6FB5DFABE11ED33F7C2DE9184371B6EF7082CBC0B692839CC05C59E2` | Report brawl bracket truth, carrier-target evidence, historical specialization provenance, and health eligibility. |
| 16 | `UI/CombatRosterVisuals.lua` | `7BD25723D9B9CEDBDB1CC2EC4CC60F2E9E3BF4723A16D1452B133A4691034356` | Normalize and abbreviate enemy location display with explicit unknown state and confidence coloring. |
| 17 | `UI/HUD.lua` | `9C15EE378610661E0C0D685D992AF3A4B7AB043A8AA02C09523453BAA4D34AC4` | Simplify revision tracking without suppressing a required render or causing redundant frame mutation. |
| 18 | `UI/MainWindow.lua` | `1162158113676DDF33181C96AEB7F2BA49E764175FA83377A10E6D81EC27D329` | Route specialization labels through the shared bounded formatter with caller-selected width. |
| 19 | `UI/MainWindowPages.lua` | `01C74C2116B8FBEF8339D5FB8EDA81035C6CDBA4215C0B7BD46BCCC16B2AEC9D` | Use shared specialization formatting consistently in assignment and roster rows. |
| 20 | `UI/RosterPresentation.lua` | `CB378FE50881B0A516A33570C3FD5EE59A639C18D096AEE99283CB7799EBD251` | Add width-aware specialization labels that preserve the `(HIST)` provenance suffix under truncation. |

# Review disposition

All 20 useful behaviors are adopted. `REWORK` means the behavior was retained
but reconciled with newer canonical fixes or stricter truth/provenance rules;
no live file was copied wholesale.

| # | Decision | Rationale and deterministic evidence |
| --- | --- | --- |
| 1 | REWORK | Advanced review freshness through 2026-08-26 only; knowledge audit and manifest validation bind the date. |
| 2 | REWORK | Added Warlock and the August 26 lifecycle item while leaving the 12.1 capability overlay empty; smoke hotfix-provenance checks and knowledge audit cover the boundary. |
| 3 | REWORK | Uses the canonical dated Blizzard ledger URL and retains authority-tier validation. |
| 4 | REWORK | Documents the complete review window and advisory-only doctrine policy; document-authority validation covers it. |
| 5 | ADOPT | Canonical map identity promotion is covered by the stale-world-label AAR regression. |
| 6 | REWORK | Current-roster filtering plus response mover/stayer deduplication are covered by direct filter and response-package regressions. |
| 7 | REWORK | Preserves stronger active-play stability while adding world standby and complete active-play clearing; direct clear, world-transition, and invalidation regressions cover it. |
| 8 | ADOPT | One-result, signature-keyed formation caching is covered by hit/miss and connection-change invalidation checks. |
| 9 | REWORK | Keeps the current transition-sweep model while adding reason-aware critical refreshes, explicit reuse, world standby, and corrected post-refresh roster rescans; smoke, soak, and event-subscription checks cover it. |
| 10 | ADOPT | Active-PvP cache retention and between-match clearing have direct deterministic checks; the 500-refresh soak covers runtime cost. |
| 11 | ADOPT | Unknown flag targets are held at `VERIFY` with raw/canonical provenance; direct normalization and reviewed localized-target checks cover it. |
| 12 | REWORK | Adds bounded scoreboard reuse/invalidation and brawl truth without weakening specialization provenance; direct invalidation, brawl, roster hydration, and score-authority checks cover it. |
| 13 | ADOPT | Strategy signatures include connection/carrier truth and retain a three-second one-result bound; cache reuse and live carrier regressions cover it. |
| 14 | ADOPT | Scoreboard reuse is explicit at the resolver boundary; capture and team-side regressions cover fresh versus reused resolution. |
| 15 | REWORK | Adds bracket, carrier target, historical-spec, and health-eligibility evidence to the stronger current verification report; verification and field-bundle checks cover it. |
| 16 | ADOPT | Location-first enemy presentation with unknown/confidence handling is covered by compact tracker visual checks. |
| 17 | ADOPT | Revision-independent HUD signatures retain required renders and suppress unchanged row repaint; UI render/skip checks cover it. |
| 18 | ADOPT | Main-window specialization labels accept explicit widths through the shared formatter; UI construction checks cover it. |
| 19 | ADOPT | Assignment and team rows consistently use the shared formatter; roster-page checks cover it. |
| 20 | ADOPT | Width-aware labels preserve `(HIST)` within the requested bound; a direct compact-width regression covers it. |

# Required behavior

1. Preserve an immutable copy or manifest of the 20 audited live files before
   changing the installed AddOns folder.
2. Start from the exact current public `main` commit, not from the installed
   folder or a stale Alpha 4 worktree.
3. Review each inventory row independently against `v6.1.1-alpha.5`; record
   `ADOPT`, `REWORK`, or `REJECT`, the reason, and the evidence.
4. Reimplement approved behavior in canonical modules. Do not bulk-copy the
   live tree or overwrite newer reviewed source.
5. Keep combat-lockdown, protected-action, taint, nil-result, message-limit,
   history-bound, and refresh-budget constraints explicit.
6. Correct official provenance through the latest reviewed Blizzard ledger.
   Official notes remain advisory; do not alter capability ratings, target
   priority, predictions, or doctrine without separately reviewed Retail proof.
7. Add deterministic tests for every adopted behavior and regression tests for
   stale map identity, scoreboard reuse, match completion, command clearing,
   cache invalidation, historical spec labels, and unknown/verification states.
8. Publish approved changes only as a new version. Never retag or replace
   `v6.1.1-alpha.5` or its public assets.
9. Bind the new tag, commit, Commander/Sentinel ZIP hashes, package manifests,
   installed-folder receipts, and Retail field evidence to one identity.

# Non-goals

- Treating all 20 files as automatically correct because they exist live.
- Editing the published Alpha 5 release, tag, checksums, or assets.
- Changing doctrine or numerical capability weights from tuning notes alone.
- Publishing, deploying, announcing, or enabling GitHub/AI integrations as part
  of source review.
- Reviving the standalone Sentinel release lane.

# Technical constraints

- GitHub committed content is authoritative; the installed AddOns folder is an
  untrusted deployment/evidence source.
- Keep the embedded `KWRSentinel` package byte-identical to the reviewed package
  source and build Commander and Sentinel from the same tag.
- Do not combine unrelated bot intake work with this addon change.
- Preserve branch ancestry before removing any branch or worktree that tracks a
  deleted remote.
- Do not claim stable readiness until KWR-270 and this task both have
  candidate-bound field evidence.

# Acceptance criteria

- [x] All 20 rows have an `ADOPT`, `REWORK`, or `REJECT` disposition with rationale.
- [x] Every adopted enhancement has deterministic regression coverage.
- [x] Official hotfix provenance includes Warlock in the August 25 PvP list and records the August 26 Training Grounds fix without doctrine changes.
- [x] Map identity remains canonical across entry, active play, completion, and AAR export.
- [x] Scoreboard reuse and invalidation cannot leak stale team, specialization, health, or objective data across matches.
- [x] Commander produces no stale active play after match completion or world transition.
- [x] Formation and strategy caches are bounded, signature-keyed, observable, and safely invalidated.
- [x] Historical specialization labels retain `(HIST)` at every supported width.
- [x] Validation, knowledge audit, Lua tests, soak, replay, transport, package audit, and reproducibility checks pass for the Alpha 9 candidate payload.
- [x] A reviewed PR merges before any tag or publication action (PR #53; merge commit `dedf22316badc6657cd5ffcdaa11e34e8d415bb3`).
- [ ] A new versioned Commander/Sentinel package has exact public-manifest, installed-tree, and deployment-receipt parity.
- [ ] Candidate-bound Retail evidence clears stability, safety, performance, readability, and supported map-family gates.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `./tools/knowledge-audit.ps1`.
3. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-lua.ps1`.
4. Run the replay, soak, transport, source-drift, security, and release-contract suites affected by the adopted rows.
5. Build twice from a clean exact commit and require matching package manifests and reproducibility evidence.
6. Audit extracted Commander and Sentinel packages before installation.
7. Capture `/kwr verify`, `/kwr perf`, AAR, Lua error/taint results, supported-resolution screenshots, and representative map-family evidence from the exact installed hashes.

# Rollback

Keep `v6.1.1-alpha.5` immutable and retain its public hashes as the rollback
baseline. Before installing a successor, retain a rollback snapshot of the
current AddOns and SavedVariables. If any adopted enhancement fails review,
combat safety, performance, package parity, or Retail evidence, remove that
enhancement from the new candidate or revert the reviewed commit; never mutate
the historical Alpha 5 release.
