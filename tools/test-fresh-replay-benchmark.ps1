[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$out = Join-Path ([IO.Path]::GetTempPath()) ("kwr-fresh-replay-" + [guid]::NewGuid().ToString("N"))
$sourceOut = Join-Path ([IO.Path]::GetTempPath()) ("kwr-fresh-replay-source-" + [guid]::NewGuid().ToString("N"))
try {
    & (Join-Path $PSScriptRoot "fresh-replay-benchmark.ps1") -MaxReplays 1 -OutputDirectory $out
    if ($LASTEXITCODE -ne 0) { throw "One-replay fresh benchmark failed." }
    $report = Get-Content -LiteralPath (Join-Path $out "fresh-replay-benchmark.json") -Raw | ConvertFrom-Json
    if ($report.scope -notmatch "bounded" -or $report.runs.Count -ne 1 -or -not $report.runs[0].resultSha256) { throw "Fresh benchmark did not bind its one replay result to hashes." }
    if ($report.coverage.missingLabels.Count -ne 0) { throw "Reviewed replay fixtures are missing golden labels." }
    $result = Get-Content -LiteralPath (Join-Path $out $report.runs[0].resultFile.Replace('/', '\\')) -Raw | ConvertFrom-Json
    if (-not (@($result.final.tags) | Where-Object { $_ -like 'PLAN_TAG_*' })) { throw "Fresh replay output did not retain reviewed plan taxonomy tags." }
    $windowsOutput = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "tools\\fresh-replay-benchmark.ps1") -MaxReplays 1 -OutputDirectory $out
    if ($LASTEXITCODE -ne 0 -or -not ($windowsOutput -match "KWR fresh replay benchmark: True")) { throw "Windows PowerShell 5-compatible fresh benchmark failed." }

    # Raw source intentionally contains developer modules, unlike the player
    # package. Source parity must opt into that mode rather than disabling the
    # production-only assertion for extracted-package tests.
    & (Join-Path $PSScriptRoot "fresh-replay-benchmark.ps1") -MaxReplays 1 -OutputDirectory $sourceOut -AddonRoot $root -SourceRuntime -SkipDecisionBenchmark
    if ($LASTEXITCODE -ne 0) { throw "One-replay source-runtime benchmark failed." }
    $sourceReport = Get-Content -LiteralPath (Join-Path $sourceOut "fresh-replay-benchmark.json") -Raw | ConvertFrom-Json
    if (-not $sourceReport.source.sourceRuntime -or $sourceReport.runs.Count -ne 1 -or -not $sourceReport.runs[0].pass) {
        throw "Source-runtime benchmark did not bind and pass its explicit source mode."
    }
} finally {
    if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out -Recurse -Force }
    if (Test-Path -LiteralPath $sourceOut) { Remove-Item -LiteralPath $sourceOut -Recurse -Force }
}
Write-Output "KWR fresh replay benchmark test passed"
