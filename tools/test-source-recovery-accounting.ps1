[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('kwr-source-recovery-' + [guid]::NewGuid().ToString('N'))
$checks = 0
. (Join-Path $PSScriptRoot 'hash-utils.ps1')

function Assert-True {
    param([bool]$Condition, [string]$Message)
    $script:checks++
    if (-not $Condition) { throw $Message }
}

try {
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
    $tool = Join-Path $root 'tools\source-recovery-accounting.ps1'
    $baseline = Join-Path $root 'artifacts\source-install-review-ledger-20260908-live-session.json'
    foreach ($path in @($tool, $baseline)) {
        Assert-True (Test-Path -LiteralPath $path -PathType Leaf) "Required P00 evidence is absent: $path"
    }
    # Historical r7 candidate hashes are not the current source. Construct a
    # scoped contract fixture from this checkout instead of letting a new
    # version make the positive test stale by definition.
    $sourceOnlyPath = 'Core\Diagnostics.lua'
    $releaseExcludedPath = 'UI\ReporterMap.lua'
    $historical = Get-Content -LiteralPath $baseline -Raw | ConvertFrom-Json
    $entries = @{ Commander = @(); Sentinel = @() }
    $reviews = @()
    foreach ($row in @($historical.rows)) {
        $sourceRoot = if ($row.addon -eq 'Sentinel') { Join-Path $root 'KWRSentinel' } else { $root }
        $sourceFile = Join-Path $sourceRoot $row.path
        if (-not (Test-Path -LiteralPath $sourceFile -PathType Leaf)) { continue }
        if ($row.path -eq $releaseExcludedPath) { continue }
        $hash = Get-KwrFileSha256 -LiteralPath $sourceFile
        $state = if ($row.path -eq $sourceOnlyPath) { 'SOURCE_ONLY' } else { 'MATCH' }
        $entries[[string]$row.addon] += [ordered]@{
            addon=$row.addon; path=$row.path; state=$state;
            sourceSha256=$hash; installedSha256=$(if($state -eq 'MATCH'){$hash}else{$null})
        }
        if ($state -eq 'SOURCE_ONLY') {
            $reviews += [ordered]@{
                addon=$row.addon; path=$row.path; reviewStatus='reviewed';
                disposition='PRESERVE_SOURCE'; sourceSha256=$hash
            }
        }
    }
    $reconciliation = Join-Path $tempRoot 'reconciliation.json'
    $reviewLedger = Join-Path $tempRoot 'review-ledger.json'
    $packageAudit = Join-Path $tempRoot 'package-audit.json'
    [ordered]@{
        schema='kwr-source-install-reconciliation'; schemaVersion=1;
        addons=@(
            [ordered]@{ addon='Commander'; entries=@($entries.Commander) },
            [ordered]@{ addon='Sentinel'; entries=@($entries.Sentinel) }
        )
    } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reconciliation -Encoding UTF8
    [ordered]@{
        schema='kwr-source-install-review-ledger-report'; schemaVersion=1;
        summary=@{complete=$true}; rows=$reviews
    } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reviewLedger -Encoding UTF8
    @{result='PASS'; scope='SYNTHETIC_CONTRACT_FIXTURE'} |
        ConvertTo-Json | Set-Content -LiteralPath $packageAudit -Encoding UTF8

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
    Assert-True ($positiveReceipt.summary.currentCandidateReviewedSourceOnly -eq 1) 'P00 receipt did not bind the source-only review.'

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
