[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ReconciliationReport,
    [Parameter(Mandatory = $true)][string]$OutputFile
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'hash-utils.ps1')
$repositoryRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$reportPath = if ([IO.Path]::IsPathRooted($ReconciliationReport)) { [IO.Path]::GetFullPath($ReconciliationReport) } else { Join-Path $repositoryRoot $ReconciliationReport }
$outputPath = if ([IO.Path]::IsPathRooted($OutputFile)) { [IO.Path]::GetFullPath($OutputFile) } else { Join-Path $repositoryRoot $OutputFile }
if (-not (Test-Path -LiteralPath $reportPath -PathType Leaf)) { throw "Reconciliation report not found: $reportPath" }
$report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
if ($report.schema -ne "kwr-source-install-reconciliation" -or $report.schemaVersion -ne 1) { throw "Unsupported reconciliation report: $reportPath" }

function Get-SafeEntryPath {
    param([Parameter(Mandatory = $true)][string]$Root, [Parameter(Mandatory = $true)][string]$Entry)
    if ([IO.Path]::IsPathRooted($Entry) -or $Entry -match '(^|[\\/])\.\.?(?=([\\/]|$))') { throw "Unsafe reconciliation entry: $Entry" }
    return Join-Path $Root $Entry
}

function Assert-ReportedHash {
    param([string]$Path, [string]$Expected, [string]$Side, [string]$Entry)
    if (-not $Expected) { return }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Reported $Side file is missing for ${Entry}: $Path" }
    $actual = Get-KwrFileSha256 -LiteralPath $Path
    if ($actual -ne $Expected) { throw "Reported $Side hash drifted for $Entry. Expected $Expected; found $actual." }
}

function Get-TextRange {
    param([string]$SourcePath, [string]$InstalledPath)
    if (-not $SourcePath -or -not $InstalledPath) { return $null }
    $sourceLines = @(Get-Content -LiteralPath $SourcePath)
    $installedLines = @(Get-Content -LiteralPath $InstalledPath)
    $prefix = 0
    while ($prefix -lt $sourceLines.Count -and $prefix -lt $installedLines.Count -and $sourceLines[$prefix] -ceq $installedLines[$prefix]) { $prefix++ }
    $suffix = 0
    while ($suffix -lt ($sourceLines.Count - $prefix) -and $suffix -lt ($installedLines.Count - $prefix) -and $sourceLines[$sourceLines.Count - 1 - $suffix] -ceq $installedLines[$installedLines.Count - 1 - $suffix]) { $suffix++ }
    [pscustomobject]@{
        sourceLines = $sourceLines.Count
        installedLines = $installedLines.Count
        firstDifferingLine = $prefix + 1
        sourceChangedLines = $sourceLines.Count - $prefix - $suffix
        installedChangedLines = $installedLines.Count - $prefix - $suffix
        sharedPrefixLines = $prefix
        sharedSuffixLines = $suffix
    }
}

function Get-ReviewPriority {
    param([Parameter(Mandatory = $true)][string]$Addon, [Parameter(Mandatory = $true)][string]$Entry)
    $criticalRoots = @('Core\', 'Runtime\', 'Intelligence\', 'State\')
    if ($Addon -eq 'Sentinel' -or @($criticalRoots | Where-Object { $Entry.StartsWith($_, [StringComparison]::OrdinalIgnoreCase) }).Count -gt 0) {
        return [pscustomobject]@{
            priority = 'P0'
            rationale = 'Loaded runtime or transport behavior can change tactical truth, lifecycle, or communication.'
        }
    }
    return [pscustomobject]@{
        priority = 'P1'
        rationale = 'Loaded adapter, data, feature, or presentation behavior needs review after runtime-critical differences.'
    }
}

$rows = @()
foreach ($addon in @($report.addons)) {
    $sourceRoot = if ($addon.addon -eq "Sentinel") { Join-Path $report.sourceRoot "KWRSentinel" } else { $report.sourceRoot }
    $installedRoot = if ($addon.addon -eq "Sentinel") { $report.installedSentinelRoot } else { $report.installedRoot }
    foreach ($entry in @($addon.entries | Where-Object { $_.state -ne "MATCH" } | Sort-Object path)) {
        $sourcePath = if ($entry.sourceSha256) { Get-SafeEntryPath -Root $sourceRoot -Entry $entry.path } else { $null }
        $installedPath = if ($entry.installedSha256) { Get-SafeEntryPath -Root $installedRoot -Entry $entry.path } else { $null }
        Assert-ReportedHash -Path $sourcePath -Expected $entry.sourceSha256 -Side "source" -Entry "$($addon.addon)/$($entry.path)"
        Assert-ReportedHash -Path $installedPath -Expected $entry.installedSha256 -Side "installed" -Entry "$($addon.addon)/$($entry.path)"
        $triage = Get-ReviewPriority -Addon $addon.addon -Entry $entry.path
        $rows += [pscustomobject]@{
            addon = $addon.addon
            path = $entry.path
            state = $entry.state
            sourceSha256 = $entry.sourceSha256
            installedSha256 = $entry.installedSha256
            textRange = Get-TextRange -SourcePath $sourcePath -InstalledPath $installedPath
            reviewPriority = $triage.priority
            reviewRationale = $triage.rationale
            reviewStatus = "review_required"
            disposition = $null
            requiredEvidence = @("named reviewer", "source/install comparison", "regression or field evidence appropriate to the file", "recorded disposition")
        }
    }
}

$packet = [pscustomobject]@{
    schema = "kwr-source-install-review-packet"
    schemaVersion = 1
    generatedAt = [DateTime]::UtcNow.ToString("o")
    reconciliationReport = [pscustomobject]@{
        path = $reportPath
        sha256 = Get-KwrFileSha256 -LiteralPath $reportPath
        generatedAt = $report.generatedAt
    }
    reviewPacketToolSha256 = Get-KwrFileSha256 -LiteralPath $PSCommandPath
    policy = "Every row is hash-verified against the captured reconciliation receipt before packet creation. This packet records review work only; it never copies, installs, deletes, or accepts a difference."
    summary = [pscustomobject]@{
        reviewRequired = $rows.Count
        changed = @($rows | Where-Object state -eq "CHANGED").Count
        sourceOnly = @($rows | Where-Object state -eq "SOURCE_ONLY").Count
        installedOnly = @($rows | Where-Object state -eq "INSTALLED_ONLY").Count
        p0 = @($rows | Where-Object reviewPriority -eq "P0").Count
        p1 = @($rows | Where-Object reviewPriority -eq "P1").Count
        reviewed = 0
    }
    entries = $rows
}
$parent = Split-Path -Parent $outputPath
if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$packet | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $outputPath -Encoding UTF8
Write-Output "KWR source/install review packet"
Write-Output "REVIEW_REQUIRED=$($packet.summary.reviewRequired) CHANGED=$($packet.summary.changed) SOURCE_ONLY=$($packet.summary.sourceOnly) INSTALLED_ONLY=$($packet.summary.installedOnly)"
Write-Output "Packet: $outputPath"
