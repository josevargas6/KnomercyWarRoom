$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$temp = Join-Path ([IO.Path]::GetTempPath()) ('kwr-semantic-parity-' + [guid]::NewGuid().ToString('N'))

function Write-Json([string]$Path, [object]$Value) {
    [IO.Directory]::CreateDirectory((Split-Path -Parent $Path)) | Out-Null
    $Value | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $Path -Encoding UTF8
}
function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

try {
    $replay = Join-Path $temp 'inputs\one.json'
    $label = Join-Path $temp 'labels\one.label.json'
    Write-Json $replay ([ordered]@{ replayId = 'one'; fixture = 'source-bound' })
    Write-Json $label ([ordered]@{ replayId = 'one'; labelId = 'one-label' })
    $result = [ordered]@{
        schema = 'kwr-replay-run-result'; schemaVersion = 1; replayId = 'one'
        replayPath = $replay; labelPath = $label
        final = [ordered]@{ planID = 'PLAN_ONE'; status = 'HOLD'; tags = @('PLAN_ONE') }
        evaluation = [ordered]@{ primaryMatch = $true; fallbackMatch = $false; forbiddenHits = @() }
        checkpoints = @([ordered]@{ step = 1; event = 'start'; planID = 'PLAN_ONE'; status = 'HOLD'; current = @{}; next = @{}; tags = @('PLAN_ONE') })
    }
    $sourceRoot = Join-Path $temp 'source'
    $packageRoot = Join-Path $temp 'package'
    Write-Json (Join-Path $sourceRoot 'results\one.run.json') $result
    Write-Json (Join-Path $packageRoot 'results\one.run.json') $result
    $manifest = [ordered]@{
        schema = 'kwr-fresh-replay-benchmark'; scope = 'full reviewed replay corpus'; pass = $true
        coverage = [ordered]@{ totalReplays = 1; reviewedLabels = 1; selected = 1; complete = $true }
        source = [ordered]@{ replayRunnerSha256 = 'runner'; testDriverSha256 = 'driver'; addonRoot = 'fixture' }
    }
    Write-Json (Join-Path $sourceRoot 'fresh-replay-benchmark.json') $manifest
    Write-Json (Join-Path $packageRoot 'fresh-replay-benchmark.json') $manifest
    $tool = Join-Path $root 'tools\replay-semantic-parity.ps1'
    $positive = Join-Path $temp 'positive.json'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $tool -SourceResultsDir (Join-Path $sourceRoot 'results') -PackageResultsDir (Join-Path $packageRoot 'results') -OutputFile $positive -RequireProvenance
    Assert-True ($LASTEXITCODE -eq 0) 'Strict source/package parity rejected matching complete fixtures.'
    Assert-True ((Get-Content $positive -Raw | ConvertFrom-Json).pass -eq $true) 'Positive parity receipt was not a pass.'

    $broken = Get-Content (Join-Path $packageRoot 'results\one.run.json') -Raw | ConvertFrom-Json
    $broken.labelPath = Join-Path $temp 'labels\missing.label.json'
    Write-Json (Join-Path $packageRoot 'results\one.run.json') $broken
    $negative = Join-Path $temp 'negative.json'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $tool -SourceResultsDir (Join-Path $sourceRoot 'results') -PackageResultsDir (Join-Path $packageRoot 'results') -OutputFile $negative -RequireProvenance
    Assert-True ($LASTEXITCODE -ne 0) 'Strict parity accepted a missing package label input.'
    $negativeReceipt = Get-Content $negative -Raw | ConvertFrom-Json
    Assert-True ($negativeReceipt.pass -eq $false -and @($negativeReceipt.provenanceDifferences).Count -eq 1) 'Missing input was not reported as a provenance difference.'
    # The preceding invocation is intentionally nonzero; do not let that
    # expected negative case become this test script's own process result.
    $global:LASTEXITCODE = 0
    Write-Output 'KWR replay semantic parity test passed'
} finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
