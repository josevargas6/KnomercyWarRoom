[CmdletBinding()]
param(
    [string]$OutputDirectory = "C:\Users\josev\Desktop\KWR\Builds",
    [switch]$SkipBuild,
    [string]$ReplayParityReceiptPath = "",
    [string]$ReplayDiscrepancyReportPath = "",
    [string]$ReplayAdjudicationReviewPath = ""
)

# The one supported offline certification entrypoint. It is safe to run from a
# fresh checkout once the documented Node/Fengari runtime is available.
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
function Invoke-KwrTool([string]$Name, [string[]]$Arguments = @()) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "tools\$Name") @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Name failed." }
}
function Require-KwrJsonReceipt([string]$Path, [string]$ExpectedSchema, [string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Path)) { throw "$Name is required for full offline certification." }
    $fullPath = if ([IO.Path]::IsPathRooted($Path)) { [IO.Path]::GetFullPath($Path) } else { Join-Path $root $Path }
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) { throw "$Name is missing: $fullPath" }
    try { $receipt = Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json }
    catch { throw "$Name is not valid JSON: $fullPath" }
    if ($receipt.schema -ne $ExpectedSchema) { throw "$Name has unexpected schema: $fullPath" }
    return $receipt
}
function Assert-StrictReplayEvidence {
    $parity = Require-KwrJsonReceipt $ReplayParityReceiptPath 'kwr-replay-semantic-parity' 'Replay parity receipt'
    $discrepancy = Require-KwrJsonReceipt $ReplayDiscrepancyReportPath 'kwr-replay-discrepancy-report' 'Replay discrepancy report'
    $reviews = Require-KwrJsonReceipt $ReplayAdjudicationReviewPath 'kwr-replay-contract-adjudication-review-report' 'Replay adjudication review report'
    $parityValid = $parity.schemaVersion -ge 2 -and $parity.pass -eq $true `
        -and $parity.sourceCount -ge 1 -and $parity.sourceCount -eq $parity.packageCount `
        -and @($parity.provenanceDifferences).Count -eq 0 -and @($parity.manifests.errors).Count -eq 0
    if (-not $parityValid) { throw 'Replay parity receipt does not prove complete provenance equality.' }
    $strictPrimary = $discrepancy.summary.total -eq $parity.sourceCount `
        -and $discrepancy.summary.primary -eq $discrepancy.summary.total `
        -and $discrepancy.summary.fallback -eq 0 -and $discrepancy.summary.unmatched -eq 0 `
        -and $discrepancy.summary.forbidden -eq 0
    if (-not $strictPrimary) {
        throw 'Replay discrepancy report does not meet the strict primary gate.'
    }
    $reviewsComplete = $reviews.summary.complete -eq $true -and $reviews.summary.queued -eq $parity.sourceCount `
        -and $reviews.summary.validReviews -eq $parity.sourceCount
    if (-not $reviewsComplete) { throw 'Replay adjudication review report is incomplete.' }
}

if ($SkipBuild) {
    # Source-only CI certification must not rewrite the tracked, machine-bound
    # runtime receipt before the official clean-worktree package build.
    $preflightOut = Join-Path ([IO.Path]::GetTempPath()) ('kwr-runtime-preflight-' + [guid]::NewGuid().ToString('N') + '.json')
    Invoke-KwrTool 'runtime-preflight.ps1' @('-OutFile', $preflightOut)
} else {
    Invoke-KwrTool 'runtime-preflight.ps1'
}
Invoke-KwrTool 'validate.ps1'
# A new TOC version cannot have a candidate-bound package receipt until the
# exact archive exists.  Audit durable knowledge first, omitting only the
# version-bound generated receipts; the complete audit runs after packaging.
Invoke-KwrTool 'knowledge-audit.ps1' @('-AllowGeneratedEvidenceOmission')
Invoke-KwrTool 'season2-rbg-simulation-audit.ps1'
Invoke-KwrTool 'test-lua.ps1' @('-Suite', 'All')
if ($SkipBuild) {
    $benchmarkOut = Join-Path ([IO.Path]::GetTempPath()) ('kwr-offline-benchmark-' + [guid]::NewGuid().ToString('N') + '.json')
    Invoke-KwrTool 'performance-benchmark.ps1' @('-OutFile', $benchmarkOut)
} else {
    Invoke-KwrTool 'performance-benchmark.ps1'
}
if (-not $SkipBuild) {
    Invoke-KwrTool 'build.ps1' @('-OutputDirectory', $OutputDirectory, '-IncludeSentinel')
    Assert-StrictReplayEvidence
    Invoke-KwrTool 'candidate-package-report.ps1' @('-BuildOutputDirectory', $OutputDirectory)
    Invoke-KwrTool 'field-readiness-report.ps1'
    Invoke-KwrTool 'field-blocker-report.ps1'
    Invoke-KwrTool 'offline-completion-audit.ps1'
    Invoke-KwrTool 'knowledge-audit.ps1'
}
if ($SkipBuild) {
    Write-Output 'KWR OFFLINE SOURCE CERTIFICATION PASS'
} else {
    Write-Output 'KWR OFFLINE CERTIFICATION PASS'
}
