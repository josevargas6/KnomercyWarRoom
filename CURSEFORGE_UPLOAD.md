# Knomercy War Room CurseForge Upload Checklist

Upload artifact:

```text
artifacts\KWR_6_1_0_ALPHA_43_DISTRIBUTION.zip
```

Project:

```text
https://www.curseforge.com/wow/addons/knomercy-war-room
```

Required upload fields:

- File: `KWR_6_1_0_ALPHA_43_DISTRIBUTION.zip`
- Display name: `Knomercy War Room 6.1.0-alpha.43`
- Release type: `Alpha` for current candidate testing
- Supported game: `World of Warcraft`
- Supported flavor: `Retail`
- Supported game versions: `12.1.0` / interface `120100` and `12.0.7` / interface `120007`
- Changelog source: `CHANGELOG.md`
- Description source: `CURSEFORGE_DESCRIPTION.md`

Guarded API upload command:

```powershell
$env:CURSEFORGE_PROJECT_ID = "<project id>"
$env:CURSEFORGE_API_TOKEN = "<author token>"
$env:CURSEFORGE_GAME_VERSION_IDS = "<comma-separated Retail version ids>"
$artifact = "<absolute path to certified KWR_6_1_0_ALPHA_42_DISTRIBUTION.zip>"
./tools/curseforge-upload-commander.ps1 -ArtifactPath $artifact -DryRun
./tools/curseforge-upload-commander.ps1 -ArtifactPath $artifact
```

The script uses CurseForge's multipart upload API:
`POST /api/projects/{projectId}/upload-file` with `metadata` and `file`.

Package evidence:

- ZIP root folder: `KnomercyWarRoom/`
- TOC file: `KnomercyWarRoom/KnomercyWarRoom.toc`
- TOC basename matches parent folder.
- Interface numbers: `120100`, `120007`
- Package audit: passed by the certified build gate.
- Certified ZIP hash: use the generated `KWR_6_1_0_ALPHA_42_SHA256.txt`
  manifest next to the built artifact. Rebuild the package before final upload
  if the source changes.

Do not upload:

- `KWR_6_1_0_ALPHA_42_DEVELOPER.zip`
- `KWRSentinel_*.zip`
- Discord bot files
- SavedVariables or local WTF/account data
- workspace-only temp files

Important download note:

- Alpha files are appropriate for field testing.
- CurseForge App users usually need at least one approved `Release` file before
  the addon becomes a normal default install/update target.

After upload:

1. Wait for CurseForge moderation.
2. Record the CurseForge file URL and file ID in your release handoff notes.
3. Verify the public CurseForge download URL before announcing it.
4. When you want broad app installs instead of tester distribution, promote a
   reviewed build as `Release`, not only `Alpha`.
