# Release Readiness - 6.1.1-alpha.27

## Alpha27 engineering repair — 2026-09-20

Candidate `alpha27-bounded-runtime-projections-20260920-1` removes redundant
publication copies and repeated derived work. Instrumented host NODE/CART traces
show 43.5%/42.2% less elapsed CPU and 58.3%/58.0% fewer copied tables than alpha26;
all 20 decision records per workload match. This is not Retail timing or measured
memory certification. Publication projection is now included in runtime duration;
notification/UI, communications and audio remain outside that measurement.
See `docs/adr/ADR-035-bounded-runtime-projections.md`. Existing random-map,
two-game collection policy is unchanged. No stable release approval is implied.

## Previous candidate evidence

## Current operational truth — 2026-09-19

**ALPHA26 OFFLINE REPAIR; LIVE PERFORMANCE CERTIFICATION STILL REQUIRED.**
Alpha25 was built, audited, installed with matching Sentinel and separate
Developer Tools on September 18, and field-tested. Its completed Arathi Basin
capture reported zero runtime errors but strategic P95 34.561 ms, tactical P95
8.222 ms, and sampled memory as high as 44.26 MB before falling to 13.64 MB after
the match. These are failures, not release approval or proof of a retained leak.

`alpha26-runtime-clock-ownership-20260919-1` (`6.1.1-alpha.26`) repairs clock
units, retained plan consistency, inspection invalidation, redundant captures,
bounded capability lookup and stale-memory recovery thrashing. Current combat
evidence and bounded caches survive pressure pruning. The source runtime suite
passes including deterministic long-uptime and 1,001-event burst regressions.
Packaging and deployment receipts, not this prose, establish the installed bytes.
The final clean build at `2a8c260` passed source validation, full Lua tests,
knowledge audit and extracted-package/reproducibility checks. It is installed
with matching Sentinel and separate LoadOnDemand Developer Tools; all three
installed trees match their archives with zero differences. Receipt:
`artifacts/alpha26-install-20260919/DEPLOYMENT.json`. Previous files and KWR
SavedVariables are recoverable from `artifacts/alpha26-backup-20260919`.
The 2 ms P95, 4 ms routine maximum and 32 MB hard memory goals are unchanged;
alpha26 now has live performance failures: strategic P95 22.415/33.962 ms,
tactical P95 6.087/7.095 ms and sampled memory peaks 35.83/38.12 MB. The supplied
Silvershard verification binds to the installed alpha26 candidate; the standalone
NODE telemetry has no embedded build ID. Both reports record zero runtime errors.
See `docs/evidence/ALPHA26_RANDOM_RATED_2026-09-19.md` and
[the bounded field checklist](docs/ALPHA26_FIELD_CHECKLIST.md).

The owner's alpha26 collection uses at most two randomly offered rated
battlegrounds; any map or repeated map counts. No flag/base-defense map or specific
mechanic is a prerequisite. Missing mechanics are NOT_OBSERVED/NOT_APPLICABLE,
not a failed session and not a fabricated pass. After two games, engineering owns
remaining replay/targeted reproduction or scope decisions. This completes the
bounded field collection without claiming every map family has live certification.
The supplied NODE/CART captures already establish repeat CPU/memory failures;
do not request further random games to establish them or to obtain a flag map.
The next step is engineering profiling/reproduction, not release promotion.

Existing compact lower-right field safeguards, contained setup/options layouts,
complete manual copying and plain-language roles remain. Retired cursor/player
markers and persistent opponent/doctrine histories remain retired. Roster/AAR
auto-opening defaults are off; existing explicit saved preferences are preserved.
Developer Tools remains a separate optional addon, installed here for diagnostics.

Alpha.15 was packaged, installed, and field-tested. It captured a complete WSG
match without runtime errors, but failed release acceptance: the complete Commander
card obstructed combat, strategic refresh P95 reached 35.02 ms (target <2 ms),
and addon memory peaked at 38.22 MB (32 MB hard limit). Assignment integrity was
WARN because every live assignment location was unknown; command delivery remained
unverified. This is defect evidence, not release approval. P00's 62 recovery rows
and alpha.13's 2,003 paired replay-parity records remain valid offline evidence,
but do not certify alpha.17.

Current diagnostic blockers are `LIVE-TEAM-TRUTH`, `LIVE-STABILITY`,
`LIVE-CARRIER-TARGET`, `LIVE-READABILITY`, memory/refresh budgets, command-delivery
evidence, AAR-anchor stability, and native-map/combat-safety proof. Field evidence must include
`/kwr field`, `/kwr verify`, `/kwr perf`, `/kwr aar copy`, and a `/kwr bug` export
for every failure.

Stable release remains blocked by a clean source-bound/tagged package, remaining
offline completion, the 2,003-item replay adjudication/independent tactical
review gate, all required field evidence, and publication approval. Earlier candidate sections below are
historical records and cannot override this status.

This is the sole authority for current blockers and promotion status.
[PRODUCT_ROADMAP.md](PRODUCT_ROADMAP.md) retains the OVR-01 through OVR-22
requirements and tactical vision. This file explains how to execute and close
them. [AGENTS.md](AGENTS.md) owns engineering rules;
[RELEASE_POLICY.md](RELEASE_POLICY.md) owns release authorization.

## September 9 local field-repair authorization

The owner now requests the independent-review defects be fixed and a local
candidate installed so field testing can begin. KWR-296 prepares diagnostic
candidate `alpha12-fieldfix-20260909-1` from the preserved dirty tree. Its external
deployment receipt records exact archives, installed parity, backup and isolated
restoration. This supersedes the earlier requirement to wait for every overhaul
item before this local test session. Unfinished REC/OVR work and clean/public
release gates remain open.

### September 10 detailed completion packages and card feedback scope

The owner requested additional implementation packages for Terra Medium/High,
with Astra-level evidence review. [KWR-297](docs/tasks/KWR-297-s-tier-completion-packages.md)
now decomposes the existing OVR-01..22 and REC work into P00-P14, including code
ownership, algorithms/contracts, failure cases, verification, rollback and
copyable execution/review prompts. It supplements this authority; it does not
replace requirements or award completion for writing specifications.

The owner's field feedback adds [KWR-298 / P13](docs/tasks/KWR-298-commander-callout-card-rebuild.md):
an **Astra-led full visual/information rebuild** of the fight/mini-command card.
It must clearly distinguish NOW and observed/ordered position, NEXT movement,
all movers/stayers, local target and CC jobs, with complete unclipped verbal calls.
This is not merely a cosmetic Terra restyle. Existing installed bytes remain
unchanged while these source work packages are prepared.

[KWR-299 / P14](docs/tasks/KWR-299-command-followthrough-feedback.md) specifies
left-click NOT_FOLLOWED and right-click FOLLOWED on the card, bound to the exact
issued call/revision with drag/race protection, visible status and Undo. These
are manual adherence attestations, not automatic proof of verbal delivery,
objective success or causal improvement. AAR/learning must retain separate
delivery, adherence, observed-outcome and manual-review fields.

