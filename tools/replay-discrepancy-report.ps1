[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ResultsDir,
    [string]$GoldenDir = "tests\\golden",
    [Parameter(Mandatory = $true)][string]$OutputFile
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
. (Join-Path $PSScriptRoot 'hash-utils.ps1')

function Resolve-KwrPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    if ([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
    return Join-Path $root $Path
}

function Read-KwrJson {
    param([Parameter(Mandatory = $true)][string]$Path)
    try { return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json }
    catch { throw "Invalid JSON at $Path :: $($_.Exception.Message)" }
}

function Get-KwrHash {
    param([Parameter(Mandatory = $true)][string]$Path)
    return Get-KwrFileSha256 -LiteralPath $Path
}

function Add-UniqueTag {
    param([System.Collections.Generic.List[string]]$Tags, [object[]]$Values)
    foreach ($value in @($Values)) {
        if ($null -ne $value -and -not $Tags.Contains([string]$value)) {
            [void]$Tags.Add([string]$value)
        }
    }
}

$resultsPath = Resolve-KwrPath $ResultsDir
$goldenPath = Resolve-KwrPath $GoldenDir
$outputPath = Resolve-KwrPath $OutputFile
if (-not (Test-Path -LiteralPath $resultsPath)) { throw "Results directory not found: $resultsPath" }
if (-not (Test-Path -LiteralPath $goldenPath)) { throw "Golden directory not found: $goldenPath" }

$labels = @{}
foreach ($file in @(Get-ChildItem -LiteralPath $goldenPath -Filter "*.json" | Where-Object { -not $_.PSIsContainer })) {
    $label = Read-KwrJson $file.FullName
    if ($label.replayId) { $labels[$label.replayId] = [pscustomobject]@{ data = $label; path = $file.FullName; sha256 = Get-KwrHash $file.FullName } }
}

$rows = @()
foreach ($file in @(Get-ChildItem -LiteralPath $resultsPath -Filter "*.run.json" | Where-Object { -not $_.PSIsContainer } | Sort-Object Name)) {
    $result = Read-KwrJson $file.FullName
    $labelRecord = $labels[$result.replayId]
    if (-not $labelRecord) { throw "No golden label for replay ID $($result.replayId)." }
    $label = $labelRecord.data
    $tags = [System.Collections.Generic.List[string]]::new()
    Add-UniqueTag -Tags $tags -Values $result.final.tags
    foreach ($checkpoint in @($result.checkpoints)) { Add-UniqueTag -Tags $tags -Values $checkpoint.tags }
    $forbidden = @($result.evaluation.forbiddenHits)
    $classification = if ($forbidden.Count -gt 0) { "forbidden" }
        elseif ($result.evaluation.primaryMatch -eq $true) { "primary" }
        elseif ($result.evaluation.fallbackMatch -eq $true) { "fallback" }
        else { "unmatched" }
    $rows += [pscustomobject]@{
        replayId = $result.replayId
        mapProfile = $label.mapProfile
        classification = $classification
        label = [pscustomobject]@{
            id = $label.labelId
            sha256 = $labelRecord.sha256
            reviewers = @($label.reviewers | ForEach-Object {
                [pscustomobject]@{ reviewerId = $_.reviewerId; role = $_.role; agreed = $_.agreed }
            })
            primaryActions = @($label.decision.acceptablePrimaryActions)
            fallbackActions = @($label.decision.acceptableFallbackActions)
            forbiddenActions = @($label.decision.forbiddenActions)
            mustStay = @($label.decision.mustStay)
            requiredCapabilities = @($label.decision.requiredCapabilities)
        }
        observed = [pscustomobject]@{
            resultSha256 = Get-KwrHash $file.FullName
            fixtureSha256 = if ($result.replayPath -and (Test-Path -LiteralPath $result.replayPath)) { Get-KwrHash $result.replayPath } else { $null }
            planId = $result.final.planID
            status = $result.final.status
            actionTags = @($tags)
            checkpoints = @($result.checkpoints | ForEach-Object {
                [pscustomobject]@{ at = $_.at; event = $_.event; tags = @($_.tags); current = $_.current; next = $_.next }
            })
        }
        evaluation = [pscustomobject]@{
            primaryMatch = [bool]$result.evaluation.primaryMatch
            fallbackMatch = [bool]$result.evaluation.fallbackMatch
            forbiddenHits = $forbidden
        }
    }
}

$summary = [pscustomobject]@{
    total = $rows.Count
    primary = @($rows | Where-Object { $_.classification -eq "primary" }).Count
    fallback = @($rows | Where-Object { $_.classification -eq "fallback" }).Count
    unmatched = @($rows | Where-Object { $_.classification -eq "unmatched" }).Count
    forbidden = @($rows | Where-Object { $_.classification -eq "forbidden" }).Count
    byProfile = @($rows | Group-Object mapProfile | Sort-Object Name | ForEach-Object {
        [pscustomobject]@{
            mapProfile = $_.Name
            total = $_.Count
            primary = @($_.Group | Where-Object { $_.classification -eq "primary" }).Count
            fallback = @($_.Group | Where-Object { $_.classification -eq "fallback" }).Count
            unmatched = @($_.Group | Where-Object { $_.classification -eq "unmatched" }).Count
            forbidden = @($_.Group | Where-Object { $_.classification -eq "forbidden" }).Count
        }
    })
}
$report = [pscustomobject]@{
    schema = "kwr-replay-discrepancy-report"
    schemaVersion = 1
    generatedAt = [DateTime]::UtcNow.ToString("o")
    source = [pscustomobject]@{
        resultsDirectory = $resultsPath
        goldenDirectory = $goldenPath
        discrepancyToolSha256 = Get-KwrHash $PSCommandPath
    }
    summary = $summary
    rows = $rows
}
$parent = Split-Path -Parent $outputPath
if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$report | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $outputPath -Encoding UTF8
Write-Output "KWR replay discrepancy report"
Write-Output "Results: $($summary.total); primary: $($summary.primary); fallback: $($summary.fallback); unmatched: $($summary.unmatched); forbidden: $($summary.forbidden)"
Write-Output "Report: $outputPath"
