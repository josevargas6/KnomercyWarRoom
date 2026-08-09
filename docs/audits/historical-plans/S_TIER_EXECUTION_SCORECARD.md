# Historical: KWR S-Tier Execution Scorecard

`RELEASE_VISION.md` owns release scope and sequencing. This scorecard owns
Commander subsystem estimates and proof requirements only. The current
candidate is `6.1.0-alpha.28`; older alpha numbers in retained progress notes
are historical implementation milestones.

This scorecard is the strict companion to `PILLAR_EXECUTION_SHEET.md`.

Use the pillar sheet to decide **what order** work happens.
Use this scorecard to decide **whether a surface or subsystem is actually good enough**.

Imported planning source also includes:

- `C:\Users\josev\.codex\codex-remote-attachments\019f38e6-581c-7e71-a6a0-1e0593566370\9E719851-D4B8-4B27-A164-AE3DA4F94FAB\1-KWR_Winning_State_Offline_Work_Plan.zip`

If that package conflicts with this scorecard, this file wins because it tracks
the current repo and the latest validated slices.

Current scores are engineering estimates based on the current offline-validated
alpha candidate. They are not marketing scores. Any category that fails live
Retail proof drops immediately and blocks promotion.

Recent retained-system progress:

- Completed the first release-audit execution pass against the repo instead of the handoff notes: exact Store publication semantics, objective-source authority, canonical identity resolution, enemy coordinate truthfulness, and compact secure-surface suppression all now have code repairs plus deterministic coverage.
- Completed the first identity-safety hardening slice across roster, enemy truth, and commander overrides: same-short-name players no longer collapse by default, ambiguous short-name override queries fail closed, and legacy override data is preserved on a migration path instead of being silently discarded.
- Completed the first truthfulness hardening slice for enemy positioning: engagement-only context remains semantic and no longer becomes a fake enemy map position through fallback coordinates.
- Completed the first strategist cache-authority slice: objective-conflict evidence now participates in the decision signature so stale clean-strategy results cannot survive after public objective truth becomes conflicted.
- Completed the first audit-regression coverage slice: smoke now locks exact nested Store publication, same-short-name roster separation, ambiguous override rejection, and engagement-only enemy truth storage.
- Completed the second audit-regression coverage slice: smoke now also locks Reporter stale-friendly pruning, current-state MemoryBudget sampling, post-integrity strategy output, and zero-deficit recovery summaries.
- Completed the release-packaging trust slice at the Alpha 25 milestone: the extracted distribution archive now runs smoke and soak during package audit, the release workflow refuses tag/version drift, and the then-active release metadata pointed at alpha.25 with 277 deterministic checks.
- Completed the first runtime-efficiency observability slice: Verification now skips duplicate heavy entry construction, ordinary friendly health churn no longer queues full refreshes, and Commander command-certification metrics now distinguish repeated evaluations from actually published command changes.
- Completed the first SavedVariables and interruption-policy slice: bootstrap now normalizes malformed persisted fields against typed defaults, journal/learning/encounter/override/opponent-model roots are normalized before module consumption, and active AAR journals now persist a single explicit interrupted outcome instead of vanishing on teardown.
- Completed the first objective-carrier message slice: named flag return/capture messages now clear only the affected flag carrier, while explicit full-reset language uses a separate global reset path proven in smoke.
- Completed the future-schema compatibility slice: newer SavedVariables revisions now trigger explicit read-only compatibility mode so the addon can inspect normalized data without silently downgrading or rewriting the persisted schema.
- Completed the first release-provenance slice: build output now emits source manifests, tool provenance, and reproducibility reports, and two clean builds now prove matching staged payload digests with a documented PowerShell ZIP-container exception instead of an unproven archive story.
- Completed the deterministic timing-proof slice: `tests/soak.lua` now injects a reviewed synthetic cost pattern so average, p95, and max runtime timings have to retain nontrivial percentile behavior instead of passing on flat stub values alone.
- Completed a verification-only truth slice on top of the new objective evidence envelope: `/kwr verify` now exposes per-objective native semantic, selected source, and conflict status for sampled objective rows without adding live HUD clutter or a second interpretation path.
- Completed the first strategist uncertainty gate on top of that evidence: conflicted or non-authoritative objective truth now reduces commitment confidence and suppresses hard macro commits before battlefield calls over-trust weak map-state evidence.
- Completed the first command-stability audit slice: `Commander` now measures the current 2.5-second retention rule, 3-second PvP TTL, bypass classes, churn counters, reversal events, and command lifetimes, and verification exposes those metrics as the baseline for the shared `ActivePlay` engine.
- Completed the first shared `ActivePlay` slice: the existing `Commander`/`Store` path now publishes one authoritative persistent play object with family, objective, movers/stayers, timing windows, lifecycle phase, and success/abort/invalidation metadata, and verification exposes it for technical proof.
- Completed the first publication-control slice on top of `ActivePlay`: `Commander` now tracks candidate preference trends, checks current-play invalidation, and can retain an in-flight active play when a fresh alternative lacks a valid bypass or a proven replacement edge, instead of publishing every new candidate immediately.
- Completed the first explicit switch-cost and node-policy slice: replacement decisions now carry transparent scoring (`current`, `alternative`, `margin`, `cost`), and node-family timing and map-pressure modifiers from reviewed battleground definitions now raise the bar for lateral node swaps and abandoning held node structure.
- Completed the shared override/invalidation slice: decisive invalidation now authorizes explicit replacement, override records are logged with lost commitment time and evidence, verification exposes override/invalidation counters and the latest override event, and node-family hard invalidation now includes at least one concrete rule (`HELD_NODE_LOST`) proven in smoke.
- Completed the review-surface diagnostics slice: finished-match AAR entries now persist command-stability telemetry and the latest override/invalidation record, the AAR window surfaces replacements and override counts in review cards, exports include a dedicated `Command Stability` section, and validate + smoke + soak prove the path.
- Completed the first battleground-aware node-policy refinement slice: node switch cost and superiority margins now incorporate reviewed route distance plus map-specific structure protection for Battle for Gilneas, Arathi Basin, Deepwind Gorge, and hybrid node posture, with smoke proving BFG 2-base holds and Arathi outer-node swaps resist low-value reversals.
- Completed the first flag-family execution-control slice: escort/return/reset plays now use flag-state-aware margins and carry/reset penalties, flag ActivePlay commitments are longer than generic field pressure, decisive flag-state changes invalidate those plays explicitly, and smoke proves a WSG escort play resists low-value mid pressure until the flag state actually changes.
- Completed the first orb-family execution-control slice: center/carry/hunt plays now use orb-state-aware margins and carrier-control penalties, orb ActivePlay commitments remain short but protected from generic pressure churn, decisive orb-ownership changes invalidate those plays explicitly, and smoke proves a Temple center-control play resists a low-value hunt switch until friendly orb ownership actually changes.
- Completed the first cart-family execution-control slice: escort/delay/crystal/lane plays now use cart-state-aware margins and lane-side penalties, cart ActivePlay commitments remain protected from ordinary lane noise, decisive friendly-cart or lane-state collapse invalidates those plays explicitly, and smoke proves a Silvershard escort play resists a low-value lane swap until the cart lane actually breaks.
- Completed the first resource/spawn-family execution-control slice: active-node and next-spawn plays now use resource-state-aware margins and spawn penalties, resource ActivePlay commitments remain protected from speculative opportunity churn, decisive active-node or spawn-state changes invalidate those plays explicitly, and smoke proves a Seething Shore active-node play resists a low-value early spawn swap until the node state actually changes.
- Completed the first family-milestone phase slice: ActivePlay now derives family-specific execution milestones across node, flag, orb, cart, and resource maps and can promote live plays into committed/resolving state from observed battleground truth instead of only timer windows, with smoke proving milestone-to-phase behavior on representative examples from every major family.
- Completed the first family-state explainability slice: ActivePlay decisions now carry family-specific live or terminal state reasons, `/kwr verify` surfaces those reasons directly, and smoke proves the commander can explain why a held flag-family play is still live instead of only exposing abstract retain/replace counters.
- Completed the shared perf-reporting slice for command stability: the performance payload now exposes churn, bypass, lifetime, override, and current ActivePlay state alongside runtime telemetry, so technical review no longer has to cross-check perf output against `/kwr verify` or AAR to understand live command behavior.
- Completed the first local teamfight multi-assignment command slice: safe adapters, rulesets, compliance gate, normalized fact/teamfight state, enemy problem detection, friendly capability profiles, assignment scoring/optimization, kill-target selection, countdown generation, target-assist presenter contracts, and debug reasons now exist as one vertical pipeline. Smoke replay proves Knomercy -> Subdue Priest-V, Stan -> Subdue Priest-M, and Team -> Kill Warrior-Z in 5 without auto-targeting, auto-casting, macros, focus changes, hidden communication, or spell-specific commander instructions.
- Completed the Commander gap-closure implementation pass from `docs/KWR_COMMANDER_GAP_CLOSURE_DESIGN_PATH_2026-07-15.md`: local teamfight intelligence now has a read-only `BoardState` compatibility view, bounded evidence summaries, expanded enemy-problem taxonomy, a data-driven `CounterplayMatrix`, objective/locality-aware assignment scoring, safe DR confidence propagation, ruleset-owned decision/optimizer policy, deterministic bounded assignment optimization, universal assignment reasons, and kill-target selection that accounts for resolved support-control coverage. Validate, knowledge audit, smoke, soak, build, and package audit all pass.
- Completed the compact battlefield identifier offline slice: the existing nameplate presenter now uses friendly role icons, enemy class icons, carrier-specific flag/orb replacement, target-only health, active-priority-cast-only progress, transparent framing, and safe UNKNOWN fallbacks. Refresh cadence is 4 Hz and non-target health reads are removed; live carrier and density screenshots remain the sign-off gate.

