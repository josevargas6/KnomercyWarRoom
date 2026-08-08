# Twin Peaks Alpha 28 Field Evidence

Capture date: 2026-07-28  
Candidate: `6.1.0-alpha.28`  
Battleground: Twin Peaks  
Bracket: Standard  
Assigned team: Horde  
Decision: `PARTIAL - DEFECTS FOUND`

This record reviews one screenshot sequence. It proves only what is visible in
the supplied frames. Twin Peaks remains unverified until the missing
diagnostics, completion, and exit evidence are captured and the confirmed
trust defects are repaired.

## Evidence catalog

| # | File | Capture time | Dimensions | SHA-256 | Visible state |
| --- | --- | --- | --- | --- | --- |
| 1 | `01-lobby-compact.png` | 22:04:14 | 2558x1438 | `C178F8CABA667733A1C677410A5BAA033246BF1E041528C4DDAC71130699746B` | Lobby, compact roster, native map, command card |
| 2 | `02-command-center-tactical.png` | 22:04:29 | 1592x982 | `DA11D58821078104AB276FBF29D9873A3A435D48EB251052D60E5444944EF715` | Tactical page |
| 3 | `03-command-center-objectives.png` | 22:04:37 | 1583x983 | `2AFB28336479747956BD1512922FFACBD649906D5FDF8CFB0C7DBC6A3A90D45E` | Objectives page |
| 4 | `04-command-center-team.png` | 22:04:43 | 1612x966 | `EF06C8305726FE2A38B6162607280754F7C301FDC73D580476B555893D1D5BDF` | Team page |
| 5 | `05-command-center-enemies.png` | 22:04:51 | 1571x967 | `76058F4355B24D3DE011C3005785A1C855BAAB515A9AD09871C42FAD4119B335` | Enemies page |
| 6 | `06-command-center-assignments.png` | 22:04:57 | 1612x985 | `20E5EA4A37271E5772604C9F5A305946968E3427D15B52A0B2367874C2922ABC` | Assignments page |
| 7 | `07-command-center-review.png` | 22:05:06 | 1596x982 | `E0AEBA6D4465EE36F0C55EDE9F787BE77FCF7B898851E488C6FD968EE84AE9FA` | Review/AAR page |
| 8 | `08-live-opening.png` | 22:06:35 | 2558x1438 | `FAAB2966E12017905B9C9CDB95E09FECAB6BEA2C07931D10D2453FE2A725AFAE` | Live opening, seen enemies |
| 9 | `09-live-score-change-death.png` | 22:10:42 | 2558x1438 | `9C23EDFAEBAF2F7682CF0059B2CAA6954AC8F74DC70BD3548CE5FAB3BC3A553F` | Enemy cap, player dead |
| 10 | `10-recovery-call-tactical.png` | 22:12:10 | 1660x1027 | `2D19FB5963C97199EE0231E1E374B0328A8CAF22402094CD294B3D244DE5BE2B` | Urgent recovery, flag events, tactical map |
| 11 | `11-final-aar.png` | 22:18:33 | 1220x991 | `DE8C5AF9E60B406FEBBFFDC16DFCD1E93793F1235B44A86B6D92C7EF6FF01D8C` | Final AAR, defeat `0-3`, stability telemetry |
| 12 | `12-match-end-team.png` | 22:18:57 | 1627x1023 | `C694C62BD3AEF4A7DE58C8411596B1D8B297B47E6B14CB64F456AFE3D8E8235F` | Match-end Team page |
| 13 | `13-match-end-enemies.png` | 22:19:02 | 1615x1001 | `E4D9482390502CDAE2EB189D1BB6BBED9D9C816B875D19BF97AC444A8B75DFA6` | Match-end enemy aging |
| 14 | `14-match-end-assignments.png` | 22:19:11 | 1566x940 | `3D6260EABC2F9B4951BD42FB3DB5229E2002F6BA607E1D90B9D0DB32484FF31C` | Match-end assignments and recovery plan |

## Confirmed live evidence

### TP-E01 - Context and team direction

Status: `PARTIAL PASS`

- KWR identifies Twin Peaks, Standard, live battleground, and assigned Horde.
- The Command Center, compact HUD, Team, Enemies, and Assignments surfaces use
  the same team orientation.
- No teammate is visibly placed in the enemy roster.

This is one-side evidence only. Native-faction, mercenary, and cross-faction
coverage remain open.

### TP-E02 - Score transition

Status: `PARTIAL PASS`

