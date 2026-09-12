[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('kwr-source-recovery-' + [guid]::NewGuid().ToString('N'))
$checks = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    $script:checks++
    if (-not $Condition) { throw $Message }
}

try {
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
    $tool = Join-Path $root 'tools\source-recovery-accounting.ps1'
    $baseline = Join-Path $root 'artifacts\source-install-review-ledger-20260908-live-session.json'
    $reconciliation = Join-Path $root 'artifacts\release-source-reconciliation-20260912-r7.json'
    $reviewLedger = Join-Path $root 'artifacts\release-source-review-ledger-20260912-r7.json'
    $packageAudit = Join-Path $root 'artifacts\release-offline-candidate-20260912-r7\KWR_6_1_1_ALPHA_12_PACKAGE_AUDIT.json'
    foreach ($path in @($tool, $baseline, $reconciliation, $reviewLedger, $packageAudit)) {
        Assert-True (Test-Path -LiteralPath $path -PathType Leaf) "Required P00 evidence is absent: $path"
    }

    $positive = Join-Path $tempRoot 'positive.json'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $tool `
        -HistoricalLedger $baseline `
        -CurrentReconciliationReport $reconciliation `
        -CurrentReviewLedger $reviewLedger `
        -CurrentPackageAudit $packageAudit `
        -OutputFile $positive | Out-Null
    Assert-True ($LASTEXITCODE -eq 0) 'P00 recovery accounting rejected the complete current candidate evidence.'
    $positiveReceipt = Get-Content -LiteralPath $positive -Raw | ConvertFrom-Json
    Assert-True ($positiveReceipt.summary.complete -eq $true) 'P00 complete receipt did not report complete.'
    Assert-True ($positiveReceipt.summary.total -eq 62) 'P00 receipt changed the historical denominator.'
    Assert-True ($positiveReceipt.summary.currentCandidateReleaseExcluded -eq 1) 'P00 receipt did not bind the audited release exclusion.'

    $negative = Join-Path $tempRoot 'negative.json'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $tool `
        -HistoricalLedger $baseline `
        -CurrentReconciliationReport $reconciliation `
        -CurrentReviewLedger $reviewLedger `
        -OutputFile $negative | Out-Null
    Assert-True ($LASTEXITCODE -ne 0) 'P00 accounting accepted a release exclusion without package-audit evidence.'
    $negativeReceipt = Get-Content -LiteralPath $negative -Raw | ConvertFrom-Json
    Assert-True ($negativeReceipt.summary.complete -eq $false -and $negativeReceipt.summary.unresolved -eq 1) `
        'P00 accounting did not fail closed when package-audit evidence was absent.'
    $global:LASTEXITCODE = 0
    Write-Output "KWR_SOURCE_RECOVERY_ACCOUNTING_TEST_PASS checks=$checks"
} finally {
    if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}
