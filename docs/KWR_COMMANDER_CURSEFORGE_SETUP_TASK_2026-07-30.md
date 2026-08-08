---
id: KWR-037
title: Setup CurseForge commander distribution path
owner: Codex
priority: high
risk: low
dependencies: []
affected_modules:
  - tools/curseforge-upload-commander.ps1
  - CURSEFORGE_UPLOAD.md
  - CURSEFORGE_DESCRIPTION.md
  - CHANGELOG.md
---

# Objective

Establish a repository-owned CurseForge upload path for the main Knomercy War
Room commander addon instead of leaving upload instructions only for the
separate Sentinel package.

# User outcome

The maintainer can build the certified commander ZIP, run one guarded upload
script, and know exactly which archive, metadata, and post-upload checks are
required for a valid CurseForge download.

# Current behavior

The repository already produces a CurseForge-compatible commander distribution
ZIP through `tools/build.ps1`, but only `KWRSentinel` has a dedicated
CurseForge upload checklist and guarded upload script.

# Required behavior

- Add a main-addon CurseForge upload checklist.
- Add a guarded upload script for the main commander package.
- Keep the version and public-description text aligned with the current addon
  candidate.
- Reuse the same evidence-first release pattern already used by Sentinel.

# Non-goals

- Automatic external upload during this task.
- Guessing the maintainer's CurseForge project ID or current Retail game
  version IDs.
- Stable-release promotion policy changes.

# Technical constraints

- Upload instructions must point only to the certified distribution ZIP.
- The developer ZIP and any non-addon artifacts must remain excluded.
- The script must support a safe dry-run path.
- Metadata must come from reviewed repository truth where practical.

# Acceptance criteria

- [x] The repository contains a commander-specific CurseForge upload checklist.
- [x] The repository contains a guarded commander upload script with dry-run support.
- [x] Commander CurseForge description text reflects `6.1.0-alpha.29`.
- [x] Release notes mention the new CurseForge commander distribution path.

# Verification

1. Run `./tools/validate.ps1`.
2. Run the new upload script with `-DryRun` against a certified commander ZIP.

# Rollback

Remove the commander upload script and checklist, then revert the related
description and changelog edits.