P13/P14 source implementation is IN_PROGRESS; P01-P12 remain IN_PROGRESS and
P00 is offline-complete. The first
slice now includes the actual measured HUD, complete verbal projection,
reversible AAR-owned feedback, and a Tactical-page summary derived from the same
structured card rather than a competing local-teamfight call. See
[ADR-011](docs/architecture/ADR-011-complete-callout-and-followthrough.md) for
implemented behavior, test scope and remaining CODE obligations. Source candidate
`alpha12-kwr297-source-20260910-1` is distinct from the unchanged installed field
candidate. The full Lua suite passed after the latest secondary-surface semantic
and queued-audio lifecycle changes, plus current P01/P03/P08 source hardening,
in `artifacts/kwr297-all-20260911-b.json`; the focused Card suite and development
validation also pass. The current full receipt is
`artifacts/kwr297-all-20260911-f.json`: Developer Tools, smoke, Sentinel,
soak, and replay passed after the full release-tooling SHA-256 portability
change. The matching automation receipt is
`artifacts/kwr297-automation-after-portability-20260911d.log` (238 checks).
This is not a final program receipt.

On September 11, the subsequent source-only package at
`artifacts/kwr297-build-20260911-local-fixed` passed binary reproducibility and
extracted-package audit after correcting a minimal-host SHA-256 portability
defect. Its package audit includes extracted validation, documentation/control
checks, knowledge generation/audit, the 100,000-case simulation, 276-check
developer smoke, soak and DevTools lifecycle. The exact receipts are
`KWR_6_1_1_ALPHA_12_REPRODUCIBILITY.json` and
`KWR_6_1_1_ALPHA_12_PACKAGE_AUDIT.json` in that artifact directory. This is a
dirty, local source build and has no clean commit/tag, installed-folder parity,
full replay-adjudication closure, field proof or public publication claim.

P05 has a separate source-only lifecycle hardening slice: execution packets carry
the command ID/revision, and queued audio rejects a superseded command or packet
before speaking. Its fake-clock regression is in the smoke suite. The broader
P05 transition, secure-binding and client-taint requirements remain open.

Card layout fixtures and feedback contracts start before the entire tactical overhaul is complete;
final integration must use the shared truth/lifecycle contracts. Current local
diagnostic field authorization remains separate from full completion/promotion.

Sentinel uses the production score source/freshness gate. New verification/AAR
exports include the candidate ID; older AARs stay UNBOUND. `/kwr field` starts
Diagnostic context; leadership tests use `/kwr commander` and confirm only
actually communicated calls via `/kwr delivered <token>`. Real host timings are
measurements of a mocked preview workload, not Retail CPU/FPS certification.
Consult the final deployment receipt for actual test and installation results.

### September 11 Fight Now stability hotfix — installed diagnostic candidate

The current Retail diagnostic install is the `6.1.1-alpha.12` stability hotfix
from `artifacts/fight-card-stability-build-20260911`. It fixes two observed
presentation defects: the legacy Fight Now card no longer changes height when
local-focus or CC state changes, and the complete Commander card retains its
largest live geometry so shorter follow-up calls do not shrink, jump, or distort
the card. This is a bounded P13/P09 presentation repair, not closure of either
package.

- Commander archive SHA-256:
  `09DD52E8D9C94109CA04F673DC6D74D481BBA420EE0E288897DBEE801F3F62E3`.
- Focused Commander-card suite, full 276-check smoke, binary reproducibility,
  and extracted distribution/developer smoke and soak passed. The package audit
  and reproducibility receipts are in `artifacts/fight-card-stability-build-20260911`.
- Deployment receipt:
  `artifacts/fight-card-stability-install2-20260911/DEPLOYMENT.json` reports
  `INSTALLED_VERIFIED`; Commander (399 files), Sentinel (12), and DevTools (7)
  compare exactly to their staged archives.
- The installer additionally passed an isolated first-install/restore rehearsal
  where optional Sentinel and DevTools were absent initially; rollback preserves
  that absence. Retail rollback snapshot:
  `D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KWR-Rollbacks\fight-card-stability-alpha12-install2-20260911`.
- Source/install TOC reconciliation has 142 matches and zero changed or
  installed-only entries. Four source-only files are intentional development
  modules excluded from the player package: `Core/Diagnostics.lua`,
  `Runtime/Preview.lua`, `Runtime/Season2Readiness.lua`, and
  `Runtime/Verification.lua`.

This proves local diagnostic deployment and the layout repair only. P00-P12
remain planned/in progress as stated above; client field evidence, independent
review, clean release provenance, and publication approval remain open.

### Installed diagnostic candidate — September 9, 2026, 22:00 CDT

**READY FOR OWNER DIAGNOSTIC FIELD TESTING.** The repaired candidate is installed
in Retail AddOns. This is not full-overhaul completion or stable promotion.

- Candidate: `alpha12-fieldfix-20260909-1` (`6.1.1-alpha.12`).
- Build: `C:\Users\josev\Desktop\KWR\Builds\6.1.1-alpha.12-fieldfix-20260909-1`.
- Deployment receipt: `C:\Users\josev\Desktop\KWR\Builds\fieldfix-deployment-20260909-1\DEPLOYMENT.json`.
- Commander 396, Sentinel 12 and DevTools 7 files: zero missing, changed or extra
  relative to the exact extracted archives. Source TOC reconciliation has 139
  matches, zero changed and four intentional source-only development modules;
  those four ship in optional DevTools, not the Commander production TOC.
- Complete verified prior-trio backup and four KWR SavedVariables files:
  `D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KWR-Rollbacks\fieldfix-baseline-20260909-1`.
  Both the staged restoration rehearsal and the standalone restore script
  passed against isolated test folders. Live SavedVariables were not modified.
- Final Lua suite passed all five stages (`artifacts/fieldfix-final-all-20260909.json`).
  Validation, knowledge/scenario audit, security, automation, host measurement,
  four-archive binary reproducibility and extracted-package audit passed.
- R04 follow-up covers real numeric no-widget defaults, unresolved team,
  missing/expired/future timestamps, observed 0-0 and Sentinel HUD unknown state.
  R09/R10 local backup, isolated restore and exact installation work is complete.
  R11 capture identity is implemented and regression-tested; actual client
  captures tied to this candidate are still required.
- External report paths now resolve and the candidate archive hash verifies.
  Full-clean eligibility remains false because the source is dirty. These
  booleans no longer claim to be individual test execution results. Broader
  REC/OVR work, full replay/tactical review and live/public gates remain open.

Use [the field guide](docs/FIELD_TEST_20260909.md): restart WoW, run `/kwr field`
and `/kwr verify` outside combat, confirm the candidate ID, then use
`/kwr commander` only when leading. Capture `/kwr perf`, `/kwr bug` on failure,
and `/kwr aar copy` after the match; retain the deployment receipt with exports.

This completion record and task-status update were written after artifact
freeze; they do not change the installed archive bytes or claim that the
subsequently edited documentation is identical to the frozen developer ZIP.

## Earlier full-overhaul execution order — 2026-09-08

**Full overhaul and stable distribution remain NOT READY.** The local diagnostic
field session is separately authorized above.

**Finish all offline work before requesting field testing.** The next milestone
is **OFFLINE COMPLETE — READY FOR FIELD TESTING**, not another interim alpha.
Complete source recovery, shipped-behavior fixes, persistence migrations,
and every audited offline enhancement in OVR-01 through OVR-22, including
tactical depth, before the field-test handoff. The owner's latest full-overhaul
instruction supersedes earlier minimum-stable-first sequencing. Complete
deterministic correctness tests, real host benchmarks, client instrumentation,
fresh replay contracts and exact package verification first. Implementation is
now authorized and in progress. Installation and field sessions follow the
offline gate; the current installation remains diagnostic evidence.