## Scoring scale

- `10.0` = repeated live proof, no visible weakness in normal use, trusted for release.
- `9.5` = release-candidate quality; only minor tuning remains.
- `9.0` = strong alpha quality; real users can test it without excuse-making.
- `8.5` = acceptable offline alpha gate; live proof still required.
- `8.0` and below = materially incomplete for a premium tactical addon.

## Global release rules

No category is considered `S-tier` unless all of these are true:

- truth is correct or explicitly unknown;
- no combat taint or protected-action regression exists;
- refresh behavior stays bounded in soak conditions;
- visuals remain readable at `1280x720`, `1920x1080`, and `2560x1440`;
- visuals remain stable at `0.80`, `1.00`, and `1.15` UI scale;
- labels, abbreviations, and state colors are consistent;
- stale, inferred, and direct evidence are visibly distinct;
- proof exists in screenshots, `/kwr verify`, AAR export, or deterministic test output.

---

## Section A - Surface Scorecard

| Surface | Current | Target | Effort | Owner | Dependency | Proof artifact |
| --- | ---: | ---: | --- | --- | --- | --- |
| Global visual system | 8.9 | 9.5 | 2-3 days | Codex | none | screenshot matrix + copy audit |
| Main dashboard / MainWindow | 9.2 | 9.5 | 2-4 days | Codex | visual system | three-resolution screenshot set |
| Commander HUD | 9.0 | 9.5 | 2-3 days | Codex | visual system | combat screenshot and short clip |
| Reporter map | 9.2 | 9.5 | 4-6 days | Codex + live QA | truth + visual system | evidence screenshots across 3 maps |
| Tactical map | 9.1 | 9.3 | 2-3 days | Codex | visual system | screenshot matrix with assignments visible |
| Combat roster | 9.0 | 9.4 | 2-3 days | Codex | truth + visual system | combat screenshot set |
| Enemy tab / note editor | 9.2 | 9.4 | 1.5-2.5 days | Codex + live QA | opponent models + visual system | hover/click screenshot set |
| Quick calls | 8.9 | 9.2 | 1-2 days | Codex + live QA | stability | battleground click-cycle evidence |
| Options window | 9.1 | 9.1 | complete offline; live visual QA remains | Codex + live QA | feature audit | option inventory with defaults review |
| AAR window | 9.2 | 9.2 | complete offline; live visual QA remains | Codex | learning + export clarity | exported AAR screenshot set |
| Cursor ring / crosshair / local target | 9.2 | 9.3 | offline identifier contract complete; live visual QA remains | Codex + live QA | local target rules | live target/carrier screenshots |
| Minimap button / ring | 8.8 | 9.0 | 0.5-1 day | Codex | visual system | drag and hover screenshot set |
| Status messaging / toasts / alerts | 8.8 | 9.2 | 1-2 days | Codex | commander message hierarchy | alert sequence capture |