- Captures 1 and 8 show Blizzard and KWR at `0-0`.
- Capture 9 shows Blizzard Alliance `1/3`, Horde `0/3`, while the Horde-relative
  KWR card shows `TP 0-1`, `LOSE`, and a changed return-and-cap win condition.

The sampled score direction and state transition agree. The screenshots do not
prove the required 0.5-second convergence time.

### TP-E03 - Native battlefield-map coexistence

Status: `PARTIAL PASS`

- Blizzard's native battlefield map is open with KWR compact surfaces in
  captures 1, 8, and 9.
- KWR continues showing score, assignments, enemy tracking, and command state.

Opening/closing behavior, combat taint, and transition persistence still need
direct testing.

### TP-E04 - Conservative unknown handling

Status: `PASS FOR CAPTURED STATES`

- Unseen enemy health, trinkets, defensives, locations, and specializations
  remain unknown or roster-only.
- Objectives remain `UNKNOWN` when owner truth is unavailable.
- The Combat Roster may show a visible fallback as `PRESS/SEEN`, while the
  synchronized command card remains `KILL: NO LOCAL TARGET`.

Code inspection confirms these labels have different contracts:
`CombatRosterVisuals` may display the best visible/recent enemy, while
`HUD.localFightText` requires a reviewed synchronized local-fight target. The
screenshots therefore demonstrate a safe refusal to promote merely seen
evidence into a kill command.

### TP-E05 - Roster and assignments

Status: `PARTIAL PASS`

- Ten friendly players resolve as one tank, three healers, and six damage.
- Every visible player receives one battlefield job and one location.
- Healer-specific jobs are assigned to visible healer roles in this sample.
- The death capture changes the compact team state to `7/10 READY` and retains
  the Horde-relative command plan.

Reassessment, manual overrides, secure clicks, and replacement behavior were
not captured.

### TP-E06 - Enemy observation aging

Status: `PARTIAL PASS`

- The enemy page begins with ten roster records and no fabricated live health.
- The live captures show `SEEN WITH` and `LAST SEEN` evidence while unobserved
  enemies remain roster-only.
- The dead-state capture retains bounded last-seen records instead of claiming
  continuous visibility.

Exact expiration timing and nameplate churn still require `/kwr verify`
evidence.

### TP-E07 - Flag event and recovery-state capture

Status: `PARTIAL PASS`

- Capture 10 shows pickup, return, and drop events for both faction flags.
- Flag/carrier markers appear on the Tactical map.
- The state advances to `RECOVERY`, `URGENT`, and `HIGH` while trailing `0-1`.
- Capture 11 records the final Horde-flag capture as the last objective event.

The raw event evidence is useful, but one command-target defect is recorded
below. Exact carrier ownership/stacks and localized-message behavior still need
`/kwr verify`.

### TP-E08 - Final result and AAR agreement

Status: `PARTIAL PASS`

- Captures 12-14 show Twin Peaks, assigned Horde, final score `0-3`, and
  `Match lost`.
- Capture 11 records `RESULT DEFEAT` and `FINAL 0-3`.
- The AAR is `EXPORT READY` and contains objective-event, command-review,
  outcome, transition, and last-switch evidence.

The sampled final result agrees across the in-instance Command Center and AAR.
Exactly-one history entry and world-exit cleanup remain unproven.

## Confirmed defects

### TP-D01 - Expanded Team health is not meaningfully rendered

Priority: `P1`  
Status: `CONFIRMED`

Capture 4 shows ten connected, ready players with empty/dark health bars and no
health text. Captures 1, 8, and 9 show the compact team tracker receiving live
health values during the same session.

This fails the QA requirement that friendly health bars render when legal unit
tokens exist.

Owning path:

- `Runtime/Sensors.lua` normalizes friendly health;
- `UI/MainWindowPages.lua` renders `player.healthPercent` and falls back to
  `applyDirectHealth`;
- `UI/MainWindow.lua` owns the direct-health fallback.

Candidate cause to verify: when normalized `healthPercent` is unavailable under
Retail secret-value behavior, the direct fallback can leave the bar using the
dim unknown color and can return without a usable text value. A deterministic
test must cover the legal-unit/direct-display path without performing secret
arithmetic.

### TP-D02 - Historical specialization provenance disagrees across surfaces

Priority: `P1`  
Status: `CONFIRMED`

Capture 1 labels friendly specializations `(HIST)` in the compact team tracker.
Capture 4 shows the same players and specializations on the expanded Team page
without `(HIST)`.

