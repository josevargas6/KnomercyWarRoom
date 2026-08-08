# KWR Automation Master Directive

This file is the repository-level operating policy for synchronization,
validation, packaging, release automation, and development isolation.

GitHub is the authoritative source of truth. Local WoW addon folders are
deployment targets only; they are never release sources. Production releases
must be created by an approved GitHub workflow from a commit and tag. Codex
may prepare changes and release evidence, but may not publish production
artifacts or access production credentials.

## Channel policy

KWR recognizes `production`, `release-candidate`, `beta`, `development`, and
`local`. A dirty working tree is always `local`. Development and local builds
must use isolated deployment targets, SavedVariables, UI identity, and (when
communication is approved) message prefixes. They may not use production
CurseForge or Discord credentials.

## Current implementation boundary

The established root-level addon layout remains authoritative. Commander is
the root addon and Sentinel is the optional `KWRSentinel/` addon. Shared data
is not copied between them. Any future generated output must identify its
canonical source and generator and be checked by CI.

The current addon communication policy remains restrictive. Do not add
`SendAddonMessage` or equivalent APIs without an approved protocol decision,
validator update, tests, and security review.

## Required workflow

Every material change has a Markdown task brief, a dedicated branch, a pull
request, validation, tests, package dry-run evidence, documentation, and a
rollback path. Production deployment remains an owner-approved external
operation. The tagged release workflow must pause at the protected
`production` environment before external publication. See
`docs/maintainers/DEVELOPMENT_ENVIRONMENTS.md` and
`docs/maintainers/DEVELOPMENT_TO_PRODUCTION.md`.

## Owner-only configuration

Branch protection, GitHub environments and secrets, Discord applications and
channels, CurseForge project IDs/tokens, and production approval rules require
owner action. They are documented in `docs/maintainers/OWNER_ACTION_CHECKLIST.md`.
