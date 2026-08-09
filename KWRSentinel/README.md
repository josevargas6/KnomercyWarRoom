# KWR Sentinel

KWR Sentinel is the compact non-commander player client for Knomercy War Room.

It has one live surface: a small execution card that shows commander trust,
match state, your job, movement authority, target responsibility, and the
single hold/win instruction. It also shows a small target-confirmation cue:
white for the reviewed target, red for the wrong target, and muted when no
reviewed target instruction exists.

Current alpha scope:

- same-client `KnomercyWarRoom` bridge through the reviewed `KWR.SentinelBridge`
  export, plus bounded cross-client `KWRSync1` relays after Commander handshake;
- safe standalone fallback when the commander addon is not installed locally;
- one-shot pre-match readiness alert with conservative unknown handling;
- native Blizzard battleground map and scoreboard toggles.

Not included in this build:

- no automatic target or focus changes;
- no auto-casting, macro execution, or movement automation;
- no Sentinel-to-Sentinel mesh, visible-chat fallback, or automatic gameplay
  action;
- no reporter map, enemy table, tactical board, or commander dashboard.

Slash commands:

- `/sentinel` or `/kwrs` toggles the execution card
- `/kwrs map` toggles the battlefield map
- `/kwrs score` toggles the scoreboard
- `/kwrs reset` restores the execution card to its default position

When Commander is installed on the same client, Sentinel uses its layout
coordinator to dock the execution card and status helper away from active KWR
windows. Drag either window to keep a custom placement; `/kwrs reset` returns
it to managed docking.
