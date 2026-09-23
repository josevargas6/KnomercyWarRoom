[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$SourceResultsDir,
    [Parameter(Mandatory = $true)][string]$PackageResultsDir,
    [Parameter(Mandatory = $true)][string]$OutputFile,
    [switch]$RequireProvenance
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'hash-utils.ps1')
function Resolve-KwrPath([string]$Path) {
    if ([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
    return Join-Path ([IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))) $Path
}
function Read-Results([string]$Directory) {
    $items = @{}
    foreach ($file in Get-ChildItem -LiteralPath $Directory -File -Filter '*.run.json') {
        $row = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
        if (-not $row.replayId -or $items.ContainsKey([string]$row.replayId)) {
            throw "Replay results must have one non-empty replayId: $($file.Name)"
        }
        $replayPath = [string]$row.replayPath
        $labelPath = [string]$row.labelPath
        $items[[string]$row.replayId] = [pscustomobject]@{
            row = $row
            resultFile = $file.FullName
            resultSha256 = Get-KwrFileSha256 -LiteralPath $file.FullName
            replayPath = $replayPath
            labelPath = $labelPath
            replaySha256 = if ($replayPath -and (Test-Path -LiteralPath $replayPath -PathType Leaf)) {
                Get-KwrFileSha256 -LiteralPath $replayPath
            } else { $null }
            labelSha256 = if ($labelPath -and (Test-Path -LiteralPath $labelPath -PathType Leaf)) {
                Get-KwrFileSha256 -LiteralPath $labelPath
            } else { $null }
        }
    }
    return $items
}
function Read-Manifest([string]$ResultsDirectory) {
    $path = Join-Path (Split-Path -Parent $ResultsDirectory) 'fresh-replay-benchmark.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    try { return [pscustomobject]@{ path = $path; sha256 = Get-KwrFileSha256 -LiteralPath $path; data = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json } }
    catch { throw "Invalid replay benchmark manifest: $path :: $($_.Exception.Message)" }
}
function SemanticJson($row) {
    $projection = [ordered]@{
        replayId = $row.replayId
        final = [ordered]@{ planID = $row.final.planID; status = $row.final.status; tags = @($row.final.tags) }
        evaluation = [ordered]@{ primaryMatch = [bool]$row.evaluation.primaryMatch; fallbackMatch = [bool]$row.evaluation.fallbackMatch; forbiddenHits = @($row.evaluation.forbiddenHits) }
        checkpoints = @($row.checkpoints | ForEach-Object { [ordered]@{ step=$_.step; event=$_.event; planID=$_.planID; status=$_.status; current=$_.current; next=$_.next; tags=@($_.tags) } })
    }
    return $projection | ConvertTo-Json -Depth 12 -Compress
}
$sourceDirectory = Resolve-KwrPath $SourceResultsDir
$packageDirectory = Resolve-KwrPath $PackageResultsDir
$source = Read-Results $sourceDirectory
$package = Read-Results $packageDirectory
$sourceManifest = Read-Manifest $sourceDirectory
$packageManifest = Read-Manifest $packageDirectory
$missingSource = @($package.Keys | Where-Object { -not $source.ContainsKey($_) } | Sort-Object)
$missingPackage = @($source.Keys | Where-Object { -not $package.ContainsKey($_) } | Sort-Object)
$different = @()
foreach ($id in @($source.Keys | Where-Object { $package.ContainsKey($_) } | Sort-Object)) {
    if ((SemanticJson $source[$id].row) -ne (SemanticJson $package[$id].row)) { $different += $id }
}
$provenanceDifferences = @()
foreach ($id in @($source.Keys | Where-Object { $package.ContainsKey($_) } | Sort-Object)) {
    $left, $right = $source[$id], $package[$id]
    if (-not $left.replaySha256 -or -not $right.replaySha256 -or $left.replaySha256 -ne $right.replaySha256) {
        $provenanceDifferences += [ordered]@{ replayId = $id; field = 'replaySha256'; source = $left.replaySha256; package = $right.replaySha256 }
    }
    if (-not $left.labelSha256 -or -not $right.labelSha256 -or $left.labelSha256 -ne $right.labelSha256) {
        $provenanceDifferences += [ordered]@{ replayId = $id; field = 'labelSha256'; source = $left.labelSha256; package = $right.labelSha256 }
    }
}
$manifestErrors = @()
if ($RequireProvenance) {
    foreach ($item in @(@{ name = 'source'; manifest = $sourceManifest }, @{ name = 'package'; manifest = $packageManifest })) {
        $manifest = $item.manifest
        $completeManifest = $manifest -and $manifest.data.pass -eq $true `
            -and $manifest.data.coverage.complete -eq $true `
            -and $manifest.data.coverage.selected -eq $manifest.data.coverage.totalReplays
        if (-not $completeManifest) {
            $manifestErrors += "$($item.name) manifest is absent, failed, or is not a complete corpus."
        }
    }
    if ($sourceManifest -and $packageManifest) {
        foreach ($field in @('replayRunnerSha256', 'testDriverSha256')) {
            $sourceValue = $sourceManifest.data.source.PSObject.Properties[$field].Value
            $packageValue = $packageManifest.data.source.PSObject.Properties[$field].Value
            if ($sourceValue -ne $packageValue) {
                $manifestErrors += "Runner provenance differs for $field."
            }
        }
    }
}
$receiptRows = @($source.Keys | Where-Object { $package.ContainsKey($_) } | Sort-Object | ForEach-Object {
    $left, $right = $source[$_], $package[$_]
    [ordered]@{ replayId = $_; sourceResultSha256 = $left.resultSha256; packageResultSha256 = $right.resultSha256; replaySha256 = $left.replaySha256; labelSha256 = $left.labelSha256 }
})
function ManifestSummary($manifest) {
    if (-not $manifest) { return $null }
    return [ordered]@{
        path = $manifest.path
        sha256 = $manifest.sha256
        pass = $manifest.data.pass
        scope = $manifest.data.scope
        coverage = $manifest.data.coverage
        runner = [ordered]@{
            replayRunnerSha256 = $manifest.data.source.replayRunnerSha256
            testDriverSha256 = $manifest.data.source.testDriverSha256
            addonRoot = $manifest.data.source.addonRoot
        }
    }
}
$report = [ordered]@{ schema='kwr-replay-semantic-parity'; schemaVersion=2; generatedAt=[DateTime]::UtcNow.ToString('o'); sourceCount=$source.Count; packageCount=$package.Count; missingFromSource=$missingSource; missingFromPackage=$missingPackage; semanticDifferences=$different; provenanceDifferences=$provenanceDifferences; manifests=[ordered]@{ source=(ManifestSummary $sourceManifest); package=(ManifestSummary $packageManifest); errors=$manifestErrors }; resultReceipts=$receiptRows; pass=($missingSource.Count -eq 0 -and $missingPackage.Count -eq 0 -and $different.Count -eq 0 -and $provenanceDifferences.Count -eq 0 -and $manifestErrors.Count -eq 0) }
$out = Resolve-KwrPath $OutputFile
[IO.Directory]::CreateDirectory((Split-Path -Parent $out)) | Out-Null
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $out -Encoding UTF8
Write-Output "KWR replay semantic parity: $($report.pass)"
if (-not $report.pass) { exit 1 }
