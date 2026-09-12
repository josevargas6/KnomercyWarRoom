[CmdletBinding()]
param([string]$OutputDirectory)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
. (Join-Path $PSScriptRoot 'hash-utils.ps1')
$temporary = -not $OutputDirectory
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
$outputRoot = if ($temporary) {
    Join-Path $tempBase ('kwr-scenario-generation-' + [guid]::NewGuid().ToString('N'))
} else {
    [IO.Path]::GetFullPath($OutputDirectory)
}
if ((Test-Path -LiteralPath $outputRoot) -and
    @(Get-ChildItem -LiteralPath $outputRoot -Force).Count -gt 0) {
    throw 'Scenario generation audit requires an empty output directory.'
}
[IO.Directory]::CreateDirectory($outputRoot) | Out-Null
$results = @()
$modules = [ordered]@{
    ScenarioCalibration = 'build-scenario-calibration.ps1'
    ScenarioAdversarialCalibration = 'build-scenario-adversarial-calibration.ps1'
    ScenarioExpertCorpus = 'build-scenario-expert-corpus.ps1'
}
try {
    foreach ($module in $modules.Keys) {
        & (Join-Path $PSScriptRoot $modules[$module]) -OutputDirectory $outputRoot
        $expectedPath = Join-Path $root "Data/$module.lua"
        $actualPath = Join-Path $outputRoot "Data/$module.lua"
        # Git checkouts may normalize line endings. Compare all executable text
        # and data, excluding only encoding preamble and CRLF representation.
        $expected = [IO.File]::ReadAllText($expectedPath).Replace("`r`n", "`n")
        $actual = [IO.File]::ReadAllText($actualPath).Replace("`r`n", "`n")
        $matches = $expected -ceq $actual
        $results += [ordered]@{
            module = $module
            matches = $matches
            canonicalSha256 = Get-KwrFileSha256 -LiteralPath $expectedPath
            generatedSha256 = Get-KwrFileSha256 -LiteralPath $actualPath
        }
    }
    $failures = @($results | Where-Object { -not $_.matches })
    [ordered]@{
        recordedAtUtc = [DateTime]::UtcNow.ToString('o')
        result = $(if ($failures.Count) { 'FAIL' } else { 'PASS' })
        comparison = 'Complete Lua text, UTF-8 preamble and CRLF normalized only'
        modules = $results
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $outputRoot 'generation-audit.json') -Encoding UTF8
    if ($failures.Count) {
        throw ('Scenario runtime is stale or generator changed: ' + (($failures | ForEach-Object { $_.module }) -join ', '))
    }
    Write-Output 'KWR_SCENARIO_GENERATION_PASS modules=3'
} finally {
    if ($temporary -and (Test-Path -LiteralPath $outputRoot)) {
        $resolved = [IO.Path]::GetFullPath($outputRoot)
        if (-not $resolved.StartsWith($tempBase + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Refusing to remove scenario audit output outside the temporary directory.'
        }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
