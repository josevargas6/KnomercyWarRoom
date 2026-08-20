---
id: KWR-269
title: Competitive readiness refinement
owner: Codex
priority: critical
risk: high
status: completed
dependencies: [KWR-268]
affected_modules: [Runtime, Intelligence, UI, tests, docs]
authority_references: [AGENTS.md, DESIGN_CONTRACT.md, RELEASE_READINESS.md, QA_CHECKLIST.md]
---

# KWR-269 - Competitive Readiness Refinement

Scope: local source, deterministic tests, and release-readiness evidence only

## Battlefield problem

Several otherwise useful commander signals could overstate certainty: missing timestamps
were accepted as fresh, semantic map anchors could be counted as observed player
positions, an unverified assignment route inherited a fixed travel duration, and the
tactical map did not expose the same compact evidence contract as the canonical command.

## Root cause

The established sensor -> verification -> prediction -> strategy -> command pipeline is
sound, but a few downstream helpers collapsed observed and estimated evidence into the
same fields. The repair is incremental; no subsystem rewrite or duplicate runtime/store
is authorized.

## Delivery contract

- [x] Derive bounded score-rate evidence only from monotonic verified widget transitions.
- [x] Require timestamped, current score/objective evidence before aggressive prediction.
- [x] Separate observed positions, speeds, routes, pressure, and ETA advantage from estimates.
- [x] Remove fabricated travel defaults from assignment-integrity decisions.
- [x] Publish one command-emphasis model sourced from the canonical command.
- [x] Keep team attention secondary and unable to select a kill target or override truth gates.
- [x] Add deterministic truth fixtures for every supported battleground family/variant.
- [x] Pass offline certification, security, automation, and performance checks without packaging.
- [x] Close or supersede older implementation tasks honestly; retain live/external proof as release gates.

## Non-goals

No radar, triangulation, silent addon intelligence, automatic communications, hidden
inference, broad polling, doctrine edits, external addon changes, packaging, publishing,
deployment, Discord actions, or GitHub mutations.

## Verification evidence

- `certify-offline.ps1 -SkipBuild`: PASS, including validation, authority,
  100,000-case Season 2 simulation, knowledge, full Lua, replay, soak, and
  offline performance/source certification.
- Lua smoke: 276 checks; Sentinel transport: 10 accepted / 14 rejected;
  soak: 500 refreshes, 0.242 ms average, 0.8 ms P95, 3.2 ms max.
- Security: 8,984 files, 0 errors, 0 warnings.
- Automation: 163 checks; deployment-manifest fixture, SavedVariables audit
  fixture, and social-copy checks: PASS.
- No package, archive, external write, deployment, publication, or production
  action was performed.

## Closure disposition

Completed 2026-08-19 for local implementation scope. Distribution remains
NOT READY until the package/hash, GitHub review/CI/merge/tag, and candidate-bound
Retail evidence gates in `RELEASE_READINESS.md` are completed by authorized owners.
