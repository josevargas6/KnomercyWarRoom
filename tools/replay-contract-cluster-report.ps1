[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$DiscrepancyReport,
    [Parameter(Mandatory = $true)][string]$OutputFile
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
. (Join-Path $PSScriptRoot 'hash-utils.ps1')

function Resolve-KwrPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    if ([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
    return Join-Path $root $Path
}

function Join-KwrSignature {
    param([object[]]$Values)
    return (@($Values | ForEach-Object { [string]$_ } | Sort-Object -Unique) -join ",")
}

$inputPath = Resolve-KwrPath $DiscrepancyReport
$outputPath = Resolve-KwrPath $OutputFile
if (-not (Test-Path -LiteralPath $inputPath)) { throw "Discrepancy report not found: $inputPath" }
$report = Get-Content -LiteralPath $inputPath -Raw | ConvertFrom-Json
if ($report.schema -ne "kwr-replay-discrepancy-report" -or -not $report.rows) {
    throw "Input is not a replay discrepancy report: $inputPath"
}

$grouped = @{}
foreach ($row in @($report.rows)) {
    $primary = Join-KwrSignature -Values @($row.label.primaryActions)
    $fallback = Join-KwrSignature -Values @($row.label.fallbackActions)
    $planTags = Join-KwrSignature -Values @($row.observed.actionTags | Where-Object { $_ -like "PLAN_TAG_*" })
    $key = @(
        [string]$row.mapProfile,
        [string]$row.classification,
        $primary,
        $fallback,
        [string]$row.observed.planId,
        $planTags
    ) -join "|"
    if (-not $grouped.ContainsKey($key)) { $grouped[$key] = [System.Collections.Generic.List[object]]::new() }
    $grouped[$key].Add($row)
}

$clusters = @()
$index = 0
foreach ($group in @($grouped.GetEnumerator() | Sort-Object Key)) {
    $index++
    $rows = @($group.Value | Sort-Object replayId)
    $first = $rows[0]
    $clusters += [pscustomobject]@{
        clusterId = "KWR295-{0:D3}" -f $index
        rowCount = $rows.Count
        mapProfile = [string]$first.mapProfile
        currentClassification = [string]$first.classification
        primaryActions = @($first.label.primaryActions)
        fallbackActions = @($first.label.fallbackActions)
        forbiddenActions = @($first.label.forbiddenActions)
        observedPlanId = [string]$first.observed.planId
        observedPlanTags = @($first.observed.actionTags | Where-Object { $_ -like "PLAN_TAG_*" } | Sort-Object -Unique)
        labelReviewerProfiles = @($rows | ForEach-Object {
            @($_.label.reviewers | ForEach-Object { "{0}:{1}" -f $_.reviewerId, $_.role })
        } | Sort-Object -Unique)
        replayIds = @($rows | ForEach-Object { [string]$_.replayId })
        reviewInstruction = "A named reviewer must record an evidence-backed disposition for every replay ID in this cluster. Cluster membership is triage only and never changes a benchmark result."
    }
}

$result = [pscustomobject]@{
    schema = "kwr-replay-contract-cluster-report"
    schemaVersion = 1
    generatedAt = [DateTime]::UtcNow.ToString("o")
    source = [pscustomobject]@{
        discrepancyReport = $inputPath
        discrepancyReportSha256 = Get-KwrFileSha256 -LiteralPath $inputPath
        clusterToolSha256 = Get-KwrFileSha256 -LiteralPath $PSCommandPath
    }
    policy = "Clusters reduce review navigation only. They do not establish taxonomy equivalence, accept fallback output, or satisfy the primary-match gate."
    summary = [pscustomobject]@{
        totalRows = @($report.rows).Count
        clusters = $clusters.Count
        primaryClusters = @($clusters | Where-Object { $_.currentClassification -eq "primary" }).Count
        fallbackClusters = @($clusters | Where-Object { $_.currentClassification -eq "fallback" }).Count
        unmatchedClusters = @($clusters | Where-Object { $_.currentClassification -eq "unmatched" }).Count
        forbiddenClusters = @($clusters | Where-Object { $_.currentClassification -eq "forbidden" }).Count
    }
    clusters = $clusters
}
$parent = Split-Path -Parent $outputPath
if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $outputPath -Encoding UTF8
Write-Output "KWR replay contract cluster report"
Write-Output "Rows: $($result.summary.totalRows); clusters: $($result.summary.clusters); fallback clusters: $($result.summary.fallbackClusters); unmatched clusters: $($result.summary.unmatchedClusters)"
Write-Output "Report: $outputPath"
