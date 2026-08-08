[CmdletBinding()]
param(
    [string]$OutFile = ""
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$errors = [System.Collections.Generic.List[string]]::new()

function Add-OutcomeError {
    param([string]$Message)
    $script:errors.Add($Message)
}

function Load-JsonFile {
    param([Parameter(Mandatory = $true)][string]$Path)
    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    } catch {
        Add-OutcomeError "Invalid JSON: $Path :: $($_.Exception.Message)"
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
            Add-OutcomeError "$Label missing required field: $key"
        }
    }
}

$schema = Load-JsonFile (Join-Path $root "knowledge\\schemas\\outcome-review-schema.json")
$files = @(Get-ChildItem -LiteralPath (Join-Path $root "tests\\outcomes") -File -Filter "*.outcome.json")
$allowlist = @($schema.classificationAllowlist)
$rows = @()
$counts = @{}

foreach ($file in $files) {
    $review = Load-JsonFile $file.FullName
    if (-not $review -or -not $schema) { continue }
    Assert-HasKeys -Object $review -Keys $schema.required -Label $file.Name
    if ($review.classifications) {
        Assert-HasKeys -Object $review.classifications -Keys $schema.classificationRequired -Label "$($file.Name).classifications"
        if ($allowlist -notcontains $review.classifications.primary) {
            Add-OutcomeError "$($file.Name) has invalid primary classification: $($review.classifications.primary)"
        }
    }
    foreach ($checkpoint in @($review.checkpoints)) {
        Assert-HasKeys -Object $checkpoint -Keys $schema.checkpointRequired -Label "$($file.Name).checkpoint"
        if ($allowlist -notcontains $checkpoint.classification) {
            Add-OutcomeError "$($file.Name) has invalid checkpoint classification: $($checkpoint.classification)"
        }
    }
    $primary = [string]$review.classifications.primary
    if (-not $counts.ContainsKey($primary)) {
        $counts[$primary] = 0
    }
    $counts[$primary] = $counts[$primary] + 1
    $rows += [pscustomobject]@{
        replayId = $review.replayId
        mapProfile = $review.mapProfile
        result = $review.result
        primary = $primary
        checkpoints = @($review.checkpoints).Count
        reviewStatus = $review.reviewStatus
    }
}

$summary = [ordered]@{
    total = $rows.Count
    byPrimary = $counts
}

$report = [ordered]@{
    schema = "kwr-outcome-report"
    schemaVersion = 1
    generatedAt = (Get-Date).ToString("s")
    summary = $summary
    rows = $rows
}

if ($OutFile -ne "") {
    $target = Join-Path $root $OutFile
    $parent = Split-Path -Parent $target
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    $report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $target -Encoding UTF8
}

Write-Output "KWR outcome report"
Write-Output "Reviews: $($rows.Count)"
Write-Output "Errors: $($errors.Count)"
foreach ($name in $counts.Keys | Sort-Object) {
    Write-Output ("{0}: {1}" -f $name, $counts[$name])
}
foreach ($errorText in $errors) {
    Write-Error $errorText -ErrorAction Continue
}
if ($errors.Count -gt 0) { exit 1 }
Write-Output "OUTCOME REPORT PASSED"
