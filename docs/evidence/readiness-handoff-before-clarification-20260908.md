# Historical readiness handoff before clarification — 2026-09-08

This snapshot preserves the previous readiness text and KWR-281 task before the
owner requested explicit implementation steps and offline completion first.
It includes superseded status claims and incorrect source/installed attribution.
Use [RELEASE_READINESS.md](../../RELEASE_READINESS.md) for the corrected current
instructions; this snapshot cannot clear any gate.

## Previous readiness document (verbatim body)

# Release Readiness - 6.1.1-alpha.12

This is the sole current-version, blocker, and promotion-status authority.
GitHub committed content is the canonical development source; the live AddOns
folder is deployment evidence only after package-manifest verification.

## Current decision — audit update 2026-09-04

**NOT READY for stable promotion or a claim of leading RBG tactical quality.**
Installed Commander, Sentinel and DevTools declare `6.1.1-alpha.12`.
The inspected source is `codex/kwr-278-alpha11-field-blockers`, base commit
`bcce7f5`, with pre-existing uncommitted Alpha 11/12 work. This audit grants no
release, merge, upload or deployment authorization.

[PRODUCT_ROADMAP.md](PRODUCT_ROADMAP.md) contains the findings and the single
active overhaul sequence, OVR-01 through OVR-22. This document remains the release
decision authority. Pre-audit version/gate text below is retained as provenance
and cannot clear the current board.

The owner's September 4 follow-up prioritizes **stable distribution of the
existing Commander product** and cost control. Follow the roadmap's release-first
sequence. Additional tactical expansion and a comparative "leading" claim are
later outcomes; the correctness, compatibility, performance, advertised-map field
proof, installation, upgrade and rollback gates below remain mandatory. No gate
status changed with this priority update. Any deferred OVR acceptance items must
be listed in the candidate scope record with their effect on advertised behavior;
an unresolved safety or correctness failure in shipped behavior blocks promotion.

Implementation has started under
[KWR-281](docs/tasks/KWR-281-release-source-reconciliation.md): the source and
installed baselines are preserved, and three selective source recovery changes
pass static/mocked checks (sparse API returns, plain nameplate captions, combat
layout deferral). Source reconciliation remains IN_PROGRESS. These changes have
not been deployed or field-verified and do not clear the distribution gate board.

September 5 progress: the canonical DevTools split is implemented and the dirty
local recovery build `artifacts/recovery-devtools-20260905-02/` passed extracted
player/developer smoke and 500-refresh soak, companion lifecycle and Sentinel
transport checks. Clean reproducibility was explicitly skipped for this interim
build. The source now has 132 TOC entries; the original counts below describe the
audit baseline. Runtime projections and remaining reconciliation still block
OVR-01. [KWR-282](docs/tasks/completed/KWR-282-runtime-boundary-regressions.md) subsequently
addresses the packet, cast tuple and marker cadence defects; those changes are
not part of the recovery ZIP and need their own validation/package evidence.

Subsequent source checkpoint: KWR-282/283/284 now cover all eight original
reproductions with fixes and deterministic regressions. This includes objective
projection, preserved observation time, target preference, known unavailable
actors, explicit Blitz indicators, defensive decoding, cast return positions and
frame-rate-independent marker retries. Their source checks pass. The broader
typed-fact/feasibility contracts, remaining source reconciliation, real performance,
current-code benchmark and candidate-bound field/distribution gates remain open.
The next interim package must include and exercise these changes before the
bounded implementation tasks close; the earlier recovery ZIP predates them.

Package checkpoint: `artifacts/audited-regressions-20260905-02/` passed the
extracted Commander/developer smoke and soak tests, Sentinel transport and
DevTools lifecycle checks. Its audit verifies four ZIP hashes and the companion
source-transform digest. KWR-282/283/284 are closed for their bounded regressions.
The build was dirty and skipped clean reproducibility; it is not a stable release
and has not been installed. KWR-285 subsequently passed its own extracted-package
gate in `artifacts/memory-sampling-20260905-package/`, including source and
player/developer memory-sampling/report regressions. Its four ZIP hashes are
verified; clean reproducibility was again skipped for this interim build.
KWR-286 now repairs scenario generator/runtime API parity under OVR-01/11.
Its source regeneration, negative drift/template checks and knowledge gate pass.
KWR-287 source tests also pass for unknown-friendly availability/role handling.
The `generation-availability-20260906-package` checkpoint passes extracted
runtime/knowledge/lifecycle/transport checks and four hashes, closing KWR-286.
Subsequent KWR-287 source work also preserves known offline and unknown physical
state during complete-scoreboard roster repair. Its expanded smoke test passes,
but that follow-up is not in this package and needs the next extraction gate.
Range, coverage, field truth, final reproducibility and live certification remain open.

KWR-288 source tests pass for explicit local start/deadline projection, semantic
cancellation, expiry, reset and delayed speech. Untimed kill calls no longer
invent five seconds or say NOW. This and the KWR-287 scoreboard repair await the
next combined extraction gate; canonical ActivePlay/relay integration is not closed.

Subsequent package checkpoint: `explicit-countdown-20260906-package` passes
extracted player/developer smoke and 500-refresh soak, full knowledge regeneration,
Sentinel transport, DevTools lifecycle and four ZIP hashes. This closes the bounded
KWR-287/288 implementations, including scoreboard repair. The package is dirty,
skips clean reproducibility and is not installed; broader release gates remain open.

KWR-289 source regressions reject future/invalid evidence times and cached
freshness after expiry in the shared production truth gate. Its subsequent
`evidence-freshness-20260907-package` passed extracted player/developer runtime,
knowledge, DevTools lifecycle, Sentinel transport and four ZIP hashes. This
dirty interim package skipped clean reproducibility and is not installed; it
closes only the bounded evidence-time correction, not OVR-02 or release gates.

KWR-290 source work separates pressure/watch selection from an observed kill
commit across CombatIntel, BoardState, the problem/selection path, execution and
the reticle. Its `observed-kill-intent-20260907-package` passed extracted
player/developer runtime, knowledge, DevTools lifecycle, Sentinel transport and
four ZIP hashes. This dirty interim package skipped clean reproducibility and is
not installed; it closes only the bounded intent correction. OVR-03 target
evidence/feasibility and all release gates remain open.

KWR-291 closes known-friendly availability for support-derived kill windows.
Its dirty `local-support-availability-20260907-package` passed extracted runtime,
knowledge, DevTools lifecycle, Sentinel transport and four ZIP hashes; clean
reproducibility, installation and live feasibility proof remain open.

Determinism checkpoint: `reproducibility-20260907-package` passed binary
reproducibility for all four archives, four hash checks, and all extracted
runtime/knowledge/lifecycle/transport gates. Its provenance binds the result to
commit `bcce7f5` with `git.dirty=true`; this is deterministic staging evidence,
not the clean reviewed candidate required for stable distribution.

Current extraction checkpoint: `replay-reconciliation-20260907-package` repeats
the four-archive binary reproducibility and package audit after the fresh replay,
Predictor and reconciliation tooling work. Extracted Commander/developer runtime,
DevTools lifecycle and Sentinel transport all pass. It is again bound to dirty
commit `bcce7f5`, has not been installed, and cannot clear source identity,
clean candidate, rollback or live field gates.

September 8 current-package checkpoint:
`replay-adjudication-20260908-package` produced reproducible Commander,
Developer, DevTools and Sentinel archives after the replay-adjudication tooling
work. Commander SHA-256 is
`1A1A198096ACE110F8F55CD0931A3F31032B2FFEA2B17BD284072DBAF8CC7E01`.
The extracted audit passed four hash checks, player/developer runtime checks,
DevTools lifecycle and Sentinel transport. Provenance is still `bcce7f5` with
`git.dirty=true`, so this is an interim package receipt only: it is neither
installed nor eligible for field or distribution certification.

