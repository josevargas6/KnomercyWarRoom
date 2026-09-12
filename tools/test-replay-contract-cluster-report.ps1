[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$temp = Join-Path ([IO.Path]::GetTempPath()) ("kwr-replay-clusters-" + [guid]::NewGuid().ToString("N"))
try {
    New-Item -ItemType Directory -Force -Path $temp | Out-Null
    $rows = @(
        [pscustomobject]@{ replayId="one"; mapProfile="ab_standard"; classification="unmatched"; label=[pscustomobject]@{ primaryActions=@("PLAN:RECOVERY"); fallbackActions=@("CALL:HOLD"); forbiddenActions=@(); reviewers=@([pscustomobject]@{reviewerId="tactical-reviewer";role="commander"}) }; observed=[pscustomobject]@{ planId="AB_RECOVER"; actionTags=@("PLAN_TAG_RECOVERY", "CALL_HOLD") } },
        [pscustomobject]@{ replayId="two"; mapProfile="ab_standard"; classification="unmatched"; label=[pscustomobject]@{ primaryActions=@("PLAN:RECOVERY"); fallbackActions=@("CALL:HOLD"); forbiddenActions=@(); reviewers=@([pscustomobject]@{reviewerId="tactical-reviewer";role="commander"}) }; observed=[pscustomobject]@{ planId="AB_RECOVER"; actionTags=@("CALL_HOLD", "PLAN_TAG_RECOVERY") } },
        [pscustomobject]@{ replayId="three"; mapProfile="wsg_standard"; classification="fallback"; label=[pscustomobject]@{ primaryActions=@("PLAN:PACE_AHEAD"); fallbackActions=@("CALL:HOLD"); forbiddenActions=@(); reviewers=@([pscustomobject]@{reviewerId="fixture";role="fixture-contract"}) }; observed=[pscustomobject]@{ planId="WSG_HOLD"; actionTags=@("PLAN_TAG_WIN", "CALL_HOLD") } }
    )
    [pscustomobject]@{ schema="kwr-replay-discrepancy-report"; rows=$rows } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $temp "input.json") -Encoding UTF8
    $output = Join-Path $temp "output.json"
    $global:LASTEXITCODE = 0
    & (Join-Path $PSScriptRoot "replay-contract-cluster-report.ps1") -DiscrepancyReport (Join-Path $temp "input.json") -OutputFile $output
    if ($LASTEXITCODE -ne 0) { throw "Cluster report generation failed." }
    $report = Get-Content -LiteralPath $output -Raw | ConvertFrom-Json
    if ($report.summary.totalRows -ne 3 -or $report.summary.clusters -ne 2) { throw "Cluster report did not group equivalent rows deterministically." }
    $shared = @($report.clusters | Where-Object { $_.rowCount -eq 2 })
    if ($shared.Count -ne 1 -or @($shared[0].replayIds) -join "," -ne "one,two") { throw "Cluster report lost replay-level review scope." }
    if ($report.policy -notmatch "do not establish taxonomy equivalence") { throw "Cluster report permits automatic contract acceptance." }
    Write-Output "KWR replay contract cluster report test passed"
} finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
