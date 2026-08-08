---
id: KWR-034
title: Operate KWR as an autonomous Codex, GitHub, CurseForge, and Discord system
owner: unassigned
priority: high
risk: high
dependencies: [GitHub protected environments, CurseForge API, Discord Sentinel host]
affected_modules: [.github/workflows, tools, docs, knowledge, kwr-sentinel-bot]
---

# Objective

Implement the long-term autonomous maintenance and community operations model
defined in `docs/KWR_AUTONOMOUS_OPERATIONS_CONTRACT.md`.

# User outcome

Players receive reliable support, research summaries, release information, and
testing coordination in Discord. Codex receives structured evidence and turns
verified problems into tested GitHub changes. CurseForge receives only exact,
certified addon artifacts. Weekly corpus and doctrine updates make the addon
stronger without turning rumors into live strategy.

# Acceptance criteria

- [ ] Codex-directed daily Sentinel interaction flows collect replies with
  deduplication and unresolved-action links.
- [ ] Tuesday patch/reset workflow produces an impact report and repair queue.
- [ ] Two weekly trend reviews cover official changes, meta, compositions,
  builds, openings, map impact, and support clusters.
- [ ] Every mandatory weekly update adds at least 10 new corpus simulations and
  corresponding matrix coverage, or records a reviewed exception.
- [ ] Emergency reports are redacted, severity-classified, and routed to a
  private Codex-ready GitHub issue immediately.
- [ ] Meta and opening-doctrine updates include sources, confidence, affected
  maps, success/abort conditions, and rollback evidence.
- [ ] CurseForge publication is blocked until public file visibility is proven.
- [ ] Discord announcements always contain current versions and working public
  links.
- [ ] Every cycle emits a private evidence receipt without secrets or excess
  user identifiers.

# Verification

1. Run the local validation, security, knowledge, Lua, soak, replay, and
   package gates.
2. Run a dry-run Tuesday cycle, two trend-review fixtures, a 10-simulation
   corpus fixture, and an emergency bug fixture.
3. Run the protected external canary with real GitHub/CurseForge/Discord
   credentials.
4. Verify the public CurseForge file, GitHub release, Discord message IDs, and
   bot health receipt.
5. Exercise rollback and deduplicated retry behavior.
