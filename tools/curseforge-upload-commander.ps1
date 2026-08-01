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
$changelogPath = Join-Path $root "CHANGELOG.md"
$tocPath = Join-Path $root "KnomercyWarRoom.toc"
. (Join-Path $PSScriptRoot "curseforge-upload-http.ps1")

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
    throw "Missing commander artifact: $artifact"
}
if (-not (Test-Path -LiteralPath $changelogPath)) {
    throw "Missing commander changelog: $changelogPath"
}
if (-not (Test-Path -LiteralPath $tocPath)) {
    throw "Missing commander TOC: $tocPath"
}

$toc = Get-Content -LiteralPath $tocPath
$version = (($toc | Where-Object { $_ -match "^## Version:" }) -replace "^## Version:\s*", "").Trim()
if ([string]::IsNullOrWhiteSpace($version)) {
    throw "Unable to determine commander version from $tocPath."
}

$displayName = "Knomercy War Room $version"

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
$metadataFields.Add('"displayName":' + (ConvertTo-JsonStringLiteral $displayName))
$metadataFields.Add('"releaseType":' + (ConvertTo-JsonStringLiteral $ReleaseType))
$metadataFields.Add('"isMarkedForManualRelease":' + $(if ($ManualRelease) { "true" } else { "false" }))
if ($versionIds.Count -gt 0) {
    $metadataFields.Add('"gameVersions":[' + ($versionIds -join ",") + ']')
}

$metadataJson = "{" + ($metadataFields -join ",") + "}"
$sha256 = (Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash.ToUpperInvariant()

Write-Output "Commander artifact: $artifact"
Write-Output "Display name: $displayName"
Write-Output "SHA-256: $sha256"
Write-Output "Metadata: $metadataJson"

if ($DryRun) {
    Write-Output "DRY RUN: no CurseForge upload performed."
    exit 0
}

if ([string]::IsNullOrWhiteSpace($ProjectId)) {
    throw "Missing CurseForge project id. Set CURSEFORGE_PROJECT_ID or pass -ProjectId."
}
Assert-CurseForgeProjectId -ProjectId $ProjectId
if ([string]::IsNullOrWhiteSpace($ApiToken)) {
    throw "Missing CurseForge API token. Set CURSEFORGE_API_TOKEN or pass -ApiToken."
}

$metadataPath = Join-Path ([IO.Path]::GetTempPath()) ("kwr-curseforge-metadata-" + [guid]::NewGuid().ToString("N") + ".json")
Set-Content -LiteralPath $metadataPath -Value $metadataJson -Encoding UTF8 -NoNewline
try {
    $fileId = Invoke-CurseForgeMultipartUpload `
        -ProjectId $ProjectId `
        -ApiToken $ApiToken `
        -MetadataPath $metadataPath `
        -ArtifactPath $artifact
} finally {
    Remove-Item -LiteralPath $metadataPath -Force -ErrorAction SilentlyContinue
}

Write-Output "CurseForge accepted file $fileId for project $ProjectId."
