[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$temp = Join-Path ([IO.Path]::GetTempPath()) ("kwr-discrepancy-" + [guid]::NewGuid().ToString("N"))
try {
    $results = Join-Path $temp "results"; $golden = Join-Path $temp "golden"
    New-Item -ItemType Directory -Force -Path $results, $golden | Out-Null
    @{
        replayId = "fixture-primary"; labelId = "fixture-primary-label"; mapProfile = "fixture"; decision = @{
            acceptablePrimaryActions = @("PLAN:SAFE"); acceptableFallbackActions = @("CALL:HOLD"); forbiddenActions = @("CALL:CHASE"); mustStay = @("anchor"); requiredCapabilities = @("coverage")
        }
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $golden "fixture-primary.label.json") -Encoding UTF8
    @{
        replayId = "fixture-primary"; replayPath = $null; final = @{ planID = "FIXTURE_SAFE"; status = "WIN"; tags = @("PLAN_SAFE") }
        checkpoints = @(@{ at = 0; event = "fixture"; tags = @("CALL_HOLD"); current = @{}; next = @{} })
        evaluation = @{ primaryMatch = $true; fallbackMatch = $false; forbiddenHits = @() }
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $results "fixture-primary.run.json") -Encoding UTF8
    $out = Join-Path $temp "report.json"
    $global:LASTEXITCODE = 0
    & (Join-Path $PSScriptRoot "replay-discrepancy-report.ps1") -ResultsDir $results -GoldenDir $golden -OutputFile $out
    if ($LASTEXITCODE -ne 0) { throw "Report script failed." }
    $report = Get-Content -LiteralPath $out -Raw | ConvertFrom-Json
    if ($report.summary.total -ne 1 -or $report.summary.primary -ne 1 -or $report.summary.forbidden -ne 0) { throw "Unexpected summary." }
    if ($report.rows[0].classification -ne "primary" -or -not (@($report.rows[0].observed.actionTags) -contains "CALL_HOLD")) { throw "Observed evidence was not retained." }
    Write-Output "KWR replay discrepancy report test passed"
} finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