An actual WoW session is still needed afterward to prove current-client API
permissions, combat/taint safety, real FPS/CPU/memory, and tactical usability.
Missing field evidence blocks stable promotion; it must not stop independently
executable code, test, migration, packaging or technical review work.

The source repository is `C:\Users\josev\source\repos\KnomercyWarRoom`.
The inspected branch is `codex/kwr-278-alpha11-field-blockers`, base `bcce7f5`,
with existing uncommitted work. AddOns folders are deployment targets. Preserve
existing changes; a dirty checkout is normal during implementation and does not
justify stopping. Prepare reviewed changes for the repository's normal commit/CI
process before the final clean-candidate gate; never reset unrelated work merely
to obtain a clean result.

## Evidence correction and current baseline

The preceding handoff incorrectly read three source-to-installed diffs in the
opposite direction. These are missing recovery work, not completed protections:

| Module | What current source actually has | What still needs implementation |
| --- | --- | --- |
| `Runtime/Commander.lua` | Terminal suppression, generator/delivery boundary, per-call identity/revision, explicit local attestation, and a narrow local BG-system assault observation producer. | Complete reviewed outcome contracts, qualified aggregation and usability verification, REC-07. |
| `Runtime/AAR.lua` | Source map/evidence fixes, delivery capture, checkpoint/migration, compact TEAM versus opt-in DEVELOPMENT capture, corrected active timeline bounds and non-causal public execution display pass smoke. | Complete broader malformed-data/size verification and reviewed outcome-contract integration, REC-08. |
| `Runtime/Learning.lua` | Schema-2 legacy preservation, context-partitioned decision episodes, bounded durable deduplication and malformed/future-data guards pass the full Lua suite. | Complete public execution producers and final source/package end-state verification, REC-09. |

Installed Commander mode labels also are **not proof that a particular call was
delivered**. Recover useful code selectively and finish that evidence boundary.
The earlier passing suite did not test these missing requirements. Corrected
JSON reviews retain their superseded explanations for traceability.

| Current evidence | Meaning and limitation |
| --- | --- |
| [Source/install ledger](artifacts/source-install-review-ledger-20260908-live-session.json): 62 entries, **38 closing decisions, 9 pending implementation records (`DEFER`), 15 missing reviews, 0 invalid records** | Review accounting only. A valid record is not proof of implementation or release readiness. The nine items below are active offline work. |
| [Full Lua receipt](artifacts/lua-all-current-20260908-run2.json), September 8 | Existing dirty-source suite passed. Its test-tool hash does not establish final candidate source identity or full-corpus tactical correctness. |
| September 8 automation run: 230 checks; document-authority audit and diff check passed | Historical checks for the prior tree; rerun relevant checks after implementation. |
| [Full replay baseline](artifacts/fresh-replay-full-current-20260907-plan-tags-merged/) | 2,003 results: 0 primary, 578 fallback-only, 1,425 unmatched, 0 forbidden. Technical diagnosis and independent tactical validation remain open. |
| [Interim package](artifacts/replay-adjudication-20260908-package/) | Four reproducible archives with extracted tests; provenance is dirty `bcce7f5`. It predates this clarification and is not the final candidate. |
| [SavedVariables diagnostic receipt](artifacts/retail-savedvariables-current-session-20260908.json) | Unbound observer/diagnostic history, no qualifying real performance or scored command-stability proof. |

The eight initial reproduced defects have bounded fixes under KWR-282/283/284;
KWR-285 through KWR-291 address additional sampling, generator, availability,
countdown and evidence defects. Preserve their tests. Their completion does not
close an entire OVR row or make the latest source field-certified.
Historical progress paragraphs and earlier claims are preserved in
[the prior handoff snapshot](docs/evidence/readiness-handoff-before-clarification-20260908.md);
they cannot override this gate board.

## Execute without repeated deferrals

Implementation checkpoint: the first REC-07/08/09 change adds the shared
CommandReview delivery/execution qualification boundary. Mode selection and
clipboard activity do not qualify; records require matching command identity/
revision and finite wall-clock timestamps. Generator churn remains available in
separate fields. New AAR reviews and learning intake cannot use generated-only
match outcomes. [ADR-008](docs/architecture/ADR-008-delivery-and-execution-provenance.md)
defines the boundary and remaining producer/migration work. This is an active
partial implementation, not closure of the three REC packages.
The [checkpoint receipt](artifacts/delivery-boundary-checkpoint.json) binds its
changed source/test hashes and passing All-suite receipt. Development validation,
document-authority and diff checks pass. The suite's default replay is still
fallback-only and its soak clock simulated; neither clears the final benchmark.

1. Start with REC-07/08/09 as one coherent delivery/retention/learning contract,
   implemented in bounded changes. Add the missing regression before the fix.
   In the same offline phase, finish the 15 straightforward source/UI reviews.
2. Add real host-time profiling and truthful measurement provenance (OVR-09).
   Resolve REC-01 through REC-06 with measured, tested decisions. Reject a
   demonstrated unsafe installed optimization and retain safe source when
   appropriate; importing every installed change is not a requirement.
3. Finish remaining shipped-behavior gaps in OVR-02 through OVR-19 using the
   per-item recipes below. Dependencies mean a required interface or invariant,
   not that every upstream field certificate must already exist.
4. Repair replay evaluator/planner/label defects under KWR-295. Work on bounded
   representative cases and all members of an affected pattern before a full run.
   Technical investigation proceeds now; do not wait for 2,003 user reviews.
5. Freeze the reviewed source, run final offline certification once per candidate,
   and verify the extracted player package. Deliver one exact field-test package
   and its residual client-only checklist only after the offline gate passes.

`DEFER` is a legacy review-ledger disposition, **not a scheduling instruction**.
For every pending item, record the failing behavior, next edit, focused test,
result and final decision. Missing tests mean write the tests. Missing host
measurements mean build/run the measurement harness. An unsafe optimization
means repair or reject that optimization, not suspend the entire addon.

Use the existing task contracts. KWR-281 owns source recovery; KWR-295 owns
replay remediation. KWR-280's final WSG check is a downstream field requirement,
not a prerequisite for KWR-281 coding or packaging. Do not create another audit,
parallel roadmap, or repeated interim package for documentation-only updates.

The executing engineer owns all CODE items below. Independent tactical reviewers
own REVIEW evidence; the owner operates the WoW client only in the final FIELD
stage. Keep task frontmatter statuses within the existing schema and record
`offlineStatus`, `fieldStatus` and `releaseStatus` separately in task prose.
A field-only blocker does not turn an unfinished code task into a blocked task.

## Close the nine pending source recovery items

September 9 latest source-bound evidence:
`artifacts/aar-learning-checkpoint-20260909.json` binds scoped learning persistence,
compact AAR capture and the integrated All suite. Validation has zero errors and
one expected channel/version warning. Public execution producers, broader malformed
AAR/serialized-size verification and final source/package gates remain open.

`artifacts/recovery-checkpoint-20260909-store-encounter-observation.json` binds
the later Store, encounter, formation and narrow public-observation changes to a
passing All-suite receipt. It records the limits of that evidence: injected-clock
soak, fallback replay and no client/package certification. Do not interpret it as
an outcome contract, field certification, or closure of the remaining REC rows.

