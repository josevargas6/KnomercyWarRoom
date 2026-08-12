[CmdletBinding()]
param([string]$CorpusFile = "knowledge\season2-rbg-simulation-corpus.json")

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$path = Join-Path $root $CorpusFile
$corpus = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
$errors = [System.Collections.Generic.List[string]]::new()
if ($corpus.schema -ne "kwr-season2-rbg-simulation-corpus" -or $corpus.status -ne "SIMULATION_ONLY") {
    $errors.Add("Season 2 simulation corpus must remain explicitly simulation-only.")
}
if ([int]$corpus.totalCases -ne 5000 -or @($corpus.cases).Count -ne 5000) {
    $errors.Add("Season 2 simulation corpus must contain exactly 5,000 cases.")
}
$ids = @($corpus.cases | ForEach-Object caseId)
if (@($ids | Select-Object -Unique).Count -ne $ids.Count) { $errors.Add("Simulation case IDs are not unique.") }
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
    if ($case.status -ne "SIMULATION_ONLY" -or $case.source -ne "SEASON_2_PRE_LIVE_DETERMINISTIC") {
        $errors.Add("Simulation case $($case.caseId) has unsafe provenance.")
        break
    }
}
if ($errors.Count -gt 0) { $errors | ForEach-Object { Write-Error $_ -ErrorAction Continue }; exit 1 }
Write-Output "KWR Season 2 simulation audit PASS cases=5000 maps=10 phases=5"
