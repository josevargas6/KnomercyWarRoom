---
id: KWR-297
title: Complete RBG commander quality through Terra packages and an Astra callout rebuild
owner: unassigned
priority: high
risk: high
status: in_progress
dependencies: [KWR-281, KWR-295]
affected_modules: [Core, State, Adapters, Runtime, Intelligence, Data, UI, KWRSentinel, tools, tests]
authority_references: [AGENTS.md, PRODUCT_ROADMAP.md, RELEASE_READINESS.md, RELEASE_POLICY.md]
---

# Objective

Turn the remaining commander-quality requirements into bounded, implementable
packages for GPT-5.6 Terra Medium and High, with the acceptance standard requested
of Astra, plus the explicitly requested Astra commander-card rebuild and safe
click feedback. This is an execution specification under the existing OVR/REC program,
not another competing roadmap or a claim that an S-tier product already exists.

The September 10 execution request authorizes source implementation. P13/P14
are the first active integration slice; the other packages remain planned. Do not replace
the installed field candidate while preparing or executing source-only packages.
No automatic publication, account/service work, task creation or delegation is
authorized by this document. Copyable execution prompts are provided separately.

# User outcome

A commander can trust the facts, understand an actionable call quickly, assign
reachable players without abandoning mandatory coverage, react to real changes,
and review what was actually delivered and observed. The product must demonstrate
that usefulness under combat load; a large feature list is not the acceptance test.

# Current behavior and evidence limits

Inspection date: September 10, 2026. Source:
`C:\Users\josev\source\repos\KnomercyWarRoom`; substantial pre-existing dirty work
on base `bcce7f585a2609ad60e0c84e872e959380b3375b` is preserved. Re-read source and
status at execution time; this inventory is not a permanent claim about HEAD.

The installed `alpha12-fieldfix-20260909-1` has verified archive parity, targeted
regressions and isolated rollback proof. Its actual client and tactical results
remain separate. Do not reintroduce fixed R01-R06 defects or remove KWR-296 tests.

Observed implementation seams motivating the packages:

- `FactStore:FromSnapshot` emits context/friendly/enemy facts; objective and score
  contract completion still needs end-to-end ownership. `BoardStateBuilder:Build`
  currently derives objective identity from row names/labels and index-based
  evidence IDs, without projecting every objective's observation/expiry field.
- `Reporter:ObjectiveETAs` uses scalar straight-line/estimated travel values;
  `ObjectiveRules` contains family legality and coverage policy, not by itself
  complete, reviewed transition engines for every objective family.
- `AssignmentOptimizer:Optimize` filters availability, then scores candidates;
  physical reach, capability and collective coverage need a shared hard contract.
- `Commander` already has active-play stability and explicit delivery identity.
  `CommandReview` separates delivery/execution, but family-specific observed
  outcome production and conservative aggregation are still required.
- `host-performance.lua` now measures actual host time; the wider instrumentation,
  workload/percentile evidence and optimization requirements remain open.
- Fresh replay supports an extracted addon root and a semantic comparator exists.
  The comparator currently does not establish complete input/label provenance,
  and the old full corpus is not a passing result for the repaired candidate.
- `certify-offline.ps1` runs the repaired host benchmark, but still lacks the
  entire strict fresh source/package corpus and clean-release gate integration.

# Required behavior: package index

P13/P14 are **IN_PROGRESS**; the other packages are **PLANNED**. No package is
implemented merely by writing its document, and no review/field/release gate is closed.
P00-P14 are work-package IDs inside KWR-297, not new addon components. Existing
KWR-281 recovery decisions and KWR-295 replay reviews retain their ownership.

| Package | What must be completed | Existing requirements | Recommended lead |
| --- | --- | --- | --- |
| [P00](kwr-297/P00-source-recovery.md) | Close source recovery and establish exact evidence boundaries | OVR-01; KWR-281; REC-01..09 ledger | High decisions; Medium ledger/tests |
| [P01](kwr-297/P01-facts-context-capabilities.md) | Typed facts, identity, age, session/bracket and API capability gates | OVR-02/06/07/16 | High |
| [P02](kwr-297/P02-objective-engines.md) | Legal, map/bracket-specific objective transition engines | OVR-13 | High contracts; Medium reviewed data/fixtures |
| [P03](kwr-297/P03-routes-assignments-formation.md) | Honest route intervals, hard assignment feasibility and formation | OVR-04/14/17 | High |
| [P04](kwr-297/P04-tactical-alternatives.md) | Feasible alternatives, counterplay and truthful target intent | OVR-03/15 | High |
| [P05](kwr-297/P05-command-lifecycle-secure-ui.md) | One command lifecycle, deadline and secure identity contract | OVR-05/12; REC-07 | High integration; Medium projections/tests |
| [P06](kwr-297/P06-aar-outcomes-learning.md) | Decision-level outcomes, bounded AAR and conservative learning | OVR-18; REC-07/08/09 | High |
| [P07](kwr-297/P07-performance-scheduling.md) | Real profiling, event responsiveness and measured work reduction | OVR-09/10; REC-01/02/03/05/06 | Medium measurements; High scheduler/ownership |
| [P08](kwr-297/P08-memory-persistence-packaging.md) | Bounded memory, safe migration and compact runtime parity | OVR-11; REC-04/08/09 | High schema; Medium bounds/build fixtures |
| [P09](kwr-297/P09-commander-ux.md) | Surrounding UI, help, localization and accessibility; main card owned by P13 | OVR-19 | Medium after contracts; High semantic review |
| [P10](kwr-297/P10-sentinel-protocol.md) | Optional, bounded, authority-safe Sentinel communication | OVR-08 | High protocol; Medium adversarial fixtures |
| [P11](kwr-297/P11-replay-certification-release.md) | Strict replay adjudication, provenance, certification and release gates | OVR-20/22; KWR-295 | High |
| [P12](kwr-297/P12-field-quality-comparison.md) | Candidate-bound field evidence and independent comparative assessment | OVR-21 | Medium tooling; High validity review; owner FIELD |
| [P13 / KWR-298](KWR-298-commander-callout-card-rebuild.md) | Complete unclipped NOW/NEXT/movers/stayers/local-fight/CC verbal command card | OVR-05/19; September 10 user field feedback | Astra design and implementation |
| [P14 / KWR-299](KWR-299-command-followthrough-feedback.md) | Left-click Not followed / right-click Followed, undo and honest outcome linkage | OVR-18/19; September 10 user feedback proposal | High schema; Astra card integration |

