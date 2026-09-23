[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$temp = Join-Path ([IO.Path]::GetTempPath()) ("kwr-adjudication-review-" + [guid]::NewGuid().ToString("N"))
try {
    $reviews = Join-Path $temp "reviews"; New-Item -ItemType Directory -Force -Path $reviews | Out-Null
    $queue = Join-Path $temp "queue.json"; $output = Join-Path $temp "report.json"
    $rows = @(
        [pscustomobject]@{replayId="one";resultSha256="RESULT_ONE";labelSha256="LABEL_ONE"},
        [pscustomobject]@{replayId="two";resultSha256="RESULT_TWO";labelSha256="LABEL_TWO"}
    )
    [pscustomobject]@{schema="kwr-replay-contract-adjudication-queue";rows=$rows} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $queue -Encoding UTF8
    [pscustomobject]@{schema="kwr-replay-contract-adjudication-review";schemaVersion=1;replayId="one";resultSha256="RESULT_ONE";labelSha256="LABEL_ONE";reviewer=[pscustomobject]@{reviewerId="named-reviewer";role="rbg-commander"};disposition="LABEL_DEFECT";evidence=@("review-note-42");reviewedAt="2026-09-08T00:00:00Z"} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $reviews "one.adjudication.json") -Encoding UTF8
    $global:LASTEXITCODE=0
    & (Join-Path $PSScriptRoot "replay-contract-adjudication-review.ps1") -QueueFile $queue -ReviewDirectory $reviews -OutputFile $output -RequireComplete
    if ($LASTEXITCODE -eq 0) { throw "Incomplete review ledger was accepted." }
    $report=Get-Content -LiteralPath $output -Raw|ConvertFrom-Json
    if ($report.summary.validReviews -ne 1 -or $report.summary.missingReviews -ne 1 -or $report.summary.complete -ne $false) { throw "Partial review ledger was not reported accurately." }
    [pscustomobject]@{schema="kwr-replay-contract-adjudication-review";schemaVersion=1;replayId="two";resultSha256="RESULT_TWO";labelSha256="LABEL_TWO";reviewer=[pscustomobject]@{reviewerId="named-reviewer";role="rbg-commander"};disposition="INTENTIONAL_FALLBACK";evidence=@("review-note-43");reviewedAt="2026-09-08T00:01:00Z"} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $reviews "two.adjudication.json") -Encoding UTF8
    $global:LASTEXITCODE=0
    & (Join-Path $PSScriptRoot "replay-contract-adjudication-review.ps1") -QueueFile $queue -ReviewDirectory $reviews -OutputFile $output -RequireComplete
    if ($LASTEXITCODE -ne 0) { throw "Complete valid review ledger was rejected." }
    $report=Get-Content -LiteralPath $output -Raw|ConvertFrom-Json
    if ($report.summary.complete -ne $true -or $report.summary.validReviews -ne 2) { throw "Complete review ledger was not reported accurately." }
    Write-Output "KWR replay-contract adjudication review test passed"
} finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force } }
