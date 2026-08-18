[CmdletBinding()]
param([string]$CorpusFile = "knowledge\season2-rbg-simulation-corpus.json")

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$path = Join-Path $root $CorpusFile
$corpus = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
$schemaPath = Join-Path $root "knowledge\schemas\season2-rbg-simulation-corpus-schema.json"
$schema = Get-Content -LiteralPath $schemaPath -Raw | ConvertFrom-Json
$errors = [System.Collections.Generic.List[string]]::new()
function Get-ContentHash {
    param([Parameter(Mandatory = $true)][string]$Text)

    $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
    $hash = [Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    return -join ($hash | ForEach-Object { $_.ToString("x2") })
}
if ($corpus.schema -ne "kwr-season2-rbg-simulation-corpus" -or $corpus.status -ne "SIMULATION_ONLY") {
    $errors.Add("Season 2 simulation corpus must remain explicitly simulation-only.")
}
if ($corpus.activation -ne "IMMEDIATE_THEORY_BRANCH_ACTIVATION_AND_REGRESSION") {
    $errors.Add("Season 2 simulation corpus must activate theory branches without claiming empirical outcomes.")
}
 $completeMatrix = $corpus.coverageMode -eq 'COMPLETE_CARTESIAN'
if ([int]$corpus.totalCases -ne 100000 -or ((-not $completeMatrix) -and @($corpus.cases).Count -ne 100000)) {
    $errors.Add("Season 2 simulation corpus must contain exactly 100,000 cases.")
}
foreach ($field in @($schema.required)) {
    if ($null -eq $corpus.PSObject.Properties[$field]) {
        $errors.Add("Season 2 simulation corpus missing required field: $field")
    }
}
if ([int]$corpus.generatorVersion -lt 3) {
    $errors.Add("Season 2 simulation corpus must use generatorVersion 3 or later.")
}
if ([int]$corpus.schemaVersion -lt 2) {
    $errors.Add("Season 2 simulation corpus must use schemaVersion 2 or later for complete Cartesian coverage.")
}
$cases = if ($corpus.cases) { @($corpus.cases) } else { @() }
if (-not $completeMatrix) {
    $ids = @($cases | ForEach-Object caseId)
    if (@($ids | Select-Object -Unique).Count -ne $ids.Count) { $errors.Add("Simulation case IDs are not unique.") }
    $canonicalKeys = @($cases | ForEach-Object canonicalKey)
    if (@($canonicalKeys | Select-Object -Unique).Count -ne $canonicalKeys.Count) { $errors.Add("Simulation canonical keys are not unique.") }
    $contentHashes = @($cases | ForEach-Object contentHash)
    if (@($contentHashes | Select-Object -Unique).Count -ne $contentHashes.Count) { $errors.Add("Simulation content hashes are not unique.") }
}
$maps = if ($completeMatrix) { @($corpus.matrix.maps) } else { @($cases | Group-Object mapKey) }
if ($maps.Count -ne 10) { $errors.Add("Simulation corpus must cover exactly ten maps.") }
foreach ($map in $maps) {
    $mapName = if ($completeMatrix) { $map.mapKey } else { $map.Name }
    $mapCount = if ($completeMatrix) { [int]$corpus.casesPerMap } else { $map.Count }
    if ($mapCount -ne 10000) { $errors.Add("$mapName must contain 10,000 cases; found $mapCount.") }
    foreach ($phase in @("OPENING", "STABILIZE", "PRESSURE", "RECOVERY", "ENDGAME")) {
        $count = if ($completeMatrix) { [int]$corpus.casesPerPhasePerMap } else { @($map.Group | Where-Object phase -eq $phase).Count }
        if ($count -ne 2000) { $errors.Add("$mapName $phase must contain 2,000 cases; found $count.") }
    }
}
if ($completeMatrix) {
    $product = @($corpus.matrix.compWatches).Count * @($corpus.matrix.scoreStates).Count *
        @($corpus.matrix.counterResponses).Count * @($corpus.matrix.evidenceStates).Count
    foreach ($phase in @('OPENING', 'STABILIZE', 'PRESSURE', 'RECOVERY', 'ENDGAME')) {
        if ((@($corpus.matrix.families.$phase).Count * $product) -ne 2000) {
            $errors.Add("Complete matrix does not cover all exact $phase tactical branches.")
        }
    }
}
foreach ($case in $cases) {
    foreach ($field in @($schema.caseRequired)) {
        if ($null -eq $case.PSObject.Properties[$field]) {
            $errors.Add("Simulation case $($case.caseId) missing required field: $field")
        }
    }
    if ($case.status -ne "SIMULATION_ONLY" -or $case.source -ne "SEASON_2_PRE_LIVE_DETERMINISTIC") {
        $errors.Add("Simulation case $($case.caseId) has unsafe provenance.")
        break
    }
    if ([string]::IsNullOrWhiteSpace([string]$case.sourceScenarioId)) {
        $errors.Add("Simulation case $($case.caseId) is not linked to a canonical scenario.")
        break
    }
    if ([string]$case.contentHash -ne (Get-ContentHash ([string]$case.canonicalKey))) {
        $errors.Add("Simulation case $($case.caseId) content hash does not match its canonical key.")
        break
    }
    if (@($case.requiredLiveEvidence).Count -eq 0 -or @($case.invalidatedBy).Count -eq 0) {
        $errors.Add("Simulation case $($case.caseId) is missing activation safeguards.")
        break
    }
}
if ($errors.Count -gt 0) { $errors | ForEach-Object { Write-Error $_ -ErrorAction Continue }; exit 1 }
Write-Output "KWR Season 2 simulation audit PASS cases=100000 maps=10 phases=5 exactBranches=2000"