# Technical constraints and shared instructions

Read [execution standard](kwr-297/execution-standard.md) before the assigned
package. It specifies common contracts, clock domains, ownership, proof rules
and forbidden shortcuts. Read only relevant dependency contracts, not every
unrelated implementation document on every turn.

Read [verification and review](kwr-297/verification-and-review.md) for actual
commands, receipt requirements, negative tests and Astra review decisions.
Use [Terra and Astra prompts](kwr-297/terra-astra-prompts.md) to execute or review.
These are engineering quality controls, not guarantees about model capability.
P13/P14 capture the owner's later messages in the same specification request.
The card is a genuine visual/information rebuild, not merely additional styling.

# Execution order and dependency boundaries

Use this order to avoid building UI or scoring around uncertain contracts:

1. P00 records a usable baseline and routes every recovery item; start P01 and
   P07 measurement scaffolding. P00 need not wait for all REC implementation to
   start these packages, but cannot close until routed rows actually close.
2. P02 implements objective contracts; P03 builds route/assignment feasibility.
   P10 can proceed after P01's context/capability interface is stable.
3. P04 consumes P01-P03; P05 completes command and secure projection integration.
4. P06 and P08 consume stable identity/lifecycle contracts; P07 optimizations use
   real measurements and semantic comparisons. P09 consumes those projections.
   P14 defines adherence records with P06; Astra P13 owns their primary card UI.
5. P11 can implement its harness early using intentionally failing test data;
   final full-corpus execution waits for a frozen integrated source. P12 capture
   tooling can also be built early, without claiming live results.
6. Close P00's remaining ledger rows, complete integrated P11, obtain engineering
   review, then obtain the owner/client and independent reviewer results in P12.

Implementation dependencies mean a tested interface, not upstream FIELD approval.
Avoid circular blocking: P06's episode schema is the input to P08 migration;
P08's bounds feed P06 retention tests; neither waits for match wins. P11's early
harness validates failures before other packages are complete. A single writer
owns overlapping files; do not run concurrent agents in this dirty checkout.

User-priority visual track: Astra can start P13's reproduction, structured
projection and layout fixtures immediately against the known field candidate,
with explicit unknown states. It need not wait for the entire planner overhaul.
P14's schema precedes click integration; final P13 acceptance consumes approved
P01/P03/P05 semantics. Terra must not simultaneously edit Astra-owned HUD/card
files. Update the shared code consumer map when ownership changes.

# Milestones and truthful status

| Milestone | Required evidence | What it does not mean |
| --- | --- | --- |
| PACKAGE CODE VERIFIED | All package CODE cases pass with current hashes | S-tier or field approval |
| INTEGRATED OFFLINE VERIFIED | Required CODE and technical review gates, strict corpora, packaging and restore pass | Live client performance or tactical superiority |
| FIELD VERIFIED | Bound client safety/performance/usability results pass the existing matrix | Comparative leading claim or publication authority |
| COMPARATIVE STANDARD MET | Required independent reviews and baseline comparisons support the stated scope | Universal best addon or guaranteed wins |
| RELEASE APPROVED | All required evidence plus normal protected release authorization | Permission inferred from a local build |

S-tier is a quality judgment supported by the last two evidence milestones,
not a runtime flag or a score the implementing agent may award itself. Coding
can enable that outcome; it cannot manufacture the human/client observations.

# Acceptance criteria

- [ ] P00-P11 CODE obligations, P12 capture/review tooling and P13/P14 rebuild/
      feedback implementation are complete,
      source-bound and reviewed; all OVR/REC requirements have explicit closure.
- [ ] No generated coverage count, fallback-only replay or missing observation
      is relabeled as tactical quality or a passing live measurement.
- [ ] One frozen candidate passes current source/extracted semantic equality,
      clean release provenance when applicable, and install/upgrade/restore.
- [ ] Required client, tactical and independent comparative evidence is retained
      with denominators and limitations, not replaced with model self-review.
- [ ] RELEASE_READINESS accurately separates CODE, REVIEW, FIELD and RELEASE.

# Verification

Package authors execute the shared verification recipe and their exact negative
cases. Reviewers rerun selected failures independently and inspect actual loaded
paths. The specification itself is checked for valid task identity, working file
links, OVR-01..22 coverage, existing code seams and clearly labeled proposed APIs.

Specification delivery: complete on September 10; implementation status remains
PLANNED. No runtime modifications, deployment, or product certification is part
of that document-delivery status.

# Rollback and non-goals

Preserve the installed field candidate, pre-existing dirty changes and all
SavedVariables. Each implementation package needs a bounded rollback or safe
feature-off path that does not bypass truth gates. Use the existing deployment
and verified restoration tooling only under a separate installation request.
Do not add online AI calls, autonomous gameplay, bot/service scope, hidden-data
inference, a second planner or a second Store to satisfy these requirements.
