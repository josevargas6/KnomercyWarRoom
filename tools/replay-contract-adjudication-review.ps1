[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$QueueFile,
    [Parameter(Mandatory = $true)][string]$ReviewDirectory,
    [Parameter(Mandatory = $true)][string]$OutputFile,
    [switch]$RequireComplete
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
. (Join-Path $PSScriptRoot 'hash-utils.ps1')
function Resolve-KwrPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    if ([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
    return Join-Path $root $Path
}
function Is-NonEmptyString { param([object]$Value) return -not [string]::IsNullOrWhiteSpace([string]$Value) }

$queuePath = Resolve-KwrPath $QueueFile
$reviewsPath = Resolve-KwrPath $ReviewDirectory
$outputPath = Resolve-KwrPath $OutputFile
if (-not (Test-Path -LiteralPath $queuePath)) { throw "Adjudication queue not found: $queuePath" }
if (-not (Test-Path -LiteralPath $reviewsPath)) { throw "Review directory not found: $reviewsPath" }
$queue = Get-Content -LiteralPath $queuePath -Raw | ConvertFrom-Json
if ($queue.schema -ne "kwr-replay-contract-adjudication-queue" -or -not $queue.rows) {
    throw "Input is not an adjudication queue: $queuePath"
}
$expected = @{}
foreach ($row in @($queue.rows)) {
    if ($expected.ContainsKey([string]$row.replayId)) { throw "Queue contains duplicate replay ID: $($row.replayId)" }
    $expected[[string]$row.replayId] = $row
}
$errors = [System.Collections.Generic.List[string]]::new()
$accepted = @{}
foreach ($file in @(Get-ChildItem -LiteralPath $reviewsPath -File -Filter "*.adjudication.json" | Sort-Object Name)) {
    try { $review = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json }
    catch { $errors.Add("Invalid JSON: $($file.Name)"); continue }
    if ($review.schema -ne "kwr-replay-contract-adjudication-review" -or $review.schemaVersion -ne 1) {
        $errors.Add("Invalid review schema: $($file.Name)"); continue
    }
    $replayId = [string]$review.replayId
    if (-not $expected.ContainsKey($replayId)) { $errors.Add("Review references unknown replay: $replayId"); continue }
    if ($accepted.ContainsKey($replayId)) { $errors.Add("Duplicate review for replay: $replayId"); continue }
    $row = $expected[$replayId]
    if ($review.resultSha256 -ne $row.resultSha256 -or $review.labelSha256 -ne $row.labelSha256) {
        $errors.Add("Stale review hashes for replay: $replayId"); continue
    }
    if (-not $review.reviewer -or -not (Is-NonEmptyString $review.reviewer.reviewerId) -or -not (Is-NonEmptyString $review.reviewer.role)) {
        $errors.Add("Missing named reviewer for replay: $replayId"); continue
    }
    if (@("EVALUATOR_DEFECT", "LABEL_DEFECT", "INTENTIONAL_FALLBACK", "PLANNER_DEFECT", "PRIMARY_CONFIRMED") -notcontains [string]$review.disposition) {
        $errors.Add("Invalid disposition for replay: $replayId"); continue
    }
    if (@($review.evidence | Where-Object { Is-NonEmptyString $_ }).Count -eq 0) {
        $errors.Add("Missing review evidence for replay: $replayId"); continue
    }
    if (-not (Is-NonEmptyString $review.reviewedAt)) { $errors.Add("Missing review timestamp for replay: $replayId"); continue }
    $accepted[$replayId] = $review
}
$missing = @($expected.Keys | Where-Object { -not $accepted.ContainsKey($_) } | Sort-Object)
$result = [pscustomobject]@{
    schema = "kwr-replay-contract-adjudication-review-report"
    schemaVersion = 1
    generatedAt = [DateTime]::UtcNow.ToString("o")
    source = [pscustomobject]@{
        queue = $queuePath
        queueSha256 = Get-KwrFileSha256 -LiteralPath $queuePath
        reviewDirectory = $reviewsPath
    }
    policy = "A review is valid only when its replay ID and input hashes match the queue, it identifies a named reviewer, supplies evidence, and records an allowed disposition. This report never changes a benchmark score."
    summary = [pscustomobject]@{
        queued = $expected.Count
        validReviews = $accepted.Count
        missingReviews = $missing.Count
        invalidReviews = $errors.Count
        complete = ($missing.Count -eq 0 -and $errors.Count -eq 0)
    }
    missingReplayIds = $missing
    errors = @($errors)
}
$parent = Split-Path -Parent $outputPath
if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $outputPath -Encoding UTF8
Write-Output "KWR replay-contract adjudication review report"
Write-Output "Queued: $($result.summary.queued); valid: $($result.summary.validReviews); missing: $($result.summary.missingReviews); invalid: $($result.summary.invalidReviews)"
Write-Output "Report: $outputPath"
if ($RequireComplete -and -not $result.summary.complete) { exit 1 }
