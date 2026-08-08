---
id: KWR-036
title: Establish governed live addon automation
owner: unassigned
priority: high
risk: high
status: planned
authority_references: [AGENTS.md, RELEASE_POLICY.md]
dependencies: []
affected_modules:
  - .github/workflows/release.yml
  - docs/maintainers/LIVE_ADDON_AUTOMATION.md
---

# Objective

Make live-addon development, verification, packaging, promotion, and rollback
repeatable without allowing local or unreviewed content to reach production.

# User outcome

Future maintainers have one operating model from task brief through field
verification and rollback.

# Current behavior

CI certifies changes, but tagged publication depends on external repository
configuration and is not visibly documented as a protected approval gate.

# Required behavior

All release candidates run the complete repository gate. External publication
requires explicit protected `production` environment approval.

# Non-goals

- Automating Blizzard client interaction or combat decisions.
- Adding addon-message transport or bypassing combat lockdown.

# Acceptance criteria

- [ ] Live-addon operating rules and owner-only setup are documented.
- [ ] Production publication is blocked until protected approval.
- [ ] Rollback and field-verification evidence are required.

# Verification

1. Run `./tools/validate.ps1` and the knowledge audit.
2. Run the Lua test gate and package dry run.
3. Confirm the production workflow pauses before external publication.

# Rollback

Redeploy the last approved GitHub artifact and record checksum, reason, and
field verification. Never copy a local WoW folder into release source.
