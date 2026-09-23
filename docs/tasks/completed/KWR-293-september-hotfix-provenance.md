---
id: KWR-293
title: Review Retail 12.1 official hotfixes through September 4
owner: Codex
priority: high
risk: medium
status: completed
dependencies: [KWR-276, KWR-292]
affected_modules: [Data/PatchData.lua, META_SOURCES.md, smoke]
authority_references: [RELEASE_READINESS.md, PRODUCT_ROADMAP.md, META_SOURCES.md]
---

# Objective

Advance the documented official-hotfix review boundary using Blizzard's current
Retail ledger without claiming that source notes alone prove live tactical values.

# Required behavior

The 12.1 pack records review through September 4, 2026. September 1 PvP tuning
(healer trinket primary stat, Devourer damage, Rain from Above and Innervate) and
September 2 PvP fixes (Faerie Swarm presentation and Rewind versus Cyclone) remain
advisory. September 4 contains no new PvP, RBG-objective or addon API change.
No capability, cooldown, target-priority or doctrine override is added.

# Non-goals

This is not a replacement for current-client API observation, player-reviewed
field evidence, a fresh pre-release delta review, or a strategic meta update.

# Acceptance criteria

- [x] The active 12.1 pack and provenance record the September 4 review boundary.
- [x] The affected PvP notes are specific enough to drive field observation.
- [x] The smoke assertion covers the revised review boundary.
- [x] No strategic value is inferred from official text alone.

# Verification

Review Blizzard's [official hotfix ledger](https://worldofwarcraft.blizzard.com/en-us/news/24296142),
then run the Smoke suite, knowledge audit and validation. Repeat the delta review
immediately before any clean candidate build because the ledger is live.

# Rollback

Restore the prior review date and advisory entries as one change. This alters no
SavedVariables or installed add-ons.
