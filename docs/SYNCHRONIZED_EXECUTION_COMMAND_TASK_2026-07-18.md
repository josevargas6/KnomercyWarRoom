---
id: KWR-126
title: Synchronize Commander, mini HUD, Sentinel, and audio assignments
owner: codex
priority: high
risk: high
dependencies:
  - TeamfightCommandPlanner
  - Assignments
  - Commander
  - SentinelBridge
affected_modules:
  - Intelligence/ExecutionCommandBuilder
  - Runtime/MatchRuntime
  - Runtime/SentinelBridge
  - Runtime/CommandAudio
  - Adapters/SafeSpeechAdapter
  - UI/HUD
---

# Objective

Build one authoritative execution packet from the existing objective assignments and local teamfight planner, then use that same packet for the mini HUD, each player's Sentinel assignment, and optional spoken calls.

# User outcome

The target caller sees one concise synchronized call, while each player running Sentinel receives only their personal pickup, healer-control, or kill assignment from that same command revision.

# Current behavior

The runtime independently builds objective assignments, a local teamfight plan with up to three healer-control jobs, a kill target, and a countdown. The compact HUD partially renders the teamfight plan, while Sentinel independently derives its job from the broader objective assignment list. No speech service consumes the plan.

# Required behavior

- Build one execution packet after Commander, objective assignments, and the teamfight planner have completed.
- Preserve up to three qualified healer-control assignments and the selected kill target.
- Include a qualified orb handoff direction when an existing replacement or pickup assignment is available.
- Generate ordered visual lines and one canonical spoken call from the same fields.
- Resolve a personal assignment by stable player identity without falling back to another player's teamfight job.
- Render the execution packet in the mini HUD's Current Call and My Assignment sections.
- Relay the same personal assignment and execution revision through SentinelBridge.
- Speak only authoritative, non-preview packets when enabled, deduplicated by signature and rate limited.
- Keep every action advisory and display-only; never automate targeting, spells, movement, or chat.

# Non-goals

- Replacing the existing planners, assignment optimizer, Commander, Store, or Sentinel transport.
- Inventing a replacement player when the existing assignment systems cannot qualify one.
- Sending remote addon messages or automatically issuing group-chat commands.
- Naming specific spells or automating crowd control.

# Technical constraints

- Blizzard speech APIs must be isolated behind a guarded adapter.
- Secret or protected values must not be inspected to build speech or assignments.
- Runtime builds exactly one packet per refresh; UI and Sentinel are pure consumers.
- Audio must cancel stale pending speech and avoid repeating unchanged calls.
- Player matching must use canonical short-name/GUID identity where available.
- Existing saved-variable profiles must upgrade through defaults without destructive migration.

# Acceptance criteria

- [x] One packet contains objective handoff, up to three control assignments, kill target, countdown, visual lines, spoken text, confidence, revision signature, and per-player jobs.
- [x] Mini HUD Current Call renders the packet in objective/control/kill/trigger order.
- [x] Mini HUD My Assignment never shows another player's teamfight assignment.
- [x] Sentinel receives the matching player's packet assignment and packet signature.
- [x] Visual and spoken calls are derived from identical packet fields.
- [x] Unchanged packet signatures do not replay audio.
- [x] Preview, low-confidence, unavailable-TTS, and disabled-audio states fail silent.
- [x] Deterministic tests cover two and three healer-control lanes, kill target, personal routing, objective handoff, signature stability, and safe unknown fallbacks.

# Verification

1. Run `./tools/validate.ps1`.
2. Run `./tools/knowledge-audit.ps1`.
3. Run `fengari tests/smoke.lua`.
4. Run `fengari tests/soak.lua`.
5. Run `./tools/build.ps1`.
6. In Temple, verify a qualified call appears identically in the mini HUD and Sentinel, and audio speaks it only once per signature.
7. Verify preview and low-confidence calls remain silent.

# Rollback

Remove the execution builder, speech adapter/service, and their TOC entries; restore HUD and SentinelBridge to their previous direct consumers. The added audio profile keys are backward-compatible and harmless if left persisted.
