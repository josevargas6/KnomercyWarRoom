[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$temp = Join-Path ([IO.Path]::GetTempPath()) ("kwr-decision-benchmark-" + [guid]::NewGuid().ToString("N"))
try {
    $results = Join-Path $temp "results"
    $golden = Join-Path $temp "golden"
    New-Item -ItemType Directory -Force -Path $results, $golden | Out-Null
    [pscustomobject]@{
        replayId = "fallback-only"
        labelId = "fallback-only-label"
        decision = [pscustomobject]@{
            acceptablePrimaryActions = @("PLAN:PRIMARY")
            acceptableFallbackActions = @("CALL:HOLD")
            forbiddenActions = @()
        }
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $golden "fallback-only.label.json") -Encoding UTF8
    [pscustomobject]@{
        schema = "kwr-replay-run-result"
        schemaVersion = 1
        replayId = "fallback-only"
        replayPath = "fixture.json"
        strict = $false
        final = [pscustomobject]@{ planID = "FALLBACK"; status = "WIN"; tags = @("CALL_HOLD"); summary = @() }
        checkpoints = @()
        evaluation = [pscustomobject]@{ primaryMatch = $false; fallbackMatch = $true; forbiddenHits = @() }
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $results "fallback-only.run.json") -Encoding UTF8
    $out = Join-Path $temp "benchmark.json"
    $global:LASTEXITCODE = 0
    & (Join-Path $PSScriptRoot "decision-benchmark.ps1") -ResultsDir $results -GoldenDir $golden -OutFile $out -RequirePrimaryForEveryResult
    if ($LASTEXITCODE -eq 0) { throw "Primary-required benchmark accepted fallback-only output." }
    $report = Get-Content -LiteralPath $out -Raw | ConvertFrom-Json
    if ($report.summary.pass -ne $false -or $report.summary.requirePrimaryForEveryResult -ne $true -or $report.summary.fallbackOnlyMatches -ne 1) {
        throw "Primary-required benchmark did not record fallback-only failure."
    }
    $global:LASTEXITCODE = 0
    & (Join-Path $PSScriptRoot "decision-benchmark.ps1") -ResultsDir $results -GoldenDir $golden -OutFile $out
    if ($LASTEXITCODE -ne 0) { throw "Bounded diagnostic benchmark rejected allowed fallback." }
    Write-Output "KWR decision benchmark test passed"
} finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
