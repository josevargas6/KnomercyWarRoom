# KWR Twin Peaks First Session Operator Sheet

Candidate: `6.1.0-alpha.29`  
Date: 2026-07-29

This sheet is for the first blocker-clearing Twin Peaks session.

Use it with:

- [FIELD_TEST_SESSION_TEMPLATE_2026-07-29.md](D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom\docs\FIELD_TEST_SESSION_TEMPLATE_2026-07-29.md)
- [CANDIDATE_FIELD_CAPTURE_MATRIX_2026-07-29.md](D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom\docs\CANDIDATE_FIELD_CAPTURE_MATRIX_2026-07-29.md)
- [field-evidence Twin Peaks review](D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom\docs\field-evidence\2026-07-28-twin-peaks\README.md)

## Session goal

Try to clear these in one live Twin Peaks run:

- `KWR-032`
- `KWR-033`
- `KWR-034`
- `TP-D03`

## Before queue

- [ ] confirm exact package version is `6.1.0-alpha.29`
- [ ] record package hash
- [ ] backup SavedVariables
- [ ] enable Lua error capture
- [ ] prepare taint / blocked-action capture
- [ ] record idle FPS / CPU / memory
- [ ] run `/kwr verify`

## Opening captures

- [ ] compact HUD in staging
- [ ] compact Team roster in staging
- [ ] expanded Team page after roster fill
- [ ] Assignments page after roster fill
- [ ] Tactical page after opening route call

Suggested filenames:

- `tp-01-staging-compact.png`
- `tp-02-staging-team-page.png`
- `tp-03-staging-assignments-page.png`
- `tp-04-staging-tactical-page.png`

## Blocker-specific evidence

### `KWR-032`

Need:

- [ ] same player visible on compact Team, expanded Team, and Assignments
- [ ] one clearly usable expanded Team health state
- [ ] one `(HIST)` specialization case if available

### `KWR-034`

Need during pickup / drop / return / cap:

- [ ] Tactical page
- [ ] compact HUD or command copy
- [ ] evidence / event line if visible

Pass condition:

- canonical route/carrier target
- no raw prose as command target

### `KWR-033`

Need one full match with:

- [ ] `/kwr verify` during a decisive state change
- [ ] `/kwr perf` during or after heavy combat
- [ ] final scoreboard
- [ ] final AAR

Pass condition:

- stability story is coherent across verify, perf, and AAR

### `TP-D03`

Need one clean tab sweep:

- [ ] Tactical
- [ ] Objectives
- [ ] Team
- [ ] Enemies
- [ ] Assignments
- [ ] Review / AAR

Pass condition:

- no meaningful clipping at supported scale

## Stop immediately if any occur

- [ ] Lua error
- [ ] taint or blocked action
- [ ] reload needed to fix state
- [ ] fabricated fact
- [ ] wrong team orientation
- [ ] identity merge
- [ ] malformed command target

## Suggested end-of-match files

- `tp-05-carrier-event-tactical.png`
- `tp-06-carrier-event-command.png`
- `tp-07-midmatch-verify.png`
- `tp-08-midmatch-perf.png`
- `tp-09-match-end-scoreboard.png`
- `tp-10-match-end-aar.png`
- `tp-11-cc-tactical.png`
- `tp-12-cc-objectives.png`
- `tp-13-cc-team.png`
- `tp-14-cc-enemies.png`
- `tp-15-cc-assignments.png`
- `tp-16-cc-review.png`

## Final session summary

| Blocker | Result | Evidence | Notes |
| --- | --- | --- | --- |
| `KWR-032` | `PASS / PARTIAL / FAIL` |  |  |
| `KWR-033` | `PASS / PARTIAL / FAIL` |  |  |
| `KWR-034` | `PASS / PARTIAL / FAIL` |  |  |
| `TP-D03` | `PASS / PARTIAL / FAIL` |  |  |
