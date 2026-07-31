# KWR Sentinel Changelog

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