The active Retail source/install receipt has a companion hash-bound review packet:
`artifacts/source-install-review-packet-20260908-live-session.json`. It has 62
open rows (49 changed, 11 source-only and two installed-only) and zero completed
reviews. Packet creation rechecks each captured hash and records per-file review
evidence requirements; it does not choose a source of truth or alter either tree.
It prioritizes 40 loaded runtime/transport rows as `P0` and 22 loaded
adapter/data/feature/presentation rows as `P1`; priority remains triage only.
Its companion review-ledger baseline has 62 missing records, zero invalid records
and `complete=false`. A closing record binds the packet/file hashes, named reviewer
and role, evidence, and a disposition; a deferral cannot satisfy reconciliation.
Twenty-seven P0 engineering reviews preserve source `Core/CommandReview.lua` (the
installed variant deletes KWR-280 derived evidence), `Runtime/Reporter.lua`
(the installed variant deletes identity-alias migration), `Core/BuildInfo.lua`
(safe DevTools load/version lifecycle), `Runtime/TruthContract.lua` (canonical
production truth gate), and `Core/CommandView.lua` (installed code invents NOW
instead of preserving local timing). It keeps Diagnostics, Preview, Verification,
and Season2Readiness as canonical source that is staged only into KWR_DevTools;
player-mode smoke requires them absent from Commander. The earlier review set
includes source
Predictor, BoardStateBuilder, CountdownState, FactStore and FriendlyRoleState
for completed missing-score, objective/unknown-truth, explicit-timing,
observation-time and availability contracts. Source CommanderComm and Sentinel
Comm/Observer retain strict transport decoding and public cast-boundary fixes.
The assignment/kill chain retains unavailable-actor rejection, observed kill
commitment, and explicit timing rather than installed fallback behavior. The
Core Addon lifecycle/processed-match guards, CommandAudio stale-cue
protection, and Strategist deep-copy cache isolation are also preserved. The
ledger remains incomplete.
Store, Util, MatchRuntime and MemoryBudget are explicitly deferred: their
installed performance changes require snapshot/event/countdown or write-bound
regressions before any merge. The ledger is 41 closing reviews, six deferrals,
15 missing, zero invalid and incomplete.

The CI and tagged-release build invocations now require a clean Git worktree;
the current dirty checkout is explicitly rejected by that gate. This prevents
an official-release claim from being generated locally before reconciliation,
review and commit, but the clean-candidate gate remains blocked.

`tools/test-lua.ps1` can now write a hash-bound receipt for a selected suite.
The receipt records the requested suite, completed stages, timestamps, pass/fail
state, failure text and exact test-tool hash. This makes long deterministic
candidate runs independently inspectable when their console capture ends before
the Fengari subprocess completes; it does not replace a clean-candidate run or
make a detached process result a pass.

Current-source verification receipt:
`artifacts/lua-all-current-20260908-run2.json` records a passing full suite in
94.6 seconds (Developer Tools, smoke, Sentinel transport, soak and replay),
bound to test-tool SHA-256
`7DE2FAB96F62F60F6F762670B6AD6C4F00D20F912DB2BBFC564BD9D9B13C7AAF`.
Development validation has zero errors and automation passes 228 checks. This
is deterministic dirty-source evidence only; it cannot clear review, clean
candidate, package, installation or field gates.

September 7 offline measurement refresh: the Alpha 12 soak reports 500 refreshes,
0.208 ms average, 0.8 ms P95 and 3.2 ms maximum with bounded history/evidence;
`runtime-preflight.json` also confirms the extracted-package test runtime is
available. These are injected-clock source measurements only. Real WoW CPU/FPS,
memory plateau and event-to-display proof remain live blockers.

Client metadata checkpoint: `knowledge/client-build-preflight.json` records the
installed Retail 12.1.0.69587 client, derived interface `120100`, and matching
Commander/Sentinel TOCs plus active `PatchData`. This is a source metadata
receipt only. It does not prove a clean package, addon load, current API behavior
or release readiness. The official 12.1 hotfix ledger was reviewed through
September 4 and remains advisory; repeat the delta review immediately before a
clean build or field session. Current-client API behavior remains OVR-07 work.

Replay checkpoint: KWR-294 replaces the historical-result shortcut with a fresh,
hash-bound replay runner and completes golden labels for all 2,003 current
fixtures. Its bounded self-test uncovered and repaired missing derived-score
handling in Predictor. A full current-source run completed on September 7: all
2,003 distinct results are bound to one runner and driver hash, with zero forbidden
actions. The current repeat also records reviewed catalog plan tags beside each
concrete plan ID. It fails the decision gate by design: 0 primary matches, 578
allowed fallback matches and 1,425 unmatched contracts. That is actionable
diagnosis, not tactical certification. KWR-295 must adjudicate each output/label
discrepancy; a full run against the final clean candidate and its extracted package
is still required.

Full-corpus and merged replay benchmarks now require a primary match for every
fixture. An allowed fallback remains visible diagnostic evidence but cannot make
a candidate benchmark pass. The bounded runner self-test intentionally retains
fallback acceptance because it tests execution only, never certification.
The current strict report (`benchmark-primary-required.json`) correctly exits
nonzero with all 578 fallback-only rows rejected.

The current adjudication queue contains every 2,003 replay row: 446 exact
catalog-taxonomy candidates, 979 planner-or-label contract reviews and 578
fallback-only reviews. Its source labels carry generic fixture-review metadata
(`reviewer-a`, `offline-foundation-pack` or `developer-fixture-contract`), not
named independent tactical adjudications. No queue row is accepted; this remains
an OVR-20 blocker.

The corresponding cluster receipt has 69 contract patterns (15 fallback-only,
54 unmatched and zero forbidden). It preserves every replay ID and separates
fallback contracts, so it reduces reviewer navigation without granting a
taxonomy equivalence or changing the zero-primary score.

The hash-bound adjudication ledger validator now reports the current baseline as
2,003 required records, zero valid records and zero invalid records. It rejects
missing, duplicate, stale, unnamed and unevidenced reviews when run with its
completion gate; filling that ledger does not itself make the strict benchmark
pass.

The live-capture matrix now requires clean candidate tag/commit, both package
hashes, manifest digest and Retail client/UI context on every match record.
It identifies the remaining in-game gates: exact install/rollback, map/bracket
win/loss coverage, identity/objective/carrier truth, command lifecycle, secure
click/Quick Call safety, performance, taint, AAR/exit, and opt-in Sentinel
multi-client behavior. Unbound historical screenshots cannot satisfy them.

Field-readiness evidence now requires a candidate build provenance record bound
to the current clean Git commit. The September 1 Alpha 12 report is rejected for
the current source even though its version and base commit match: the current
worktree is dirty, so `candidateSourceBound=false` and all offline candidate-gate
claims are false. This prevents stale package reports from being reused for a
later source state. `tools/test-field-readiness-report.ps1` supplies a synthetic
otherwise-passing package report with no provenance and proves all four offline
candidate gates remain false; it also verifies external report paths so the
release workflow can exercise the gate without replacing durable evidence.
The readiness receipt now independently hashes the referenced Commander ZIP;
the report cannot use a missing or replaced archive merely because its package
report claims a passing audit. The current interim ZIP matches
`1A1A198096ACE110F8F55CD0931A3F31032B2FFEA2B17BD284072DBAF8CC7E01`, but
its dirty source binding still blocks every candidate gate.

Current Retail SavedVariables audit (September 8):
`artifacts/retail-savedvariables-current-session-20260908.json` read the active
Alpha 12 saved data without changing the installation. It found eight retained
sessions: four completed and four interrupted, across Arathi, Silvershard,
Warsong Gulch, Temple and Deephaul. The data is unbound to the current candidate
package and every retained session is diagnostic or observer-only, with zero
performance samples and no scored command-stability result. It is useful
diagnostic context only; it clears no lifecycle, taint, performance, team-truth,
carrier-target, readability or map-family gate. The same BugGrabber snapshot
contains one blocked-action record for `FuryCrosshair`, not KWR or Sentinel; it
cannot certify KWR taint safety.

