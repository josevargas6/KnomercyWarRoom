[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$HistoricalLedger,
    [string]$CurrentReconciliationReport,
    [string]$CurrentReviewLedger,
    [string]$CurrentPackageAudit,
    [Parameter(Mandatory = $true)][string]$OutputFile,
    [int]$ExpectedRows = 62
)

# Historical evidence remains immutable.  When supplied, a current candidate
# reconciliation can close a historical row only by proving the present source
# and deployment relationship (or by a hash-bound current source-only review).
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
. (Join-Path $PSScriptRoot 'hash-utils.ps1')

function Resolve-KwrPath([string]$Path) {
    if ([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
    return Join-Path $root $Path
}

$ledgerPath = Resolve-KwrPath $HistoricalLedger
$currentReconciliationPath = if ($CurrentReconciliationReport) { Resolve-KwrPath $CurrentReconciliationReport } else { $null }
$currentReviewLedgerPath = if ($CurrentReviewLedger) { Resolve-KwrPath $CurrentReviewLedger } else { $null }
$currentPackageAuditPath = if ($CurrentPackageAudit) { Resolve-KwrPath $CurrentPackageAudit } else { $null }
$outputPath = Resolve-KwrPath $OutputFile
if (-not (Test-Path -LiteralPath $ledgerPath -PathType Leaf)) { throw "Historical ledger not found: $ledgerPath" }
$ledger = Get-Content -LiteralPath $ledgerPath -Raw | ConvertFrom-Json
if ($ledger.schema -ne 'kwr-source-install-review-ledger-report' -or $ledger.schemaVersion -ne 1) {
    throw "Unsupported historical ledger schema: $ledgerPath"
}
$currentRows = @{}
$releaseExcluded = @{}
$packageAuditPass = $false
if ($currentReconciliationPath) {
    if (-not (Test-Path -LiteralPath $currentReconciliationPath -PathType Leaf)) { throw "Current reconciliation report not found: $currentReconciliationPath" }
    $currentReconciliation = Get-Content -LiteralPath $currentReconciliationPath -Raw | ConvertFrom-Json
    if ($currentReconciliation.schema -ne 'kwr-source-install-reconciliation' -or $currentReconciliation.schemaVersion -ne 1) { throw "Unsupported current reconciliation schema: $currentReconciliationPath" }
    foreach ($addonReport in @($currentReconciliation.addons)) {
        foreach ($entry in @($addonReport.entries)) {
            $key = "$($entry.addon)|$($entry.path)"
            if ($currentRows.ContainsKey($key)) { throw "Current reconciliation has duplicate row: $key" }
            $currentRows[$key] = $entry
        }
    }
    . (Join-Path $PSScriptRoot 'release-manifest.ps1')
    foreach ($entry in @(Get-ReleaseExcludedEntries)) { $releaseExcluded[[string]$entry] = $true }
    if ($currentPackageAuditPath) {
        if (-not (Test-Path -LiteralPath $currentPackageAuditPath -PathType Leaf)) { throw "Current package audit not found: $currentPackageAuditPath" }
        $currentPackageAuditData = Get-Content -LiteralPath $currentPackageAuditPath -Raw | ConvertFrom-Json
        if ($currentPackageAuditData.result -ne 'PASS') { throw "Current package audit did not pass: $currentPackageAuditPath" }
        $packageAuditPass = $true
    }
}
$currentReviews = @{}
if ($currentReviewLedgerPath) {
    if (-not $currentReconciliationPath) { throw 'CurrentReviewLedger requires CurrentReconciliationReport.' }
    if (-not (Test-Path -LiteralPath $currentReviewLedgerPath -PathType Leaf)) { throw "Current review ledger not found: $currentReviewLedgerPath" }
    $currentReviewLedgerData = Get-Content -LiteralPath $currentReviewLedgerPath -Raw | ConvertFrom-Json
    $reviewLedgerIsComplete = ($currentReviewLedgerData.summary.complete -eq $true)
    if (($currentReviewLedgerData.schema -ne 'kwr-source-install-review-ledger-report') -or ($currentReviewLedgerData.schemaVersion -ne 1) -or (-not $reviewLedgerIsComplete)) { throw "Current review ledger is unsupported or incomplete: $currentReviewLedgerPath" }
    foreach ($entry in @($currentReviewLedgerData.rows)) {
        $key = "$($entry.addon)|$($entry.path)"
        if ($currentReviews.ContainsKey($key)) { throw "Current review ledger has duplicate row: $key" }
        $currentReviews[$key] = $entry
    }
}
$rows = @($ledger.rows)
if ($ExpectedRows -gt 0 -and $rows.Count -ne $ExpectedRows) {
    throw "Historical ledger row count must be $ExpectedRows; found $($rows.Count)."
}
$seen = @{}
$accounted = foreach ($row in $rows | Sort-Object addon,path) {
    $addon = [string]$row.addon
    $path = [string]$row.path
    if ([string]::IsNullOrWhiteSpace($addon) -or [string]::IsNullOrWhiteSpace($path)) {
        throw 'Historical ledger contains a row without addon/path identity.'
    }
    if ($path -match '(^|[\\/])\.\.?(?=([\\/]|$))' -or [IO.Path]::IsPathRooted($path)) {
        throw "Historical ledger path is unsafe: $path"
    }
    $key = "$addon|$path"
    if ($seen.ContainsKey($key)) { throw "Historical ledger has duplicate row: $key" }
    $seen[$key] = $true
    $sourceRoot = if ($addon -eq 'Sentinel') { Join-Path $root 'KWRSentinel' } elseif ($addon -eq 'Commander') { $root } else { throw "Unknown addon: $addon" }
    $currentPath = Join-Path $sourceRoot $path
    $exists = Test-Path -LiteralPath $currentPath -PathType Leaf
    $currentSourceHash = if ($exists) { Get-KwrFileSha256 -LiteralPath $currentPath } else { $null }
    $currentEntry = $currentRows[$key]
    $currentReview = $currentReviews[$key]
    $baselineApplies = $row.reviewStatus -eq 'reviewed' -and $row.disposition -and $row.disposition -ne 'DEFER' `
        -and (($exists -and $row.sourceSha256 -eq $currentSourceHash) -or (-not $exists -and -not $row.sourceSha256))
    $currentCandidateStatus = if ($currentEntry -and $currentEntry.state -eq 'MATCH' -and $currentEntry.sourceSha256 -eq $currentSourceHash) {
        'CURRENT_CANDIDATE_MATCH'
    } elseif ($currentEntry -and $currentEntry.state -eq 'SOURCE_ONLY' -and $currentReview -and $currentReview.reviewStatus -eq 'reviewed' -and $currentReview.sourceSha256 -eq $currentEntry.sourceSha256) {
        'CURRENT_CANDIDATE_REVIEWED_SOURCE_ONLY'
    } elseif (-not $currentEntry -and $exists -and $packageAuditPass -and $releaseExcluded.ContainsKey($path)) {
        'CURRENT_CANDIDATE_RELEASE_EXCLUDED'
    } elseif ($baselineApplies) {
        'BASELINE_DECISION_STILL_APPLIES'
    } else {
        'UNRESOLVED'
    }
    $currentCandidateRow = $null
    if ($currentEntry) {
        $reviewStatus = $null
        $reviewDisposition = $null
        if ($currentReview) {
            $reviewStatus = $currentReview.reviewStatus
            $reviewDisposition = $currentReview.disposition
        }
        $currentCandidateRow = [ordered]@{ state=$currentEntry.state; sourceSha256=$currentEntry.sourceSha256; installedSha256=$currentEntry.installedSha256; reviewStatus=$reviewStatus; disposition=$reviewDisposition }
    }
    [ordered]@{
        addon = $addon
        path = $path
        baseline = [ordered]@{
            sourceSha256 = $row.sourceSha256
            installedSha256 = $row.installedSha256
            reviewStatus = $row.reviewStatus
            disposition = $row.disposition
            recordPath = $row.recordPath
        }
        currentSource = [ordered]@{
            exists = $exists
            sha256 = $currentSourceHash
        }
        currentCandidate = $currentCandidateRow
        finalDecisionStatus = $currentCandidateStatus
    }
}
$unresolved = @($accounted | Where-Object { $_.finalDecisionStatus -eq 'UNRESOLVED' })
$changedSinceBaseline = @($accounted | Where-Object { $_.currentSource.sha256 -and $_.baseline.sourceSha256 -ne $_.currentSource.sha256 })
$missingCurrent = @($accounted | Where-Object { -not $_.currentSource.exists })
$currentCandidateReceipt = $null
if ($currentReconciliationPath) {
    $reviewLedgerHash = $null
    if ($currentReviewLedgerPath) { $reviewLedgerHash = Get-KwrFileSha256 -LiteralPath $currentReviewLedgerPath }
    $packageAuditHash = $null
    if ($currentPackageAuditPath) { $packageAuditHash = Get-KwrFileSha256 -LiteralPath $currentPackageAuditPath }
    $currentCandidateReceipt = [ordered]@{ reconciliationPath=$currentReconciliationPath; reconciliationSha256=Get-KwrFileSha256 -LiteralPath $currentReconciliationPath; reviewLedgerPath=$currentReviewLedgerPath; reviewLedgerSha256=$reviewLedgerHash; packageAuditPath=$currentPackageAuditPath; packageAuditSha256=$packageAuditHash }
}
$report = [ordered]@{
    schema = 'kwr-source-recovery-accounting'
    schemaVersion = 1
    generatedAt = [DateTime]::UtcNow.ToString('o')
    policy = 'Historical source/install evidence is immutable baseline evidence. A current candidate closes a historical row only through a source/install MATCH, a hash-bound reviewed SOURCE_ONLY disposition, or a release-manifest exclusion verified by a passing extracted-package audit. Absent source files require their reviewed historical removal disposition.'
    baseline = [ordered]@{ path=$ledgerPath; sha256=Get-KwrFileSha256 -LiteralPath $ledgerPath; generatedAt=$ledger.generatedAt; summary=$ledger.summary }
    currentCandidate = $currentCandidateReceipt
    summary = [ordered]@{ total=$accounted.Count; unresolved=$unresolved.Count; baselineDecisionStillApplies=@($accounted | Where-Object finalDecisionStatus -eq 'BASELINE_DECISION_STILL_APPLIES').Count; currentCandidateMatches=@($accounted | Where-Object finalDecisionStatus -eq 'CURRENT_CANDIDATE_MATCH').Count; currentCandidateReviewedSourceOnly=@($accounted | Where-Object finalDecisionStatus -eq 'CURRENT_CANDIDATE_REVIEWED_SOURCE_ONLY').Count; currentCandidateReleaseExcluded=@($accounted | Where-Object finalDecisionStatus -eq 'CURRENT_CANDIDATE_RELEASE_EXCLUDED').Count; changedSinceBaseline=$changedSinceBaseline.Count; missingCurrent=$missingCurrent.Count; complete=($unresolved.Count -eq 0) }
    rows = @($accounted)
}
[IO.Directory]::CreateDirectory((Split-Path -Parent $outputPath)) | Out-Null
$report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $outputPath -Encoding UTF8
Write-Output "KWR source recovery accounting: total=$($report.summary.total) unresolved=$($report.summary.unresolved) changed=$($report.summary.changedSinceBaseline) missing=$($report.summary.missingCurrent) complete=$($report.summary.complete)"
Write-Output "Output: $outputPath"
if (-not $report.summary.complete) { exit 1 }
