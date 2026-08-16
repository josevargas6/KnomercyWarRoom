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
$scoreStates = @("SAFE_DEFAULT", "FAVORABLE", "UNFAVORABLE", "TIED", "EMERGENCY")
$counterResponses = @("EXPECTED", "BAIT", "OVERCOMMIT", "CROSSMAP_PIVOT", "FAILED_CONNECT")
$evidenceStates = @("LIVE_KNOWN", "OBSERVED", "DERIVED", "META_ONLY", "UNKNOWN")
$outcomeBranches = @("SUCCESS", "PARTIAL", "FAILURE", "SWITCH", "STOP")
$perPhase = [int]($CasesPerMap / $phases.Count)
$cases = [System.Collections.Generic.List[object]]::new()

function Get-ContentHash {
    param([Parameter(Mandatory = $true)][string]$Text)

    $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
    $hash = [Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    return -join ($hash | ForEach-Object { $_.ToString("x2") })
}

foreach ($map in @($matrix.maps | Sort-Object mapKey)) {
    foreach ($phase in $phases) {
        $phaseScenarios = @($map.scenarios | Where-Object {
            $_.phase -eq $phase -and -not $_.sourceScenarioId
        })
        if ($phaseScenarios.Count -eq 0) {
            throw "$($map.mapKey) has no canonical $phase scenario to seed the Season 2 corpus."
        }
        for ($index = 1; $index -le $perPhase; $index++) {
            # 4 families x 5 score states x 5 counter-responses produces one
            # unique, inspectable tactical branch per entry in the 100-case phase.
            $zeroIndex = $index - 1
            $family = $families[$phase][$zeroIndex % $families[$phase].Count]
            $scoreState = $scoreStates[[int]($zeroIndex / $families[$phase].Count) % $scoreStates.Count]
            $counterResponse = $counterResponses[[int]($zeroIndex / ($families[$phase].Count * $scoreStates.Count)) % $counterResponses.Count]
            $watch = $compWatches[$zeroIndex % $compWatches.Count]
            $evidenceState = $evidenceStates[$zeroIndex % $evidenceStates.Count]
            $outcomeBranch = $outcomeBranches[[int]($zeroIndex / $families[$phase].Count) % $outcomeBranches.Count]
            $sourceScenario = $phaseScenarios[$zeroIndex % $phaseScenarios.Count]
            $canonicalKey = @(
                "v2", $map.mapKey, $phase, $family, $scoreState,
                $counterResponse, $watch, $evidenceState, $outcomeBranch,
                $sourceScenario.scenarioId
            ) -join "|"
            $cases.Add([ordered]@{
                caseId = ("s2-sim-{0}-{1}-{2:d3}" -f $map.mapKey.ToLowerInvariant(), $phase.ToLowerInvariant(), $index)
                canonicalKey = $canonicalKey
                contentHash = Get-ContentHash $canonicalKey
                mapKey = [string]$map.mapKey
                mapProfile = [string]$map.mapProfile
                phase = $phase
                scenarioFamily = $family
                compWatch = $watch
                scoreState = $scoreState
                counterResponse = $counterResponse
                evidenceState = $evidenceState
                outcomeBranch = $outcomeBranch
                sourceScenarioId = [string]$sourceScenario.scenarioId
                status = "SIMULATION_ONLY"
                source = "SEASON_2_PRE_LIVE_DETERMINISTIC"
                objective = "Exercise $family against $counterResponse in a $scoreState $phase branch on $($map.mapKey) without treating $evidenceState evidence as live proof."
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
    generatorVersion = 2
    casesPerMap = $CasesPerMap
    casesPerPhasePerMap = $perPhase
    totalCases = $cases.Count
    activation = "IMMEDIATE_THEORY_BRANCH_ACTIVATION_AND_REGRESSION"
    cases = $cases.ToArray()
}

[IO.File]::WriteAllText($outPath, (($document | ConvertTo-Json -Depth 8) + [Environment]::NewLine),
    [Text.UTF8Encoding]::new($false))
Write-Output "Season 2 RBG simulation corpus: $($document.totalCases) cases ($CasesPerMap per map)"