## Current distribution gate board — 2026-09-04

| Gate | Evidence | Status / task |
| --- | --- | --- |
| Source/package identity | Current hash-bound TOC receipt: Commander source has 132 entries versus installed 123 (74 match, 47 changed, 11 source-only, two installed-only); Sentinel has 11 entries on both sides (nine match, two changed). Every non-match remains review-required. | BLOCKED — OVR-01, KWR-281 |
| Existing static checks | validate.ps1 passes with zero errors/warnings on the dirty working tree. | PASS for existing rules only |
| Existing mocked tests | test-lua All passes; smoke marker 276; Sentinel accepted=10/rejected=14; 500-refresh soak; one default replay passes by fallback. | PASS for tested cases only |
| Knowledge audit | Passes 100,000 generated cases, ten maps, five phases and 2,000 exact branches. | PASS for internal coverage only |
| Reproduced defects | Objective rows lost; observation age reset; preference promoted to killable; dead actor assigned; partial standard roster classed Blitz; malformed packet throws; cast return wrong; marker retries slow at higher FPS. Reproduced in source and installed modules. | BLOCKED — OVR-02/03/04/06/07/08/12 |
| Command timing/lifecycle | Fixed five-second execution copy has no shared deadline; KWR-280 still needs its live WSG regression. | BLOCKED — OVR-05 |
| Real performance | Soak durations are injected; no new real-client CPU/FPS/memory or event-to-display receipt. | UNVERIFIED — OVR-09/10/11/21 |
| API/meta freshness | Local 12.1.0.69587 metadata receipt matches interface 120100 and active PatchData. Official hotfixes are reviewed through September 4 as advisory-only; a pre-candidate delta review and clean-package/load/API proof are absent. | OPEN — OVR-07/16 |
| Fresh complete replay benchmark | Fresh runner now binds source, fixture, label and output hashes and refuses a full run with missing labels. The dirty current-source run has all 2,003 results and zero forbidden outputs, but 0 primary / 578 fallback / 1,425 unmatched label outcomes. Its 2,003-row review queue has no named independent adjudications. No clean-candidate or extracted-package equivalence result exists. | BLOCKED — OVR-20, KWR-295 |
| Candidate-bound field quality | Receipts include Alpha 10/11 and unbound historical matches; no new Alpha 12 complete field proof established here. | BLOCKED — OVR-21 |
| Distribution/rollback | No new clean tagged build, extracted install comparison, public artifact verification or rollback rehearsal in this audit. | UNVERIFIED — OVR-22 |

Sentinel transport stays **off by default** and outside Commander-only competitive
readiness dependence. Shipping its code still requires parser/adapter fixes;
promoting remote capability requires physical-client proof. KWR_Maps,
KWR_ScoreCard and KWRBeacon are separate optional experiments; their absence
from this installation does not block Commander.

The previous stable/rollback declarations below are historical records, not newly
verified public receipts. Preserve immutable artifacts; OVR-01/22 must verify
the actual rollback pair. Version bumps and prior-alpha passes do not clear gates.

## Historical pre-audit decision text

**6.1.1-alpha.12 is the pending Season 2 developer field-test candidate;
6.1.0 remains the immutable public stable baseline and 6.1.1-alpha.9 is the
immediate field-test rollback baseline.** Alpha 11 closes the Alpha 10 field
blockers for ActivePlay retirement, Seething Shore truth, command churn,
memory pressure, secure roster identity, and unknown-score copy. Its offline certification,
binary reproducibility, extracted-package audit, and exact Retail installation
verification must complete against the Alpha 10 archive before publication.
The archive hashes are intentionally not embedded here: modifying a shipped
document changes its archive. The versioned `SHA256` manifest and deployment
certificate are the sole exact-hash authorities generated after the immutable
archive is built.

It is a field-test candidate, not yet a stable Retail-ready release. The owner
authorized Alpha 10 developer-prerelease publication on 2026-08-31 after the
weekly audit identified Alpha 9/10 publication drift. This authorization does
not waive source review, green CI, exact tagging, protected `production`
approval, package provenance, or public artifact verification. Candidate-bound
live RBG evidence remains mandatory for any later stable promotion;
source-only, historical, unbound, or simulated proof cannot substitute for
that stable-release gate.

Alpha 9 remains bound to clean source commit
`4a6bfd5f78afd4110a281080e2a50416599a9389` and certified Commander hash
`88B09C8CE037DB816CF28B84FE8122379312ADA7B2A367C856D37CE73C3AAAB1`.
Alpha 10 must produce its own clean commit, hashes, package audit, deployment
certificate, and public file IDs. Neither Alpha 9 nor historical Alpha 5
evidence can certify Alpha 10, and no prerelease evidence substitutes for
stable Retail field proof.

The 2026-08-15 owner direction explicitly accepted 6.1.0 promotion with the previously
recorded live-evidence gaps carried as refinement telemetry. It does not assert
new 6.1.1-alpha.9-bound battleground sessions or ten-client Sentinel transport
proof. The official 12.1 compatibility/hotfix review is now active, while the
stale 12.0.7 ladder snapshot, inferred numerical tuning weights, and provisional
Season 2 formations remain excluded from live meta influence. The candidate
must still pass validation, deterministic Lua tests, package extraction/audit,
Commander/Sentinel version parity, checksums, protected production approval,
and rollback-artifact creation.

## Historical pre-audit distribution gate board

- [x] Source validation, source-drift, document-authority, control-surface,
  knowledge, security, automation, SavedVariables, full Lua, and 100,000-case
  RBG-corpus gates pass.
- [x] Build the current Alpha 10 source candidate under the authorized release
  workflow and prove Commander/Sentinel version parity, binary reproducibility,
  extracted-runtime integrity, and package audits. Exact installed-folder
  parity, hashes, and rollback remain part of the live deployment gate.
- [x] Install the exact clean Alpha 10 candidate with a rollback snapshot and
  certify zero missing, changed, or extra Commander/Sentinel files.
- [x] Merge the reviewed Alpha 10 source to protected `main` after exact-head
  `certify` passes.
- [ ] Tag and publish the exact Alpha 10 developer-prerelease artifacts after
  package and live-install certification. Stable promotion remains blocked on
  candidate-bound field evidence.
- [ ] Capture candidate-bound Retail proof for Team identity/health/HIST,
  flag-map stability and AAR, canonical carrier targets, combat-safe native-map
  behavior, taint/blocked actions, supported-resolution readability, and field
  CPU/memory budgets. The capture must use the hashes recorded in the
  versioned checksum manifest and deployment certificate.
- [ ] Capture live win and loss evidence across every map family, then rerun
  the read-only SavedVariables certification with only completed candidate rows.
- [x] Keep Sentinel cross-client transport disabled by default and outside the
  competitive-readiness release dependency. Any future opt-in promotion still
  requires its own ten-client, taint, expiry, teardown, and product-value proof.
- [ ] From the green tagged commit, publish the explicit Alpha 10 field-test
  runtime ZIPs, checksums, manifest, and install guide; verify the public
  downloads and CurseForge file IDs before any announcement.

Until every unchecked live item is evidenced, this candidate may be distributed
only as an explicit **field-test prerelease, not a stable Retail release**.

Alpha 9 is the immediate public prerelease rollback baseline and Alpha 10 must
generate new receipts without reusing its file IDs or hashes. The stable
cutover must likewise generate new evidence. Render remains separately
evidenced at Sentinel-bot commit
`5ffdb7d2f60be3e673d284b62adf49a8f8d1727b`; this addon release does not alter
bot deployment, Discord settings, GitHub issue integration, or AI integration.

## Public artifact contract

The release page is player-facing and contains exactly the Commander runtime
ZIP, Sentinel runtime ZIP, `SHA256` checksums, `PUBLIC_MANIFEST.json`, and
`INSTALL.md`. It never contains a developer ZIP, source manifest, generated
certification/reproducibility report, screenshot, or field evidence.

