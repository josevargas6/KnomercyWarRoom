[CmdletBinding()]
param(
    [string]$ProjectId = $env:CURSEFORGE_PROJECT_ID,
    [string]$ApiToken = $env:CURSEFORGE_API_TOKEN,
    [string]$GameVersionIds = $env:CURSEFORGE_GAME_VERSION_IDS,
    [Parameter(Mandatory = $true)]
    [string]$ArtifactPath,
    [ValidateSet("alpha", "beta", "release")]
    [string]$ReleaseType = "alpha",
    [switch]$ManualRelease,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$artifact = [IO.Path]::GetFullPath($ArtifactPath)
$changelogPath = Join-Path $root "KWRSentinel\CHANGELOG.md"
$tocPath = Join-Path $root "KWRSentinel\KWRSentinel.toc"

function ConvertTo-JsonStringLiteral {
    param([AllowNull()][string]$Value)

    $text = if ($null -eq $Value) { "" } else { $Value }
    $text = $text.Replace("\", "\\")
    $text = $text.Replace('"', '\"')
    $text = $text.Replace("`r", "\r")
    $text = $text.Replace("`n", "\n")
    $text = $text.Replace("`t", "\t")
    return '"' + $text + '"'
}

if (-not (Test-Path -LiteralPath $artifact)) {
    throw "Missing Sentinel artifact: $artifact"
}
if (-not (Test-Path -LiteralPath $changelogPath)) {
    throw "Missing Sentinel changelog: $changelogPath"
}
if (-not (Test-Path -LiteralPath $tocPath)) {
    throw "Missing Sentinel TOC: $tocPath"
}

$toc = Get-Content -LiteralPath $tocPath
$version = (($toc | Where-Object { $_ -match "^## Version:" }) -replace "^## Version:\s*", "").Trim()
if ([string]::IsNullOrWhiteSpace($version)) {
    throw "Unable to determine Sentinel version from $tocPath."
}

$versionIds = @()
if (-not [string]::IsNullOrWhiteSpace($GameVersionIds)) {
    $versionIds = @(
        $GameVersionIds -split "," |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -ne "" } |
            ForEach-Object { [int]$_ }
    )
}

$metadataFields = New-Object System.Collections.Generic.List[string]
$metadataFields.Add('"changelog":' + (ConvertTo-JsonStringLiteral (Get-Content -LiteralPath $changelogPath -Raw)))
$metadataFields.Add('"changelogType":"markdown"')
$metadataFields.Add('"displayName":' + (ConvertTo-JsonStringLiteral ("KWR Sentinel $version")))
$metadataFields.Add('"releaseType":' + (ConvertTo-JsonStringLiteral $ReleaseType))
$metadataFields.Add('"isMarkedForManualRelease":' + $(if ($ManualRelease) { "true" } else { "false" }))
if ($versionIds.Count -gt 0) {
    $metadataFields.Add('"gameVersions":[' + ($versionIds -join ",") + ']')
}

$metadataJson = "{" + ($metadataFields -join ",") + "}"
$sha256 = (Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash.ToUpperInvariant()

Write-Output "Sentinel artifact: $artifact"
Write-Output "SHA-256: $sha256"
Write-Output "Metadata: $metadataJson"

if ($DryRun) {
    Write-Output "DRY RUN: no CurseForge upload performed."
    exit 0
}

if ([string]::IsNullOrWhiteSpace($ProjectId)) {
    throw "Missing CurseForge project id. Set CURSEFORGE_PROJECT_ID or pass -ProjectId."
}
if ([string]::IsNullOrWhiteSpace($ApiToken)) {
    throw "Missing CurseForge API token. Set CURSEFORGE_API_TOKEN or pass -ApiToken."
}
if ($versionIds.Count -eq 0) {
    throw "Missing CurseForge game version ids. Set CURSEFORGE_GAME_VERSION_IDS to comma-separated numeric IDs."
}

$curl = Get-Command curl.exe -ErrorAction SilentlyContinue
if (-not $curl) {
    throw "curl.exe is required for the multipart CurseForge upload."
}

$endpoint = "https://www.curseforge.com/api/projects/$ProjectId/upload-file"
& $curl.Source `
    -f `
    -X POST `
    -H "X-Api-Token: $ApiToken" `
    -F "metadata=$metadataJson" `
    -F "file=@$artifact" `
    $endpoint

if ($LASTEXITCODE -ne 0) {
    throw "CurseForge upload failed with exit code $LASTEXITCODE."
}

Write-Output "CurseForge upload request completed for project $ProjectId."
