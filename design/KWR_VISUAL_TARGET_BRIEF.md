# KWR Visual Target Brief

This mockup is a KWR visual target, not a redesign mandate.

Its purpose is to give us a stable goal while we refine the existing addon. We should preserve KWR's current visual identity, runtime architecture, and command language while improving clarity, layout discipline, and battleground focus.

## Non-negotiables

- Stay visually consistent with current KWR:
  - black / charcoal panels
  - gold framing and headers
  - restrained blue / red / green / purple tactical accents
  - clean serif-like command headers with readable WoW-safe body text
- Do not introduce arcade clutter, icon spam, or a second information wall.
- Keep the battlefield readable. The player must still play the game.
- Use battleground-only UI restructuring. Outside battlegrounds, normal world UI should remain mostly untouched.

## What the mockup means

The mockup is showing the direction of commander mode:

- top compact command card
- bottom-aligned command surfaces
- reporter map as the primary tactical map surface
- compact team strip driven by assignment integrity
- compact enemy strip driven by threat / kill / kick / peel logic
- battlefield overlays limited to:
  - target reticle
  - clean role/class markers
  - opportunity/status rings
  - minimal health/nameplate language

## What it does not mean

- not a replacement of the current command brain
- not a promise to replicate third-party addons exactly
- not permission to drift from KWR's existing structure
- not permission to overload the screen with cooldown encyclopedias

## Asset direction

We can support this target using either:

- WoW-native art and icons where safe and appropriate
- a KWR-owned symbol library for consistent tactical language

Preferred KWR symbol classes:

- tank / anchor / FC
- healer
- damage / strike
- defend / peel
- rotate / float
- kill target
- kick target
- CC target
- dead / drink / stale / unknown

These symbols should mean the same thing across:

- commander HUD
- reporter map
- team strip
- enemy strip
- nameplates / battlefield overlays
- copy / explanation windows

## Battleground-only noise reduction target

When zoning into a battleground, KWR can optionally shift into a cleaner command presentation mode.

Target behavior:

- reduce or hide non-critical world UI noise
- preserve essential combat and gameplay controls
- keep quest / leveling / world chatter from dominating the screen
- favor KWR surfaces for command truth during battleground play

Candidate battleground-only cleanup options:

- minimize quest tracker
- reduce chat footprint
- suppress non-essential world widgets
- prefer reporter map over default minimap for command use
- keep focus on combat frames, command HUD, and tactical map

This should always be:

- optional
- reversible
- safe
- consistent with WoW's protected UI rules

## Quality bar

Every future UI change should be judged by:

Does this improve win probability without increasing cognitive load?

If not, it belongs in debug, explanation, or not at all.