September 9 OVR-17 checkpoint: FormationAdvisor now selects an explicit
`RBG_10` (1 tank / 3 healer / 6 damage) or `BLITZ_8` (1 / 2 / 5) ruleset from
the rated-Blitz context. The chosen ruleset controls open slots, shortages,
overages, completion, target build requirements and cache identity, so a
ten-player composition cannot be presented as an eight-player Blitz target.
Smoke covers a complete eight-player roster and requirement cap. The remaining
OVR-17 work is the separate assignment/override proof: leaver, spec-change,
cross-realm duplicate, mandatory-defense and unavailable-player cases must be
run against both rulesets before the row can close. The current-source full
suite receipt is `artifacts/formation-ruleset-all-20260909.json`; it includes
Developer Tools, smoke, Sentinel transport, soak and replay stages. It remains
development evidence only and does not substitute for the final replay or
package gates.

September 9 OVR-17 override checkpoint: role and location overrides now reject
dead or disconnected players using current roster identity, rather than saving
an impossible command. Smoke covers the rejection. Mandatory-defense movement,
leaver replacement selection, spec changes and cross-realm duplicate cases are
still separate required regressions. The integrated source receipt
`artifacts/override-safety-all-20260909.json` passes Developer Tools, smoke,
Sentinel transport, soak and replay; it remains dirty development evidence, not
final package or client certification.

Latest implementation evidence: `artifacts/delivery-capture-checkpoint.json`
binds the per-call confirmation, AAR capture/checkpoint/migration source and test
receipts. The All suite passed; final export/help changes passed smoke (276
checks plus the delivery fixture) and development validation (zero errors, one
expected channel/version warning). Soak timing is injected and the default replay
matched its fallback; neither proves real performance or full tactical coverage.
All REC closures and final source/package certification remain separate gates.

REC numbers below are work packages inside KWR-281, not new backlog IDs.
All are executable offline. Proposed tests should extend the existing fixtures
or smoke harness; create a focused fixture only where it makes isolation clearer.

| Work package / files | Exact implementation decision | Required regression and closing end state |
| --- | --- | --- |
| **REC-01 — Core/Util.lua** | Preserve `OptionalBoolean`, sparse `Call` returns, and finite/secret/future-time evidence guards. Add a shallow-copy helper only with an actual measured consumer from REC-02/03; copy each branch that consumer mutates. | Nil holes, false, zero returns, throwing APIs and bad evidence remain safe. Mutating the new top-level table cannot alter its input; explicitly test ownership of nested branches. Close as selective merge, or preserve source with evidence that the helper has no necessary safe consumer. |
| **REC-02 — Core/Store.lua** | Implemented owned copies for every published branch before reconciliation and deterministic listener registration order. Existing deep-equal reconciliation reuses only Store-owned prior branches. | Focused fixture passes producer-mutation, previous-state, removed-field, order and filtered latest-generation paths. Real host Store/subscriber timing and final candidate verification remain required. |
| **REC-03 — Runtime/MatchRuntime.lua** | Recover event coalescing/filtered work selectively. Define which objective, score, roster, spec, target, match-end and countdown events dirty each domain. Bypass cached work on relevant critical evidence; cancel obsolete scheduled generations. Keep source stage timers and CountdownState reset/cancel integration. | Burst mixed events ending in a capture, disconnect or match end; final truth must reach the next eligible refresh. Test reload/rematch, target loss, spec inspection and t=100/105 countdown expiry. Compare complete semantic decisions before/after and real host stage cost; no savings obtained by leaving stale calls visible. |
| **REC-04 — Runtime/MemoryBudget.lua** | Preserve measurement age/reason and processed-match ledgers. Bound records at insertion/update and on load. Throttle expensive scans only after every producer's write bound is covered; retain active-match truth and trim derived caches first. | Insert limit+1 and burst entries through AAR, Learning, OpponentModels, EncounterHistory and live caches; verify documented limits even while in PvP. Test failed memory API samples, repeated loads and active-match retention. Mock bounds can close code; real client plateau remains a separate field metric. |
| **REC-05 — Runtime/EncounterHistory.lua** | Implemented stable GUID identity with legacy-name read/migration, one season lookup per capture, in-place last-seen updates, meaningful field replacement, load-time malformed quarantine, expiry and newest-first caps. | Focused fixture passes first/repeat/session/spec/role/legacy/expiry/cap paths. Real host allocation comparison and final source/package verification remain required. |
| **REC-06 — Runtime/FormationAdvisor.lua** | Formation signature now includes kind/rated/blitz context as well as map/profile/roster state; cached results continue to be copied for callers. | Smoke proves caller nested mutation cannot corrupt cache and connection/death/bracket transitions invalidate it. Add explicit profile-selection change and real-host reuse measurement before final closure. |
| **REC-07 — Runtime/Commander.lua** | Preserve `terminalPlays` and material-truth suppression. Add one proposed per-play delivery record: command ID/revision, generated time, context, delivery state/time/source. Generated or unknown-delivery recommendations cannot certify execution. A context setting or copy-to-clipboard alone cannot prove team receipt; explicit leader attestation must be labeled as such. Require public emergency/coverage evidence before bypassing commitment. | Generated-only, Diagnostic, Spectator, Commander-without-delivery and explicit-attested cases stay distinct. Context changes cannot relabel prior calls. Identical terminal truth does not reissue; real score/carrier/emergency changes invalidate promptly. No false delivery certification and no suppression regression. |
| **REC-08 — Runtime/AAR.lua** | Consume REC-07 records. Recover TEAM/DEVELOPMENT capture separation, bounded command/event/player timelines and checkpoint cadence; force initial/final persistence. Keep source canonical map identity and derived evidence. Normalize legacy PLAYER/missing modes without erasing history or active working indexes before finalization. | Clean DB, Alpha 10/12 fixture upgrades, malformed entries, reload interruption, repeated finalization and mode changes preserve data. Generated-only episodes have no execution/outcome credit. TEAM remains useful and compact; DevTools opt-in alone retains full diagnostics. Verify write count, default serialized size and no loss of final AAR. |
| **REC-09 — Runtime/Learning.lua** | Consume REC-07/08 eligibility. Validate bucket shape before mutation; preserve unproven aggregates in a versioned quarantine once. Partition eligible adjustments by team/bracket/patch/plan revision; use bounded stable episode-ID deduplication rather than relying on `entry.learned` on one table. Keep OpponentModels' persistent processed-match protection. | Diagnostic/observer/unknown-delivery/interrupted episodes add no training. Reconstructed copies of the same entry cannot count twice after reload. Double migration is idempotent; malformed/future schema is preserved or quarantined. Incompatible contexts do not pool; existing minimum sample/clamp safeguards hold and learning cannot override hard feasibility. |

A row closes only after its implementation/rejection decision, relevant tests and
resulting source hash are recorded. Preserve the baseline diff and superseded
review; bind resulting candidate contents to the final manifest. Do not turn a
plan to merge into an already completed `MERGE_INSTALLED` receipt.

### Finish the remaining 15 review rows

These are prescribed dispositions to validate, not already accepted records.
Check source as the first diff path and installed as the second. Preserve
source-only developer inputs without assuming they belong in the player ZIP.

