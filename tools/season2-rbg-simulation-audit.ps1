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
if ([int]$corpus.totalCases -ne 5000 -or @($corpus.cases).Count -ne 5000) {
    $errors.Add("Season 2 simulation corpus must contain exactly 5,000 cases.")
}
foreach ($field in @($schema.required)) {
    if ($null -eq $corpus.PSObject.Properties[$field]) {
        $errors.Add("Season 2 simulation corpus missing required field: $field")
    }
}
if ([int]$corpus.generatorVersion -lt 2) {
    $errors.Add("Season 2 simulation corpus must use generatorVersion 2 or later.")
}
$ids = @($corpus.cases | ForEach-Object caseId)
if (@($ids | Select-Object -Unique).Count -ne $ids.Count) { $errors.Add("Simulation case IDs are not unique.") }
$canonicalKeys = @($corpus.cases | ForEach-Object canonicalKey)
if (@($canonicalKeys | Select-Object -Unique).Count -ne $canonicalKeys.Count) { $errors.Add("Simulation canonical keys are not unique.") }
$contentHashes = @($corpus.cases | ForEach-Object contentHash)
if (@($contentHashes | Select-Object -Unique).Count -ne $contentHashes.Count) { $errors.Add("Simulation content hashes are not unique.") }
$maps = @($corpus.cases | Group-Object mapKey)
if ($maps.Count -ne 10) { $errors.Add("Simulation corpus must cover exactly ten maps.") }
foreach ($map in $maps) {
    if ($map.Count -ne 500) { $errors.Add("$($map.Name) must contain 500 cases; found $($map.Count).") }
    foreach ($phase in @("OPENING", "STABILIZE", "PRESSURE", "RECOVERY", "ENDGAME")) {
        $count = @($map.Group | Where-Object phase -eq $phase).Count
        if ($count -ne 100) { $errors.Add("$($map.Name) $phase must contain 100 cases; found $count.") }
    }
}
foreach ($case in @($corpus.cases)) {
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
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "tools\compile-season2-rbg-lifecycle.ps1") -CorpusFile $CorpusFile -Check
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Output "KWR Season 2 simulation audit PASS cases=5000 maps=10 phases=5"