Visual audit status update:

- The before/during/after battleground screenshot review is now consolidated in
  `docs/visual-direction/2026-07-15/COMPREHENSIVE_BATTLEGROUND_VISUAL_AUDIT.md`.
- Visual direction is no longer missing; the open work is implementation and
  re-verification.
- The dominant remaining visual blockers are live-combat clutter, support-view
  readability, assignment-page player-facing language, and post-match/AAR hierarchy.
- The 2026-07-15 repair pass closed the biggest offline readability blockers on
  Support View, Assignments, Review/AAR summaries, and verification/export
  dialogs; those surfaces are now in live-follow-up status rather than offline
  blocker status.

### Surface acceptance criteria

#### Global visual system

- one shared spacing scale, header pattern, badge language, status color scale, and text hierarchy exists across commander surfaces;
- identical states use identical visual treatment everywhere;
- no surface uses ad hoc padding, misaligned headers, or one-off badge semantics;
- terminology is standardized across titles, labels, badges, and helper text.

#### Main dashboard / MainWindow

- no title, tab, control, or row overlap exists at supported scales or resolutions;
- current match truth, primary command, and confidence are visible without hunting;
- sections scan in a clear order: situation, command, evidence, roster, enemy, review;
- empty and stale states explain why data is absent;
- commander actions are visually distinct from passive information.