| Files (15 total) | What to finish and how to verify |
| --- | --- |
| `Adapters/SafeBattlegroundAdapter.lua` | Preserve original context observation time and unknown confidence for missing/future capture. Exercise t=10 observation reprojected at t=100; never stamp it fresh. |
| `Data/PatchData.lua` | Preserve the newer recorded review window; independently perform OVR-16's pre-candidate official delta review. Metadata agreement alone is not API proof. |
| `Data/PlayerControlProfiles.lua` | Preserve removal of named-player bonuses and unknown-role damage defaults. Rename otherwise identical actors and require identical eligibility/scores. |
| `Features/CursorRing.lua` | Preserve source pressure/kill distinction, full elapsed retry accounting, remainder and plain nameplate holders. Run target/plate recycling and 30/60/144 FPS mock cases. |
| `UI/LayoutCoordinator.lua` | Shared behavior already guards combat layout; differences inspected are comments. Preserve source and cite combat setter rejection plus deferred apply regression. |
| `UI/CombatRosterVisuals.lua`, `UI/CountdownFrame.lua`, `UI/TeamfightCommandCard.lua` | Preserve shared CountdownState projection/text. Test all three against one deadline, cancellation and missing start; no generated five-second or stale GO text. |
| `UI/MainWindowCommands.lua` | Preserve countdown start/cancel commands and loader failure messages. Keep truthful DevTools-off wording: capture stops, loaded code remains until reload. Execute each help-listed command with/without the companion. |
| `UI/Options.lua` | Preserve dynamically available preview controls and the space they require. Open options before companion load, load/disable/re-enable it, and verify availability, explanation and layout. |
| `UI/MainWindow.lua` | Keep loader failure handling. Explicit field/review mode selection feeds REC-07 without upgrading prior or undelivered calls. Verify mode switching, reset, and ordinary local-only operation; do not enable transport merely to collect local evidence. |
| `UI/AARWindow.lua` | Selectively recover TEAM/DEV and generated/delivered labels from REC-07/08. UI must read the same episode eligibility as AAR export, including old and interrupted entries. |
| `UI/MainWindowReports.lua` | Add recovered delivery/quarantine and filtered-work counters only when their owners supply them. Preserve source memory sample age/status; unavailable memory cannot become zero. Test missing and populated reports. |
| `UI/DebugReasonPanel.lua`, `UI/ReporterMap.lua` | Resolve their role through `release-manifest.ps1` and actual callers. Verify source/companion/player load graphs, absent-companion fallback and display behavior; do not delete a source module merely because the installed TOC omits it. |

## Completion recipe for every overhaul item

For each OVR item, retain completed bounded fixes and implement the remaining
acceptance criteria in the roadmap. The tests below describe observable behavior;
a fixture file name alone does not prove coverage.

### OVR-01 — Reconciled source and reproducible baseline

**Edit:** KWR-281 and REC-01..09; finish all 15 reviews above. Reconcile TOC,
`tools/release-manifest.ps1` and companion loading. Reject the installed-only
hardcoded ScenarioRuntimeKnowledge/StrategistNexusRuntimeIndex projections;
preserve canonical generated inputs and implement any needed compact projection
from them in OVR-11.
**Verify/end state:** every one of 62 baseline differences has a tested final
disposition, final file hashes map to the clean candidate manifest, and extracted
Commander/Sentinel/DevTools load with their intended features. No WSG prerequisite
for this offline work. Clean source approval/CI is downstream of coding.

### OVR-02 — Facts retain identity, age and uncertainty

**Edit:** `State/FactStore.lua`, `State/BoardStateBuilder.lua`,
`Runtime/TruthContract.lua`, `Adapters/SafeBattlegroundAdapter.lua`.
Complete canonical objective IDs independent of labels, source/observation IDs,
TTL/expiry and conflict handling; retain separate projection time.
**Verify/end state:** actual Sensors-to-board-to-Predictor/UI path preserves row
IDs/counts; t=10 stays t=10 at t=100/200; input permutations are equivalent;
expiry or contradiction withdraws only dependent actions. Extend
`tests/fixtures/tactical_truth.lua` and `observation_bracket.lua`.

### OVR-03 — Target preference cannot manufacture a kill

**Edit:** `Runtime/CombatIntel.lua`, `Intelligence/EnemyProblemDetector.lua`,
`KillTargetSelector.lua`, execution projection and CursorRing. Preserve
KWR-290/291; finish defensive immunity, manual priority provenance and uniform
target-intent consumption.
**Verify/end state:** unknown-health pressure stays pressure; no legal target
gives a calm empty state; immunity/expiry removes incompatible commits from HUD,
reticle, copy, audio and optional packet. Removing evidence never raises confidence.

### OVR-04 — Feasible assignments before scoring

**Edit:** `Intelligence/AssignmentScorer.lua`, `AssignmentOptimizer.lua`,
`Runtime/Assignments.lua`, `AssignmentOverrides.lua` and control profiles.
Pass availability, observed reach/capability and mandatory defense coverage into
candidate generation before scoring; preserve a feasible deterministic incumbent
when search budget expires.
**Verify/end state:** dead/offline/unknown actor, remote rogue, carrier, last
defender, missing healer and ambiguous names never receive an impossible job.
No contradictory responsibilities; renaming characters does not change defaults.
Use public unknown state when reach cannot be established.

### OVR-05 — One command lifecycle and actual deadline

**Edit:** Commander ActivePlay, CountdownState, execution builder, audio and
all countdown consumers. Complete common command ID/revision and issue/start/
deadline/abort/terminal projections. Integrate REC-07 while retaining KWR-280.
**Verify/end state:** start t=100/deadline 105 shows 5,4,1,0 at 100,101,104,105;
repaint does not restart. Target loss/match end cancels every stale cue; invariant
truth never reissues a terminal call. Extend `explicit_countdown.lua` and smoke.
WSG proves the final client behavior only after the offline gate.

### OVR-06 — Bracket and match generations

**Edit:** Sensors, TeamResolver, MatchRuntime and RulesetLoader.
Complete explicit STANDARD_RBG/BLITZ/UNRATED/TRAINING/UNKNOWN context with
evidence and session generation. Derive roster and objective rules from it.
**Verify/end state:** partial 8+8 never latches Blitz; a verified Blitz indicator
selects eight-player rules. Late hydration, cross-faction/mercenary teams, reload,
same-map rematch and interrupted matches cannot leak prior truth. Create the
candidate's supported map/bracket/client scope in its task evidence; do not
silently remove currently advertised support.

### OVR-07 — Current-build, secret-safe adapters

**Edit:** existing Adapters, Util, RulesetLoader and Sentinel Observer.
Complete a call-site/return-field matrix for units, casts, auras, widgets,
scoreboard, positions and messages, including permitted display-only fields.
**Verify/end state:** absent/throwing APIs, sparse returns, secret proxies and
non-finite fields yield bounded unknowns without arithmetic/formatting leaks;
cast 9/channel 8 remains correct. Unknown builds degrade visibly. Compare
current official API documentation before candidate freeze. Actual Blizzard
permissions and taint remain FIELD evidence, never a reason to skip these mocks.

### OVR-08 — Optional Sentinel transport

**Edit:** `Runtime/CommanderComm.lua`, `KWRSentinel/Comm.lua` and Observer.
Retain strict decoding; complete bounded ingress, sender/leader authority,
session/sequence expiry, handoff and teardown.
**Verify/end state:** both actual codecs pass `tests/sentinel-transport.lua`
with malformed/flood/localized/reordered/expired/duplicate/reload cases.
Blocked communication stays visibly local-only; transport remains off by default.
Ten physical clients are required to promote remote capability, not to finish
local Commander code or request its eventual field test.

