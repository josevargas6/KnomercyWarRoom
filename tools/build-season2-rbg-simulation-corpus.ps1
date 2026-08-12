[CmdletBinding()]
param(
    [ValidateRange(1, 5000)]
    [int]$CasesPerMap = 500,
    [string]$OutFile = "knowledge\season2-rbg-simulation-corpus.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$matrix = Get-Content -LiteralPath (Join-Path $root "knowledge\rbg-scenario-matrix.json") -Raw |
    ConvertFrom-Json
$outPath = Join-Path $root $OutFile
$phases = @("OPENING", "STABILIZE", "PRESSURE", "RECOVERY", "ENDGAME")
if (($CasesPerMap % $phases.Count) -ne 0) {
    throw "CasesPerMap must split evenly across the five phases."
}

$families = @{
    OPENING = @("first-contact", "scout-confirm", "reserve-route", "anti-stealth")
    STABILIZE = @("score-floor", "healer-triangle", "defender-pair", "rotation-discipline")
    PRESSURE = @("control-chain", "grip-window", "ranged-sightline", "weak-side-pivot")
    RECOVERY = @("regroup", "cross-map-trade", "post-wipe", "objective-denial")
    ENDGAME = @("clock-protection", "last-window", "safe-cap", "deny-throw")
}
$compWatches = @("HUNTER_DK_PRESSURE", "ARMS_AFFLICTION_CONTROL", "HUNTER_RET_TEMPO", "ROGUE_AFFLICTION_SPLIT")
$perPhase = [int]($CasesPerMap / $phases.Count)
$cases = [System.Collections.Generic.List[object]]::new()

foreach ($map in @($matrix.maps | Sort-Object mapKey)) {
    foreach ($phase in $phases) {
        for ($index = 1; $index -le $perPhase; $index++) {
            $family = $families[$phase][($index - 1) % $families[$phase].Count]
            $watch = $compWatches[($index - 1) % $compWatches.Count]
            $cases.Add([ordered]@{
                caseId = ("s2-sim-{0}-{1}-{2:d3}" -f $map.mapKey.ToLowerInvariant(), $phase.ToLowerInvariant(), $index)
                mapKey = [string]$map.mapKey
                mapProfile = [string]$map.mapProfile
                phase = $phase
                scenarioFamily = $family
                compWatch = $watch
                status = "SIMULATION_ONLY"
                source = "SEASON_2_PRE_LIVE_DETERMINISTIC"
                objective = "Exercise a reversible $phase branch on $($map.mapKey) without treating a forecast as live evidence."
                requiredLiveEvidence = @("legal objective state", "roster capability confirmation", "outcome review")
                invalidatedBy = @("official tuning change", "contradictory live objective behavior", "roster capability mismatch")
            }) | Out-Null
        }
    }
}

$document = [ordered]@{
    schema = "kwr-season2-rbg-simulation-corpus"
    schemaVersion = 1
    generatedAt = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
    patch = "12.1.0"
    status = "SIMULATION_ONLY"
    casesPerMap = $CasesPerMap
    casesPerPhasePerMap = $perPhase
    totalCases = $cases.Count
    activation = "OFFLINE_COVERAGE_AND_REGRESSION_ONLY"
    cases = $cases.ToArray()
}

[IO.File]::WriteAllText($outPath, (($document | ConvertTo-Json -Depth 8) + [Environment]::NewLine),
    [Text.UTF8Encoding]::new($false))
Write-Output "Season 2 RBG simulation corpus: $($document.totalCases) cases ($CasesPerMap per map)"