#### Commander HUD

- no tracker bar, title, badge, or button overlap exists;
- the highest-priority battlefield call is readable in under one second;
- urgent states stand out without spamming the user;
- the HUD does not jitter or relayout on rapid refresh;
- drag/reposition behavior is smooth and always persists correctly.

#### Reporter map

- direct sightings, inferred movement, and stale reports are visually different;
- marker layering remains readable during high-density fights;
- objective, route, pressure, and callout information can coexist without clutter collapse;
- the map instantly answers where pressure is, where rotation is, and what commander trusts;
- no fabricated certainty is shown where public APIs do not support it.

#### Tactical map

- assignment overlays, objective state, and strategic callouts do not obscure each other;
- friendly, enemy, contested, and command overlays are distinguishable at a glance;
- node and lane labels remain readable at all supported sizes;
- hover and click affordances expose useful context without covering the map.

#### Combat roster

- role, assignment, pressure, target, and execution state fit without clipping or jitter;
- row ordering feels deliberate and remains stable during combat updates;
- the most actionable roster issue is visually obvious at all times;
- updating badges do not cause row-height or column drift.

#### Enemy tab / note editor

- name, class/spec, threat, trust, note, and last-seen context align consistently;
- note hover and note click behaviors are obvious and not visually overloaded;
- manual notes and persistent model output are visually separated;
- wrapped profile text remains readable and never collides with controls;
- profile badges do not shove other row content out of alignment.

#### Quick calls

- buttons are grouped by commander intent rather than historical implementation order;
- critical calls are easiest to reach;
- every call has clear click behavior and safe feedback;
- repeated use does not create taint, stale state, or misleading feedback.

#### Options window

- every option is grouped into a clear system family;
- every toggle has a concise explanation and a safe default;
- dead, duplicate, or low-value toggles are removed, hidden, or marked experimental;
- dependencies between options are visible rather than implicit.

#### AAR window

- match outcome, why it happened, key swings, and next lessons are the visual hierarchy;
- evidence is separated from recommendations and from unknown facts;
- long text wraps cleanly and remains scannable;
- export/readback does not degrade readability.
- verification and export dialogs do not show template artifacts, ghost lines,
  or clipped note text.

#### Cursor ring / crosshair / local target

- the ring is centered, stable, and proportionate at all scales;
- commander target, local target, and fallback state are visually distinct;
- friendlies default to role icon plus name; enemies default to class icon plus name;
- flag/orb carrier identity replaces the normal icon without duplicating detail;
- KWR health appears only for the current enemy target and cast progress only for an active priority cast;
- UNKNOWN role/class remains neutral instead of guessing;
- the overlay never hides critical nearby combat information;
- battleground-only behavior is respected and arena silence is preserved.

#### Minimap button / ring

- the ring is centered on the button and stays centered while moving;
- hover state and click state are clean and intentional;
- the button never feels visually cheap relative to the addon’s core surfaces.

#### Status messaging / toasts / alerts

- only one primary urgent message competes for focus at once;
- repeated alerts collapse intelligently;
- stale alerts clear predictably;
- severity language and colors match the rest of KWR.

---

## Section B - System Scorecard

| Category | Current | Target | Effort | Owner | Dependency | Proof artifact |
| --- | ---: | ---: | --- | --- | --- | --- |
| Truth and state authority | 9.4 | 9.6 | ongoing | Codex + live QA | live battleground proof | `/kwr verify` capture pack |
| Stability and protected-action safety | 9.1 | 9.6 | ongoing | Codex + live QA | live combat cycle | taint-free battleground cycle |
| Decision quality and doctrine | 9.1 | 9.5 | 3-5 days + live review | Codex + live QA | truth, knowledge freshness | AAR evidence set |
| Enemy intelligence and opponent modeling | 9.2 | 9.4 | 2-4 days + match evidence | Codex + live QA | safe observations + AAR | enemy profile evidence set |
| Assignment engine | 9.3 | 9.4 | 1-2 days + live review | Codex + live QA | role certainty + map truth | assignment audit screenshots |
| Reporter and battlefield awareness | 9.2 | 9.4 | 3-5 days + live proof | Codex + live QA | map truth + evidence routing | reporter comparison pack |
| Local kill-targeting and execution assist | 9.2 | 9.3 | 2-4 days + live proof | Codex + live QA | enemy truth + role logic | local-fight validation clips |
| Commander usability and action clarity | 9.4 | 9.5 | 2-4 days | Codex | surface polish | live command-readability review |
| Verification, diagnostics, and auditability | 9.7 | 9.7 | 1-2 days | Codex | none | deterministic test output |
| AAR, learning, and reviewed memory | 9.1 | 9.4 | 2-3 days + evidence review | Codex + live QA | complete-match truth | exported AAR package |
| Performance and bounded refresh cost | 9.4 | 9.6 | 1-2 days + live profiling | Codex + live QA | stable runtime | soak + profiling notes |
| Knowledge freshness and data governance | 9.2 | 9.6 | 1-2 days | Codex | source review discipline | knowledge audit output |
| Configuration quality and feature discipline | 9.1 | 9.2 | 2-3 days | Codex | options audit | toggle inventory and decision log |
| Release packaging and distribution readiness | 9.6 | 9.6 | 1 day | Codex | QA evidence | build, hashes, extracted distribution audit |

