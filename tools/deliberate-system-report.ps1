[CmdletBinding()]
param(
    [string]$OutFile = ""
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))

function Load-JsonFile {
    param([Parameter(Mandatory = $true)][string]$Path)
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Get-ValueByPath {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Path
    )
    $current = $Object
    foreach ($segment in $Path.Split('.')) {
        if ($null -eq $current) { return $null }
        $property = $current.PSObject.Properties[$segment]
        if ($null -eq $property) { return $null }
        $current = $property.Value
    }
    return $current
}

function Map-ProfileCounts {
    param(
        [Parameter(Mandatory = $true)]$Items,
        [Parameter(Mandatory = $true)][string]$PropertyName
    )
    $result = @{}
    foreach ($item in @($Items)) {
        $value = Get-ValueByPath -Object $item -Path $PropertyName
        if ([string]::IsNullOrWhiteSpace([string]$value)) { continue }
        if (-not $result.ContainsKey($value)) {
            $result[$value] = 0
        }
        $result[$value] = $result[$value] + 1
    }
    return $result
}

$scenarioMatrix = Load-JsonFile (Join-Path $root "knowledge\rbg-scenario-matrix.json")
$corpusManifest = Load-JsonFile (Join-Path $root "knowledge\corpus-manifest.json")
$reportSchema = Load-JsonFile (Join-Path $root "knowledge\schemas\deliberate-system-report-schema.json")

$baseScenariosPerMap = [int]$scenarioMatrix.targetBaseScenariosPerMap
$supportedMaps = @($scenarioMatrix.maps).Count

$reviewedCasesPerScenario = 5
$adversarialCasesPerScenario = 1
$starterCorpusPerScenario = 1

$replays = @()
$labels = @()
$results = @()
$outcomes = @()
$adversarial = @()

$replayDir = Join-Path $root "tests\replays"
$labelDir = Join-Path $root "tests\golden"
$resultDir = Join-Path $root "tests\replay-results"
$outcomeDir = Join-Path $root "tests\outcomes"
$adversarialDir = Join-Path $root "tests\adversarial"

if (Test-Path -LiteralPath $replayDir) {
    foreach ($file in @(Get-ChildItem -LiteralPath $replayDir -File -Filter "*.json")) {
        $replays += Load-JsonFile $file.FullName
    }
}
if (Test-Path -LiteralPath $labelDir) {
    foreach ($file in @(Get-ChildItem -LiteralPath $labelDir -File -Filter "*.json")) {
        $labels += Load-JsonFile $file.FullName
    }
}
if (Test-Path -LiteralPath $resultDir) {
    foreach ($file in @(Get-ChildItem -LiteralPath $resultDir -File -Filter "*.run.json")) {
        $results += Load-JsonFile $file.FullName
    }
}
if (Test-Path -LiteralPath $outcomeDir) {
    foreach ($file in @(Get-ChildItem -LiteralPath $outcomeDir -File -Filter "*.outcome.json")) {
        $outcomes += Load-JsonFile $file.FullName
    }
}
if (Test-Path -LiteralPath $adversarialDir) {
    foreach ($file in @(Get-ChildItem -LiteralPath $adversarialDir -File -Filter "*.json")) {
        $adversarial += Load-JsonFile $file.FullName
    }
}

$replayByProfile = Map-ProfileCounts -Items $replays -PropertyName "map.profile"
$labelByProfile = Map-ProfileCounts -Items $labels -PropertyName "mapProfile"
$resultReplayIds = @{}
foreach ($row in @($results)) {
    if (-not [string]::IsNullOrWhiteSpace([string]$row.replayId)) {
        $resultReplayIds[$row.replayId] = $true
    }
}
$outcomeByProfile = Map-ProfileCounts -Items $outcomes -PropertyName "mapProfile"
$adversarialByProfile = @{}
foreach ($row in @($adversarial)) {
    $profile = $row.map.profile
    if ([string]::IsNullOrWhiteSpace([string]$profile)) { continue }
    if (-not $adversarialByProfile.ContainsKey($profile)) {
        $adversarialByProfile[$profile] = 0
    }
    $adversarialByProfile[$profile] = $adversarialByProfile[$profile] + 1
}

