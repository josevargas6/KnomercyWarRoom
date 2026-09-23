[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$temp = Join-Path ([IO.Path]::GetTempPath()) ("kwr-adjudication-" + [guid]::NewGuid().ToString("N"))
try {
    New-Item -ItemType Directory -Path $temp | Out-Null
    $input = Join-Path $temp "report.json"
    $output = Join-Path $temp "queue.json"
    [pscustomobject]@{
        schema = "kwr-replay-discrepancy-report"
        rows = @(
            [pscustomobject]@{ replayId="taxonomy"; mapProfile="fixture"; classification="unmatched"; label=[pscustomobject]@{primaryActions=@("PLAN:RECOVERY");fallbackActions=@();forbiddenActions=@();sha256="label-a"};observed=[pscustomobject]@{planId="FIXTURE_RECOVERY";actionTags=@("PLAN_FIXTURE_RECOVERY","PLAN_TAG_RECOVERY");resultSha256="result-a"} },
            [pscustomobject]@{ replayId="fallback"; mapProfile="fixture"; classification="fallback"; label=[pscustomobject]@{primaryActions=@("PLAN:CHECK");fallbackActions=@("CALL:HOLD");forbiddenActions=@();sha256="label-b"};observed=[pscustomobject]@{planId="FIXTURE_HOLD";actionTags=@("CALL_HOLD");resultSha256="result-b"} },
            [pscustomobject]@{ replayId="forbidden"; mapProfile="fixture"; classification="forbidden"; label=[pscustomobject]@{primaryActions=@();fallbackActions=@();forbiddenActions=@("CALL:CHASE");sha256="label-c"};observed=[pscustomobject]@{planId="FIXTURE_BAD";actionTags=@("CALL_CHASE");resultSha256="result-c"} }
        )
    } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $input -Encoding UTF8
    $global:LASTEXITCODE = 0
    & (Join-Path $PSScriptRoot "replay-contract-adjudication.ps1") -DiscrepancyReport $input -OutputFile $output
    if ($LASTEXITCODE -ne 0) { throw "Queue script failed." }
    $queue = Get-Content -LiteralPath $output -Raw | ConvertFrom-Json
    if ($queue.summary.total -ne 3 -or $queue.summary.catalogTaxonomyCandidates -ne 1 -or $queue.summary.fallbackOnly -ne 1 -or $queue.summary.forbidden -ne 1) { throw "Unexpected queue summary." }
    $taxonomy = @($queue.rows | Where-Object replayId -eq "taxonomy")[0]
    if ($taxonomy.reviewBucket -ne "review_catalog_taxonomy_equivalence" -or $taxonomy.autoAccepted -ne $false -or $taxonomy.taxonomyCandidates[0] -ne "PLAN_TAG_RECOVERY") { throw "Taxonomy candidate was not retained as non-accepted review evidence." }
    Write-Output "KWR replay contract adjudication test passed"
} finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
