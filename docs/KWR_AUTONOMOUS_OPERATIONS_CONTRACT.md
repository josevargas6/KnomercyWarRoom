# KWR Autonomous Operations Contract

## Mission

Knomercy War Room operates as a continuously maintained Rated Battleground
system. Codex owns code, tests, repairs, corpus generation, pull requests, and
release evidence. GitHub is the secure source-of-truth and automation ledger.
CurseForge is the public addon distribution hub. Discord Sentinel is a
constrained execution and communication transport controlled by Codex and
GitHub workflows.

Autonomous means the system can collect, classify, test, queue, report, and
prepare changes without waiting for routine manual coordination. It does not
mean bypassing review, inventing live facts, exposing credentials, or allowing
Discord to merge or publish code directly.

## Ownership boundaries

| Surface | Owns | Must not do |
| --- | --- | --- |
| Local workspace + Codex | Lua/PowerShell/docs, repairs, tests, corpus, PRs, release evidence | store production secrets or claim unverified live truth |
| GitHub | source, issues, PR review, Actions, artifacts, provenance, protected secrets | accept direct unreviewed production writes |
| CurseForge | public addon files, moderation, player downloads | serve as source-of-truth for code or metadata generation |
| Discord Sentinel | execute Codex-directed questions, posts, replies, polls, intake routing, and health receipts; return structured community replies | decide what to research, interpret evidence, merge, tag, upload, alter doctrine, or automate gameplay |

## Operating cadence

### Daily

- Codex produces the interaction/support prompt and sends it to Sentinel for
  delivery to the correct Discord channel.
- Sentinel collects the requested replies, redacts disallowed data, groups
  responses by the supplied change/question identity, and returns a structured
  receipt to Codex.
- Codex maintenance checks failed CI, stale evidence, open release blockers,
  CurseForge availability, bot health, and queued Codex-ready issues.

### Tuesday patch/reset cycle

After the weekly World of Warcraft patch and server reset:

1. Codex collects official Blizzard patch/hotfix notes and relevant Retail API
   or restriction changes.
2. Codex compares the changes with KWR adapters, rulesets, maps, supported
   game versions, and current corpus assumptions.
3. Codex creates a dated impact report and repair PRs for verified breakage.
4. CI runs architecture, security, knowledge, Lua, soak, replay, package, and
   release checks.
5. A candidate may be uploaded to CurseForge only through the protected
   environment after the exact artifact is verified.
6. Discord receives a reviewed impact summary with links and known limits.

### Twice-weekly trend reviews

Codex runs two scheduled research windows reviewing:

- official PvP changes and upcoming changes;
- RBG/PvP compositions, builds, class/spec shifts, opening strategies, and
  map play styles;
- player-meta signals from approved public sources;
- support/bug clusters and their effect on command clarity;
- impact on every supported map and current doctrine.

Every brief includes source links, retrieval time, patch/season context,
confidence, corroboration status, and unknowns. Community or leaderboard
signals remain advisory until reviewed and field-tested.

### Weekly corpus and doctrine requirement

Every mandatory weekly update must add at least:

- 10 new deterministic corpus simulations;
- corresponding matrix/scenario coverage;
- labels/results or an explicit reason a scenario is unavailable;
- map, phase, objective, composition, counterplay, success, abort, and review
  metadata;
- at least one review record connecting new evidence to doctrine or explaining
  why doctrine remains unchanged.

Meta composition updates and new opening doctrines must cover the affected
maps, name the source and confidence, state the expected battlefield impact,
and remain reversible until field evidence passes.

## Emergency repair lane

Codex classifies incoming reports as `urgent`, `high`, `normal`, or
`informational`, creates the private GitHub issue, and sends Sentinel a
validated alert command. Sentinel only delivers the alert and returns a
redacted receipt. Codex may start a hotfix branch and run the emergency gate.
CurseForge and public Discord publication still require the protected
production workflow gate.

## Required evidence receipts

Each automated cycle stores a private, structured receipt containing:

- run ID, commit, workflow, timestamps, and source URLs;
- bot commit/image and health state;
- issue/change IDs and deduplication result;
- tests, package hashes, and release asset names;
- CurseForge project/file status when available;
- Discord message IDs and delivery status;
- human approval or reason for holding publication.

Receipts never contain tokens, webhook URLs, raw private chat, or unnecessary
user identifiers.

## Publication gates

No public release announcement is allowed unless:

1. GitHub release and exact artifacts exist;
2. CI and package audit pass;
3. CurseForge returns a valid file ID and the public file is visible;
4. Sentinel health and event deduplication are healthy;
5. Discord copy contains current versions and working links;
6. rollback artifacts and an owner are recorded.

If any gate fails, the system posts a clear hold status to operators and does
not claim that the addon is available.

## Rollback

Freeze public announcements, retain the last-known-good GitHub and CurseForge
artifacts, disable the affected workflow lane, and revert the smallest change.
Restore the previous bot image/commit if Discord health or event processing is
degraded. Reopen publication only after the failed gate has a new receipt.
