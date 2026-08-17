# Release Readiness - 6.1.1-alpha.1

This is the sole current-version, blocker, and promotion-status authority.
GitHub committed content is the canonical development source; the live AddOns
folder is deployment evidence only after package-manifest verification.

## Current decision

**6.1.1-alpha.1 is the local Season 2 release candidate; 6.1.0 remains the
immutable public stable baseline.** The candidate integrates the five reviewed
post-stable commits, the active Retail 12.1 knowledge review, deterministic ZIP
repair, and release-audit hardening under a new Commander/Sentinel version.
It is not authorized for publication from this local branch. Promotion requires
a green reviewed merge, exact tag, protected `production` approval, matching
public artifacts, and the production-authority evidence listed below.

The 2026-08-15 owner direction explicitly accepted 6.1.0 promotion with the previously
recorded live-evidence gaps carried as refinement telemetry. It does not assert
new 6.1.1-alpha.1-bound battleground sessions or ten-client Sentinel transport
proof. The official 12.1 compatibility/hotfix review is now active, while the
stale 12.0.7 ladder snapshot, inferred numerical tuning weights, and provisional
Season 2 formations remain excluded from live meta influence. The candidate
must still pass validation, deterministic Lua tests, package extraction/audit,
Commander/Sentinel version parity, checksums, protected production approval,
and rollback-artifact creation.

Alpha 43 remains the last published prerelease baseline. Its protected run
completed on 2026-08-14 from commit
`734254c98371cf9dc00235a58ed884de3000ec69`; CurseForge accepted Commander file
`8650550` and Sentinel file `8650551`, and both release announcements succeeded.
The stable cutover must generate new receipts and must not reuse those IDs or
hashes. Render remains separately evidenced at Sentinel-bot commit
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

Five complete Retail battlegrounds were reported with no observed errors, but
they ran on an external PC. On 2026-08-11 the product owner authorized this
evidence gap for the Alpha 41 release: `LIVE-TEAM-TRUTH`, `LIVE-STABILITY`,
`LIVE-CARRIER-TARGET`, and `LIVE-READABILITY` are no longer release blockers.
They are refinement telemetry until the external SavedVariables journal and
associated screenshots or logs are imported. This authorization is recorded in
`knowledge/field-verification-attestation.json`; it does not certify cross-PC
Sentinel, which retains its separate ten-client safety/value refinement proof.

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
- no internal release blockers remain under the explicit Alpha 41 product-owner
  authorization; live stability, taint/safety, field-performance proof,
  screenshot matrix, supported-map certification, official 12.1 tuning review,
  and release presentation are refinement telemetry;
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

### Truth as of 2026-08-15

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

### P0 cutover register — complete before public Season 2 promotion

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