### OVR-09 — Honest performance measurement

**Edit:** MatchRuntime stage timers, Store publication/subscribers, relevant UI
render hooks, `tools/performance-benchmark.ps1` and the test harness.
The existing benchmark invokes an injected-clock soak; its PASS is not speed.
Add explicit REAL_HOST/REAL_CLIENT/SIMULATED_CLOCK provenance. Use a pinned
runtime and monotonic host clock for repeatable offline profiling without
replacing real elapsed time with mock durations.
**Verify/end state:** offline reports contain warm-up, workload, runtime/hardware,
source hashes, sample count, P50/P95/P99/max, allocation/retention, queue wait and
event-to-publication latency. Report render tail separately. Exercise client
instrumentation with controlled clocks, including missing sample and DevTools
on/off. Real host results establish optimization evidence; live budgets await FIELD.

### OVR-10 — Measured reductions in work

**Edit:** REC-01/02/03/05/06, Strategist caches and expensive subscribers.
Prioritize stages measured in OVR-09. Use explicit revisions and mutation
ownership, bounded coalescing and hidden-view render suppression.
**Verify/end state:** equivalent public input yields equivalent feasible decisions;
A cannot change after publishing B; final burst events are delivered; world/idle
states avoid BG strategy work. Repeat the same real host workload before/after.
Reject regressions in latency or truth, even if average CPU improves.

### OVR-11 — Player package, retained memory and schema

**Edit:** release manifest/generators, DevTools split, REC-04/08/09 and Core's
existing SavedVariables initialization boundary. Inventory runtime consumers
before generating compact data; retain all fields/lookup APIs they require.
**Verify/end state:** generated compact/full decisions agree on every accepted
input; full diagnostic corpora are excluded from the player archive. Scenario
generator parity alone does not prove this packaging result. Fresh/Alpha10/
Alpha12/malformed/future-schema loads preserve data; double migration is harmless.
Retained collections and serialized default DB meet the budgets below. Real
client loaded-memory plateau remains separately unverified.

### OVR-12 — Markers, secure identity and cleanup

**Edit:** CursorRing, CombatRoster and LayoutCoordinator. Preserve KWR-282
elapsed accounting, plain holders and combat mutation guards.
**Verify/end state:** 30/60/144 FPS mock retry count differs by at most one;
plate reuse/duplicate names/carrier changes cannot display or bind the wrong
actor. During combat, secure binding changes queue and unusable rows are clear;
post-combat changes apply once. Ten mocked lifecycle cycles leave bounded pools
and no stale KWR-owned visuals. Real secure-click/coexistence proof is FIELD.

### OVR-13 — Every advertised objective family

**Edit:** ObjectiveIntel, `Data/ObjectiveRules.lua`, Predictor and map profiles.
Implement explicit legal transitions with per-field authority, freshness,
score contribution, deadline and terminal state.
**Verify/end state:** for all advertised map/bracket pairs, opening/lead/deficit/
tie/transition/endgame/unknown/conflicting/end fixtures agree across sensors,
prediction, assignment, command, UI and AAR. Use the roadmap's ten-map matrix:
node races; flag return/cap; EotS tower/flag value; Kotmogu orb/zone value;
Silvershard/Deephaul carts; Seething spawn/channel/exhaustion. Do not replace
unimplemented mechanics with generic node prose.

### OVR-14 — Reachable rotations

**Edit:** Reporter ETA/route calculations, map profiles and assignment feasibility
consumers. Replace unsupported exact seconds with sourced route ranges,
crossing/elevation assumptions and confidence; distinguish observed from estimated
arrival and unknown resurrection phase.
**Verify/end state:** river/long-route/carrier/regroup/last-second cases reject
impossible arrival. Unknown reach cannot beat a safe hold through invented timing.
Coarse fallback is labeled and remains a fallback; the full route enhancement
stays open until the roadmap's route requirements pass.

### OVR-15 — Feasible tactical alternatives

**Edit:** Strategist, Nexus policy and assignment response packages. Enforce
OVR-04/13/14 constraints before comparing value, deadline, defense, reserve,
rotation cost and reversibility. Complete required counter/recovery branches.
**Verify/end state:** each selected play has movers/stayers, objective, success,
abort, fallback and switch condition. Publicly different held-out states produce
meaningfully different feasible calls; failed openings do not repeat unchanged.
Generated coverage supplies no empirical win bonus. Implement all audited
competitive-depth requirements before the field-test handoff; comparative field
proof remains a later evidence gate.

### OVR-16 — Reviewed patch knowledge

**Edit:** PatchData, SourceRegistry, KnowledgeManifest and affected capabilities/
doctrine inputs after reviewing official deltas since the last recorded review
(September 4 in source), through candidate freeze.
**Verify/end state:** each active change has a cited source, reviewer, affected
slice, expiry and regression; unsupported population/spec assumptions remain
advisory. Expired/unknown-build facts cannot authorize advanced commits.
Regenerate and run the knowledge audit; source date strings alone do not pass.
This review is development work and needs no WoW session.

### OVR-17 — General-purpose formation

**Edit:** FormationAdvisor, Assignments, AssignmentOverrides and existing setup UI.
Complete bracket-sized slots, capability shortages and scoped leader choices for
caller/carrier/backup/healer anchors/defense/reserve.
**Verify/end state:** ten/eight-player, missing role, leaver, spec change and
cross-realm duplicates yield valid slots and explicit shortages. Manual overrides
cannot bypass physical availability or mandatory defense; no character-name
bonus. Partial enemy information still permits a safe pregame opening.

### OVR-18 — Truthful AAR and conservative learning

**Edit:** REC-07/08/09, AARWindow and MainWindowReports.
Complete bounded decision episodes tied to command/version, bracket, doctrine,
public facts, actual/attested/unknown delivery and observed outcome.
**Verify/end state:** undelivered/interrupted episodes do not train execution;
incompatible team/patch/plan contexts do not pool; reload cannot count twice.
Match victory alone gives no causal credit. Export preview offers stable
anonymized aliases with relationships preserved and sends nothing automatically.
Keep useful local history and opt-in full diagnostics.

### OVR-19 — Usable, accessible commander surfaces

**Edit:** existing MainWindow/HUD/roster/cards/Options, command help and audio.
Finish UI recovery rows; show next call, personal job, place and trust state.
Use stable protocol IDs, localizable text and UTF-8-safe truncation.
**Verify/end state:** automated layout/command/Unicode/audio-cancellation cases
pass at supported scales; no essential element clips in reviewable offline
layouts. Companion unavailable/load failure states explain recovery. Final actual
1080p/1440p/4K and 0.65/0.8/1.0 UI checks plus five-second comprehension are FIELD.
New UX expansion does not excuse bugs in existing screens.

### OVR-20 — Correct replay contracts and source/package parity

**Edit:** KWR-295, `tools/replay-test-runner.lua`, fresh runner, benchmark and
the demonstrated faulty planner/label boundary.
**Verify/end state:** use the procedure below. All 2,003 current acceptance IDs
have current results and justified contracts; no stale/missing/duplicate result,
forbidden action or unexplained fallback passes. Mutation of each original audit
defect fails its relevant test. Source and extracted player package have identical
semantic decisions/contract scores on identical inputs; raw report hashes may
differ because timestamps and source/package paths are provenance.
Independent tactical label review is recorded honestly and never manufactured.