### System acceptance criteria

#### Truth and state authority

- all major surfaces agree on battleground truth or explicitly show unknown;
- faction, score, objectives, roster, and match-end results remain synchronized;
- reporter and enemy systems never contradict stronger authoritative truth.

#### Stability and protected-action safety

- no blocked actions, forbidden secure mutations, or protected-row regressions occur in normal battleground play;
- world, queue, loading, death, rez, match end, and scoreboard transitions do not require `/reload`.

#### Decision quality and doctrine

- command output remains map-aware, evidence-backed, role-aware, and reversible;
- advanced logic never activates when truth or knowledge freshness is too weak;
- AAR review can explain why a decision was made and what evidence supported it.

#### Enemy intelligence and opponent modeling

- enemy rows distinguish roster-known, last-seen, engaged, and directly visible truth consistently;
- persistent player models remain bounded, trust-scored, and clearly separated from live truth;
- weakness and strength notes are useful without pretending certainty.

#### Assignment engine

- role assignment is roster-valid, map-valid, and carrier-valid;
- assignment language matches commander language across all surfaces;
- invalid or contradictory assignments are rejected rather than quietly displayed.

#### Reporter and battlefield awareness

- reporter evidence improves commander awareness without fabricating map truth;
- hotspot, route, and pressure signals are explainable and bounded;
- stale reports age out cleanly.

#### Local kill-targeting and execution assist

- local target logic only uses safe local facts and commander-approved weighting;
- commander target and local target remain clearly separate concepts;
- local target help improves focus without overriding map strategy.

#### Commander usability and action clarity

- the addon makes the next correct action obvious;
- evidence is available when needed but does not bury the command path;
- commander surfaces reward fast scanning rather than deep digging mid-fight.

#### Verification, diagnostics, and auditability

- deterministic tests cover critical pipelines and edge cases;
- `/kwr verify` exposes enough state to diagnose truth, freshness, assignment, and reporter quality;
- failures are explainable rather than mysterious.

#### AAR, learning, and reviewed memory

- match review retains useful truth, recommendations, and observed outcomes without polluting live logic;
- historical memory stays bounded and source-aware;
- reviewed learning remains distinguishable from live battlefield fact;
- command churn, overrides, and command lifetime remain inspectable after the match instead of only during live verification.

#### Performance and bounded refresh cost

- no new system introduces unbounded growth, avoidable polling, or heavy redraw loops;
- high-density battleground use remains smooth enough to trust.
- live field budgets are enforced:
  - memory target `<= 25 MB`, warning `> 28 MB`, fail `> 32 MB`;
  - average refresh `<= 1.5 ms`, p95 `<= 4.0 ms`, fail `> 6.0 ms`;
  - repeated full-refresh rate `<= 2.5 / second`;
  - at most one coalesced follow-up and one settle-refresh pending at a time;
  - average CPU share `<= 1.0%`, repeated peak `<= 3.0%`, fail `> 5.0%`;
- hidden surfaces and export paths do not burn runtime budget;
- redundant truth-chasing refreshes are dropped or coalesced instead of chained.

#### Knowledge freshness and data governance

- release-dated external knowledge cannot silently overrule fresher direct evidence;
- stale reviewed data degrades confidence instead of biasing live recommendations.

#### Configuration quality and feature discipline

- every setting materially improves control, safety, or quality of life;
- dead, redundant, and confusing options do not survive to release.

#### Release packaging and distribution readiness

- builds, hashes, validation, smoke, soak, and knowledge audit pass together;
- release notes and QA evidence match the shipped artifact.

