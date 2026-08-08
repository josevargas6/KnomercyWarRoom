[CmdletBinding()]
param(
    [string]$ResultsDir = "tests\\replay-results",
    [string]$GoldenDir = "tests\\golden",
    [string]$OutFile = ""
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$errors = [System.Collections.Generic.List[string]]::new()

function Add-BenchmarkError {
    param([string]$Message)
    $script:errors.Add($Message)
}

function Load-JsonFile {
    param([Parameter(Mandatory = $true)][string]$Path)
    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    } catch {
        Add-BenchmarkError "Invalid JSON: $Path :: $($_.Exception.Message)"
        return $null
    }
}

function Assert-HasKeys {
    param(
        [Parameter(Mandatory = $true)] $Object,
        [Parameter(Mandatory = $true)][string[]]$Keys,
        [Parameter(Mandatory = $true)][string]$Label
    )
    foreach ($key in $Keys) {
        if ($null -eq $Object.PSObject.Properties[$key]) {
            Add-BenchmarkError "$Label missing required field: $key"
        }
    }
}

$resultsPath = Join-Path $root $ResultsDir
$goldenPath = Join-Path $root $GoldenDir
$resultSchema = Load-JsonFile (Join-Path $root "knowledge\\schemas\\replay-run-result-schema.json")
$reportSchema = Load-JsonFile (Join-Path $root "knowledge\\schemas\\benchmark-report-schema.json")

$labels = @{}
foreach ($file in @(Get-ChildItem -LiteralPath $goldenPath -File -Filter "*.json")) {
    $label = Load-JsonFile $file.FullName
    if ($label -and $label.replayId) {
        $labels[$label.replayId] = $label
    }
}

$results = @()
foreach ($file in @(Get-ChildItem -LiteralPath $resultsPath -File -Filter "*.run.json")) {
    $result = Load-JsonFile $file.FullName
    if (-not $result) { continue }
    Assert-HasKeys -Object $result -Keys $resultSchema.required -Label $file.Name
    if ($result.final) { Assert-HasKeys -Object $result.final -Keys $resultSchema.finalRequired -Label "$($file.Name).final" }
    if ($result.evaluation) { Assert-HasKeys -Object $result.evaluation -Keys $resultSchema.evaluationRequired -Label "$($file.Name).evaluation" }
    foreach ($checkpoint in @($result.checkpoints)) {
        Assert-HasKeys -Object $checkpoint -Keys $resultSchema.checkpointRequired -Label "$($file.Name).checkpoint"
    }
    $label = $labels[$result.replayId]
    if (-not $label) {
        Add-BenchmarkError "$($file.Name) has no matching golden label for replayId $($result.replayId)."
        continue
    }
    $pass = ($result.evaluation.primaryMatch -eq $true -or $result.evaluation.fallbackMatch -eq $true) `
        -and @($result.evaluation.forbiddenHits).Count -eq 0
    $results += [pscustomobject]@{
        replayId = $result.replayId
        labelId = $label.labelId
        primaryMatch = [bool]$result.evaluation.primaryMatch
        fallbackMatch = [bool]$result.evaluation.fallbackMatch
        forbiddenHits = @($result.evaluation.forbiddenHits)
        pass = $pass
    }
}

$summary = [pscustomobject]@{
    total = @($results).Count
    primaryMatches = @($results | Where-Object { $_.primaryMatch }).Count
    fallbackMatches = @($results | Where-Object { $_.fallbackMatch }).Count
    forbiddenFailures = @($results | Where-Object { @($_.forbiddenHits).Count -gt 0 }).Count
    pass = (@($results).Count -gt 0) -and (@($results | Where-Object { -not $_.pass }).Count -eq 0)
}

$report = [pscustomobject]@{
    schema = "kwr-benchmark-report"
    schemaVersion = 1
    generatedAt = (Get-Date).ToString("s")
    summary = $summary
    results = $results
}

Assert-HasKeys -Object $report -Keys $reportSchema.required -Label "benchmark report"
Assert-HasKeys -Object $report.summary -Keys $reportSchema.summaryRequired -Label "benchmark report.summary"
foreach ($row in @($report.results)) {
    Assert-HasKeys -Object $row -Keys $reportSchema.resultRequired -Label "benchmark report.result"
}

if ($OutFile -ne "") {
    $target = Join-Path $root $OutFile
    $parent = Split-Path -Parent $target
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    $report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $target -Encoding UTF8
}

Write-Output "KWR decision benchmark"
Write-Output "Results: $($summary.total)"
Write-Output "Primary matches: $($summary.primaryMatches)"
Write-Output "Fallback matches: $($summary.fallbackMatches)"
Write-Output "Forbidden failures: $($summary.forbiddenFailures)"
Write-Output "Pass: $($summary.pass)"
Write-Output "Errors: $($errors.Count)"
foreach ($errorText in $errors) {
    Write-Error $errorText -ErrorAction Continue
}
if ($errors.Count -gt 0) { exit 1 }
if (-not $summary.pass) { exit 1 }
Write-Output "DECISION BENCHMARK PASSED"
