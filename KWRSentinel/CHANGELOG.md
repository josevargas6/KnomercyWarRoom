# KWR Sentinel Changelog

## 6.1.0-alpha.43 - 2026-08-14

- Keeps the Sentinel execution layer available in lightweight arena and world-PvP contexts while Commander battleground surfaces remain suppressed.
- Retains safe unknown-state handling and direct nameplate-token validation from Alpha 42.

## 6.1.0-alpha.42 - 2026-08-14

- Guards supported observation, cast, and HUD paths against Blizzard secret
  values and degrades unavailable facts to safe unknown state.
- Restricts nameplate lookup to legal direct nameplate unit tokens so group,
  arena, and compound tokens cannot trigger protected API errors.

## 6.1.0-alpha.40 - 2026-08-09

- Aligns Sentinel metadata with Commander's composition-aware opening candidate.

## 6.1.0-alpha.39 - 2026-08-09

- Uses the Commander LayoutCoordinator for managed screen-edge docking when
  both addons run locally, preventing the execution card and status helper
  from covering active KWR surfaces. Dragging keeps a manual layout; `/kwrs
  reset` restores managed docking.

## 6.1.0-alpha.38 - 2026-08-09

- Adds bounded cross-client `KWRSync1` Commander relay and observation transport.
- Keeps same-client bridge and standalone fallback intact.
- Does not add targeting, focus, casting, macros, movement, or visible-chat transport.

## 6.1.0-alpha.33 - 2026-08-01

- Restores the complete execution card, target cue, status helper, options, and minimap runtime to standalone source.
- Makes the TOC and runtime-reported version agree.
- Removes out-of-scope team/enemy tracker panels and inert raid-frame controls.
- Preserves unresolved commander targets and renders unavailable cooldown data as unknown.
- Preserves Retail protected-data fallbacks and player-controlled behavior.

## 6.1.0-alpha.32 - 2026-08-01

- Declares both supported Retail interface builds, 12.0.7 and 12.1.0.
- Preserves the Alpha 31 execution-card behavior and safety boundary.

## 6.1.0-alpha.31 - 2026-08-01

- Aligns the standalone source with the certified Commander Alpha 31 bundle.
- Publishes explicit World of Warcraft Retail 12.1.0 and 12.0.7 metadata.
- Preserves the Alpha 25 execution-card behavior and safety boundary.

## 6.1.0-alpha.25 - 2026-07-17

Initial official Sentinel alpha distribution candidate.

- Polishes the execution card with stronger visual hierarchy, more disciplined
  spacing, shorter player-facing hold/win lines, and a less intrusive default
  position.
- Adds `/kwrs reset` to restore the card to its default position.
- Adds the compact non-commander execution card defined by the Sentinel design
  handoff.
- Shows commander trust, win state, player job, movement authority, target
  responsibility, match state, and hold/win instruction.
- Adds a small target-confirmation cue with white, red, and muted states.
- Adds one conservative pre-match readiness alert.
- Uses the reviewed same-client `KnomercyWarRoom` bridge when available.
- Falls back safely when commander data is not available.
- Keeps cross-player addon-channel relay disabled until the transport spec,
  validator gates, deterministic tests, soak tests, and live field proof are
  complete.
- Performs no targeting, focusing, casting, macro execution, keybinding writes,
  movement automation, or automatic chat.
