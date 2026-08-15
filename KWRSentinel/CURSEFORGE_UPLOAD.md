# KWR Sentinel CurseForge Upload Checklist

Upload artifact:

```text
<absolute path to certified KWRSentinel_6_1_0.zip>
```

Project:

```text
https://www.curseforge.com/wow/addons/kwr-sentinel
```

Required upload fields:

- File: `KWRSentinel_6_1_0.zip`
- Display name: `KWR Sentinel 6.1.0`
- Release type: `Release`
- Supported game: `World of Warcraft`
- Supported flavor: `Retail`
- Supported game versions: `12.1.0` / interface `120100` and `12.0.7` / interface `120007`
- Changelog source: `KWRSentinel/CHANGELOG.md`
- Description source: `KWRSentinel/CURSEFORGE_DESCRIPTION.md`

Guarded API upload command:

```powershell
$env:CURSEFORGE_PROJECT_ID = "<project id>"
$env:CURSEFORGE_API_TOKEN = "<author token>"
$env:CURSEFORGE_GAME_VERSION_IDS = "<comma-separated Retail version ids>"
$artifact = "<absolute path to certified KWRSentinel zip>"
./tools/curseforge-upload-sentinel.ps1 -ArtifactPath $artifact -ReleaseType release -DryRun
./tools/curseforge-upload-sentinel.ps1 -ArtifactPath $artifact -ReleaseType release
```

The script uses CurseForge's multipart upload API:
`POST /api/projects/{projectId}/upload-file` with `metadata` and `file`.

GitHub Actions route:

1. Add repository secrets:
   - `CURSEFORGE_PROJECT_ID`
   - `CURSEFORGE_API_TOKEN`
   - `CURSEFORGE_GAME_VERSION_IDS`
2. Run `.github/workflows/sentinel-release-ops.yml` with
   `upload_curseforge=true` and `confirm_external_writes=PUBLISH`.

Package evidence:

- ZIP root folder: `KWRSentinel/`
- TOC file: `KWRSentinel/KWRSentinel.toc`
- TOC basename matches parent folder.
- Interface numbers: `120100`, `120007`
- Package audit: passed.
- Sentinel ZIP SHA-256: use the generated
  `KWR_6_1_0_SHA256.txt` manifest next to the built artifact. The
  exact hash is intentionally not embedded here because this file is packaged
  inside the ZIP.

Do not upload:

- `KWR_6_1_0_DISTRIBUTION.zip`
- `KWR_6_1_0_DEVELOPER.zip`
- Discord bot files
- SavedVariables or local WTF/account data
- workspace-only temp files

After upload:

1. Wait for CurseForge moderation.
2. Record the CurseForge file URL and file ID in
   `docs/SENTINEL_RELEASE_HANDOFF.md`.
3. Verify the public CurseForge download URL before announcing it.
4. Post the Discord channel updates from
   `docs/SENTINEL_DISCORD_CHANNEL_UPDATES.md`.
