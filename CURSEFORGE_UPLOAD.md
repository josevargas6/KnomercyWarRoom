# Knomercy War Room CurseForge Upload Checklist

Upload artifact:

```text
artifacts\KnomercyWarRoom-6.1.1-alpha.3.zip
```

Project:

```text
https://www.curseforge.com/wow/addons/knomercy-war-room
```

Required upload fields:

- File: `KnomercyWarRoom-6.1.1-alpha.3.zip`
- Display name: `Knomercy War Room 6.1.1-alpha.3`
- Release type: `Alpha`
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
$artifact = "<absolute path to certified KnomercyWarRoom-6.1.1-alpha.3.zip>"
./tools/curseforge-upload-commander.ps1 -ArtifactPath $artifact -ReleaseType alpha -DryRun
./tools/curseforge-upload-commander.ps1 -ArtifactPath $artifact -ReleaseType alpha
```

The script uses CurseForge's multipart upload API:
`POST /api/projects/{projectId}/upload-file` with `metadata` and `file`.

Package evidence:

- ZIP root folder: `KnomercyWarRoom/`
- TOC file: `KnomercyWarRoom/KnomercyWarRoom.toc`
- TOC basename matches parent folder.
- Interface numbers: `120100`, `120007`
- Package audit: passed by the certified build gate.
- Certified ZIP hash: use the generated `KWR_6_1_1_ALPHA_3_SHA256.txt`
  manifest next to the built artifact. Rebuild the package before final upload
  if the source changes.

Do not upload:

- `KWR_6_1_1_ALPHA_3_DEVELOPER.zip`
- `KWRSentinel_*.zip`
- Discord bot files
- SavedVariables or local WTF/account data
- workspace-only temp files

Important download note:

- This field-test build remains an Alpha until the release owner approves
  stable promotion after the required Retail evidence is captured.

After upload:

1. Wait for CurseForge moderation.
2. Record the CurseForge file URL and file ID in your release handoff notes.
3. Verify the public CurseForge download URL before announcing it.
4. Confirm CurseForge reports the file type as `Alpha`, not `Release`.
