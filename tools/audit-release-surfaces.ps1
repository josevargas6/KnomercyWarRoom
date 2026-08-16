[CmdletBinding()]
param(
    [string]$Repository = "josevargas6/KnomercyWarRoom",
    [string]$ReleaseTag = "v6.1.0"
)

$ErrorActionPreference = "Stop"
$headers = @{
    Accept = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}
$apiRoot = "https://api.github.com/repos/$Repository"
$findings = New-Object System.Collections.Generic.List[string]

function Add-Finding {
    param([string]$Message)
    $findings.Add($Message)
}

$release = Invoke-RestMethod -Headers $headers -Uri "$apiRoot/releases/tags/$ReleaseTag"
$expectsPrerelease = $ReleaseTag.Substring(1) -match '-'
if ([bool]$release.prerelease -ne $expectsPrerelease) {
    Add-Finding "Release $ReleaseTag channel does not match its semantic version."
}
if ($release.assets.Count -lt 1) { Add-Finding "Release $ReleaseTag has no GitHub assets." }

$workflowResponse = Invoke-RestMethod -Headers $headers -Uri "$apiRoot/contents/.github/workflows/release.yml?ref=main"
$workflow = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($workflowResponse.content))
if ($workflow -notmatch 'CURSEFORGE_PROJECT_ID:\s*"1632632"') {
    Add-Finding "main release workflow does not contain Commander numeric CurseForge project id 1632632."
}
if ($workflow -notmatch 'CURSEFORGE_PROJECT_ID:\s*"1614463"') {
    Add-Finding "main release workflow does not contain Sentinel numeric CurseForge project id 1614463."
}
if ($workflow -notmatch 'curseforge-upload-http') {
    Add-Finding "main release workflow does not use truthful CurseForge upload response validation."
}

$comparison = Invoke-RestMethod -Headers $headers -Uri "$apiRoot/compare/main...develop"
if ($comparison.status -ne "ahead") {
    Add-Finding "main and develop are $($comparison.status) (develop ahead $($comparison.ahead_by), behind $($comparison.behind_by)); targeted promotion is required."
}

foreach ($path in @(
    "tools/sentinel-discord-announce.ps1",
    "docs/KWR_COMMANDER_DISCORD_CHANNEL_UPDATES.md",
    "docs/SENTINEL_DISCORD_CHANNEL_UPDATES.md"
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot "..\$path") -PathType Leaf)) {
        Add-Finding "Missing Discord communication source: $path"
    }
}

[pscustomobject]@{
    repository = $Repository
    release = $ReleaseTag
    github_release_assets = $release.assets.Count
    github_release_url = $release.html_url
    findings = @($findings)
    status = if ($findings.Count -eq 0) { "PASS" } else { "BLOCKED" }
} | ConvertTo-Json -Depth 5

if ($findings.Count -gt 0) { exit 2 }
