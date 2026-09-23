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

function Normalize-KwrToken {
    param([AllowNull()][string]$Value)
    $token = ([string]$Value).ToUpperInvariant() -replace "[^A-Z0-9]+", "_"
    $token = $token -replace "_+", "_"
    return $token.Trim('_')
}

$inputPath = Resolve-KwrPath $DiscrepancyReport
$outputPath = Resolve-KwrPath $OutputFile
if (-not (Test-Path -LiteralPath $inputPath)) { throw "Discrepancy report not found: $inputPath" }
$report = Get-Content -LiteralPath $inputPath -Raw | ConvertFrom-Json
if ($report.schema -ne "kwr-replay-discrepancy-report" -or -not $report.rows) {
    throw "Input is not a replay discrepancy report: $inputPath"
}

$rows = @()
foreach ($row in @($report.rows | Sort-Object replayId)) {
    $primary = @($row.label.primaryActions)
    $observedTags = @($row.observed.actionTags)
    $taxonomyCandidates = @()
    foreach ($expected in $primary) {
        $normalized = Normalize-KwrToken $expected
        if ($normalized -like "PLAN_*") {
            $catalogTag = "PLAN_TAG_" + $normalized.Substring(5)
            if ($observedTags -contains $catalogTag) { $taxonomyCandidates += $catalogTag }
        }
    }
    $taxonomyCandidates = @($taxonomyCandidates | Sort-Object -Unique)
    $bucket = switch ([string]$row.classification) {
        "forbidden" { "block_forbidden_output"; break }
        "primary" { "record_primary_match"; break }
        "fallback" { "review_fallback_only"; break }
        default {
            if ($taxonomyCandidates.Count -gt 0) { "review_catalog_taxonomy_equivalence" }
            else { "review_planner_or_label_contract" }
        }
    }
    $rows += [pscustomobject]@{
        replayId = $row.replayId
        mapProfile = $row.mapProfile
        currentClassification = $row.classification
        reviewBucket = $bucket
        autoAccepted = $false
        reviewer = $null
        disposition = $null
        labelReviewers = @($row.label.reviewers)
        primaryActions = $primary
        fallbackActions = @($row.label.fallbackActions)
        forbiddenActions = @($row.label.forbiddenActions)
        observedPlanId = $row.observed.planId
        observedPlanTags = @($observedTags | Where-Object { $_ -like "PLAN_TAG_*" })
        taxonomyCandidates = $taxonomyCandidates
        observedActionTags = $observedTags
        resultSha256 = $row.observed.resultSha256
        labelSha256 = $row.label.sha256
    }
}

$summary = [pscustomobject]@{
    total = $rows.Count
    requiresHumanReview = @($rows | Where-Object { $_.reviewBucket -notin @("record_primary_match") }).Count
    forbidden = @($rows | Where-Object { $_.reviewBucket -eq "block_forbidden_output" }).Count
    primary = @($rows | Where-Object { $_.reviewBucket -eq "record_primary_match" }).Count
    fallbackOnly = @($rows | Where-Object { $_.reviewBucket -eq "review_fallback_only" }).Count
    catalogTaxonomyCandidates = @($rows | Where-Object { $_.reviewBucket -eq "review_catalog_taxonomy_equivalence" }).Count
    plannerOrLabelReviews = @($rows | Where-Object { $_.reviewBucket -eq "review_planner_or_label_contract" }).Count
}
$queue = [pscustomobject]@{
    schema = "kwr-replay-contract-adjudication-queue"
    schemaVersion = 1
    generatedAt = [DateTime]::UtcNow.ToString("o")
    source = [pscustomobject]@{
        discrepancyReport = $inputPath
        adjudicationToolSha256 = Get-KwrFileSha256 -LiteralPath $PSCommandPath
    }
    policy = "Rows are review prompts only. No taxonomy candidate, fallback, or observed plan is accepted automatically."
    summary = $summary
    rows = $rows
}
$parent = Split-Path -Parent $outputPath
if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$queue | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $outputPath -Encoding UTF8
Write-Output "KWR replay contract adjudication queue"
Write-Output "Rows: $($summary.total); taxonomy candidates: $($summary.catalogTaxonomyCandidates); planner/label reviews: $($summary.plannerOrLabelReviews); fallback-only: $($summary.fallbackOnly); forbidden: $($summary.forbidden)"
Write-Output "Queue: $outputPath"
