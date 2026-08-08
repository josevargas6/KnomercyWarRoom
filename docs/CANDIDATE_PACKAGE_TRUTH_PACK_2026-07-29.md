# KWR candidate package truth pack — 2026-07-29

This is a historical offline package receipt for the dated field-test candidate:
`6.1.0-alpha.29`.

Use this pack when we want later live evidence to mean something exact. Every
field screenshot, `/kwr verify`, bug note, AAR, or promotion decision should
tie back to the same distribution ZIP hash.

## Exact candidate artifacts

- Distribution ZIP:
  [KWR_6_1_0_ALPHA_29_DISTRIBUTION.zip](D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom\artifacts\candidate-package\alpha29\KWR_6_1_0_ALPHA_29_DISTRIBUTION.zip)
- Developer ZIP:
  [KWR_6_1_0_ALPHA_29_DEVELOPER.zip](D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom\artifacts\candidate-package\alpha29\KWR_6_1_0_ALPHA_29_DEVELOPER.zip)
- SHA256 manifest:
  [KWR_6_1_0_ALPHA_29_SHA256.txt](D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom\artifacts\candidate-package\alpha29\KWR_6_1_0_ALPHA_29_SHA256.txt)
- Source manifest:
  [KWR_6_1_0_ALPHA_29_SOURCE_MANIFEST.json](D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom\artifacts\candidate-package\alpha29\KWR_6_1_0_ALPHA_29_SOURCE_MANIFEST.json)
- Build provenance:
  [KWR_6_1_0_ALPHA_29_BUILD_PROVENANCE.json](D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom\artifacts\candidate-package\alpha29\KWR_6_1_0_ALPHA_29_BUILD_PROVENANCE.json)
- Reproducibility report:
  [KWR_6_1_0_ALPHA_29_REPRODUCIBILITY.json](D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom\artifacts\candidate-package\alpha29\KWR_6_1_0_ALPHA_29_REPRODUCIBILITY.json)
- Machine-readable receipt:
  [knowledge/candidate-package-report.json](D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom\knowledge\candidate-package-report.json)

## Exact hashes

- Distribution ZIP:
  `8BB330C967E71F5C7DF8A9ED32758EDFEDD59F381048EACBF478B2000E7F08E2`
- Developer ZIP:
  `D37D3432D1567F400EC32B19253AE7774818FAF057B355A34D8D5A0C5734C763`

## What this pack proves now

- the exact alpha.29 candidate ZIPs were built in this workspace
- SHA256 hashes were generated for those exact files
- source digests were captured for distribution and developer payloads
- reproducibility was checked across two clean staged builds
- staged payload digests matched
- PowerShell ZIP container bytes still differ across clean builds, which is
  already documented as a container-level exception rather than payload drift

## What this pack does not pretend to prove

- it does not prove a live clean install
- it does not prove a live upgrade install
- it does not prove taint, blocked-action, or match-end lifecycle safety
- it does not prove field performance or decision quality

Those still need live capture tied to the same distribution ZIP hash.

## Install truth

Use the distribution ZIP for field certification.

Target folder:

- `World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom`

SavedVariables to protect before the session:

- `World of Warcraft\_retail_\WTF\Account\<ACCOUNT>\SavedVariables\KnomercyWarRoom.lua`
- `World of Warcraft\_retail_\WTF\Account\<ACCOUNT>\SavedVariables\KnomercyWarRoom.lua.bak`

Recommended backup folder:

- `World of Warcraft\_retail_\WTF\Account\<ACCOUNT>\SavedVariables\KWR_Backups\6.1.0-alpha.29`

## Clean install checklist

- [ ] Record candidate version `6.1.0-alpha.29`
- [ ] Record distribution ZIP hash
- [ ] Backup current `KnomercyWarRoom.lua` and `.bak`
- [ ] Remove the prior `KnomercyWarRoom` addon folder from `Interface\AddOns`
- [ ] Extract only `KWR_6_1_0_ALPHA_29_DISTRIBUTION.zip`
- [ ] Confirm the installed TOC still shows `6.1.0-alpha.29`
- [ ] Start the game and capture first-load evidence

## Upgrade install checklist

- [ ] Record candidate version `6.1.0-alpha.29`
- [ ] Record distribution ZIP hash
- [ ] Backup current `KnomercyWarRoom.lua` and `.bak`
- [ ] Keep the existing SavedVariables in place
- [ ] Replace only the addon folder with the exact distribution ZIP contents
- [ ] Confirm the installed TOC still shows `6.1.0-alpha.29`
- [ ] Start the game and capture upgrade-path evidence

## Required evidence binding

Every live session should record:

- the exact distribution ZIP hash
- whether the session was clean install or upgrade install
- where the SavedVariables backup lives
- any blocker ID being tested
- screenshots, `/kwr verify`, AAR, or bug evidence tied to that same hash

## Current offline state

The existing build produced the exact candidate artifacts in this workspace, but
the final extracted package audit has not been rerun against those artifacts.
The cached Node and Fengari files are readable, the source smoke, soak, and
replay gates pass, and runtime preflight now reports `packageAuditReady: true`.
Runtime availability is no longer the blocker; refreshing extracted package
certification is the remaining offline package step.

## Next live use

Use this pack together with:

- [FIELD_MACHINE_PREP_2026-07-29.md](D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom\docs\FIELD_MACHINE_PREP_2026-07-29.md)
- [FIELD_READINESS_PACK_2026-07-29.md](D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom\docs\FIELD_READINESS_PACK_2026-07-29.md)
- [CANDIDATE_FIELD_CAPTURE_MATRIX_2026-07-29.md](D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom\docs\CANDIDATE_FIELD_CAPTURE_MATRIX_2026-07-29.md)
- [KWR_TWIN_PEAKS_FIRST_SESSION_OPERATOR_SHEET_2026-07-29.md](D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom\docs\KWR_TWIN_PEAKS_FIRST_SESSION_OPERATOR_SHEET_2026-07-29.md)
- [OFFLINE_COMPLETION_AUDIT_2026-07-29.md](D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\KnomercyWarRoom\docs\OFFLINE_COMPLETION_AUDIT_2026-07-29.md)
