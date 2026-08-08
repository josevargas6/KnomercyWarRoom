# KWR Live Test Operator Guide

Use this guide for live testing of candidate `6.1.0-alpha.29` on Wednesday, July 29, 2026.

This is the shortest path to gather the exact evidence I need from you.

## Important test interpretation

When you are in a battleground mainly to observe KWR, capture screenshots, and
sample the addon while someone else leads, do not treat the match result as a
clean verdict on KWR command quality.

In those sessions:

- the score and final result still matter;
- the AAR is still useful;
- but losses are not automatically evidence that the KWR call was wrong.

Use those matches first to judge:

- live truth quality;
- HUD readability;
- assignment clarity;
- current and next call quality;
- kill / CC clarity;
- command stability;
- AAR evidence quality.

Only treat a match as stronger command-validation evidence when you were
actually leading with KWR calls and the team substantially followed them.

## Certified candidate

- Candidate version: `6.1.0-alpha.29`
- Certified distribution SHA256: `B5F597D5C52B9E94F6CA9E5298FC13C2889F205EC882DAADF50EA88EB59ED51D`

## Before you queue

1. Install the exact `KnomercyWarRoom` folder for `6.1.0-alpha.29`.
2. Back up:
   - `World of Warcraft/_retail_/WTF/Account/<ACCOUNT>/SavedVariables/KnomercyWarRoom.lua`
   - `World of Warcraft/_retail_/WTF/Account/<ACCOUNT>/SavedVariables/KnomercyWarRoom.lua.bak`
3. Log in and run:
   - `/kwr field`
4. Then run:
   - `/kwr verify`

Take one screenshot here:

- `00-field-armed-verify.png`

## Commands to use during a match

Use these exact commands:

- `/kwr verify`
  - use during an important game-state swing
  - example: first cap, first deficit, recovery setup, final push

- `/kwr perf`
  - use during or just after heavy combat

- `/kwr evidence`
  - use once mid-match if something strange happens

- `/kwr bug`
  - use immediately if there is a bad call, taint, wrong target, bad truth, wrong assignment, or UI failure

- `/kwr aar`
  - open AAR after match end

- `/kwr aar copy`
  - copy the final AAR export after match end

## Screenshots I want

Take these if they happen:

1. staging / gates with HUD visible
   - `01-staging-hud.png`

2. full roster loaded
   - Team page
   - Assignments page
   - `02-team-page.png`
   - `03-assignments-page.png`

3. first real live tactical call
   - Tactical page
   - `04-tactical-opening-call.png`

4. first real fight
   - compact HUD showing `NOW`, `NEXT`, `POSTURE`, and `KILL / CC`
   - `05-first-fight-hud.png`

5. one decisive swing
   - Tactical or HUD
   - then run `/kwr verify`
   - `06-decisive-state.png`
   - `07-verify-copy.txt`

6. heavy combat performance check
   - run `/kwr perf`
   - `08-perf-copy.txt`

7. any bug or wrong call
   - screenshot first
   - then run `/kwr bug`
   - `09-bug-screenshot.png`
   - `10-bug-copy.txt`

8. end of match
   - scoreboard
   - Review / AAR
   - `11-scoreboard-end.png`
   - `12-aar-window.png`
   - `13-aar-copy.txt`

## What to copy and paste back to me

Paste these text outputs into chat when available:

1. `/kwr verify`
2. `/kwr perf`
3. `/kwr evidence` if used
4. `/kwr bug` if used
5. `/kwr aar copy`

If a copy window opens, copy the full contents and paste it here.

Also tell me which of these best describes the match:

- `observer session` - you were mainly gathering evidence and not leading;
- `partial command session` - you suggested KWR calls, but team compliance was mixed;
- `true command session` - you were actively leading and the team substantially followed the calls.

## Minimum clean evidence bundle

If you only get one match, bring me this minimum set:

- `00-field-armed-verify.png`
- `05-first-fight-hud.png`
- `06-decisive-state.png`
- `11-scoreboard-end.png`
- `12-aar-window.png`
- full `/kwr verify` text
- full `/kwr perf` text
- full `/kwr aar copy` text

## Stop immediately if any happen

- Lua error
- blocked action
- taint warning
- wrong target
- fabricated carrier/objective truth
- assignment shown for wrong player
- UI disappears and needs reload

If any of these happen:

1. take screenshot
2. run `/kwr bug`
3. paste the bug report to me

## Best one-line live workflow

Before queue:

- `/kwr field`
- `/kwr verify`

During match:

- screenshot important state
- `/kwr verify`
- `/kwr perf`

If broken:

- screenshot
- `/kwr bug`

After match:

- `/kwr aar`
- `/kwr aar copy`

## Related docs

- [FIELD_TEST_SESSION_TEMPLATE_2026-07-29.md](D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom\docs\FIELD_TEST_SESSION_TEMPLATE_2026-07-29.md)
- [KWR_TWIN_PEAKS_FIRST_SESSION_OPERATOR_SHEET_2026-07-29.md](D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom\docs\KWR_TWIN_PEAKS_FIRST_SESSION_OPERATOR_SHEET_2026-07-29.md)
- [CANDIDATE_PACKAGE_TRUTH_PACK_2026-07-29.md](D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom\docs\CANDIDATE_PACKAGE_TRUTH_PACK_2026-07-29.md)