$mapRows = @()
foreach ($map in @($scenarioMatrix.maps)) {
    $profile = [string]$map.mapProfile
    $targetScenarios = @($map.scenarios).Count
    $currentStarterReplays = if ($replayByProfile.ContainsKey($profile)) { [int]$replayByProfile[$profile] } else { 0 }
    $currentGoldenLabels = if ($labelByProfile.ContainsKey($profile)) { [int]$labelByProfile[$profile] } else { 0 }
    $currentReplayResults = 0
    foreach ($replay in @($replays | Where-Object { $_.map.profile -eq $profile })) {
        if ($resultReplayIds.ContainsKey([string]$replay.replayId)) {
            $currentReplayResults = $currentReplayResults + 1
        }
    }
    $currentOutcomeReviews = if ($outcomeByProfile.ContainsKey($profile)) { [int]$outcomeByProfile[$profile] } else { 0 }
    $currentAdversarialCases = if ($adversarialByProfile.ContainsKey($profile)) { [int]$adversarialByProfile[$profile] } else { 0 }

    $reviewedTarget = $targetScenarios * $reviewedCasesPerScenario
    $adversarialTarget = $targetScenarios * $adversarialCasesPerScenario

    $mapRows += [pscustomobject]@{
        mapKey = $map.mapKey
        mapProfile = $profile
        targetScenarios = $targetScenarios
        currentStarterReplays = $currentStarterReplays
        currentGoldenLabels = $currentGoldenLabels
        currentReplayResults = $currentReplayResults
        currentOutcomeReviews = $currentOutcomeReviews
        currentAdversarialCases = $currentAdversarialCases
        starterReplayGap = [Math]::Max(0, $targetScenarios - $currentStarterReplays)
        reviewedCorpusGap = [Math]::Max(0, $reviewedTarget - $currentStarterReplays)
        adversarialGap = [Math]::Max(0, $adversarialTarget - $currentAdversarialCases)
    }
}

$targetStarterTotal = $supportedMaps * $baseScenariosPerMap * $starterCorpusPerScenario
$targetReviewedTotal = $supportedMaps * $baseScenariosPerMap * $reviewedCasesPerScenario
$targetAdversarialTotal = $supportedMaps * $baseScenariosPerMap * $adversarialCasesPerScenario

$report = [pscustomobject]@{
    schema = "kwr-deliberate-system-report"
    schemaVersion = 1
    generatedAt = (Get-Date).ToString("s")
    targets = [pscustomobject]@{
        supportedMaps = $supportedMaps
        baseScenariosPerMap = $baseScenariosPerMap
        starterCorpusPerScenario = $starterCorpusPerScenario
        reviewedCasesPerScenario = $reviewedCasesPerScenario
        adversarialCasesPerScenario = $adversarialCasesPerScenario
    }
    current = [pscustomobject]@{
        supportedMaps = $supportedMaps
        scenarioDefinitions = @($scenarioMatrix.maps | ForEach-Object { @($_.scenarios).Count } | Measure-Object -Sum).Sum
        starterReplays = @($replays).Count
        goldenLabels = @($labels).Count
        replayResults = @($results).Count
        outcomeReviews = @($outcomes).Count
        adversarialCases = @($adversarial).Count
    }
    gaps = [pscustomobject]@{
        starterReplayGap = [Math]::Max(0, $targetStarterTotal - @($replays).Count)
        goldenLabelGap = [Math]::Max(0, $targetStarterTotal - @($labels).Count)
        replayResultGap = [Math]::Max(0, $targetStarterTotal - @($results).Count)
        outcomeReviewGap = [Math]::Max(0, $targetStarterTotal - @($outcomes).Count)
        reviewedCorpusGap = [Math]::Max(0, $targetReviewedTotal - @($replays).Count)
        adversarialGap = [Math]::Max(0, $targetAdversarialTotal - @($adversarial).Count)
    }
    maps = $mapRows
}

foreach ($key in @($reportSchema.required)) {
    if ($null -eq $report.PSObject.Properties[$key]) {
        throw "Report missing required field: $key"
    }
}

if ($OutFile -ne "") {
    $target = Join-Path $root $OutFile
    $parent = Split-Path -Parent $target
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    $report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $target -Encoding UTF8
}

Write-Output "KWR deliberate system report"
Write-Output "Supported maps: $($report.targets.supportedMaps)"
Write-Output "Base scenarios per map: $($report.targets.baseScenariosPerMap)"
Write-Output "Scenario definitions: $($report.current.scenarioDefinitions)"
Write-Output "Starter replays: $($report.current.starterReplays) / $targetStarterTotal"
Write-Output "Golden labels: $($report.current.goldenLabels) / $targetStarterTotal"
Write-Output "Replay results: $($report.current.replayResults) / $targetStarterTotal"
Write-Output "Outcome reviews: $($report.current.outcomeReviews) / $targetStarterTotal"
Write-Output "Adversarial cases: $($report.current.adversarialCases) / $targetAdversarialTotal"
Write-Output "Reviewed corpus target: $targetReviewedTotal"
Write-Output "Starter replay gap: $($report.gaps.starterReplayGap)"
Write-Output "Reviewed corpus gap: $($report.gaps.reviewedCorpusGap)"
Write-Output "Adversarial gap: $($report.gaps.adversarialGap)"
