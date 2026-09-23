[CmdletBinding()]
param(
    [string]$SourceRoot = "",
    [Parameter(Mandatory = $true)][string]$InstalledRoot,
    [string]$InstalledSentinelRoot = "",
    [Parameter(Mandatory = $true)][string]$OutputFile
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'hash-utils.ps1')
$repositoryRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
if (-not $SourceRoot) { $SourceRoot = $repositoryRoot }
$sourcePath = [IO.Path]::GetFullPath($SourceRoot)
$installedPath = [IO.Path]::GetFullPath($InstalledRoot)
$installedSentinelPath = if ($InstalledSentinelRoot) {
    [IO.Path]::GetFullPath($InstalledSentinelRoot)
} else {
    Join-Path (Split-Path -Parent $installedPath) "KWRSentinel"
}
$outputPath = if ([IO.Path]::IsPathRooted($OutputFile)) { [IO.Path]::GetFullPath($OutputFile) } else { Join-Path $repositoryRoot $OutputFile }

function Get-TocEntries {
    param([Parameter(Mandatory = $true)][string]$Root, [Parameter(Mandatory = $true)][string]$Toc)
    $tocPath = Join-Path $Root $Toc
    if (-not (Test-Path -LiteralPath $tocPath -PathType Leaf)) { throw "TOC not found: $tocPath" }
    $entries = @(
        Get-Content -LiteralPath $tocPath |
            Where-Object { $_ -and $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*##' } |
            ForEach-Object { $_.Trim().Replace('/', '\\') }
    )
    foreach ($entry in $entries) {
        if ($entry -match '(^|\\)\.\.?(\\|$)' -or [IO.Path]::IsPathRooted($entry)) {
            throw "Unsafe TOC entry in ${tocPath}: $entry"
        }
    }
    return $entries
}

function Get-EntryHash {
    param([Parameter(Mandatory = $true)][string]$Root, [Parameter(Mandatory = $true)][string]$Entry)
    $path = Join-Path $Root $Entry
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "TOC entry not found: $path" }
    return Get-KwrFileSha256 -LiteralPath $path
}

function Compare-AddonToc {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$SourceAddonRoot,
        [Parameter(Mandatory = $true)][string]$InstalledAddonRoot,
        [Parameter(Mandatory = $true)][string]$Toc
    )
    $sourceEntries = @(Get-TocEntries -Root $sourceAddonRoot -Toc $Toc)
    $installedEntries = @(Get-TocEntries -Root $installedAddonRoot -Toc $Toc)
    $allEntries = @($sourceEntries + $installedEntries | Sort-Object -Unique)
    $rows = @()
    foreach ($entry in $allEntries) {
        $inSource = $sourceEntries -contains $entry
        $inInstalled = $installedEntries -contains $entry
        $sourceHash = if ($inSource) { Get-EntryHash -Root $sourceAddonRoot -Entry $entry } else { $null }
        $installedHash = if ($inInstalled) { Get-EntryHash -Root $installedAddonRoot -Entry $entry } else { $null }
        $state = if ($inSource -and $inInstalled -and $sourceHash -eq $installedHash) { "MATCH" }
            elseif ($inSource -and $inInstalled) { "CHANGED" }
            elseif ($inSource) { "SOURCE_ONLY" }
            else { "INSTALLED_ONLY" }
        $rows += [pscustomobject]@{
            addon = $Name
            path = $entry
            state = $state
            sourceSha256 = $sourceHash
            installedSha256 = $installedHash
            disposition = if ($state -eq "MATCH") { "verified_match" } else { "review_required" }
        }
    }
    return [pscustomobject]@{
        addon = $Name
        sourceTocSha256 = Get-KwrFileSha256 -LiteralPath (Join-Path $sourceAddonRoot $Toc)
        installedTocSha256 = Get-KwrFileSha256 -LiteralPath (Join-Path $installedAddonRoot $Toc)
        sourceEntries = $sourceEntries.Count
        installedEntries = $installedEntries.Count
        summary = [pscustomobject]@{
            match = @($rows | Where-Object { $_.state -eq "MATCH" }).Count
            changed = @($rows | Where-Object { $_.state -eq "CHANGED" }).Count
            sourceOnly = @($rows | Where-Object { $_.state -eq "SOURCE_ONLY" }).Count
            installedOnly = @($rows | Where-Object { $_.state -eq "INSTALLED_ONLY" }).Count
        }
        entries = $rows
    }
}

$commander = Compare-AddonToc -Name "Commander" -SourceAddonRoot $sourcePath -InstalledAddonRoot $installedPath -Toc "KnomercyWarRoom.toc"
$sentinel = Compare-AddonToc -Name "Sentinel" -SourceAddonRoot (Join-Path $sourcePath "KWRSentinel") -InstalledAddonRoot $installedSentinelPath -Toc "KWRSentinel.toc"
$report = [pscustomobject]@{
    schema = "kwr-source-install-reconciliation"
    schemaVersion = 1
    generatedAt = [DateTime]::UtcNow.ToString("o")
    sourceRoot = $sourcePath
    installedRoot = $installedPath
    installedSentinelRoot = $installedSentinelPath
    policy = "Any non-MATCH TOC entry is review_required; this report never copies, deletes, installs, or accepts a difference."
    addons = @($commander, $sentinel)
    summary = [pscustomobject]@{
        match = @($commander.entries + $sentinel.entries | Where-Object { $_.state -eq "MATCH" }).Count
        changed = @($commander.entries + $sentinel.entries | Where-Object { $_.state -eq "CHANGED" }).Count
        sourceOnly = @($commander.entries + $sentinel.entries | Where-Object { $_.state -eq "SOURCE_ONLY" }).Count
        installedOnly = @($commander.entries + $sentinel.entries | Where-Object { $_.state -eq "INSTALLED_ONLY" }).Count
    }
}
$parent = Split-Path -Parent $outputPath
if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $outputPath -Encoding UTF8
Write-Output "KWR source/install reconciliation"
Write-Output "MATCH=$($report.summary.match) CHANGED=$($report.summary.changed) SOURCE_ONLY=$($report.summary.sourceOnly) INSTALLED_ONLY=$($report.summary.installedOnly)"
Write-Output "Report: $outputPath"