Developer packages and generated diagnostic evidence are CI artifacts only,
with a 30-day retention policy. The five most recent successful release runs
are the operational rebuild/diagnosis window; durable source history is held
by immutable Git tags and GitHub releases, not by player or developer ZIP
bundles. The release workflow uses an explicit public-asset allowlist and the
CI workflow uploads public and developer artifacts separately, so a wildcard
upload cannot reintroduce internal evidence to player downloads.

Historical reports of complete Retail battlegrounds and the prior
field-verification attestation are diagnostic provenance only. They do not bind
to the current package hashes and therefore cannot clear
`LIVE-TEAM-TRUTH`, `LIVE-STABILITY`, `LIVE-CARRIER-TARGET`, or
`LIVE-READABILITY`. Cross-PC Sentinel transport likewise requires its separate
ten-client safety and product-value proof.

The read-only SavedVariables audit in
`knowledge/retail-field-certification.json` found four completed matches and
four interrupted records across Deephaul, Deepwind, Gilneas, and Silvershard.
All four completed matches report `FAIL_REVIEW` command stability, with 36-75
replacements and 6-28 reversals. The records predate the exact deployment
certification receipt and are therefore useful defect evidence but remain
`UNBOUND` for promotion. KWR-250 owns deterministic candidate binding.

The first preserved Twin Peaks screenshot pass is recorded at
`docs/field-evidence/2026-07-28-twin-peaks/README.md`. It confirms working
Horde-relative score direction, native-map coexistence, roster/assignment
population, conservative unknown handling, enemy observation aging, and a live
lose-state command transition. It also confirms two P1 trust blockers:

- expanded Team health is empty/dim while compact legal health is visible;
- expanded Team specialization labels drop historical `(HIST)` provenance.

Twin Peaks remains partial because that screenshot predates the repaired
candidate and cannot certify it.

Supplemental match-end evidence confirms the final Horde-relative `0-3`
defeat agrees with the AAR and captures flag pickup/drop/return/capture events.
It also adds two P1 command blockers:

- `KWR-033`: the prior candidate recorded 58 replacements and misleading
  `0:00` lifetime semantics;
- `KWR-034`: the prior candidate allowed raw flag-event prose into a tactical
  target.

The Team and carrier-target implementation repairs remain closed offline. The
command-stability repair is reopened by real AAR evidence: after the minimum
commitment window, a non-superior alternative could replace an active play
despite a negative replacement decision. The closure branch now retains the
active play until superiority or an explicit invalidation is proven; fresh
candidate-bound Retail evidence is required to verify the repair.

Current repo state:

- the offline winning-state execution pass is closed by repo evidence;
- the expert scenario corpus and bounded enemy-response planner are integrated
  into the strategist and verified offline;
- the current offline candidate passes validation, knowledge audit, smoke,
  soak, and replay as of 2026-07-30;
- the interrupted local-fight HUD slice is closed by deterministic evidence;
- synchronized personal routing now preserves protected objective assignments;
- package certification requires explicit smoke and soak pass markers;
- the recovered distribution and developer package audits pass, with exact
  evidence recorded in `artifacts/recovery-candidate/BUILD_RECEIPT.md`;
- the default release package now excludes the optional Sentinel bundle unless
  `tools/build.ps1 -IncludeSentinel` is used intentionally;
- all offline distribution gates pass for the exact current artifacts, while
  live stability, taint/safety, field-performance proof, screenshot matrix,
  supported-map certification, official 12.1 tuning review, and release
  presentation remain hard promotion gates;
- `LIVE-TEAM-TRUTH`, `LIVE-STABILITY`, `LIVE-CARRIER-TARGET`, and
  `LIVE-READABILITY` are the field-gate identifiers in
  `knowledge/field-blocker-report.json`; implementation task IDs are not reused
  as live evidence IDs.

## Alpha engineering gate

The implementation is above the 8.5 pre-field gate in architecture, safety,
performance design, map knowledge, deterministic decision behavior, UI
consistency, packaging, and diagnostics. Team/enemy tracking, score
convergence, transition repainting, and complete-match trust remain
provisional at 8.5 until repeated Retail matches confirm the public APIs behave
as modeled. A field failure lowers that category and blocks promotion; it does
not get hidden by the aggregate score.

## Proven offline

- One authoritative Store and one MatchRuntime ticker.
- Four finite zone-transition confirmations and three finite roster
  confirmations repair loading-screen truth without adding another ticker.
- Full spoken command calls list every named mover and defender; numeric
  shorthand is not used on the Scout HUD.
- Complete TOC and version consistency.
- No legacy patch markers.
- No automatic chat, addon messages, targeting/focus, macro execution, spell
  casting, or keybinding writes; fixed quick calls execute only from an
  explicit player click.
- Secure compact-row target/focus bindings are centralized and changed only
  out of combat.
- Secure fixed Instance Chat quick calls are centralized, immutable in combat,
  and retain a compact right-click copy fallback.
- Lua 5.1 syntax for all runtime and test files.
- World, Arathi prediction, assignment, commander, preview, journal, and AAR pipeline smoke coverage.
- Internal Reporter objective state and bounded permitted movement evidence.
- Local kill-target selection, roster-validated assigned-team normalization,
  and explicit unknown handling for Midnight-blocked combat evidence.
- Dated Murlok RBG specialization snapshot with an explicit advisory boundary.
- Two hundred seventy-five deterministic diagnostics plus a 500-refresh bounded-state soak
  and knowledge audit.
- Reviewed expert scenario labels now inform preferred line, fallback line,
  safest counter, expected enemy answer, and review confidence on live
  strategist output.
- A bounded enemy-response planner now classifies likely punish patterns and
  adjusts candidate consequence scoring before the final recommendation is
  selected.
- Reviewed doctrine depth now includes comp-threat models, enemy-defense models,
  per-map opener branches, per-map recovery branches, per-map endgame branches,
  deterministic doctrine fixtures, and verification-surface doctrine reporting.
- All ten supported battlegrounds exercise lead, deficit, tie, assignment
  family, valid-location, and map-specific node-priority fixtures.
- Forty deterministic scenario combinations per map cover opening,
  stabilization, pressure, recovery, and endgame response shapes.
- GUID-based role validation prevents incompatible healer assignments.
- Bounded current-season encounter history remains explicitly distinct from
  live and last-observed evidence.
- Five-second freshness gates prevent stale score or objective evidence from
  driving live recommendations.
- `/kwr verify` includes map and team identity, source ages, complete command,
  assignment audit and rows, Reporter coverage, and transition performance.
- Versioned capabilities, composition archetypes, battle plans, counters,
  patch overlays, source authority, and bounded reviewed learning.
- Fourteen bounded specialization ratings, nine battlefield-job preferences,
  advisory Hero talent modifiers, and observed tactical ability windows all
  feed existing engines without duplicate polling or state ownership.
- Every weighted category has three or more evidence signals, three documented
  battlefield effects, and objective-plan influence.
- Objective commands publish success and abort criteria; all seven generic
  enemy archetypes have reviewed three-step counter sequences.
- Capability caching, summary reuse, render-signature skipping, and
  lightweight friendly health/aura handling reduce repeat work.
- Multi-source confidence, objective ETA, enemy intent, opportunity, momentum,
  resource economy, assignment-integrity, and five-candidate heuristic
  simulation all feed the existing Strategist and Commander path.
- Low-confidence calls become conservative; unknown information remains
  unknown and cannot inflate the confidence budget.
- Knowledge freshness gating now scores patch alignment, reviewed-data age,
  live enemy specialization certainty, and historical-spec dependence before
  composition-specific or meta-assisted calls are allowed to influence the
  command path.
- Stale or unaligned meta data can no longer silently bias kill-target scoring
  or composition-driven strategic commits.
- Counterfactual decision reviews are bounded developer logs and never
  self-modify battlefield doctrine.
- Manual AAR export reuses the existing AAR subscriber and copy dialog, records
  bounded evidence only, has no automatic chat behavior, and can be disabled.
