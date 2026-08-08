# KWR Release Rewrite Guardrails

Date: 2026-07-11  
Purpose: govern all release-cleanup and efficiency rewrite work so the addon does not drift away from its battleground commander mission.

## Core Rule

Every rewrite must make the addon:
- cleaner
- faster
- easier to trust

Without making it:
- more generic
- less battleground-specific
- less actionable for a commander
- more dependent on UI-layer logic

If a rewrite improves structure but weakens battleground command value, it fails.

## Product Identity Lock

KWR is:
- a Rated Battleground commander addon
- a legal-data battlefield interpretation system
- an assignment, objective, local target, and review tool

KWR is not:
- a generic PvP widget bundle
- a UI experiment sandbox
- a theorycraft database without command output
- a passive stat display addon

All cleanup work must preserve that identity.

## Rewrite Invariants

These are mandatory.

### 1. One Owner Per Concern

- `Store` owns current live truth.
- runtime modules compute from truth.
- `Commander` summarizes into a command contract.
- review/AAR modules store compact evidence and outcomes.
- UI surfaces present approved contracts and user interactions only.

No subsystem may silently absorb another subsystem’s responsibility.

### 2. UI Does Not Become the Brain

UI modules may:
- format text
- render state
- invoke explicit user actions
- choose between already-produced display variants

UI modules may not:
- invent tactical conclusions
- assemble large hidden logic chains
- re-derive truth already owned by runtime
- become fallback owners for missing runtime design

### 3. Runtime Does Not Become Persistence

Runtime modules may:
- hold bounded session state
- cache short-lived calculations
- produce compact summaries for command or review

Runtime modules may not:
- accumulate unbounded historical payloads
- keep review-grade copies just because they are convenient
- persist data without explicit retention value

### 4. Persistence Must Earn Its Cost

Persisted data is allowed only if it directly improves one of:
- future command quality
- future target identification
- trustworthy match review
- explicit user-authored notes or overrides

If persisted data does not clearly improve one of those, it should be removed.

### 5. No Dev Tooling In The Field Build

The release package must not ship:
- diagnostics harnesses
- preview-only systems
- fixture libraries used only for development validation
- developer-facing payload expansion paths

Dev-only tooling must be separated from release packaging.

### 6. No Rewrite Without A Tighter Contract

A subsystem split is only valid if the new boundaries are more explicit than the old ones.

Every rewritten subsystem must declare:
- `Mission`
- `Inputs`
- `Outputs`
- `State owned`
- `State forbidden`
- `Non-goals`

If those are not clearer after the rewrite, the rewrite is not done.

## Approved Decision Test

Before any rewrite lands, it must pass all of these questions.

### Mission Test

Can this subsystem’s purpose be explained in one sentence tied to battleground command value?

If not, it is too vague and should be reduced or split.

### Data Test

Does it consume only the data it actually needs?

If not, narrow the contract.

### Ownership Test

Does some other subsystem already own part of this responsibility?

If yes, remove the duplicate ownership.

### Retention Test

If this state survives longer than one match, can we defend exactly why?

If not, do not persist it.

### Surface Test

Is the user seeing only information that helps act, verify, or review?

If not, remove the rest from the field surface.

### Release Test

Would I ship this exact subsystem to real testers without apologizing for it?

If not, it needs more cleanup or needs to be excluded from the release package.

## Allowed Rewrite Categories

These are explicitly in-scope.

### Keep

Subsystem is structurally sound enough to preserve.

Allowed work:
- narrow contracts
- reduce copies
- trim allocations
- improve naming
- move formatting out of runtime

### Rewrite

Subsystem mission is valid but implementation is mixed or heavy.

Allowed work:
- split into smaller owners
- replace fat payloads with thin DTOs
- redesign state retention
- move developer-only logic out of field paths

### Remove

Subsystem or behavior has no place in the field build.

Allowed work:
- remove from release TOC
- move behind dev-only build boundary
- delete entirely if not strategically useful

## Forbidden Drift Patterns

These patterns are not allowed.

### 1. Genericization Drift

Do not replace battleground-specific language and behavior with generic PvP abstractions unless the battleground purpose remains stronger after the change.

### 2. Convenience Persistence Drift

Do not keep large payloads just because review or UI code currently reads them.

### 3. Surface Logic Drift

Do not fix runtime design weaknesses by teaching UI modules to infer more.

### 4. Cleanup Vanity Drift

Do not rewrite stable battleground logic just to make it look architecturally prettier.

### 5. Feature Erosion Drift

Do not remove player-trust features that matter:
- assignment clarity
- local target clarity
- map pressure clarity
- evidence-backed review
- battleground-only visibility behavior

## Required Rewrite Template

Every major rewrite slice must start with this checklist:

### Rewrite Charter

- `Subsystem`:
- `Mission`:
- `Current problems`:
- `Keep`:
- `Remove`:
- `Rewrite shape`:
- `Inputs after rewrite`:
- `Outputs after rewrite`:
- `Persistence impact`:
- `Runtime impact`:
- `User-visible impact`:
- `How we verify no drift`:

No major subsystem rewrite should begin without this charter.

## Current Mandatory Priorities

These are the first release-cleanup priorities and should be executed in order unless a stronger dependency is found.

1. Separate dev-only and release-only packaging.
2. Remove diagnostics and preview from the release build.
3. Replace the fat command object with a thin release command DTO.
4. Replace AAR’s copied runtime payloads with a compact review schema.
5. Split `MainWindow` into page modules.
6. Split `CombatRoster` into clearer surface and renderer boundaries.
7. Unify persistence policy under one retention contract.

## Definition Of Done For The Cleanup Program

The cleanup program is done only when:
- release package excludes dev-only systems
- each major subsystem has a clear single-sentence mission
- runtime and persistence ownership are explicit and non-overlapping
- UI surfaces do not carry hidden decision logic
- memory growth is bounded by design, not just patched by caps
- battleground commander value is at least as strong as before the rewrites

If structure improves but commander value weakens, the work is not done.
