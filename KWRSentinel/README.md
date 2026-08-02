# KWR Sentinel

KWR Sentinel is the compact non-commander player client for Knomercy War Room.

It has one live surface: a small execution card that shows commander trust,
match state, your job, movement authority, target responsibility, and the
single hold/win instruction. It also shows a small target-confirmation cue:
white for the reviewed target, red for the wrong target, and muted when no
reviewed target instruction exists.

Current alpha scope:

- same-client `KnomercyWarRoom` bridge through the reviewed `KWR.SentinelBridge`
  export;
- safe standalone fallback when the commander addon is not installed locally;
- one-shot pre-match readiness alert with conservative unknown handling;
- native Blizzard battleground map and scoreboard toggles.

Not included in this build:

- no automatic target or focus changes;
- no auto-casting, macro execution, or movement automation;
- no cross-player addon-channel relay until `SENTINEL_TRANSPORT_SPEC.md` gates
  are implemented and validated;
- no reporter map, enemy table, tactical board, or commander dashboard.

Slash commands:

- `/sentinel` or `/kwrs` toggles the execution card
- `/kwrs map` toggles the battlefield map
- `/kwrs score` toggles the scoreboard
- `/kwrs raid` toggles Blizzard raid frames
- `/kwrs reset` restores the execution card to its default position