- The existing Strategist now derives bounded commitment, reinforcement,
  pressure, rotation-economy, collapse, recovery, organization, and
  single-action assessments from already-sanitized state.
- Execution assessments are review evidence only in this candidate; they do
  not add HUD lines, automatic actions, or a second decision owner.
- The optional target spotlight and priority-cast accents are precreated with
  the compact roster and update from fixed target/event evidence.
- Observed swap-class protection suppresses automatic kill-candidate ranking;
  KWR never changes the player's target or claims interruptibility.
- Tactical telemetry remains on the expanded command board, the compact HUD
  reserves one persistent local-fight card, the combat roster spotlight uses a
  dedicated readability lane, and native `Shift-M` owns battlefield-map display.
- Qualified execution evidence produces one shared response package containing
  movers, stayers, success, and abort; all command and review surfaces consume
  that same package.
- Assignment audits reject non-roster identities, invalid priorities, and
  incompatible flag carriers.
- Repeated execution assessments and carrier aura reads use bounded caches.
- Export sections explicitly separate recommendations, evidence, execution,
  known outcomes, enemy observations, and unavailable facts.
- Live performance telemetry and enforced strategic refresh budgeting.
- Field distribution packaging now excludes developer preview and deterministic diagnostics paths.

## Requires Retail proof

- Native `Shift-M` coexistence across battleground transitions and combat.
- PvP scoreboard fields under Retail 12.0.7 secret-value behavior.
- Event-fed teammate-target/nameplate last-seen behavior.
- Live objective-marker changes; instanced player coordinates are unavailable
  through the public map-position API.
- Reporter pressure/hotspot quality across objective families.
- Compact local-fight card readability with zero, one, two, and three healers.
- UI clipping and scaling at common resolutions.
- Match-complete and instance-exit journal behavior.
- Taint, blocked-action, CPU, and memory checks.
- Assigned-team resolution across native, mercenary, and cross-faction matches.
- Enemy/friendly secure row click behavior through a complete combat cycle.
- Fixed Quick Call behavior and taint through a complete battleground cycle.
- Kill-target quality across melee and ranged local-fight conditions.
- Knowledge-status thresholds across real inspected, partially observed, and
  fully unknown enemy lobbies.

## Intentionally incomplete

- Enemy buffs not explicitly observed remain unknown.
- Defensive and trinket readiness is never assumed. Retail 12 blocks the combat
  log subscription formerly used for observations, so live state remains unknown.
- An enemy's health may be displayed directly by a protected StatusBar when the
  client permits it, but secret health cannot be used in target scoring.
- External meta data is release-dated and cannot reveal an individual enemy's
  actual talents, gear, enchants, or PvP build.
- KWR can identify when composition certainty is too weak for an advanced
  commit, but it still cannot discover hidden enemy builds that Blizzard does
  not safely expose.
- Reporter cannot plot an enemy whose map position Blizzard does not safely expose; roster knowledge alone never becomes a fabricated dot.
- Predictions for public widgets not exposed by Blizzard remain low-confidence or unknown.

Promotion requires the live sections of `QA_CHECKLIST.md` to pass with captured evidence.
This document is the current gate board; prior gate plans are retained only under
`docs/audits/historical-plans/` for provenance.

## Season 2 cutover and autonomous-maintenance authority

### Goal

Before the next Season 2 reset, deliver one evidence-bound, Retail 12.1
Commander/Sentinel release that helps an RBG leader make a clearer next call
without fabricating game state, automating gameplay, or turning community input
into unreviewed doctrine. The product target is one dependable loop:

```text
public game truth -> one explained team call -> player-confirmed execution
                         ^
official patch data + reviewed field evidence + bounded community reports
```

`KnomercyWarRoom` is the sole source and release authority. Its embedded
`KWRSentinel` is the only Sentinel package that may ship with a Commander
release; both TOCs, runtime constants, package manifests, hashes, tag, GitHub
release, CurseForge files, and Discord copy must name the same version and
commit. The installed AddOns folders are runtime evidence, never source control.
`KWRBeacon`, `KWR_Maps`, and `KWR_ScoreCard` are optional, independently
versioned experiments. Their intentional absence from an AddOns installation
does not block a Commander/Sentinel cutover unless a future release explicitly
adds one of them to its signed package manifest.

### Historical 6.1.0 cutover provenance — not the current gate board

- `main` contains the merged Alpha 43 line plus subsequent maintenance; the
  stable cutover branch reconciles the reviewed field-test commits without
  moving any prior tag.
- `v6.1.0-alpha.43` is immutable prerelease evidence. The new stable tag is
  `v6.1.0` and may be created only at the green merged cutover commit.
- The separate `KWRSentinel` repository still contains Alpha 33-oriented
  release automation. It is not release-authoritative for 6.1.0 and is a
  drift risk until it is explicitly archived as a standalone historical lane or
  regenerated from the embedded package.
- The Sentinel Discord bot local checkout was behind its remote `main` by two
  commits at audit time. Render has a worker manifest and health endpoint, but
  automatic Render deploys are intentionally disabled; a release receipt must
  prove the deployed commit and ready Discord session.
- The scheduled maintenance workflow performs certification and dry-run
  reporting by design. It does not publish to CurseForge, Discord, Render, or
  GitHub from a timer. That is correct: scheduled unattended work may discover
  and prepare a change, but may not publish unreviewed player input or modify
  production.

### Required control plane

| Lane | Required operating rule | Completion evidence |
| --- | --- | --- |
| GitHub | `main` is protected by the `certify` check, linear history, resolved conversations, and no force-push/delete. Merge only a green, reviewed candidate; tag only that merge commit. | PR merge receipt, exact annotated tag, clean `git status --branch`, and `HEAD == origin/main`. |
| Source hygiene | Fetch/prune every working clone before a release. Keep historical branches until their ancestry is reconciled; then remove only branches/worktrees proven merged or intentionally archived. Never use the installed WoW folder as a Git checkout. | Branch/worktree inventory with no active branch tracking a deleted remote and no uncommitted release files. |
| Commander + Sentinel | Build both packages from the same tagged canonical checkout. The standalone Sentinel repository is release-frozen until its versioned source-parity check is regenerated for the current package. | TOC/runtime parity, extracted manifest parity, SHA-256 manifests, and package install comparison for both addons. |
| CurseForge | Upload only the certified tagged ZIPs with explicit Retail game-version IDs. Verify the returned file IDs, file type, version, hash, and public download resolution before announcing. | GitHub workflow receipt plus captured public file IDs and hashes. |
| Discord | Announce only a verified immutable GitHub release and matching CurseForge file IDs. Webhooks are notifications, not feedback intake or a deployment control plane. | Dry-run copy equals posted copy; announcement receipt links to the exact tag and files. |
| Bot + Render | Keep Render as a least-privilege Discord intake worker. Deploy only the reviewed bot `main` commit, run a post-deploy `/readyz` check, and record the commit, deployment ID, ready time, and command-registration result. | Render deployment receipt and a private health result proving `discordReady: true`; no secret or user identifier in the receipt. |

### Historical P0 cutover register — retained for provenance

