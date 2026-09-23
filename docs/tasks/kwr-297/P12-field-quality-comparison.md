# P12 — Candidate-bound field proof and independent comparative assessment

Parent: [KWR-297](../KWR-297-s-tier-completion-packages.md).
Read [execution standard](execution-standard.md). OVR-21.
Medium implements collection/review tooling; High reviews measurement validity.
The owner operates WoW; actual independent RBG reviewers provide tactical review.
Capture tooling can start early. Candidate acceptance follows integrated P11.

## What can be coded, and what cannot

Code reliable capture identities, review/import validation, paired comparisons,
sample accounting and readable reports. Do not code a flag that awards S-tier,
generate fictitious matches/reviewers, or count model self-review as independent
competitive evidence. This package must separate its CODE and FIELD/REVIEW work.

## Existing owners

Extend AAR/Verification/performance exports, `tools/outcome-report.ps1`, current
field-blocker/readiness and SavedVariables audit tools. Use `QA_CHECKLIST.md`,
the existing candidate capture matrix and BATTLEGROUND_VERIFICATION. Inspect
schemas before extending; avoid a parallel outcome database.

## CODE implementation

1. Bind each capture to candidate ID/archive hash, client build, map/bracket,
   match/session, role/context, addon/UI profile, enabled capabilities and actual
   observation coverage. Reject incomplete/mismatched identity for certification;
   retain it as unbound diagnostic evidence rather than erasing it.
2. Validate imports as data, never executable Lua. If reading SavedVariables,
   use the established safe parser/audit path, not eval/dofile on untrusted files.
   Keep exports local by default and provide anonymized identity-preserving review
   views; sharing requires explicit owner choice.
3. Build a bounded decision review record: public facts available at the time,
   selected call/jobs/deadline, alternatives, delivery state, observed result and
   reviewer judgment. Preserve harmful overrides, missed deadlines, unsupported
   reversals, warning lead time and unknown cases, not only successful calls.
4. Create a stratified held-out review packet by advertised map/bracket/phase.
   Keep training/development cases separate from held-out evaluation. Where
   practical blind reviewers to candidate/baseline. Record reviewer identity/role,
   disagreements, adjudication and denominators; no invented independent labels.
5. Compare the frozen candidate with a defined prior KWR/native/permitted-tool
   baseline under matched scenario, roster, UI and hardware conditions. Record
   tool versions at test time; do not assert a market ranking from this spec.
6. Keep actual strategic/tactical/Store/display timings, FPS and memory samples
   with warmup, DevTools state, clock and observation coverage. Summarize all
   runs with uncertainty; missing/short samples are NOT_MEASURED/INSUFFICIENT,
   never zero impact. Win rate alone is not causal evidence of addon quality.
7. Extend reports with per-gate status and minimum sample checks. Validate that
   cherry-picked wins, duplicate matches, wrong hashes, unlabeled brackets,
   missing reviewers and unsupported client timings cannot clear a gate.

## FIELD and REVIEW acceptance retained from the roadmap

- Zero fabricated/impossible accepted calls and zero KWR-attributable Lua errors,
  taint or blocked actions in the accepted sample.
- At least 90% of sampled calls judged legal and tactically reasonable, retaining
  denominators/disagreements. Two independent RBG reviewers and comparison
  evidence are required for a comparative leading claim.
- At least 20 complete reviewed matches per advertised map for stable strategic
  certification, stratified by bracket; do not pool Blitz and standard into one
  certificate. Every family needs lead/win and deficit/loss evidence.
- Held-out offline label review covers at least 30 distinct decisions per
  advertised map/bracket across five phases. These are review requirements,
  not a request to invent live queue availability or missing samples.
- Five-second recognition of current call, movement, movers/stayers and personal
  job; the new Astra commander card additionally needs full verbal-call accuracy
  and zero essential clipping in its supported layout matrix.
- Client strategic P95 <2 ms, routine max <=4 ms; tactical and Store/subscribers
  each P95 <=1.5 ms; critical/ordinary display P95 <=250/750 ms.
- Matched FPS loss median <1%, 1% low loss <3%; player memory soft/warn/hard
  25/28/32 MB, growth <1 MB over 30 minutes after comparable warmup/GC.
- Ten queue/exit/reload cycles and 30-minute combat safety; ten physical clients
  only when promoting optional Sentinel remote capability.

These inherited targets are not proof of feasibility on every machine. Failure
requires diagnosis and scoped correction or an explicit product decision, not
silent threshold relaxation. No-field evidence never blocks unrelated CODE work.

## Verification and acceptance criteria

Run import/report tests with valid synthetic records explicitly labeled synthetic.
Reject duplicated IDs, mixed hashes, absent client clocks, fake reviewer metadata,
wrong brackets and hand-picked sample subsets against the declared sampling plan.
Verify scripts fail closed without changing raw captures.

- [ ] CODE tooling correctly binds, preserves, validates and summarizes evidence.
- [ ] Actual FIELD matrix completed with adequate sample counts and no false passes.
- [ ] Real independent REVIEW and baseline comparisons support the stated scope.
- [ ] Inconclusive comparisons remain inconclusive; publication requires RELEASE.

## Current implementation evidence — September 11, 2026

`tools/field-evidence-import.ps1` now accepts only JSON capture data and writes
a separate non-overwriting evidence envelope. It verifies the candidate package
report's actual archive hash, requires candidate/session/map/bracket/client-build
identity, rejects invalid timestamps, wrong candidates, duplicate records and
mixed archive hashes in a review directory. Raw capture files are never edited,
and every accepted envelope remains `UNREVIEWED_FIELD_EVIDENCE` rather than
asserting a field pass. `tools/test-field-evidence-import.ps1` covers valid
binding plus duplicate and wrong-candidate rejection; the full automation suite
passes with 239 checks in `artifacts/kwr297-automation-p12-20260911.log`.

This implements a bounded CODE slice only. No actual capture, reviewer judgment,
baseline comparison, live budget or public-release claim is supplied by it.

On 2026-09-12 the evidence-import and field-readiness-report test suites passed
again, and `knowledge/field-test-readiness.json` was regenerated for the r6
archive hash. It continues to report `candidateSourceBound: false` and
`REQUIRES_RETAIL_MEASUREMENT` because the source worktree is dirty; that is an
intentional safety gate, not a failed field capture.

## Rollback and handoff

Never rewrite raw match records to make a report pass. Keep old report versions
and provenance. Handoff CODE status separately from outstanding owner/reviewer
activities, with exact capture commands and a compact review queue. Astra may
review engineering validity but cannot supply the owner's missing client sessions.
