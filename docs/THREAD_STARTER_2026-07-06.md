# KWR Fresh Thread Starter

Use this prompt bundle to resume KWR in a fresh Codex thread with minimal drift.

## Repo

`D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom`

## Read first

1. `docs/CURRENT_STATE_HANDOFF_2026-07-06.md`
2. `docs/WORKFLOW_NOW.md`
3. `PILLAR_EXECUTION_SHEET.md`
4. `PROJECT_HANDOFF.md`
5. `RELEASE_READINESS.md`

## Current truth

- addon version: `6.1.0-alpha.23`
- this is still alpha stabilization work, not release packaging
- architecture must remain one truth pipeline / one commander path
- priority is pillar completion, not cosmetic drift

## Current priority order

1. Pillar 1 truth stabilization
2. Pillar 2 runtime/surface stability
3. Pillar 3 doctrine depth
4. Pillar 4 commander usability polish
5. Pillar 5 verification cleanup

## Most important current problems

1. battleground side can still resolve wrong in live cases
2. compact HUD refresh path was hardened, but still needs live verification
3. split combat roster persists positions badly across reload
4. enemy truth still needs full live verification and target-loss follow-through
5. post-match stale truth cleanup is still open after battleground completion
6. doctrine depth is still too generic on some battlegrounds

## Current verification baseline

- offline smoke currently passes: `npx --yes -p fengari-node-cli fengari tests/smoke.lua`
- keep that green while finishing Pillar 1 and Pillar 2 live stabilization

## Freshly hardened

- post-match refreshes now preserve the last qualified battleground side,
  score, and objectives through widget decay until the player leaves the battleground

## Non-negotiables

- do not add a second engine
- do not patch around truth with fake UI labels
- do not invent unknown data
- do not drift into massive UI clutter
- do not weaken secure target/focus behavior

## Working style

- make focused fixes
- verify source-of-truth flow before adding doctrine
- keep docs current as you fix major issues
- use live test reports to validate, not to hand-wave
- keep `docs/WORKFLOW_NOW.md` updated so the next task is always obvious