| ID | Gap to close | Required action | Done only when |
| --- | --- | --- | --- |
| GIT-01 | Stable metadata and the reconciled field-test source require one reviewed merge commit. | Merge the 6.1.0 cutover only after the required `certify` check is green; create a new annotated `v6.1.0` tag at that merge without altering Alpha 43. | `main`, stable tag, GitHub release assets, and canonical checkout resolve to one commit with no ahead/behind or uncommitted state. |
| GIT-02 | Historical local branches track deleted remotes. | Inventory ancestry, preserve any unmerged work under a named archive/ref, then remove only merged or explicitly retired worktrees and stale tracking refs. | No active worktree follows `[gone]`; a retained archive explains every unmerged historical branch. |
| REL-01 | A standalone Alpha 33 Sentinel release lane conflicts with the embedded 6.1.0 package. | Keep the standalone lane release-frozen; ship only the embedded Sentinel package built from the Commander tag. | One documented Sentinel release owner; parity test accepts 6.1.0; no standalone workflow publishes a competing package. |
| REL-02 | Publication must be proven end-to-end, not inferred from a green build. | Run the protected tagged-release workflow once, then verify GitHub assets, Commander and Sentinel CurseForge file IDs/version/channel, Discord announcement URLs, and installed-folder manifests. | One signed evidence bundle binds tag, commit, two ZIP hashes, two CurseForge files, Discord receipts, and installation manifests. |
| BOT-01 | Render configuration exists, but current deployment and command freshness are not a release invariant. | Fast-forward bot source, run its locked dependency/smoke/test/audit gate, deploy the reviewed commit, register guild commands, and capture private readiness. Keep Render auto-deploy off for unreviewed commits. | Bot commit equals approved remote `main`; `/readyz` returns 200 after Discord is ready; issue creation and AI stay disabled unless separately approved. |
| RBG-01 | Stable command quality and cross-client Sentinel value retain unverified field claims. | Capture bounded 6.1.0 evidence for each map family and both win/loss states: command replacement/expiry, team identity, carrier grammar, secure clicks, taint/blocked-action, CPU/memory, and ten-client relay leadership/reload/packet-loss. | Evidence is version- and package-hash-bound; any failure opens a labeled issue and drives a new patch release rather than rewriting 6.1.0. |
| META-01 | Static meta data can become stale between official tuning and player evidence. | Use a development-only intake pipeline: official Blizzard notes first, at least two independent trend sources second, human review third, versioned data/fixtures fourth, PR + deterministic test last. The addon never fetches data in-game. | Every changed recommendation records patch, sources, reviewer, confidence, expiry, affected maps/specs, and a passing fixture; unreviewed trends remain `PENDING` and cannot influence live calls. |
| SOCIAL-01 | Feedback exists, but needs a measurable closed loop. | Make `/bug`, `/diag`, `/aar`, `/strat`, and `/suggest` create structured, deduplicated GitHub intake only when the least-privilege issue integration is enabled. Add `status:needs-review`, `needs-repro`, `needs-field-test`, `accepted`, `declined`, and `shipped` response paths. | A test submission reaches the correct private Discord channel and labeled issue, receives an acknowledgement, contains no secret/identifier by default, and cannot trigger merge, release, deploy, or doctrine changes. |

### Product refinements that earn “go-to RBG addon” status

Prioritize decision quality and trust over more panels or simulated omniscience:

1. **Command stability and explanation.** One call must persist until a
   superior, materially changed, or invalidated fact is proven. Show the
   replacing evidence, confidence, success condition, abort condition, and
   personal assignment delta.
2. **Role-aware, map-aware routing.** Maintain reviewed capability and
   composition data, but only permit it to refine a public-objective plan when
   roster certainty and patch freshness meet the gate. Otherwise fall back to
   map fundamentals.
3. **Sentinel must be smaller and more reliable than Commander.** It should
   show the recipient's job, target/watch, expiry, transport trust state, and
   local safe facts. It must fail visibly to local guidance, never become a
   second commander, and never require cross-client transport to be useful.
4. **AAR-to-fixture learning.** Convert reproducible reports into anonymized,
   bounded fixtures. Do not train or self-modify live doctrine from outcomes;
   a reviewed PR must promote every change.
5. **Performance and accessibility.** Maintain combat-safe layout behavior,
   zero unbounded allocations in hot paths, scalable contrast-safe surfaces,
   and a per-release taint/CPU/memory receipt on common UI scales.

### Discord follower and outside-input system

Use Discord as a community front door, not the truth engine. Create visible
`#announcements`, `#known-issues`, `#field-testing`, `#strategy-lab`,
`#install-help`, and `#release-notes` channels plus private moderation and
ops channels. Pin a short evidence standard: version, map/bracket, team side,
time, exact KWR call, observed result, `/kwr verify`/error text, and optional
redacted screenshot. Ask every field tester for one high-signal question:
“What call was unclear, late, or wrong, and what public fact would have made
it better?”

The bot should acknowledge submissions immediately, provide the issue link or
receipt, publish a weekly anonymized “heard / investigating / shipped” digest,
and offer a monthly opt-in playtest/strategy review. Rate-limit intake, retain
only the minimum report data, redact character/account identifiers by default,
and never let votes determine tactical truth. Popularity can prioritize a test;
only evidence can change doctrine.

### Codex scheduler: permitted autonomous operation

Codex automation is the operational auditor and maintainer, not an unattended
production publisher. Run it in an isolated worktree whenever it may propose a
change. Its durable jobs are:

| Cadence | Autonomous job | Required output / stop rule |
| --- | --- | --- |
| Daily through Season 2 launch | Fetch/prune source state; inspect the active stable release, tag parity, package manifests, bot remote drift, Render-ready receipt availability, open issue intake, and official patch/news deltas. | A concise `READY`/`NOT READY` report with exact blockers. Stop before external writes, merge, deploy, publication, or secret access. |
| Patch day | Run preflight before maintenance, then repeated read-only patch watch and a post-maintenance regression report. | A versioned patch-impact issue/PR proposal only; no doctrine change without reviewed sources and passing fixtures. |
| Weekly | Run the existing readiness/security audit across source, installed addons, workflows, public distribution evidence, bot, and Beacon. | Evidence-backed risk register; escalate missing credentials, failed health, version drift, or failed CI immediately. |
| Biweekly | Compare reviewed meta sources and closed AAR/field reports; cluster duplicate reports and propose fixture/data changes. | A human-reviewable PR or issue, never a direct data/release mutation. |
| Monthly | Verify action pinning, dependency advisories, branch/worktree hygiene, secrets inventory by presence only, retention policy, and rollback rehearsal. | Signed-off maintenance receipt and rollback readiness result. |

Every autonomous run must be idempotent, preserve uncommitted user work,
produce a receipt, and report “no change” quietly. It may create a draft
finding or a reviewed PR only if the task explicitly grants that authority. It
must never merge, tag, upload, deploy, post an announcement, change a
CurseForge channel, alter Discord permissions, or enable bot AI/GitHub-write
credentials on its own.

### Completion test

The Season 2 system is implemented and complete only when all P0 rows above
have their evidence bundle, the latest release branch is merged and tagged,
all required CI/release checks are green, and the following command-level
checks pass without exceptions:

```text
git status --short --branch                    -> clean and synchronized
tools/validate.ps1                             -> VALIDATION PASSED
tools/security-audit.ps1                       -> pass
tools/knowledge-audit.ps1                      -> pass
tools/test-automation.ps1                      -> pass
tools/certify-offline.ps1                      -> pass
tools/build.ps1 -IncludeSentinel               -> two certified archives
installed-folder manifest comparison           -> zero missing/changed/extra
bot npm ci && smoke && test && high audit      -> pass
Render ready receipt + Discord command check   -> current approved commit
```

Any missing receipt, stale version, failed check, unbound field evidence,
unreviewed external trend, or open release-critical issue is `NOT READY`.
This gate is intentionally stricter than “the addon loads”: reliable RBG
leadership requires accurate facts, calm calls, clear personal execution, and
a release chain that can be audited and rolled back.

## Previous KWR-281 task (verbatim body)

---
id: KWR-281
title: Reconcile release source and preserve installed improvements
owner: Codex
priority: critical
risk: high
status: in_progress
dependencies: [KWR-280]
affected_modules: [Core, Runtime, Features, Data, UI, tools, KWR_DevTools]
authority_references: [AGENTS.md, PRODUCT_ROADMAP.md, RELEASE_READINESS.md, RELEASE_POLICY.md]
---

# Objective

Execute OVR-01 from the release-first roadmap: establish a reproducible candidate
that preserves both the existing source fixes and the installed improvements.

# User outcome

The addon being tested can be rebuilt from reviewed source without losing prior
field fixes, and its runtime, optional developer tools and Sentinel are identifiable.