### OVR-21 — Field proof, prepared only after offline closure

**Offline edit/verify:** finalize the capture matrix, build/hash-bound logging,
instrumentation, export and review forms. Include all failure and missing-evidence
paths. **Offline end state:** an engineer can hand the owner one exact tested
package, installation/rollback instructions and executable capture steps.
**FIELD end state:** the matrix below and existing roadmap quality/sample budgets
pass. Two independent RBG reviewers and comparison evidence are required for the
comparative leading claim. Do not request matches while CODE work remains.

### OVR-22 — Distribution and rollback

**Edit:** canonical build/certification/package audit and CI/release workflow.
Pin Node/Lua/Fengari/build dependencies; enforce clean provenance and candidate
scope. Audit roots, TOCs, versions, interface, licenses/assets, links and public
allowlist. Prepare and test install/upgrade/rollback in isolated directories.
**Verify/end state:** two builds of the same clean source produce identical
archive hashes; extracted tests and replay parity pass; simulated clean install,
upgrade and rollback restore exactly the expected files and compatible saved
data. Actual WoW loading/rollback and public download verification follow at the
appropriate FIELD/RELEASE stage. A bot deployment or unrelated optional addon is
not a prerequisite for this Commander release.

## Replay remediation that can proceed offline

1. Open the 69 existing clusters; choose one representative and inspect its
   fixture facts, selected concrete plan, checkpoint outputs and label predicate.
   Trace the real code path. State whether the defect is evaluator, fixture/
   label, planner, or justified conservative fallback, citing evidence.
2. For a pure identifier-contract mismatch, document a narrow semantic mapping
   in the existing evaluator, with positive and negative counterexamples.
   Similar words or matching catalog tags alone are insufficient. For a planner
   defect, fix the responsible decision owner; for a label defect, preserve the
   old label and record why reviewed facts require the replacement.
3. Run every member of that pattern and mutation cases, including missing/stale/
   secret evidence and roster order. Split the cluster when predicates differ.
   Persist per-replay evidence; a shared reviewed explanation may be referenced
   by many records only after each input/result satisfies its stated predicate.
4. Engineering reviews can be authored by the actual coding reviewer and labeled
   as technical reviews. Do not invent human reviewers or call self-review
   independent expert validation. Prepare the required held-out tactical review
   packet while continuing other offline implementation.
5. Preserve the strict primary gate. If an unknown-input fixture correctly needs
   a conservative action, review and explicitly encode that expected primary
   behavior for that fixture; do not silently promote all fallback outcomes.
6. After bounded changes pass, run the complete source and extracted-package
   corpora once for the frozen candidate. Report all IDs, provenance hashes,
   primary/fallback/forbidden outcomes and semantic equality. The existing
   fresh runner is source-root based; add/test extracted-root execution and a
   semantic comparator before claiming this final step exists.

[KWR-295](docs/tasks/KWR-295-replay-contract-adjudication.md) owns these changes.
It does not require the owner to manually diagnose 2,003 coding contracts before
engineering work can begin. Independent tactical review remains necessary for
the advertised map/bracket/phase quality claim.

## Offline completion gate and verified commands

Run focused tests during changes. Run one final certification sequence after
recovery, required behavior and replay repairs are ready. Preserve exact command,
exit code, output, candidate/source/input hashes, environment and timestamp.
A tool PASS proves only the assertions it actually ran.

Existing commands below use current parameters. New harnesses/fields mentioned
above are required implementation, not already available commands.

```powershell
Set-Location 'C:\Users\josev\source\repos\KnomercyWarRoom'
powershell -NoProfile -ExecutionPolicy Bypass -File tools\validate.ps1 -Channel development
powershell -NoProfile -ExecutionPolicy Bypass -File tools\test-lua.ps1 -Suite All -ReceiptFile artifacts\offline-final-lua.json
powershell -NoProfile -ExecutionPolicy Bypass -File tools\security-audit.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\test-automation.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\knowledge-audit.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\fresh-replay-benchmark.ps1 -OutputDirectory artifacts\offline-final-replays
```

