[CmdletBinding()]
param(
    [string]$ReplayDir = "tests\\replays",
    [string]$GoldenDir = "tests\\golden",
    [string]$OutputDirectory = "",
    [int]$MaxReplays = 0,
    [int]$StartIndex = 0,
    [string]$AddonRoot,
    [switch]$SkipDecisionBenchmark
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
. (Join-Path $PSScriptRoot "hash-utils.ps1")
if ($MaxReplays -lt 0) { throw "MaxReplays cannot be negative." }
if ($StartIndex -lt 0) { throw "StartIndex cannot be negative." }
if (-not $OutputDirectory) {
    $OutputDirectory = "artifacts\\fresh-replay-benchmark-" + (Get-Date -Format "yyyyMMdd-HHmmss")
}
if (-not [IO.Path]::IsPathRooted($OutputDirectory)) { $OutputDirectory = Join-Path $root $OutputDirectory }

function Resolve-AddonRoot {
    param([AllowNull()][string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $root }
    $candidate = [IO.Path]::GetFullPath($Path)
    if (Test-Path -LiteralPath (Join-Path $candidate 'KnomercyWarRoom.toc') -PathType Leaf) {
        return $candidate
    }
    # A player ZIP contains one KnomercyWarRoom directory. Accept the ordinary
    # extraction destination as well as that inner addon root, so source/package
    # parity cannot fail merely because archive layout adds its required wrapper.
    $nested = Join-Path $candidate 'KnomercyWarRoom'
    if (Test-Path -LiteralPath (Join-Path $nested 'KnomercyWarRoom.toc') -PathType Leaf) {
        return $nested
    }
    throw "AddonRoot must contain KnomercyWarRoom.toc: $candidate"
}
$resolvedAddonRoot = Resolve-AddonRoot $AddonRoot
$replayPath = Join-Path $root $ReplayDir
$goldenPath = Join-Path $root $GoldenDir
if (-not (Test-Path -LiteralPath $replayPath) -or -not (Test-Path -LiteralPath $goldenPath)) { throw "Replay or golden directory is missing." }

function Read-Json([string]$Path) { Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json }
function Get-PortableRelativePath([string]$BasePath, [string]$TargetPath) {
    $base = [IO.Path]::GetFullPath($BasePath).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    $baseUri = [Uri]::new($base)
    $targetUri = [Uri]::new([IO.Path]::GetFullPath($TargetPath))
    return [Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace('\', '/')
}
$labels = @{}
Get-ChildItem -LiteralPath $goldenPath -File -Filter "*.label.json" | ForEach-Object {
    $label = Read-Json $_.FullName
    if ($label.replayId) { $labels[[string]$label.replayId] = $_.FullName }
}
$allReplays = @(Get-ChildItem -LiteralPath $replayPath -File -Filter "*.json" | Sort-Object Name)
$missingLabels = @()
$selected = @()
foreach ($file in $allReplays) {
    $replay = Read-Json $file.FullName
    if (-not $replay.replayId -or -not $labels.ContainsKey([string]$replay.replayId)) {
        $missingLabels += [ordered]@{ file = $file.Name; replayId = $replay.replayId }
        continue
    }
    $selected += [ordered]@{ file = $file; replayId = [string]$replay.replayId; label = $labels[[string]$replay.replayId] }
}
if ($StartIndex -ge $selected.Count) { throw "StartIndex is outside the reviewed replay corpus." }
$selected = @($selected | Select-Object -Skip $StartIndex)
if ($MaxReplays -gt 0) { $selected = @($selected | Select-Object -First $MaxReplays) }
if ($selected.Count -eq 0) { throw "No replay fixtures with reviewed golden labels were selected." }

$outputRoot = [IO.Path]::GetFullPath($OutputDirectory)
$resultsRoot = Join-Path $outputRoot "results"
[IO.Directory]::CreateDirectory($resultsRoot) | Out-Null
$failures = [System.Collections.Generic.List[string]]::new()
$runs = @()
foreach ($entry in $selected) {
    $out = Join-Path $resultsRoot ($entry.file.BaseName + ".run.json")
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        # A failed replay is benchmark evidence, not a runner crash. Windows
        # PowerShell otherwise promotes its nonzero child exit into a terminating
        # NativeCommandError under this script's Stop policy.
        $ErrorActionPreference = "Continue"
        $runOutput = @(& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "test-lua.ps1") `
            -Suite Replay -ReplayPath $entry.file.FullName -ReplayLabelPath $entry.label -ReplayOutputPath $out -ReplayNonStrict `
            $(if ($AddonRoot) { @('-AddonRoot', $resolvedAddonRoot) }) 2>&1)
        $runExitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    $ok = ($runExitCode -eq 0) -and (Test-Path -LiteralPath $out -PathType Leaf)
    if (-not $ok) { $failures.Add("$($entry.file.Name): $($runOutput -join [Environment]::NewLine)") }
    $runs += [ordered]@{
        replayId = $entry.replayId
        replaySha256 = Get-KwrFileSha256 -LiteralPath $entry.file.FullName
        labelSha256 = Get-KwrFileSha256 -LiteralPath $entry.label
        resultFile = if ($ok) { Get-PortableRelativePath $outputRoot $out } else { $null }
        resultSha256 = if ($ok) { Get-KwrFileSha256 -LiteralPath $out } else { $null }
        pass = $ok
    }
}

$benchmarkPath = Join-Path $outputRoot "benchmark.json"
$fullRun = $StartIndex -eq 0 -and $MaxReplays -eq 0
if (-not $SkipDecisionBenchmark -and $failures.Count -eq 0) {
    $benchmarkParameters = @{
        ResultsDir = $resultsRoot
        GoldenDir = $goldenPath
        OutFile = $benchmarkPath
    }
    if ($fullRun) { $benchmarkParameters.RequirePrimaryForEveryResult = $true }
    & (Join-Path $PSScriptRoot "decision-benchmark.ps1") @benchmarkParameters
    if ($LASTEXITCODE -ne 0) { $failures.Add("decision-benchmark.ps1 failed.") }
}
$coveragePass = (-not $fullRun) -or ($missingLabels.Count -eq 0 -and $selected.Count -eq $allReplays.Count)
$manifest = [ordered]@{
    schema = "kwr-fresh-replay-benchmark"
    schemaVersion = 1
    generatedAt = [DateTime]::UtcNow.ToString("o")
    scope = if ($fullRun) { "full reviewed replay corpus" } else { "bounded worker slice; not complete corpus evidence" }
    source = [ordered]@{
        replayRunnerSha256 = Get-KwrFileSha256 -LiteralPath (Join-Path $PSScriptRoot "replay-test-runner.lua")
        testDriverSha256 = Get-KwrFileSha256 -LiteralPath (Join-Path $PSScriptRoot "test-lua.ps1")
        addonRoot = $resolvedAddonRoot
    }
    coverage = [ordered]@{ totalReplays = $allReplays.Count; reviewedLabels = $labels.Count; selected = $selected.Count; missingLabels = $missingLabels; complete = $coveragePass }
    runs = $runs
    benchmark = if (Test-Path -LiteralPath $benchmarkPath) { Get-PortableRelativePath $outputRoot $benchmarkPath } else { $null }
    worker = [ordered]@{ startIndex = $StartIndex; maxReplays = $MaxReplays; skipDecisionBenchmark = $SkipDecisionBenchmark.IsPresent }
    pass = ($failures.Count -eq 0 -and $coveragePass)
    failures = $failures
}
$manifestPath = Join-Path $outputRoot "fresh-replay-benchmark.json"
$manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $manifestPath -Encoding utf8
Write-Output "KWR fresh replay benchmark: $($manifest.pass)"
Write-Output "Selected: $($selected.Count); total: $($allReplays.Count); missing labels: $($missingLabels.Count)"
Write-Output "Manifest: $manifestPath"
if (-not $manifest.pass) { exit 1 }