# Current behavior

The source branch is `codex/kwr-278-alpha11-field-blockers`, based on `bcce7f5`,
with uncommitted KWR-278/279/280 changes. The installed Alpha 12 Commander has
47 changed shared TOC files, 11 source-only TOC entries and two installed-only
generated projections; Sentinel has two changed shared TOC files. The September
8 Retail-active receipt has 62 non-matches in total, all `review_required`. The
desktop field-package script packages an existing runtime; it does not generate
the installed projections or developer split. Installed CommandReview and
Reporter lack source KWR-280 fixes, so a wholesale copy would regress those fixes.

# Required behavior

- Preserve source changes, all three installed addon trees, and addon-specific
  SavedVariables before mutation. Keep account data in ignored local evidence.
- Classify each loaded-file difference and recover additive improvements with
  focused tests. Preserve the newer source changes where installed code is older.
- Put production projections and optional developer tools under the canonical
  source/build contract, with equivalent runtime decisions and deterministic ZIPs.
- Correct obsolete repository instructions using actual Git and workflow evidence.
- Bind the eventual clean candidate, extracted tests, install and rollback records.

# Non-goals

No tactical expansion, unverified stable claim, public upload, or silent overwrite
of the current WoW installation. This task does not close KWR-280's live WSG gate.

# Technical constraints

Keep existing namespace and module boundaries. Preserve combat-safe nameplate
holders, sparse API return positions, source evidence generation, identity
enrichment and terminal-play suppression. Do not ship diagnostic corpora in the
player runtime. Do not discard persisted learning/history without a migration.

# Acceptance criteria

- [x] Pre-change source diff/files, installed addons and SavedVariables backed up.
- [x] Source/install loaded-file differences recorded with hashes.
- [ ] Every difference has a reviewed disposition and relevant regression evidence.
- [ ] Clean candidate builds Commander, Sentinel and optional DevTools reproducibly.
- [ ] Extracted packages pass tests and match the candidate's approved manifest.
- [ ] Source authority and packaging documentation agree with actual behavior.
- [ ] KWR-280 live WSG requirement remains explicit until evidenced.

# Verification

Baseline: `artifacts/release-first-baseline-20260904-203231/` contains 458 backed-up
files, including 35 dirty/untracked source files and four addon SavedVariables
files. `backup-manifest.json` contains local hashes; `runtime-differences.json`
records the 28 source/install mismatches. These artifacts are private local
evidence, not distribution content.

Current receipt — September 7: `artifacts/source-install-reconciliation-20260907.json`
compares the actual loaded Commander and sibling Sentinel TOCs without copying or
accepting a file. Commander has 74 exact matches, 47 changed shared files, 11
source-only TOC entries and two installed-only generated projections. Sentinel
has nine exact matches and two changed shared files (`Comm.lua`, `Observer.lua`).
All 62 current non-matching loaded entries are `review_required`. The original
28-row baseline is preserved as historical evidence, but it is no longer an
adequate current reconciliation count.

September 8 live-session receipt:
`artifacts/source-install-reconciliation-20260908-live-session.json` reran the
same read-only TOC/hash comparison while Retail was active. It reports the same
83 matches, 49 changed entries, 11 source-only entries and two installed-only
entries. No installation drift occurred during that session; all 62 non-matches
remain `review_required` and no live evidence is candidate-bound.

The matching hash-bound review packet is
`artifacts/source-install-review-packet-20260908-live-session.json`. It verifies
each of those 62 file hashes again before it emits a compact line-range summary
and the evidence required for a disposition. Its summary is 49 `CHANGED`, 11
`SOURCE_ONLY`, and two `INSTALLED_ONLY`, with zero reviewed rows. The packet is
work allocation evidence only: it neither selects a source of truth nor copies,
installs, deletes, or accepts any file.

The packet now puts 40 Core/Runtime/Intelligence/State/Sentinel rows in `P0`
review order and 22 adapter, data, feature and presentation rows in `P1`. The
priority is deterministic triage with a recorded rationale, not an acceptance
decision. The packet also records the SHA-256 of its own generator alongside the
input receipt hash.

`artifacts/source-install-review-ledger-20260908-live-session.json` is the
companion fail-closed ledger receipt. It starts with 62 missing review records,
zero invalid records and `complete=false`. Each future
`*.source-install-review.json` record must bind the packet and both file hashes,
name the reviewer and role, cite evidence, and use a documented disposition.
`DEFER` remains visible but cannot close reconciliation. The validator never
copies, installs, deletes or accepts source.

September 8 engineering review has 27 completed P0 dispositions in
`artifacts/source-install-reviews-20260908/`: preserve source
`Core/CommandReview.lua`, because installed code removes the KWR-280 derived
evidence fallback; and preserve source `Runtime/Reporter.lua`, because installed
code removes alias-based name/key-to-GUID track migration. The ledger binds both
decisions to their packet hashes, exact smoke assertions and task evidence. It
also preserves source `Core/BuildInfo.lua` for safe DevTools version/load
lifecycle, `Runtime/TruthContract.lua` for the canonical production truth gate,
and `Core/CommandView.lua` because installed code turns verified local timing
into unconditional NOW. It additionally preserves the canonical source of
`Core/Diagnostics.lua`, `Runtime/Preview.lua`, `Runtime/Verification.lua`, and
`Runtime/Season2Readiness.lua`: `release-manifest.ps1` stages them into
KWR_DevTools and player-mode smoke requires their absence from the player
runtime. It also preserves source Predictor missing-score fallback, canonical
BoardState objective/unknown truth, explicit CountdownState deadlines, FactStore
observation times and FriendlyRoleState unknown availability. The installed
versions regress those completed KWR-283/284/287/288 contracts. The ledger now
remains incomplete; these source decisions do not clear the required
clean-candidate WSG regression. Source
`Runtime/CommanderComm.lua` and Sentinel `Comm.lua`/`Observer.lua` are also
preserved: their installed variants regress strict KWRSync1 decoding and the
public cast spell-ID/error boundary repaired by KWR-282.

The source assignment/kill chain (`AssignmentOptimizer`, `AssignmentScorer`,
`EnemyProblemDetector`, `KillTargetSelector`, `TeamfightCommandPlanner`,
`ExecutionCommandBuilder`, and `CommandReasonBuilder`) is also preserved. Its
installed variants reintroduce unavailable actor assignment, inferred kill
commitment, and generated five-second execution wording that KWR-283/287/288/290
explicitly correct. Source Core Addon lifecycle/processed-match guards,
CommandAudio stale-countdown protection, and Strategist deep-copy cache isolation
are also preserved. The installed variants weaken those contracts. The ledger now
remains incomplete.

Four P0 performance-sensitive rows are reviewed as `DEFER`, not accepted:
`Core/Store.lua`, `Core/Util.lua`, `Runtime/MatchRuntime.lua`, and
`Runtime/MemoryBudget.lua`. Installed code contains possible allocation and
event-coalescing improvements, but it also weakens source evidence/countdown
contracts or lacks pruning write-bound proof. Each requires the recorded focused
regression before a selective merge. The ledger now reports 41 closing reviews,
six deferrals, 15 missing, zero invalid and `complete=false`.

Run focused Lua regressions for recovered behavior, source validation, then the
complete source/build/extracted-package gates against the final candidate.
Current work is IN_PROGRESS; no live or distribution gate is cleared.

September 7 determinism checkpoint: the current source produced byte-identical
Commander, developer, DevTools and Sentinel archives in
`artifacts/reproducibility-20260907-package/`; the package audit passed all
extracted runtime gates. Build provenance records base commit `bcce7f5` and a
dirty working tree, so this does not satisfy the clean-candidate criterion.

The release build now has an explicit `-RequireCleanGit` gate, used by CI and
the tagged release workflow. A local negative probe proves it rejects this
dirty checkout; the historical `tools/test-automation.ps1` receipt had 220
checks and validation passed.
The guard prevents mis-certification but does not turn the present source into
a reviewed clean candidate.

