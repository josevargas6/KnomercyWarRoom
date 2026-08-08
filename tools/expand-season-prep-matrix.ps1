[CmdletBinding()]
param(
    [ValidateRange(5, 200)]
    [int]$AddPerMap = 100
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$matrixPath = Join-Path $root "knowledge\rbg-scenario-matrix.json"
$matrix = Get-Content -LiteralPath $matrixPath -Raw | ConvertFrom-Json
$phases = @("OPENING", "STABILIZE", "PRESSURE", "RECOVERY", "ENDGAME")

if (($AddPerMap % $phases.Count) -ne 0) {
    throw "AddPerMap must divide equally across the five scenario phases."
}

$prompts = @{
    OPENING = @("confirm the first public objective", "protect the first arrival", "deny a blind split", "stage the reserve route", "hold the opener until coverage is real", "identify the first overcommit", "protect the safe anchor", "trade only on confirmed timing", "rebuild after a failed first touch", "keep the opening caller unambiguous", "preserve healer arrival", "deny the first free rotate", "verify the enemy opening before moving", "hold a low-risk shell", "commit only with full group timing", "recover an isolated opener", "protect a delayed arrival", "identify the actual first contest", "avoid a speculative chase", "reset the opener after lost truth")
    STABILIZE = @("hold the established score floor", "rotate a reserve without emptying the anchor", "deny a shallow bait", "protect the current carrier or objective", "rebuild after a traded cooldown", "verify an uncertain location", "protect the defender handoff", "hold until reinforcement timing is known", "punish a confirmed overextension", "avoid equal weak contacts", "stabilize after a delayed respawn", "keep one reversible reserve", "deny a back-cap or flank", "protect the winning lane", "re-anchor after a lost defender", "trade only with a recovery route", "reset after failed pressure", "confirm the next rotation", "hold the safe value", "preserve a clean regroup")
    PRESSURE = @("strike the confirmed weak lane", "collapse only before the response lands", "convert a defender advantage", "deny the enemy recovery route", "pressure without exposing the score floor", "time a coordinated reinforcement", "force a defensive cooldown trade", "punish an isolated carrier or objective", "convert a clean information edge", "reset when the window closes", "keep the retreat route covered", "hold a split until the collapse is real", "deny the enemy peel", "pressure the next score event", "reassess after an enemy counter", "preserve objective coverage during the hit", "avoid chasing through an unverified lane", "turn a local win into map value", "stabilize after a failed collapse", "call off pressure when truth degrades")
    RECOVERY = @("regroup before the next free loss", "deny the enemy snowball lane", "protect the remaining score path", "reset a broken split", "recover a missing defender", "rebuild carrier or objective coverage", "hold the last safe anchor", "trade only for a real reset", "deny a second consecutive loss", "recover after an uncertain wipe", "preserve the respawn wave", "avoid trickling into the recovery lane", "reclaim public objective truth", "stop an enemy conversion", "rebuild the reserve route", "choose the lowest-risk denial", "recover after a failed objective handoff", "hold until the regroup arrives", "protect the comeback window", "abandon a lost route cleanly")
    ENDGAME = @("protect the direct winning path", "deny the final enemy score route", "refuse low-value greed", "hold the last required objective", "close only on confirmed value", "protect the final carrier or objective shell", "time the final reinforcement", "deny desperation pressure", "trade only if it ends the match", "reset after a failed final push", "keep the emergency reserve", "protect a narrow lead", "force the enemy into the longer route", "hold a match-point shell", "confirm the last decisive fact", "avoid an unnecessary chase", "deny the final back-cap or flank", "convert a clean final window", "stabilize the last respawn wave", "call the safe finish")
}

$perPhase = [int]($AddPerMap / $phases.Count)
$created = 0
foreach ($map in @($matrix.maps)) {
    $existingIds = @{}
    foreach ($scenario in @($map.scenarios)) { $existingIds[[string]$scenario.scenarioId] = $true }
    $slug = ([string]$map.mapKey).ToLowerInvariant()
    foreach ($phase in $phases) {
        $template = @($map.scenarios | Where-Object { $_.phase -eq $phase } | Select-Object -First 1)[0]
        if (-not $template) { throw "Map $($map.mapKey) has no $phase template scenario." }
        for ($index = 1; $index -le $perPhase; $index++) {
            $id = "{0}-season-prep-{1}-{2:d2}" -f $slug, $phase.ToLowerInvariant(), $index
            if ($existingIds[$id]) { continue }
            $prompt = $prompts[$phase][$index - 1]
            $map.scenarios += [pscustomobject][ordered]@{
                scenarioId = $id
                phase = $phase
                summary = "$($template.summary) Season-prep branch: $prompt."
                goal = "$($template.goal) Validate this $phase branch after the new season launches."
                seasonStatus = "PENDING_SEASON_REVIEW"
                sourceScenarioId = [string]$template.scenarioId
            }
            $created++
        }
    }
}

$matrix.targetBaseScenariosPerMap = [int](@($matrix.maps[0].scenarios).Count)
$matrix.generatedAt = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
$matrix | Add-Member -NotePropertyName seasonPreparation -NotePropertyValue ([ordered]@{
    status = "PENDING_SEASON_REVIEW"
    addedPerMap = $AddPerMap
    totalAdded = $created
    runtimeEligible = $false
    reviewRequired = "Official patch notes plus post-launch field evidence"
}) -Force
$matrix | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $matrixPath -Encoding UTF8

Write-Output "KWR season-prep matrix expansion"
Write-Output "Added per map: $AddPerMap"
Write-Output "Total added: $created"
Write-Output "Target scenarios per map: $($matrix.targetBaseScenariosPerMap)"
