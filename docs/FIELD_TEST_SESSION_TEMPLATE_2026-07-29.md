# KWR Field Test Session Template

Use this for every live session on or after 2026-07-29.

## Candidate identity

- Date:
- Candidate version:
- Package hash:
- Session type: `observer / partial command / true command`
- Ruleset:
- Corpus revision:
- Knowledge report:
- Locale:
- Resolution:
- UI scale:
- Graphics profile:
- Sentinel enabled: `YES / NO`
- Other addons enabled:

## Pre-match steps

- [ ] Preserve current SavedVariables
- [ ] Install the exact hashed package
- [ ] Enable Lua error visibility
- [ ] Prepare taint/blocked-action capture
- [ ] Run `/kwr verify`
- [ ] Record idle FPS / CPU / memory

## Required live captures

- [ ] queue/staging entry
- [ ] first roster fill / scoreboard
- [ ] one full command center pass
- [ ] compact HUD in first real fight
- [ ] one state-change capture: lead / tie / deficit / recovery
- [ ] `/kwr verify` after a decisive state change
- [ ] `/kwr perf` during or after heavy combat
- [ ] match end scoreboard
- [ ] AAR view
- [ ] post-instance cleanup

## Stop immediately if any occur

- [ ] Lua error
- [ ] taint or blocked action
- [ ] required reload
- [ ] fabricated fact
- [ ] false high-confidence commit
- [ ] identity merge
- [ ] protected assignment violation
- [ ] refresh above hard safety maximum

## Post-match archive

- [ ] screenshots saved
- [ ] `/kwr verify` saved
- [ ] `/kwr perf` saved
- [ ] AAR export saved
- [ ] session type recorded
- [ ] command compliance noted: `low / mixed / high`
- [ ] issue/task IDs created for every failure
- [ ] outcome tagged as `PASS / PARTIAL / FAIL`

## Interpretation rule

If session type is `observer` or command compliance is `low`, do not score the
raw win/loss result as a direct command-engine verdict by itself.

Those matches still provide strong evidence for:

- truth accuracy;
- UI readability;
- command wording;
- assignment visibility;
- target / CC visibility;
- command churn;
- AAR usefulness.