September 8 current-source verification: the durable full-suite receipt
`artifacts/lua-all-current-20260908-run2.json` records a passing 94.6-second
run of Developer Tools, smoke, Sentinel transport, soak and replay. It binds the
result to `tools/test-lua.ps1` SHA-256
`7DE2FAB96F62F60F6F762670B6AD6C4F00D20F912DB2BBFC564BD9D9B13C7AAF`.
`tools/test-automation.ps1` now passes 228 checks and development validation
has zero errors. These are dirty-source checks; they neither approve the 62
review rows nor certify a release package.

September 7 extraction checkpoint: `artifacts/replay-reconciliation-20260907-package/`
contains four byte-identical-rebuild archives. Its package audit passed four
hash checks, extracted Commander and developer runtime checks, DevTools lifecycle
and Sentinel transport. Provenance binds the package to `bcce7f5` with
`git.dirty=true`; it is local interim evidence only and does not satisfy the
clean-candidate, installation or rollback criteria.

September 8 current-package checkpoint:
`artifacts/replay-adjudication-20260908-package/` contains four byte-identical
Commander, Developer, DevTools and Sentinel archives. Commander SHA-256 is
`1A1A198096ACE110F8F55CD0931A3F31032B2FFEA2B17BD284072DBAF8CC7E01`; all
four archive hashes, extracted player/developer runtime checks, DevTools
lifecycle and Sentinel transport pass. The build provenance remains
`bcce7f5` with `git.dirty=true`. It is a current interim package receipt, not
a clean candidate, installation, rollback or field certification.

Field-readiness reporting additionally rejects a package report unless its
build-provenance record identifies the same clean Git commit as the current
candidate. `tools/test-field-readiness-report.ps1` proves a synthetic report
with a matching version and passing package audit cannot make any offline
candidate gate pass when provenance is absent. This protects the final package
and field receipts from stale-report reuse; it does not reconcile the remaining
loaded-file differences or substitute for a clean build.

Recovery pass 1: `tools/test-lua.ps1 -Suite Smoke`, `tools/validate.ps1` and
`git diff --check` pass after the API tuple, plain-caption and combat-layout
changes. The local `recovery-pass-01.json` receipt binds those checks to hashes
of the three runtime files and smoke driver. The smoke output's legacy
`checks=276` text is not a count of the newly added assertions. These are mock
and static checks, not a WoW combat, performance or package certification.

Recovery pass 2 — September 5: canonical build now generates the version-matched
load-on-demand KWR_DevTools companion. The production truth contract remains
loaded; preview, full verification and Season 2 reports move into the companion.
Source smoke and isolated companion lifecycle tests passed. The extracted
`artifacts/recovery-devtools-20260905-02/` packages passed player smoke/500-refresh
soak, companion load/version/rollback tests, Sentinel transport, and extracted
developer validation, knowledge, smoke and soak. ZIP hashes and source contents
are recorded in that directory's manifest/provenance/package-audit JSON files.

This was a dirty local recovery build with reproducibility explicitly skipped,
not a clean candidate. It predates KWR-282. The first build exposed a test that
assumed a player diagnostic ledger; the corrected test requires its absence in
the player ZIP and enforces its bound in developer source. Simulated durations
are labeled `injected-test-clock`. Follow-up source changes prevent `/kwr dev off`
from creating an unused production ledger and add explicit DevTools digest and
lifecycle fields to future package-audit reports; those await the next package.

The split's source/build decision and remaining gates are in
[ADR-001](../architecture/ADR-001-developer-tools-package.md). Runtime projections,
remaining installed optimizations, clean reproducibility and live proof stay open.

## Recovery disposition ledger

| Files / group | Disposition and remaining work |
| --- | --- |
| Core/Util.lua | Recovered allocation-free sparse return forwarding; smoke asserts exact return count/positions, false, zero returns and throwing/unavailable functions. Installed ShallowCopy helper remains to recover with its consumers. |
| Features/CursorRing.lua | Recovered plain nameplate caption/badge holders and removed backdrop calls. Preserved source KWR-279 centering. Mocked template assertions pass; real combat proof remains. Audited cadence defect belongs to OVR-12 and is still open. |
| UI/LayoutCoordinator.lua | Recovered combat guard for Apply and direct ApplyStrata; regression checks protected-setter failure and PLAYER_REGEN_ENABLED recovery. |
| Core/CommandReview.lua, Runtime/Reporter.lua | Preserve source: installed variants remove KWR-280 derived evidence and identity alias enrichment. Do not copy those older variants. |
| Runtime/Commander.lua | Merge installed review-context labeling and qualified replacement behavior while retaining source terminal-play suppression; review-context labels alone are not proof a call was delivered. |
| Runtime/MatchRuntime.lua, Core/Store.lua | Integrate installed filtering/copy cost reductions with source stage timing and memory-age labeling. Prove snapshot immutability and critical-event invalidation before accepting reuse. |
| Runtime/MemoryBudget.lua, UI/MainWindowReports.lua | KWR-285 centralizes routine sampling limits and successful measurement timestamps; source and memory-sampling-20260905-package regressions pass. Preserve processed-match ledgers and persistent/live pruning. Installed skip-all-live-persistent-pruning change is not accepted without write-bound proof. |
| Runtime/EncounterHistory.lua, Runtime/FormationAdvisor.lua, Runtime/Strategist.lua | Recover allocation/caching improvements only with expiry, roster-availability and immutability regressions. |
| Runtime/Sensors.lua | Review scoreboard reuse and callback changes; preserve inspection/spec invalidation and correct bracket hydration. |
| Runtime/AAR.lua, Runtime/Learning.lua, Runtime/OpponentModels.lua | Recover team/developer retention and review provenance. Require upgrade/idempotency tests before adopting removal of processed-match ledgers or legacy learning migration. |
| Core/Addon.lua, Core/BuildInfo.lua, UI/MainWindowLauncher.lua, UI/MainWindowCommands.lua, UI/MainWindowPages.lua, UI/MainWindow.lua, UI/AARWindow.lua, UI/Options.lua | Recover developer-mode lifecycle and player UI coherently with the companion package. Preserve working commands and surface failed/missing companion loads safely. |
| Data/ScenarioRuntimeKnowledge.lua, Data/StrategistNexusRuntimeIndex.lua | **Reject the installed-only compact projections.** Current source has no runtime references to either name and supplies the replacement canonical `ScenarioCalibration`, `ScenarioAdversarialCalibration`, `ScenarioExpertCorpus` and `StrategistNexusCorpus` modules with required summary APIs. `scenario-generation-audit.ps1`, `knowledge-audit.ps1` and the extracted package checkpoint pass. Do not copy the installed hardcoded-count projections back into source. |
| Runtime/TruthContract.lua and KWR_DevTools | Recovered canonical split and load-on-demand package. Extracted lifecycle, version mismatch, failure rollback, disable/re-enable and unchanged truth gate tests pass. Clean reproducibility and live loader/UI checks remain. |

Fetched origin successfully: remote default remains main and no origin/develop
ref exists. AGENTS.md and CONTRIBUTING.md now match that flow. The desktop script
only archives already-staged files and is not adopted as a projection generator.

Additional generator reconciliation finding: the three `build-scenario-*`
generators omitted GetSummary APIs used by live Strategist, and calibration/
adversarial phase fallback selected the last `pairs` row. KWR-286 now restores
generator parity with Lua templates, shared deterministic indexes and a complete
regeneration check. Source and `generation-availability-20260906-package`
extracted runtime/knowledge checks pass. The current scenario-generation and
knowledge audits reconfirm this source authority. The installed compact projections
cover selected IDs only and omit map-summary fields exercised by source tests; they
are explicitly rejected from recovery.

# Rollback

Restore affected files from the preserved source snapshot and base commit as a
bounded change. Restore installed addons and compatible SavedVariables together
only if a later deployment needs rollback. Never replace historical tags or ZIPs.