---

## Section C - Execution order

### Performance gap-closure order

These slices are now the explicit offline performance package and should be
worked in this order unless a higher-severity truth or safety bug interrupts:

1. Runtime scheduler hardening
2. Incremental truth pipeline
3. Thin live DTO rewrite
4. Surface work suppression
5. Memory budget enforcement
6. Performance diagnostics parity
7. Release build performance gate

Each slice closes a different failure mode:

- Slice 1 closes refresh storms.
- Slice 2 closes wasteful full recomputation.
- Slice 3 closes hot-path copy bloat.
- Slice 4 closes UI-driven frame-time waste.
- Slice 5 closes retention drift.
- Slice 6 closes performance observability gaps.
- Slice 7 closes release-governance drift.

### Golden-standard comparison parameters

Executive-grade quality for KWR should be judged against these parameters:

1. Truth integrity
2. Runtime efficiency
3. Architectural discipline
4. Product clarity
5. Stability and lifecycle safety
6. Memory and retention discipline
7. UX consistency and polish
8. Auditability and supportability
9. Release governance

Current largest quality gaps against that standard:

1. runtime scheduling and backpressure
2. live performance budget enforcement
3. lifecycle hardening under heavy battleground churn
4. thinner hot-path runtime payloads
5. hard release-gate enforcement for performance and retention

### Current winning-state priority order

This is the active order for the imported winning-state package after applying
completed repo work:

1. capture live Retail evidence for the remaining release gates
2. repair only the field defects uncovered by that evidence
3. rerun the offline validation gates after each field fix

## Recent completed slices

