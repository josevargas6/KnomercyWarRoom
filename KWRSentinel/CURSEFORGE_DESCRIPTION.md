# KWR Sentinel

KWR Sentinel is the compact player execution client for Knomercy War Room.

It is built for non-commander Rated Battleground players who need one clear
personal instruction instead of a second command dashboard.

## What It Shows

- Commander trust state: `LOCAL KWR`, `NO COMMANDER`, `STALE`, `MISMATCH`, or
  future reviewed raid-commander binding.
- Current battleground score/pace and win state.
- Your job, movement authority, reviewed target responsibility, match state,
  and the one hold/win instruction.
- A small target confirmation cue: white for the reviewed target, red for the
  wrong target, muted when no reviewed target exists.
- One conservative pre-match readiness alert.

## Current Alpha Scope

This alpha uses the same-client `KnomercyWarRoom` bridge when KWR is installed
locally. If KWR is not present, Sentinel falls back safely and does not invent
assignments, match state, or target calls.

Cross-player addon-channel relay is not enabled in this build. It remains gated
by the reviewed `SENTINEL_TRANSPORT_SPEC.md` protocol, validator, soak, and live
field-test requirements.

## Safety

KWR Sentinel never targets, focuses, casts, runs macros, moves the player, sends
chat, or automates gameplay. It is a display and observation client only.

## Commands

- `/sentinel` or `/kwrs` toggles the execution card.
- `/kwrs map` toggles the Blizzard battlefield map.
- `/kwrs score` toggles the Blizzard scoreboard.
- `/kwrs raid` toggles Blizzard raid frames.