This fails the rule that historical specialization evidence stays visibly
labeled and creates a cross-surface truth disagreement.

Owning path:

- `UI/CombatRosterVisuals.lua` labels historical roster evidence;
- `UI/MainWindow.specLabel` also supports `(HIST)`;
- the expanded Team render consumes `state.snapshot.roster`.

The next implementation task must determine where `specSource` is lost or
changed before the expanded Team render and add a cross-surface assertion.

Captures 12 and 14 reconfirm the defect at match end: the Team and Assignments
pages still display historical specialization names without `(HIST)`.

### TP-D03 - Supported-resolution readability remains open

Priority: `P2`  
Status: `CONFIRMED POLISH GAP`

- Capture 2 truncates the next-objective and win-condition text.
- Capture 3 places the window low enough that the bottom Data Sources content
  is outside the captured screen, so position clamping/reset behavior needs
  verification.
- Capture 7 truncates the latest-result badge to `INTERRU...`.
- Capture 6 requires scrolling to read the complete plan explanation and
  manual-handoff copy.

This does not prove that scrolling or dragging is broken, but it does prevent
closing the supported-resolution screenshot gate.

### TP-D04 - Live command publication exceeds the stability budget

Priority: `P1`  
Status: `CONFIRMED`

Capture 11 records a 14:20 match with:

- `SWAPS 58`;
- `STABILITY REVIEW`;
- `AVG LIFE 0:00`;
- `OVERRIDES 65`;
- `CALLS 18`.

Code inspection confirms `SWAPS` is the published-command replacement count
and `STABILITY REVIEW` is produced when the existing reversal/pre-arrival
budget fails. `CALLS 18` is only the bounded retained command list because
`AAR.maxCommands` is 18. `OVERRIDES` counts ActivePlay replacements, not manual
assignment overrides.

This is a release-blocking field failure. It also exposes misleading AAR
labels: a bounded record count reads like a total, and internal play switches
read like manual commander overrides.

Owning task:

- `docs/KWR_COMMAND_STABILITY_FIELD_FIX_TASK_2026-07-28.md`

### TP-D05 - Raw flag-event prose becomes a tactical action target

Priority: `P1`  
Status: `CONFIRMED`

Capture 10 renders:

`COVER Our FC: Jade. REINFORCE Alliance Flag has been picked up`

The first clause is an actionable urgent reassignment. The second clause uses a
complete system event sentence where `REINFORCE` requires a canonical objective
or location. The event belongs in Last Events/AAR evidence, not the command
target.

Owning task:

- `docs/KWR_FLAG_COMMAND_TARGET_FIX_TASK_2026-07-28.md`

## Needs more data

### TP-Q01 - AAR record count and map attribution

Risk if confirmed: `P1`  
Status: `NEEDS DATA`

Capture 7 reports eight matches, including several interrupted records close to
completed results and `MOST PLAYED MAP UNKNOWN`. Examples include a Deephaul
Ravine victory and a Silvermoon City interrupted record with the same displayed
minute.

This could indicate duplicate match segmentation, a reload/interruption during
the same battleground, or older test data with unknown map keys. The screenshot
alone cannot distinguish them.

Required evidence:

1. `/kwr aar copy` for the relevant entries;
2. whether `/reload`, logout, disconnect, or addon disable occurred;
3. the journal portion of SavedVariables;
4. one clean match from lobby through exit with no reload.

Do not delete or migrate the history until this is resolved.

## Not proven by this set

- zero Lua errors or BugSack entries;
- zero taint or blocked-action warnings;
- `/kwr perf` timing or memory limits;
- `/kwr verify`, `/kwr explain`, or `/kwr evidence` agreement;
- secure target/focus clicks;
- quick-call send/copy behavior;
- exact carrier ownership, assault stacks, and localized flag-message parsing;
- reassessment and assignment deltas;
- exactly-one AAR history entry;
- instance-exit cleanup;
- Sentinel rendering or routing.

## Next field capture

1. Before queueing, clear or preserve diagnostics and record `/kwr verify` and
   `/kwr perf`.
2. Capture lobby, first target, first flag pickup, first score, death/resurrect,
   final score, and world exit.
3. At the same transitions, capture `/kwr verify`, `/kwr explain`, and
   `/kwr perf`.
4. Export `/kwr evidence` and `/kwr aar copy` before leaving.
5. Record whether any `/reload`, disconnect, or addon disable occurred.
6. Test the Team page after the health/provenance repairs.