- Completed one performance-control slice: `MatchRuntime` queue scheduling now hard-bounds coalesced follow-up chaining, clears deferred queue state on preemption/manual refresh, and carries smoke/soak coverage for bounded refresh behavior under churn.
- Completed one surface-suppression slice: Store now supports filtered subscriptions, and hidden `MainWindow`, `CombatRoster`, and `ReporterMap` surfaces no longer wake on every publish unless their visibility gate or rendered slice changes.
- Completed one overlay-suppression slice: `HUD` and `CursorRing` now subscribe through filtered Store tokens so live overlays stop waking on unchanged battleground publishes.
- Completed one payload-thinning slice: Store publish now structurally shares unchanged snapshot, prediction, assignment, command, and diagnostics branches instead of reallocating them every refresh.
- Completed one performance-gate slice: soak now enforces offline average/p95/max refresh budgets and zero runtime refresh errors, turning the release package audit into a real performance gate rather than a smoke-only check.
- Completed one retention-unification slice: `MemoryBudget` now owns soft/warning/fail pressure bands, trims live contracts through one path, reapplies bound caps during trims, and checks on filtered Store checkpoints instead of unbounded listener wakeups.
- Completed one command-center routing slice: default launcher, slash `reporter`, compact HUD naming, and presentation behavior now route users toward the command-center path first, with the standalone reporter treated as a secondary surface.
- Completed one command-center minimize slice: the tactical board now collapses back to the compact command-center path instead of defaulting to the standalone reporter, and the tactical intel panel now presents as embedded battlefield intelligence instead of a competing reporter surface.
- Completed one command-language alignment slice: launcher/menu copy, HUD mode labels, and command-center options text now use the command-center model consistently instead of mixing legacy dashboard/reporter naming.
- Completed one shared-command-copy slice: `CallerText` and assignments-plan secondary detail now follow the same `ACTION / WHO / TRIGGER` command family instead of mixing `CALL`, `MOVE`, and `STAY` legacy phrasing.
- Completed one command-review hierarchy slice: the explain/export report now leads with a bottom-line `ACTION / WHO / HOLD / TRIGGER` summary before deeper reviewed rationale, and smoke coverage now guards that layout.
- Completed one presentation-policy slice: the presentation controller now honors the `autoReporter` preference during restore, so the standalone reporter remains a truly secondary surface unless the user explicitly allows it to reopen.
- Completed one secondary-language cleanup slice: the support reporter now reads as a plain supporting battlefield view instead of a competing analyst product, and the command-review/export payload now uses more battleground-facing headings in place of several internal-model labels.
- Completed one live-surface wording slice: the HUD, tactical page, objectives summary, and assignments summary now prefer plain battlefield `read` / `view` wording over internal reporter/certainty phrasing while preserving the same decision logic.
- Completed one shell-ownership slice: the main board, launcher tooltip, launcher menu, and top-level review tab now use command-center/support-view/review ownership language so secondary surfaces read as subordinate support paths rather than competing live products.
- Completed one command-shell proof slice: smoke now guards the top-level shell naming contract for the review tab, tactical headline, and launcher support-view entry so that this cleanup cannot silently drift back.
- Completed one release-governance sync slice: the release-gate board and QA checklist now reflect the current command-center/review naming, current smoke count, and current offline-pass posture instead of trailing older candidate language.
- Completed one objective-evidence slice: `Sensors` objective rows now preserve native widget semantics, source evidence, lineage roots, TTLs, and field-resolution metadata without breaking the generic objective contract consumed by the existing runtime.
- Completed one configuration-discipline slice: the options surface now groups only live functional toggles by system, refreshes current state on open, and removes duplicate/dead option exposure.
- Completed one local-target clarity slice: local-fight target data is now explicit in the combat model and presented as `LOCAL TARGET` / `COMMAND PIVOT` rather than implying one global kill call.
- Completed one enemy-intelligence depth slice: opponent models now emit structured learned traits, commander takeaways, and bounded advisory assignment modifiers; enemy notes now support local structured tags that survive pruning; Reporter now exposes a plain battlefield read contract; and Options now exposes inventory/layout audit data proven by smoke.
- Completed one reporter-clarity slice: the reporter runtime now exposes visible/recent/stale enemy track quality and route memory, while the reporter map and tactical map now surface trust pace, route patterns, and evidence quality more directly.
- Completed one launcher-polish slice: the minimap launcher now uses centered ring geometry, state-aware visual treatment, and improved tooltip/status feedback instead of the off-center tracking-border chrome.
- Completed one premium-visual slice: TacticalMap now reserves dedicated header/footer rails, ReporterMap now carries a briefing card plus denser bottom cards, MainWindow now exposes one shared command/truth/reporter/doctrine header rail, CombatRoster now uses a larger spotlight lane, and CursorRing now uses readable caption plates and larger nameplate orbs.
- Completed one options-dependency slice: dependent toggles now disclose their parent-system requirements instead of behaving like standalone controls.
- Completed one quick-call intent slice: fixed battleground calls now expose commander-intent grouping and tooltip guidance rather than reading like an unstructured button wall.
- Completed one reporter-footer slice: the reporter surface now uses stable map anchoring plus explicit trust/coverage legend text above the truth cards.
- Completed one tactical-footer slice: the tactical board now surfaces reporter trust/coverage/intent in a dedicated footer line without burying it inside the map body.
- Completed one reticle-clarity slice: the target reticle now distinguishes local target, command target, and swap-local states, and stays silent on non-player battleground targets.
- Completed one shared-badge slice: core surfaces now reuse one bounded badge treatment instead of inventing separate status chrome per window.
- Completed one dashboard header slice: the main board now surfaces current command state and headline action in the global header instead of hiding it inside the active page.
- Completed one roster-readability slice: combat spotlight state is now badge-driven and pane headings summarize local/direct/stale pressure more clearly.
- Completed one alert-hierarchy slice: the compact HUD now exposes a dedicated alert-severity badge so urgency is visible without reading the full sentence first.
- Completed one AAR-summary slice: the review window now surfaces result, review completion, export readiness, and the next lesson before the longer evidence blocks.
- Completed one enemy-toolbar state slice: the tracker header now shows whether the surface is live, preview, or formation-only instead of burying that state in body copy.
- Completed one enemy-toolbar summary slice: the tracker header now summarizes direct, recent, stale, and noted enemy coverage at a glance.
- Completed one enemy-note truth slice: enemy note tooltips now separate live truth from manual note and learned-model context.
- Completed one enemy-note editor badge slice: the note editor now surfaces seen-state and model-trust badges before the longer profile text.
- Completed one reporter trust-header slice: the reporter surface now exposes trust state as an explicit header badge instead of only inline text.
- Completed one reporter forecast slice: the reporter surface now surfaces projected pace/status in a dedicated forecast badge.
- Completed one reporter card-state slice: reporter cards now mark when pressure or route/event sections are quiet or empty instead of looking silently blank.
- Completed one intel-summary badge slice: the learning library now surfaces matches, reviewed count, and latest match state as top-line badges.
- Completed one intel-review badge slice: the intel review card now surfaces latest result, review state, and export readiness before the body text.
- Completed one launcher-menu state slice: the launcher menu now carries a command-state badge and compact summary so it does not feel detached from live command truth.
- Completed one objectives-state slice: the objectives page now surfaces projected state and objective-truth status as dedicated top-line badges instead of burying them in body text.
- Completed one objectives-urgency slice: win-condition urgency and prediction confidence are now visible before the condition body text.
- Completed one team-readiness slice: the team page now surfaces ready/open-slot/readiness state as top-line badges rather than only paragraph copy.
- Completed one assignments-state slice: the assignments page now exposes command state, coverage health, and commander-lock status as dedicated badges.
- Completed one assignments-logic slice: the logic card now marks when overrides are active instead of silently mixing override and baseline logic.
- Completed one verification-contract slice: `/kwr verify` now exposes the live truth contract, aggressive-commit eligibility, and evidence coverage explicitly.
- Completed one verification-target split slice: `/kwr verify` now separates local target from commander target instead of collapsing them into one field.
- Completed one verification-reporter-trust slice: `/kwr verify` now reports reporter trust label, pace, and rationale directly.
- Completed one reticle-observation slice: observed-target reticle state now carries more target context even when no local or command target is active.
- Completed one roster/dashboard consistency slice: combat spotlight, enemy tracker emphasis, and tactical card sizing now follow the same local-target truth model, with clearer idle copy and less cramped command cards.
- Completed one compact-HUD readability slice: the HUD now has more top-rail breathing room, larger command sections, and a less cramped local-target / full-call layout.
- Completed one sentinel packaging and test-coverage slice: smoke now certifies the Sentinel relay path, and the build/package audit now stages and verifies the Sentinel artifact correctly.
- Completed one AAR evidence-surface slice: the AAR window now exposes match snapshot, decision-review, and evidence-summary cards so review quality matches the runtime evidence already being recorded.
- Completed one status-feedback slice: quick calls now use clearer transient send/copy/block feedback with safe reset behavior, and the compact HUD now exposes one collapsed alert line for the latest high-value battlefield change.
- Completed one enemy-tracker clarity slice: enemy note badges now expose manual-note plus trust state, tooltip hierarchy separates manual note from learned model output, and the note editor surfaces persistent model detail in a cleaner commander-readable summary.
- Completed one tactical-map hover-context slice: map markers now expose bounded hover context for objectives, friendly tracks, enemies, carriers, flags, and vehicles so the commander can inspect local truth without leaving the map.
- Completed one tactical-header rail slice: the tactical map now exposes command state, trust, coverage, and objective-source badges plus a local/pivot/hot context rail above the map body.
- Completed one quick-call rail slice: quick calls now expose intent-group badges, per-button group labels, and a dedicated ready/send/blocked status rail instead of one flat muted line.
- Completed one HUD truth-status slice: the compact HUD now surfaces truth authority separately from alert urgency so state quality is visible without reading the body text.
- Completed one combat-spotlight truth slice: the combat spotlight now carries an explicit truth-source badge in addition to its action-state badge.
- Completed one launcher truth-summary slice: the launcher menu now surfaces both command-state and live-truth badges before the action list.
- Completed one comp-threat slice: the strategy path now classifies the enemy plan into reviewed threat archetypes instead of relying only on generic enemy composition labels.
- Completed one defense-model slice: the strategy path now models likely bunker, escort, trap, and split-defense shells before selecting opener and recovery branches.
- Completed one opener-doctrine slice: KWR now carries reviewed opener branch libraries per map instead of one implied opening shape.
- Completed one recovery-doctrine slice: KWR now carries reviewed `ABANDON` / `REINFORCE` / `TRADE` / `RESET` branches per map for failed-open and failed-fight states.
- Completed one endgame-doctrine slice: KWR now carries reviewed protect/stall/punish/force/desperation branches per map rather than relying on generic urgency wording alone.
- Completed one doctrine-fixture slice: deterministic scenario fixtures now certify doctrine branch selection contracts offline.
- Completed one verify-doctrine slice: `/kwr verify` now surfaces the active doctrine class, doctrine branch, and enemy model directly.
- Added one performance-budget strategy slice to the work plan: KWR now has explicit field budgets for memory, refresh cadence, queue churn, and CPU use, plus a defined execution order for a truth-preserving efficiency pass.

Work categories in this order unless an urgent regression forces a detour:

1. Truth and state authority
2. Stability and protected-action safety
3. Decision quality and doctrine
4. Enemy intelligence and opponent modeling
5. Assignment engine
6. Reporter and battlefield awareness
7. Local kill-targeting and execution assist
8. Commander usability and action clarity
9. Surface polish workstreams
10. Configuration quality and feature discipline
11. AAR, learning, and reviewed memory
12. Release packaging and distribution readiness

## Section D - Proof package required before calling a category complete

Every category closed by Codex should attach or reference:

- the code change;
- the acceptance criteria it satisfies;
- deterministic validation output when available;
- live proof still required, if any;
- the exact reason the score moved.

If a category cannot produce proof, the score does not move.
