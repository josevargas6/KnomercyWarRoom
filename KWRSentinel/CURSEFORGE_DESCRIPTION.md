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
locally and can receive bounded `KWRSync1` relays from a Commander in the same
battleground group. If neither bridge is available, Sentinel falls back safely
and does not invent assignments, match state, or target calls. Retail ten-client
soak, taint, and field-value evidence remains required before promotion.

## Safety

KWR Sentinel never targets, focuses, casts, runs macros, moves the player, sends
chat, or automates gameplay. It is a display and observation client only.

## Commands

- `/sentinel` or `/kwrs` toggles the execution card.
- `/kwrs map` toggles the Blizzard battlefield map.
- `/kwrs score` toggles the Blizzard scoreboard.
