[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$WorkerDirectories,
    [string]$GoldenDir = "tests\\golden",
    [string]$OutputDirectory = "",
    [switch]$SkipDecisionBenchmark
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
. (Join-Path $PSScriptRoot "hash-utils.ps1")
if (-not $OutputDirectory) { $OutputDirectory = "artifacts\\fresh-replay-merged-" + (Get-Date -Format "yyyyMMdd-HHmmss") }
if (-not [IO.Path]::IsPathRooted($OutputDirectory)) { $OutputDirectory = Join-Path $root $OutputDirectory }
$outputRoot = [IO.Path]::GetFullPath($OutputDirectory)
$resultsRoot = Join-Path $outputRoot "results"
[IO.Directory]::CreateDirectory($resultsRoot) | Out-Null
$runs = @(); $errors = [System.Collections.Generic.List[string]]::new(); $sourceHashes = @{}
foreach ($directory in $WorkerDirectories) {
    $workerRoot = if ([IO.Path]::IsPathRooted($directory)) { [IO.Path]::GetFullPath($directory) } else { Join-Path $root $directory }
    $manifestPath = Join-Path $workerRoot "fresh-replay-benchmark.json"
    if (-not (Test-Path -LiteralPath $manifestPath)) { $errors.Add("Missing worker manifest: $workerRoot"); continue }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    foreach ($property in @("replayRunnerSha256", "testDriverSha256")) { $sourceHashes[$property] = $sourceHashes[$property] + @($manifest.source.$property) }
    foreach ($run in @($manifest.runs)) {
        if (-not $run.resultFile) { $errors.Add("Worker $workerRoot did not emit $($run.replayId)"); continue }
        $source = Join-Path $workerRoot ($run.resultFile -replace '/', '\\')
        $target = Join-Path $resultsRoot ([IO.Path]::GetFileName($source))
        if (Test-Path -LiteralPath $target) { $errors.Add("Duplicate replay result: $($run.replayId)"); continue }
        Copy-Item -LiteralPath $source -Destination $target
        $runs += [ordered]@{ replayId = $run.replayId; resultFile = "results/" + [IO.Path]::GetFileName($target); resultSha256 = Get-KwrFileSha256 -LiteralPath $target; pass = $run.pass }
    }
}
$expected = @(Get-ChildItem -LiteralPath (Join-Path $root "tests\\replays") -File -Filter "*.json").Count
$consistent = @($sourceHashes.replayRunnerSha256 | Select-Object -Unique).Count -eq 1 -and @($sourceHashes.testDriverSha256 | Select-Object -Unique).Count -eq 1
if (-not $consistent) { $errors.Add("Worker source hashes differ.") }
$benchmarkPath = Join-Path $outputRoot "benchmark.json"
if (-not $SkipDecisionBenchmark -and $errors.Count -eq 0 -and $runs.Count -eq $expected) {
    & (Join-Path $PSScriptRoot "decision-benchmark.ps1") -ResultsDir $resultsRoot -GoldenDir (Join-Path $root $GoldenDir) -OutFile $benchmarkPath -RequirePrimaryForEveryResult
    if ($LASTEXITCODE -ne 0) { $errors.Add("Decision benchmark contains replay mismatches.") }
} elseif ($runs.Count -ne $expected) { $errors.Add("Expected $expected results, found $($runs.Count).") }
$runnerHashes = @($sourceHashes.replayRunnerSha256 | Select-Object -Unique)
$driverHashes = @($sourceHashes.testDriverSha256 | Select-Object -Unique)
$report = [ordered]@{
    # Match the ordinary full-benchmark manifest contract so the semantic
    # comparator can verify a shard-merged corpus without weakening provenance.
    schema="kwr-fresh-replay-benchmark"; schemaVersion=1; generatedAt=[DateTime]::UtcNow.ToString("o")
    scope='full reviewed replay corpus; merged bounded workers'
    source=@{replayRunnerSha256=$runnerHashes[0];testDriverSha256=$driverHashes[0]}
    coverage=@{totalReplays=$expected;reviewedLabels=$expected;selected=$runs.Count;missingLabels=@();complete=($runs.Count -eq $expected)}
    worker=@{merged=$true;workerCount=$WorkerDirectories.Count;skipDecisionBenchmark=$SkipDecisionBenchmark.IsPresent}
    expectedResults=$expected; mergedResults=$runs.Count; benchmark=if(Test-Path $benchmarkPath){"benchmark.json"}else{$null}; pass=($errors.Count -eq 0); errors=$errors; runs=$runs
}
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $outputRoot "fresh-replay-benchmark.json") -Encoding utf8
Write-Output "KWR merged fresh replay benchmark: $($report.pass)"
Write-Output "Results: $($runs.Count) / $expected"
if (-not $report.pass) { exit 1 }
