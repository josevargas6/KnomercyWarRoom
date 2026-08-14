---
id: KWR-032
title: Professionalize public surfaces and restore Discord operations
owner: unassigned
priority: high
risk: high
dependencies: [GitHub, CurseForge, Discord, kwr-sentinel-bot]
affected_modules: [README.md, CURSEFORGE_DESCRIPTION.md, docs, .github/workflows, kwr-sentinel-bot]
---

# Objective

Create a coherent public communication system for Commander and Sentinel and
make the Discord bot a reliable, auditable operations surface for maintenance,
release notices, and Codex-ready evidence collection.

# User outcome

Players and reviewers see concise, current, professional descriptions. Operators
have complete private runbooks and health receipts. The bot posts only reviewed
messages, records delivery evidence, and exposes repairable failures without
leaking secrets or private operational details.

# Current behavior

- Public project descriptions and release copy are split across dated documents
  and may not match the active alpha.
- GitHub profile/repository metadata and CurseForge project presentation need a
  public-copy audit.
- Discord scripts post prepared text through guarded webhooks. The former bot
  repository dispatch was retired because no receiver consumed it; bot health
  remains a separate hosting concern.
- The private bot repository and its secrets cannot be inferred from addon files
  alone.

# Required behavior

- Public copy is audience-safe, current, non-empty, and consistent across
  GitHub, CurseForge, release notes, and Discord announcements.
- Operator runbooks contain setup, health checks, failure handling, and rollback
  details without exposing secrets.
- The bot has a deterministic health endpoint/receipt, validates inbound
  release events, deduplicates deliveries, and reports failures to a private
  maintenance artifact.
- Codex maintenance can consume structured bot evidence and publish reviewed
  user updates through the existing guarded workflows.

# Non-goals

- Do not publish tokens, webhook URLs, private logs, or user-identifying data.
- Do not enable unsolicited in-game chat or automated player actions.
- Do not claim live field proof that has not been recorded.

# Technical constraints

- Keep public copy short and player-oriented; keep runbooks private and
  operator-oriented.
- Keep external writes behind explicit workflow/environment controls.
- Preserve the current one-source-of-truth release and maintenance model.

# Acceptance criteria

- [ ] GitHub Commander and Sentinel repository descriptions are current and
  professional.
- [x] Repository-owned Commander copy and CurseForge-ready description are
  current, concise, linked, and audience-safe.
- [ ] CurseForge Commander and Sentinel descriptions, categories, links, and
  alpha-file presentation are non-empty and audience-appropriate.
- [ ] Discord announcement/support/field-testing/ops copy is synchronized to
  the active alpha and contains no secrets or internal-only instructions.
- [ ] Bot health, deduplication, event validation, and evidence receipts are
  covered by deterministic tests.
- [ ] Codex maintenance can consume bot receipts and safely publish reviewed
  updates.
- [x] Release and maintenance handoffs declare the Discord research/support
  role and the GitHub-review-only Codex boundary.
- [ ] Public pages and bot operations are reverified after publication.

# Verification

1. Run public-copy lint and secret scans.
2. Run bot unit/integration tests and a dry-run event delivery.
3. Run GitHub validation, Lua tests, and package audit.
4. Verify GitHub and CurseForge pages as an anonymous viewer.
5. Verify bot health and a deduplicated release event in the private bot
   environment without exposing credentials.

# Rollback

Revert public-copy commits, disable outbound Discord workflows, and retain the
last known-good GitHub release assets. Rotate credentials only if a secret was
ever exposed; never place replacement credentials in the repository.
