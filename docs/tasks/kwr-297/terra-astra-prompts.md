# Copyable Terra execution and Astra rebuild/review prompts

These prompts are for tasks the owner chooses to start. Creating this file does
not start another Codex task, change model settings or authorize deployment.
Use canonical source `C:\Users\josev\source\repos\KnomercyWarRoom`, not AddOns.
Select the named model/effort in the app before sending the corresponding prompt.
If it is unavailable, report that fact; do not claim a model switch occurred.

The package contracts contain the detail, so each prompt stays focused on outcome,
scope, code context and verification. That structure follows
[OpenAI's Codex prompting guidance](https://learn.chatgpt.com/docs/prompting).
Medium/High work allocation and the Astra review rubric are project-specific
engineering choices, not an OpenAI guarantee of equivalent reasoning or results.
The instruction separation also follows the emphasis on clear task boundaries
and verification in [official model guidance](https://developers.openai.com/api/docs/guides/latest-model).

## Terra High — start and complete the engineering track

```text
Work in C:\Users\josev\source\repos\KnomercyWarRoom using GPT-5.6 Terra with
High reasoning. Implement the Terra-owned engineering track in
docs/tasks/KWR-297-s-tier-completion-packages.md. Read AGENTS.md,
RELEASE_READINESS.md, the shared execution standard and verification contract,
then the current package and its actual production callers before editing.

Begin with P00 baseline/recovery accounting, P01 contracts and P07 measurement
scaffolding. Proceed through runnable packages in the documented dependency order.
Use existing KWR-281 and KWR-295 records; do not invent another planner, Store,
review ledger or roadmap. Preserve all prior dirty work and fixed regressions.
For every missing behavior: reproduce it, add the failing production-path test,
implement the smallest coherent fix, run negative/mutation and relevant integrated
tests, and preserve exact source/input hashes, commands, exit codes and receipts.

P13/KWR-298 is the owner's Astra-led full commander-card rebuild. Do not restyle
or overwrite its HUD/projection files concurrently. You own P14/KWR-299 feedback
schema and outcome/learning qualification if Astra is not implementing it jointly;
coordinate the tested interface through the repository task evidence. Left click
means NOT_FOLLOWED, right click FOLLOWED; neither means SUCCESS or automatically
attests verbal delivery. Include identity races, undo and corrections.

Continue independent CODE work when another package needs an interface or human
field evidence. Do not stop merely because WoW testing is unavailable, and do not
conceal missing implementation as FIELD. Escalate an unresolved shared contract
with a concrete counterexample; do not guess protected API permission or mechanics.
Current official API/patch review is a distinct recorded requirement if offline
access prevents it. Never waive a gate, fabricate review or promote fallback
replays to primary to make results green.

Do not change the installed alpha12-fieldfix-20260909-1 candidate, SavedVariables,
published artifacts, remote services or user model settings. Do not create tasks
or subagents automatically. Do not reset or commit the dirty tree wholesale.
Formal release clean-source approval follows the normal repository process.

Before claiming your track complete, audit every assigned acceptance ID, run the
appropriate full source/extracted checks, update task and RELEASE_READINESS status,
and produce one evidence index for Astra review. Report implemented behavior,
verified gates, remaining Astra/interface work, and separate REVIEW/FIELD/RELEASE
obligations. Do not claim S-tier certification from code completion.
```

## Terra Medium — one explicit approved slice

Replace the bracketed assignment before sending; P07-M measurement expansion is
a useful initial Medium slice. Medium is not a weaker acceptance standard.

```text
Work in C:\Users\josev\source\repos\KnomercyWarRoom using GPT-5.6 Terra with
Medium reasoning. Implement [PACKAGE ID AND APPROVED SUBSLICE] from
docs/tasks/KWR-297-s-tier-completion-packages.md. Read AGENTS.md, the package,
docs/tasks/kwr-297/execution-standard.md and
docs/tasks/kwr-297/verification-and-review.md first.
Inspect its actual owner/callers and dependency contracts; preserve existing work.

Implement the specified behavior rather than writing another plan. Add failing
production-path assertions, make bounded edits, test positive and negative cases,
and record source/fixture/tool hashes with actual commands/results. Use the same
correctness, uncertainty, identity, migration and performance standards as High.
Do not invent an unapproved state machine, scoring rule or API permission.

If a required shared contract is ambiguous, provide the conflicting inputs and
expected behaviors, finish independent test/tooling work, and hand that contract
to High. Do not label unrelated CODE blocked by missing live sessions. P13's
primary HUD/card rebuild belongs to Astra; do not edit its owned files in parallel.

Keep the current AddOns candidate and SavedVariables untouched. No publication,
remote changes, task/subagent creation, broad commits or source reset. Complete
the assigned acceptance cases and relevant integrated gates; update package
evidence and readiness honestly. Return a reviewable diff, receipts, rollback and
exact remaining work. A PASS marker without the required behavior is not closure.
```

## Astra — complete commander-card rebuild and followthrough integration

This is the recommended prompt for the user's newly prioritized UI work.

```text
Work in C:\Users\josev\source\repos\KnomercyWarRoom using GPT-6 Astra.
Implement docs/tasks/KWR-298-commander-callout-card-rebuild.md completely and
integrate docs/tasks/KWR-299-command-followthrough-feedback.md. Read AGENTS.md,
RELEASE_READINESS.md and KWR-297's shared execution/verification contracts first.
Preserve all existing dirty work and the installed field-test candidate.

This is a full visual and information-architecture rebuild of the real fight HUD
and mini-command projections, not a color/font patch or an edit only to the small
TeamfightCommandCard builder. Trace HUD.lua, CommandView:FightNow, execution
projection and actual mini-card consumers. Reproduce long-name clipping first.

Build one complete verbal-call card with clearly distinct strategic NOW, observed
versus ordered position, NEXT destination/trigger, all movers/stayers/reserve,
local pressure/kill target and local CC assignments. Generate complete SAY NOW
text from the same structured revision. Keep names/actions/locations/conditions
readable without tooltips or hidden scrolling. Use measured wrapping and adaptive
height/width; test long names, duplicate realm identities, 8/10 actors, every
valid CC row, supported resolutions/scales and locales. Never shrink essential
text into unreadability or invent unavailable position/target facts.

Implement left-click NOT_FOLLOWED and right-click FOLLOWED on noninteractive card
areas, bound to the exact issued verbal-call identity/revision. Prevent drag,
child-control and command-change race errors. Show confirmation and Undo. Preserve
separate delivery, manual adherence, observed result and manual outcome. A click
must not mark SUCCESS, cause gameplay, send chat, or directly award learning credit.
Test bounded persistence, corrections/reload, generated/Diagnostic/Spectator cases
and wrong-session feedback. Preserve existing public observation qualification.

Reuse the existing planner, Store and secure roster layer. No automatic gameplay
or forbidden combat mutations. New layouts and click handlers must be safe in
mock combat; actual client safety remains separately measured. Complete all
offline implementation and test work possible without waiting for the broader
planner overhaul; use honest unknown states for unresolved upstream capabilities.

Inspect real visual artifacts, not just code. Deliver before/after renders, bounds
and content-survival tests, the exact diff, source-bound regression receipts,
profile/schema migration and rollback instructions. Update readiness/task status
without claiming FIELD or S-tier proof. Do not install, publish, change live saved
data, create tasks/subagents or modify model settings without a separate request.
```

## Astra — evidence-based engineering review

```text
Review the completed KWR-297 package(s) and KWR-298/KWR-299 implementation in
C:\Users\josev\source\repos\KnomercyWarRoom against their actual acceptance
criteria and docs/tasks/kwr-297/verification-and-review.md. This is a review request, not
authorization to edit runtime, install, publish or change SavedVariables.

Read AGENTS.md, RELEASE_READINESS.md, the assigned contracts, actual diff and
evidence index. Inspect real production callers and test/fixture provenance.
Independently rerun targeted regressions, challenge missing/secret/stale facts,
identity/clock ownership, impossible assignments, cancellation, data loss and
package drift. For the card, inspect rendered long-name/scale fixtures and verify
complete NOW/NEXT/local-fight/CC speech plus exact-call click/undo behavior.

Return ACCEPT CODE, CHANGES REQUIRED or INSUFFICIENT EVIDENCE per package. Every
finding must identify its file/function, impact, counterexample and decisive
regression. Separate actual code defects from absent client/human/publication
evidence. Do not accept synthetic timings as client speed, generated labels as
independent tactical review, or FOLLOWED as SUCCESS. Do not award S-tier based
on suite markers or a visually attractive screenshot alone.
```

## Handoff format

Every executor/reviewer returns: package IDs and scope; completed behaviors;
changed files; exact test/evidence index; actual failures/limitations; safe rollback;
and the next independently runnable work. No percentage-complete estimate is
required. A precise unfinished acceptance ID is more useful than an invented grade.