Use fresh run directories instead of overwriting prior receipts. After the
reviewed work is committed through the normal repository process, build the
clean candidate with auditing and reproducibility enabled:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build.ps1 -Channel production -RequireCleanGit -IncludeSentinel -OutputDirectory artifacts\offline-final-package
```

The build invokes package verification; avoid rebuilding merely to collect a
second status paragraph. `certify-offline.ps1` remains the intended integrated
entrypoint, but currently it does not request `-RequireCleanGit`, delegates
performance to the simulated soak, and does not run the full fresh corpus or
extracted semantic comparator. Wire these missing gates into it under OVR-09/
20/22 before using its PASS as the final offline completion claim. Resolve
candidate-generated report ordering in that entrypoint; do not waive final
knowledge or provenance checks to break a report-generation dependency.

**OFFLINE COMPLETE — READY FOR FIELD TESTING requires all of the following:**

- [ ] All CODE acceptance items for shipped behavior in OVR-01..20 are complete;
      no pending recovery decision or missing technical review hides code work.
- [ ] Original regressions, remaining invariant tests, migrations, real host
      benchmarks and instrumentation tests pass with source-bound evidence.
- [ ] Fresh full-corpus contracts pass and source/extracted player semantic
      parity passes; technical review and required independent label review are
      explicit, with no fake approvals or unexplained fallback-only success.
- [ ] Player/DevTools/Sentinel load graphs, compact runtime parity, collection/
      serialized-data bounds and clean/upgrade/future-schema paths pass offline.
- [ ] Clean reviewed candidate, pinned runtimes, deterministic build, exact
      package audit, isolated install/upgrade/rollback and usable public docs pass.
- [ ] Every remaining unchecked item is expressly FIELD or RELEASE, with no
      unimplemented code concealed as “needs live testing.”
- [ ] One candidate evidence index names the commit, package hashes, scope,
      all test receipts and the owner-only capture checklist.

A failing live-only metric cannot be marked passed offline. Conversely, the
absence of live observations cannot block a deterministic repair, migration,
replay investigation, packaging improvement or profiling implementation.

## Performance and field gates reserved for after offline completion

These are the roadmap's unchanged client targets, not results of the mock soak.

| Client metric | Required value |
| --- | --- |
| Strategic compute | P95 <2 ms; no routine refresh >4 ms; retain and label transition outliers |
| Tactical compute / Store plus visible subscribers | Each P95 <=1.5 ms |
| Critical fact to displayed invalidation / ordinary update | P95 <=250 ms / <=750 ms, including queue wait |
| Routine full strategy | <=4 per second without dropping critical corrections |
| FPS impact | Median loss <1%; 1% low loss <3%, repeated matched runs with variance |
| Player memory / growth | Soft/warn/hard 25/28/32 MB; <1 MB growth over 30 minutes after comparable warm-up/GC |
| Default serialized SavedVariables | <=1 MB; bounded eight-match default; also test offline |
| Lifecycle and safety | Ten queue/exit/reload cycles, 30-minute combat; zero KWR-attributable errors/taint/blocked actions |

After the offline gate, use
[the candidate capture matrix](docs/CANDIDATE_FIELD_CAPTURE_MATRIX_2026-07-29.md)
and [QA_CHECKLIST.md](QA_CHECKLIST.md):

| Owner/client activity | Capture and pass condition |
| --- | --- |
| Exact candidate load and rollback rehearsal | Record commit, version, Commander/Sentinel hashes, manifest, client build and UI/addon profile. Compare installed files, load clean/upgraded data and rehearse the documented restore. |
| Controlled WSG, KWR-280 / TP-STABILITY / TP-CARRIER-TARGET | Complete a match; verify single Reporter identity during GUID enrichment, no identical terminal-call reissue, actual shared countdown cancellation, flag state/target and final AAR agreement. Retain verify/perf/AAR evidence tied to the candidate. |
| TP-TEAM-TRUTH / TP-READABILITY | Compact/expanded team and assignments agree, including HIST provenance; next call and personal job understood within five seconds; essential UI passes the supported scale/resolution matrix. |
| TP-SAFETY-MAP and combat safety | Shift-M, secure roster/Quick Call, target swaps and nameplate recycling before/during/after combat; retain bug/taint evidence. No KWR-attributable blocked action or wrong secure identity. |
| Real performance | Collect actual event-to-display, stage CPU, FPS, memory and queue/GC evidence with DevTools on/off; satisfy the above budgets without delaying calls. |
| Advertised map/bracket strategy | Existing requirement: at least 20 complete reviewed matches per advertised map, stratified by bracket; each family has lead/win and deficit/loss coverage. At least 90% reviewer-acceptable calls, zero fabricated/impossible actions; retain denominators/disagreements. Held-out offline label review covers at least 30 distinct decisions per advertised map/bracket across five phases. |
| Optional Sentinel remote promotion | Ten physical-client authority/expiry/reload/teardown and usefulness proof only if promoting remote capability. Commander-only value does not depend on this promotion. |

The five named blocker sessions are first verification steps, not substitutes
for the full map/sample requirement. Preserve the existing advertised scope;
any proposed scope change needs an explicit product decision, not silent feature
removal to make tests pass. Comparative “leading” status follows demonstrated
improvement over a verified baseline; it is separate from stable distribution.

## Public artifact and final release contract

The player-facing release contains exactly the Commander runtime ZIP, Sentinel
runtime ZIP, SHA256 checksums, PUBLIC_MANIFEST.json and INSTALL.md. DevTools,
developer ZIPs, source manifests, generated certification reports and private
field evidence remain separate CI artifacts (30-day retention; the five most
recent successful runs are the operational diagnosis window). Preserve immutable
tags and published archives.

Commander and embedded Sentinel use the same approved version/source authority.
DevTools is an optional matching artifact. Beacon, Maps, ScoreCard and bot work
are separately versioned and outside this release unless explicitly added.
Unknown buffs, cooldowns, hidden talents or unavailable positions remain unknown;
the addon must not fabricate them to satisfy a tactical feature.

**Stable distribution** requires the offline gate, required FIELD results,
reviewed clean/tagged provenance, protected production approval, verified
GitHub/CurseForge downloads matching the approved artifacts, and rollback evidence.
Release and any announcement follow RELEASE_POLICY and existing authorization.
Passing this document review, a suite marker, a generated corpus count or an
old alpha is not that end state.

September 9 replay parity checkpoint: source and an extracted player ZIP match
on the Twin Peaks recovery probe under the release-only replay harness. The
new `replay-semantic-parity.ps1` fails missing IDs and differences in final
decisions, checkpoints or contract results. Evidence is
`artifacts/replay-semantic-parity-probe.json`; full-corpus strict replay and
independent tactical review remain required before field readiness.

## 2026-09-11 installed diagnostic field candidate

With WoW closed, the current source was built into
`artifacts/field-candidate-20260911-p03p04` and installed as a diagnostic field
candidate. Package audit passed, including extracted player/developer runtime
and DevTools lifecycle checks; reproducibility passed for all four archives.
The installed archive hashes are Commander
`D37A9429F69B59510E700A5387ABA50ED41DC42EAAF41614CEE87A577794C2C0`, Sentinel
`1BBE3EEC1A14F6F00E1EF8D06A0504AB225547CBFB5647E227114B6D91A27B35`, and
DevTools `F637408EFB5648C148B48151529D10E0E99F51F20661353ECD5D666CF91C3016`.
`artifacts/field-candidate-install-20260911-p03p04/DEPLOYMENT.json` records
zero missing/changed/extra files for all three addons and a passed isolated
restore rehearsal. Source/install TOC reconciliation records 142 matching
entries, zero changed and zero installed-only entries; the four source-only
modules are intentional development exclusions.

This candidate includes the Fight Now stability repair, canonical fact identity,
initial objective-transition and assignment-feasibility contracts, and the
decision-utility terminology correction. It is still a dirty-source alpha
candidate, not an offline-complete, field-certified or public-release claim.
Its rollback snapshot is
`D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KWR-Rollbacks\field-candidate-20260911-p03p04`.
Field captures must bind to the Commander hash above and retain `/kwr field`,
`/kwr verify`, `/kwr perf`, and `/kwr aar copy` output.

## Earlier 2026-09-09 verification-audit execution record (superseded above)

Canonical source is `C:\Users\josev\source\repos\KnomercyWarRoom`, branch
`codex/kwr-278-alpha11-field-blockers`, base/HEAD
`bcce7f585a2609ad60e0c84e872e959380b3375b`, with pre-existing uncommitted
work preserved. The installed folders were compared before installation via
`artifacts/source-install-reconciliation-20260909-preinstall.json` (79 MATCH,
53 CHANGED, 11 SOURCE_ONLY, 2 INSTALLED_ONLY); no installed difference was
adopted without source review.

R01-R06 have current deterministic coverage in
`artifacts/r01-r06-final-lua-tests-20260909.json`: override command-token
dispatch preserves raw player names; malformed Commander envelopes reject
without throwing; outbound Commander transport is gated while OFF; unavailable
Sentinel scores remain UNKNOWN while observed 0-0 remains valid; Diagnostics is
now an optional DevTools module; and an already-loaded DevTools companion no
longer bypasses the combat arming guard. `ArmFieldTest` now uses the same
evidence-context reset path as an explicit context switch.

`tools/certify-offline.ps1` completed current source validation, control-surface
audit, knowledge/scenario generation, 100,000-case ten-map simulation, Lua
developer-tools/smoke/Sentinel/soak/replay tests, performance benchmark,
reproducibility, and extracted-package audit. Exact archives and receipts are
in `C:\Users\josev\Desktop\KWR\Builds\6.1.1-alpha.12-fieldtest-20260909`.
Reproducibility and extracted-package audits pass. However,
`knowledge/offline-completion-audit.json` still records several completion
booleans false despite the successful invoked stages. Treat that contradictory
generated receipt as an unresolved reporting defect; it prevents an honest
R08/OVR offline-complete assertion.

Installation from those exact archives began. Sentinel and Developer Tools were
replaced from staging. Retail held the Commander folder open, so Windows refused
to move it; it remains the prior installed Commander. The pre-install trio is
preserved at
`D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KWR-Rollbacks\6.1.1-alpha.12-pre-field-install-20260909`.
Consequently R09-R11 remain open: no matched rollback rehearsal, zero-drift
Commander installation comparison, or field-export-to-package binding has been
claimed. Close Retail completely before completing the final install and parity
audit. No live field, external publication, merge, tag, service deployment, or
announcement is evidenced by this record.
