[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))

function Load-JsonFile {
    param([Parameter(Mandatory = $true)][string]$Path)
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    $Object | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Make-Role {
    param([string]$Slot, [string]$Class, [string]$Spec, [string]$Role)
    return [ordered]@{ slot = $Slot; class = $Class; spec = $Spec; role = $Role }
}

function Normalize-EventName {
    param([string]$Value)
    return (($Value -replace '-', '_') -replace '[^a-zA-Z0-9_]', '').ToLower()
}

$matrix = Load-JsonFile (Join-Path $root "knowledge\rbg-scenario-matrix.json")

$mapMeta = @{
    ARATHI = @{
        kind = "NODE"; profile = "ab_standard"; short = "AB"; max = 1500
        openingWhere = "BS"; pressureWhere = "LM"; recoveryWhere = "BS"; endgameWhere = "FIELD"
        openingObjective = @{ friendly = 1; enemy = 0; friendlyIncoming = 0; enemyIncoming = 0 }
        stabilizeObjective = @{ friendly = 3; enemy = 2; friendlyIncoming = 0; enemyIncoming = 1 }
        pressureObjective = @{ friendly = 2; enemy = 2; friendlyIncoming = 0; enemyIncoming = 0 }
        recoveryObjective = @{ friendly = 2; enemy = 3; friendlyIncoming = 1; enemyIncoming = 0 }
        endgameObjective = @{ friendly = 3; enemy = 2; friendlyIncoming = 0; enemyIncoming = 1 }
    }
    GILNEAS = @{
        kind = "NODE"; profile = "bfg_standard"; short = "BFG"; max = 1500
        openingWhere = "WW"; pressureWhere = "LH"; recoveryWhere = "WW"; endgameWhere = "FIELD"
        openingObjective = @{ friendly = 1; enemy = 0; friendlyIncoming = 0; enemyIncoming = 0 }
        stabilizeObjective = @{ friendly = 2; enemy = 1; friendlyIncoming = 0; enemyIncoming = 1 }
        pressureObjective = @{ friendly = 1; enemy = 1; friendlyIncoming = 0; enemyIncoming = 0 }
        recoveryObjective = @{ friendly = 1; enemy = 2; friendlyIncoming = 1; enemyIncoming = 0 }
        endgameObjective = @{ friendly = 2; enemy = 1; friendlyIncoming = 0; enemyIncoming = 1 }
    }
    DEEPWIND = @{
        kind = "NODE"; profile = "dwg_standard"; short = "DWG"; max = 1500
        openingWhere = "MKT"; pressureWhere = "R"; recoveryWhere = "MKT"; endgameWhere = "FIELD"
        openingObjective = @{ friendly = 1; enemy = 1; friendlyIncoming = 0; enemyIncoming = 0 }
        stabilizeObjective = @{ friendly = 3; enemy = 2; friendlyIncoming = 0; enemyIncoming = 1 }
        pressureObjective = @{ friendly = 2; enemy = 2; friendlyIncoming = 0; enemyIncoming = 0 }
        recoveryObjective = @{ friendly = 2; enemy = 3; friendlyIncoming = 1; enemyIncoming = 0 }
        endgameObjective = @{ friendly = 3; enemy = 2; friendlyIncoming = 0; enemyIncoming = 1 }
    }
    EOTS = @{
        kind = "HYBRID"; profile = "eots_standard"; short = "EOTS"; max = 1500
        openingWhere = "MID"; pressureWhere = "MT"; recoveryWhere = "MT"; endgameWhere = "FIELD"
        openingObjective = @{ friendly = 1; enemy = 1; friendlyIncoming = 0; enemyIncoming = 0; flagValue = 75 }
        stabilizeObjective = @{ friendly = 2; enemy = 2; friendlyIncoming = 0; enemyIncoming = 0; flagValue = 85 }
        pressureObjective = @{ friendly = 2; enemy = 2; friendlyIncoming = 0; enemyIncoming = 0; flagValue = 100 }
        recoveryObjective = @{ friendly = 1; enemy = 3; friendlyIncoming = 0; enemyIncoming = 1; flagValue = 100 }
        endgameObjective = @{ friendly = 3; enemy = 1; friendlyIncoming = 0; enemyIncoming = 0; flagValue = 500 }
    }
    WSG = @{
        kind = "FLAG"; profile = "wsg_standard"; short = "WSG"; max = 3
        openingWhere = "ROUTE"; pressureWhere = "EFC"; recoveryWhere = "HOME"; endgameWhere = "CAP"
    }
    TWINPEAKS = @{
        kind = "FLAG"; profile = "tp_standard"; short = "TP"; max = 3
        openingWhere = "ROUTE"; pressureWhere = "EFC"; recoveryWhere = "HOME"; endgameWhere = "CAP"
    }
    TEMPLE = @{
        kind = "ORB"; profile = "tok_standard"; short = "TOK"; max = 1500
        openingWhere = "MID"; pressureWhere = "MID"; recoveryWhere = "MID"; endgameWhere = "MID"
    }
    SILVERSHARD = @{
        kind = "CART"; profile = "ssm_standard"; short = "SSM"; max = 1500
        openingWhere = "LAVA"; pressureWhere = "TOP"; recoveryWhere = "MID"; endgameWhere = "TOP"
    }
    DEEPHAUL = @{
        kind = "CART"; profile = "dhr_standard"; short = "DHR"; max = 1500
        openingWhere = "OC"; pressureWhere = "EC"; recoveryWhere = "OC"; endgameWhere = "OC"
    }
    SEETHING = @{
        kind = "RESOURCE"; profile = "shore_standard"; short = "SHORE"; max = 1500
        openingWhere = "FIELD"; pressureWhere = "NEXT"; recoveryWhere = "NEXT"; endgameWhere = "NEXT"
    }
}

function Build-Score {
    param([string]$Kind, [string]$Phase, [int]$Max)
    switch ($Kind) {
        "FLAG" {
            switch ($Phase) {
                "OPENING" { return [ordered]@{ friendly = 0; enemy = 0; max = $Max } }
                "STABILIZE" { return [ordered]@{ friendly = 1; enemy = 0; max = $Max } }
                "PRESSURE" { return [ordered]@{ friendly = 1; enemy = 1; max = $Max } }
                "RECOVERY" { return [ordered]@{ friendly = 0; enemy = 1; max = $Max } }
                default { return [ordered]@{ friendly = 2; enemy = 1; max = $Max } }
            }
        }
        default {
            switch ($Phase) {
                "OPENING" { return [ordered]@{ friendly = 0; enemy = 0; max = $Max } }
                "STABILIZE" { return [ordered]@{ friendly = [Math]::Floor($Max * 0.75); enemy = [Math]::Floor($Max * 0.6); max = $Max } }
                "PRESSURE" { return [ordered]@{ friendly = [Math]::Floor($Max * 0.55); enemy = [Math]::Floor($Max * 0.52); max = $Max } }
                "RECOVERY" { return [ordered]@{ friendly = [Math]::Floor($Max * 0.45); enemy = [Math]::Floor($Max * 0.62); max = $Max } }
                default { return [ordered]@{ friendly = [Math]::Floor($Max * 0.88); enemy = [Math]::Floor($Max * 0.79); max = $Max } }
            }
        }
    }
}

function Build-Objectives {
    param([hashtable]$Meta, [string]$Phase)
    switch ($Meta.kind) {
        "NODE" { return $Meta["$($Phase.ToLower())Objective"] }
        "HYBRID" { return $Meta["$($Phase.ToLower())Objective"] }
        "FLAG" {
            switch ($Phase) {
                "OPENING" { return [ordered]@{ friendlyCarrier = $null; enemyCarrier = $null } }
                "STABILIZE" { return [ordered]@{ friendlyCarrier = "our_fc"; enemyCarrier = "enemy_fc" } }
                "PRESSURE" { return [ordered]@{ friendlyCarrier = "our_fc"; enemyCarrier = "enemy_fc" } }
                "RECOVERY" { return [ordered]@{ friendlyCarrier = "our_fc"; enemyCarrier = "enemy_fc" } }
                default { return [ordered]@{ friendlyCarrier = "our_fc"; enemyCarrier = "enemy_fc" } }
            }
        }
        "ORB" {
            switch ($Phase) {
                "OPENING" { return [ordered]@{ friendlyOrbs = 1; enemyOrbs = 1; looseOrbs = 2 } }
                "STABILIZE" { return [ordered]@{ friendlyOrbs = 2; enemyOrbs = 1; looseOrbs = 1 } }
                "PRESSURE" { return [ordered]@{ friendlyOrbs = 1; enemyOrbs = 2; looseOrbs = 1 } }
                "RECOVERY" { return [ordered]@{ friendlyOrbs = 1; enemyOrbs = 2; looseOrbs = 1 } }
                default { return [ordered]@{ friendlyOrbs = 2; enemyOrbs = 1; looseOrbs = 1 } }
            }
        }
        "CART" {
            switch ($Phase) {
                "OPENING" { return [ordered]@{ activeCart = $Meta.openingWhere; nextCart = $Meta.pressureWhere } }
                "STABILIZE" { return [ordered]@{ activeCart = $Meta.openingWhere; nextCart = $Meta.pressureWhere } }
                "PRESSURE" { return [ordered]@{ activeCart = $Meta.pressureWhere; nextCart = $Meta.endgameWhere } }
                "RECOVERY" { return [ordered]@{ activeCart = $Meta.recoveryWhere; nextCart = $Meta.pressureWhere } }
                default { return [ordered]@{ activeCart = $Meta.endgameWhere; nextCart = $Meta.pressureWhere } }
            }
        }
        "RESOURCE" {
            switch ($Phase) {
                "OPENING" { return [ordered]@{ activeNode = "Center"; nextSpawnKnown = $null } }
                "STABILIZE" { return [ordered]@{ activeNode = "West"; nextSpawnKnown = "North" } }
                "PRESSURE" { return [ordered]@{ activeNode = "West"; nextSpawnKnown = "North" } }
                "RECOVERY" { return [ordered]@{ activeNode = "South"; nextSpawnKnown = "East" } }
                default { return [ordered]@{ activeNode = "North"; nextSpawnKnown = "Center" } }
            }
        }
    }
}

function Build-Rosters {
    param([string]$Kind, [string]$Phase)
    switch ($Kind) {
        "NODE" {
            return @(
                @(Make-Role "anchor" "Warrior" "Arms" "DAMAGER"),
                @(Make-Role "floater" "Mage" "Frost" "DAMAGER"),
                @(Make-Role "healer" "Priest" "Discipline" "HEALER")
            ), @(
                @(Make-Role "enemy_push" "Rogue" "Subtlety" "DAMAGER"),
                @(Make-Role "enemy_healer" "Druid" "Restoration" "HEALER")
            )
        }
        "HYBRID" {
            return @(
                @(Make-Role "tower_anchor" "Warlock" "Affliction" "DAMAGER"),
                @(Make-Role "mid_support" "Priest" "Discipline" "HEALER"),
                @(Make-Role "strike" "Mage" "Frost" "DAMAGER")
            ), @(
                @(Make-Role "enemy_flag_runner" "Mage" "Frost" "DAMAGER"),
                @(Make-Role "enemy_tower_anchor" "Hunter" "Marksman" "DAMAGER")
            )
        }
        "FLAG" {
            return @(
                @(Make-Role "our_fc" "Druid" "Guardian" "TANK"),
                @(Make-Role "carrier_healer" "Priest" "Discipline" "HEALER"),
                @(Make-Role "return_team" "Mage" "Frost" "DAMAGER")
            ), @(
                @(Make-Role "enemy_fc" "Demon Hunter" "Vengeance" "TANK"),
                @(Make-Role "enemy_healer" "Priest" "Discipline" "HEALER")
            )
        }
        "ORB" {
            return @(
                @(Make-Role "friendly_carrier" "Paladin" "Protection" "TANK"),
                @(Make-Role "mid_healer" "Priest" "Discipline" "HEALER"),
                @(Make-Role "orb_support" "Warrior" "Arms" "DAMAGER")
            ), @(
                @(Make-Role "enemy_carrier" "Warrior" "Arms" "DAMAGER"),
                @(Make-Role "enemy_support" "Rogue" "Subtlety" "DAMAGER")
            )
        }
        "CART" {
            return @(
                @(Make-Role "escort" "Warrior" "Arms" "DAMAGER"),
                @(Make-Role "cart_healer" "Shaman" "Restoration" "HEALER"),
                @(Make-Role "delay_team" "Mage" "Frost" "DAMAGER")
            ), @(
                @(Make-Role "enemy_delay" "Rogue" "Subtlety" "DAMAGER"),
                @(Make-Role "enemy_healer" "Priest" "Holy" "HEALER")
            )
        }
        default {
            return @(
                @(Make-Role "advance_group" "Hunter" "Marksman" "DAMAGER"),
                @(Make-Role "channel_healer" "Priest" "Holy" "HEALER"),
                @(Make-Role "skirmisher" "Mage" "Frost" "DAMAGER")
            ), @(
                @(Make-Role "enemy_race_team" "Druid" "Balance" "DAMAGER"),
                @(Make-Role "enemy_channel" "Warlock" "Affliction" "DAMAGER")
            )
        }
    }
}

function Build-Contract {
    param([hashtable]$Meta, [string]$Phase)
    switch ($Phase) {
        "OPENING" {
            return [ordered]@{
                planId = "OPENING"; status = "TIE"; primaryTag = "PLAN:OPENING"; result = "VICTORY"
                what = "SETUP"; nextWhat = "HOLD"; where = $Meta.openingWhere; nextWhere = $Meta.openingWhere
                forbidden = "PLAN:RECOVERY"; success = "establish_opening_shell"; abort = "enemy_wins_first_objective"
                problemType = "OBJECTIVE_THREAT"; truthBand = "HIGH"; required = @("coverage", "setup")
            }
        }
        "STABILIZE" {
            return [ordered]@{
                planId = "PACE_AHEAD"; status = "WIN"; primaryTag = "PLAN:PACE_AHEAD"; result = "VICTORY"
                what = "HOLD"; nextWhat = "HOLD"; where = "FIELD"; nextWhere = "FIELD"
                forbidden = "PLAN:RECOVERY"; success = "preserve_winning_state"; abort = "coverage_breaks"
                problemType = "OBJECTIVE_THREAT"; truthBand = "HIGH"; required = @("coverage", "rotation")
            }
        }
        "PRESSURE" {
            $what = switch ($Meta.kind) {
                "NODE" { "TAKE" }
                "HYBRID" { "SWING" }
                "FLAG" { "PRESS" }
                "ORB" { "KILL" }
                "CART" { "TURN" }
                default { "ROTATE" }
            }
            return [ordered]@{
                planId = "CHECK"; status = "TIE"; primaryTag = "PLAN:CHECK"; result = "VICTORY"
                what = $what; nextWhat = "CHECK"; where = $Meta.pressureWhere; nextWhere = "FIELD"
                forbidden = "CALL:STALL"; success = "convert_pressure_window"; abort = "target_reinforced_early"
                problemType = "OBJECTIVE_THREAT"; truthBand = "HIGH"; required = @("pressure", "control")
            }
        }
        "RECOVERY" {
            $what = switch ($Meta.kind) {
                "FLAG" { "COVER" }
                "ORB" { "RESET" }
                "RESOURCE" { "ROTATE" }
                default { "TAKE" }
            }
            return [ordered]@{
                planId = "RECOVERY"; status = "LOSE"; primaryTag = "PLAN:RECOVERY"; result = "VICTORY"
                what = $what; nextWhat = "RECOVER"; where = $Meta.recoveryWhere; nextWhere = $Meta.recoveryWhere
                forbidden = "PLAN:OPENING"; success = "rebuild_score_path"; abort = "regroup_fails"
                problemType = "BASE_UNDER_THREAT"; truthBand = "HIGH"; required = @("regroup", "deny")
            }
        }
        default {
            $what = switch ($Meta.kind) {
                "FLAG" { "CAP" }
                "RESOURCE" { "CHECK" }
                "CART" { "ESCORT" }
                default { "HOLD" }
            }
            return [ordered]@{
                planId = "PACE_AHEAD"; status = "WIN"; primaryTag = "PLAN:PACE_AHEAD"; result = "VICTORY"
                what = $what; nextWhat = $what; where = $Meta.endgameWhere; nextWhere = $Meta.endgameWhere
                forbidden = "CALL:CHASE"; success = "close_match_cleanly"; abort = "final_state_breaks"
                problemType = "OBJECTIVE_THREAT"; truthBand = "HIGH"; required = @("discipline", "coverage")
            }
        }
    }
}

function Build-BranchEvidence {
    param($Scenario, [hashtable]$Meta)

    $families = switch ($Scenario.phase) {
        "OPENING" {
            if ($Meta.kind -eq "FLAG") { @("hold", "escort", "deny") }
            elseif ($Meta.kind -eq "CART") { @("split", "escort", "rotate") }
            elseif ($Meta.kind -eq "RESOURCE") { @("rotate", "hold", "deny") }
            else { @("hold", "rotate", "bait") }
        }
        "STABILIZE" {
            if ($Meta.kind -eq "FLAG") { @("hold", "escort", "deny") }
            elseif ($Meta.kind -eq "ORB") { @("hold", "escort", "deny") }
            elseif ($Meta.kind -eq "CART") { @("hold", "escort", "rotate") }
            else { @("hold", "deny", "rotate") }
        }
        "PRESSURE" {
            if ($Meta.kind -eq "FLAG") { @("collapse", "return_window", "bait") }
            elseif ($Meta.kind -eq "ORB") { @("collapse", "deny", "escort") }
            elseif ($Meta.kind -eq "CART") { @("collapse", "rotate", "bait") }
            elseif ($Meta.kind -eq "RESOURCE") { @("bait", "rotate", "deny") }
            else { @("collapse", "split", "bait") }
        }
        "RECOVERY" {
            if ($Meta.kind -eq "FLAG") { @("recover", "escort", "deny") }
            elseif ($Meta.kind -eq "CART") { @("recover", "rotate", "deny") }
            else { @("recover", "deny", "rotate") }
        }
        default {
            if ($Meta.kind -eq "FLAG") { @("late_game_score_protection", "return_window", "escort") }
            elseif ($Meta.kind -eq "CART") { @("late_game_score_protection", "escort", "deny") }
            elseif ($Meta.kind -eq "RESOURCE") { @("late_game_score_protection", "deny", "rotate") }
            else { @("late_game_score_protection", "deny", "hold") }
        }
    }

    $preferredComparison = switch ($families[0]) {
        "hold" { "protect current score floor before expanding." }
        "collapse" { "concentrate force on the best live lane instead of equal split pressure." }
        "recover" { "rebuild one real score path instead of feeding the old fight." }
        "late_game_score_protection" { "preserve the winning path before optional pressure." }
        default { "choose the safer legal branch before adding greed." }
    }

    $safeCounter = switch ($families[1]) {
        "escort" { "protect the scoring package while denying the enemy reset." }
        "deny" { "deny the enemy score event before chasing side value." }
        "rotate" { "rotate only when the next lane beats the current score event." }
        "return_window" { "commit only on the real conversion window." }
        "split" { "refuse equal weak contacts on multiple lanes." }
        default { "preserve the safer path until battlefield truth improves." }
    }

    $thirdFocus = if ($Meta.kind -eq "FLAG") {
        "carrier route truth"
    } elseif ($Meta.kind -eq "CART") {
        "route timing truth"
    } else {
        "movement / location truth"
    }

    $comparisonIds = New-Object System.Collections.Generic.List[string]
    $responseIds = New-Object System.Collections.Generic.List[string]
    $mapKey = [string]$Scenario.mapKey
    $phase = [string]$Scenario.phase

    if ($phase -eq "OPENING" -or $phase -eq "STABILIZE") {
        [void]$comparisonIds.Add($mapKey + "_HOLD_VS_ROTATE")
        if ($Meta.kind -eq "FLAG" -or $Meta.kind -eq "ORB" -or $Meta.kind -eq "CART") {
            [void]$comparisonIds.Add($mapKey + "_ESCORT_VS_CHASE")
            [void]$responseIds.Add($mapKey + "_RESP_ESCORT_SHELL")
        } else {
            [void]$comparisonIds.Add($mapKey + "_DENY_VS_TRADE")
            [void]$responseIds.Add($mapKey + "_RESP_BAIT_SHOW")
        }
        [void]$responseIds.Add($mapKey + "_RESP_DENY_TRADE")
    } elseif ($phase -eq "PRESSURE") {
        [void]$comparisonIds.Add($mapKey + "_COLLAPSE_VS_SPLIT")
        [void]$comparisonIds.Add($mapKey + "_BAIT_VS_FRONTDOOR")
        [void]$comparisonIds.Add($mapKey + "_CONVERT_VS_GREED")
        [void]$responseIds.Add($mapKey + "_RESP_SPLIT_PRESSURE")
        [void]$responseIds.Add($mapKey + "_RESP_COLLAPSE_CONNECT")
        if ($Meta.kind -eq "FLAG") {
            [void]$responseIds.Add($mapKey + "_RESP_RETURN_WINDOW")
        } else {
            [void]$responseIds.Add($mapKey + "_RESP_ESCORT_SHELL")
        }
    } elseif ($phase -eq "RECOVERY") {
        [void]$comparisonIds.Add($mapKey + "_RECOVER_VS_TRICKLE")
        [void]$comparisonIds.Add($mapKey + "_DENY_VS_TRADE")
        if ($Meta.kind -eq "FLAG" -or $Meta.kind -eq "CART") {
            [void]$comparisonIds.Add($mapKey + "_ESCORT_VS_CHASE")
            [void]$responseIds.Add($mapKey + "_RESP_ESCORT_SHELL")
        }
        [void]$responseIds.Add($mapKey + "_RESP_RECOVER_REBAIT")
        [void]$responseIds.Add($mapKey + "_RESP_DENY_TRADE")
    } else {
        [void]$comparisonIds.Add($mapKey + "_LATE_PROTECT_VS_PRESS")
        [void]$comparisonIds.Add($mapKey + "_DENY_VS_TRADE")
        [void]$comparisonIds.Add($mapKey + "_CONVERT_VS_GREED")
        [void]$responseIds.Add($mapKey + "_RESP_LATE_GREED")
        [void]$responseIds.Add($mapKey + "_RESP_DENY_TRADE")
        if ($Meta.kind -eq "FLAG") {
            [void]$responseIds.Add($mapKey + "_RESP_RETURN_WINDOW")
        }
    }

    $legalWhen = switch ($phase) {
        "OPENING" {
            @(
                "objective truth confirms the opening lane",
                "coverage is planted before expansion",
                "the score floor is not abandoned for first contact"
            )
        }
        "STABILIZE" {
            @(
                "the current shell still wins the score path",
                "reserve timing remains intact",
                "friendly defenders stay planted on the score floor"
            )
        }
        "PRESSURE" {
            @(
                "the target lane is still live before reinforcement lands",
                "the pressure package arrives together",
                "the current score floor remains protected during the strike"
            )
        }
        "RECOVERY" {
            @(
                "a regroup wave can still arrive before resolution",
                "the enemy winning lane can still be denied",
                "the rebuild does not expose a worse immediate loss"
            )
        }
        default {
            @(
                "the protected path still wins the game",
                "the enemy desperation route is still denyable",
                "optional pressure is weaker than direct score protection"
            )
        }
    }

    $invalidatedBy = switch ($phase) {
        "OPENING" { @("the enemy wins first objective control cleanly", "coverage breaks before the opener settles") }
        "STABILIZE" { @("the shell loses its planted defender", "the reserve route is consumed by a higher-value emergency") }
        "PRESSURE" { @("the target reinforces before arrival", "the pressure package splits into equal weak contacts") }
        "RECOVERY" { @("the regroup wave arrives too late", "the denial lane is already gone") }
        default { @("the winning path no longer wins", "the enemy last-score route cannot be denied in time") }
    }

    $expectedEnemyCounter = switch ($families[0]) {
        "hold" { "Enemy tries to peel the planted coverage and create a weak-side break." }
        "collapse" { "Enemy tries to split your hit and survive to the next reset." }
        "recover" { "Enemy tries to force panic recommits before the regroup lands." }
        "late_game_score_protection" { "Enemy tries to bait greed and reopen one last scoring lane." }
        default { "Enemy tries to bend movement and expose the score floor." }
    }

    return [ordered]@{
        familyTags = $families
        preferredComparison = $preferredComparison
        safestCounter = $safeCounter
        primaryComparisonId = if ($comparisonIds.Count -gt 0) { $comparisonIds[0] } else { $null }
        primaryResponseId = if ($responseIds.Count -gt 0) { $responseIds[0] } else { $null }
        doctrineComparisonIds = @($comparisonIds)
        doctrineResponseIds = @($responseIds)
        legalWhen = $legalWhen
        invalidatedBy = $invalidatedBy
        expectedEnemyCounter = $expectedEnemyCounter
        evidenceFocus = @(
            "objective truth",
            "score truth",
            $thirdFocus
        )
    }
}

function Build-Replay {
    param($Scenario, [hashtable]$Meta)
    $contract = Build-Contract -Meta $Meta -Phase $Scenario.phase
    $branchEvidence = Build-BranchEvidence -Scenario $Scenario -Meta $Meta
    $eventBase = Normalize-EventName $Scenario.scenarioId
    $score = Build-Score -Kind $Meta.kind -Phase $Scenario.phase -Max $Meta.max
    $rosters = Build-Rosters -Kind $Meta.kind -Phase $Scenario.phase
    $objectives = Build-Objectives -Meta $Meta -Phase $Scenario.phase
    $windowPressure = if ($Scenario.phase -eq "RECOVERY") { "HIGH" } else { "MEDIUM" }
    return [ordered]@{
        schema = "kwr-replay-schema"
        schemaVersion = 1
        kind = "timeline_replay"
        replayId = "$($Scenario.scenarioId)-001"
        source = [ordered]@{ type = "synthetic_state"; consent = "n/a"; provenance = "developer_fixture"; verified = $true }
        capturedAt = "2026-07-29T00:00:00Z"
        patch = [ordered]@{ interface = 120007; build = "6.1.0-alpha.29" }
        ruleset = [ordered]@{ apiMode = "Retail_Current"; bracket = "STANDARD" }
        map = [ordered]@{ key = $Scenario.mapKey; mode = "STANDARD"; kind = $Meta.kind; profile = $Meta.profile }
        side = "HORDE"
        redaction = [ordered]@{ status = "SYNTHETIC"; identityMode = "ROLE_LABELS"; secretValuesRemoved = $true }
        initialState = [ordered]@{
            friendlyRoster = $rosters[0]
            enemyRoster = $rosters[1]
            score = $score
            objectives = $objectives
            evidenceQuality = "HIGH"
        }
        timeline = @(
            [ordered]@{ t = 0; event = "${eventBase}_state"; facts = [ordered]@{ phase = $Scenario.phase; summary = $Scenario.summary; goal = $Scenario.goal } },
            [ordered]@{ t = 10; event = "${eventBase}_window"; facts = [ordered]@{ objective = $contract.where; pressure = $windowPressure } }
        )
        expectedLabels = [ordered]@{
            primaryActions = @($contract.primaryTag)
            fallbackActions = @("CALL:$($contract.what)", "WHERE:$($contract.where)")
            forbiddenActions = @($contract.forbidden)
            mustStay = @($rosters[0][0].slot)
            requiredCapabilities = $contract.required
            successConditions = @($contract.success)
            abortConditions = @($contract.abort)
            maxDelaySeconds = 8
            rationale = "$($Scenario.summary) $($Scenario.goal)"
            legalWhen = @($branchEvidence.legalWhen)
            invalidatedBy = @($branchEvidence.invalidatedBy)
            expectedEnemyCounter = $branchEvidence.expectedEnemyCounter
            branchEvidence = $branchEvidence
        }
        outcome = [ordered]@{
            result = $contract.result
            finalScore = [ordered]@{ friendly = $score.friendly; enemy = $score.enemy }
            reviewStatus = "OPEN"
            checkpoints = @(
                [ordered]@{ offsetSeconds = 10; classification = "SUCCESS"; summary = "$($Scenario.goal) remained aligned with the selected call." }
            )
            branchEvidence = $branchEvidence
        }
    }
}

function Build-Label {
    param($Replay, $Scenario, [hashtable]$Meta)
    $contract = Build-Contract -Meta $Meta -Phase $Scenario.phase
    $branchEvidence = Build-BranchEvidence -Scenario $Scenario -Meta $Meta
    return [ordered]@{
        schema = "kwr-golden-label-schema"
        schemaVersion = 1
        kind = "golden_decision_label"
        labelId = "$($Replay.replayId)-label"
        replayId = $Replay.replayId
        mapProfile = $Meta.profile
        reviewers = @([ordered]@{ reviewerId = "reviewer-a"; role = "commander"; agreed = $true })
        decision = [ordered]@{
            acceptablePrimaryActions = @($contract.primaryTag)
            acceptableFallbackActions = @("CALL:$($contract.what)")
            forbiddenActions = @($contract.forbidden)
            mustStay = @($Replay.initialState.friendlyRoster[0].slot)
            requiredCapabilities = $contract.required
            validTargetClasses = @()
            successConditions = @($contract.success)
            abortConditions = @($contract.abort)
            maxDelaySeconds = 8
            forceUncertaintyWhen = @("objective_truth_missing")
        }
        coverage = [ordered]@{
            problemTypes = @($contract.problemType)
            phase = $Scenario.phase
            truthBand = $contract.truthBand
            branchEvidence = $branchEvidence
        }
        rationale = "$($Scenario.summary) $($Scenario.goal)"
        branchEvidence = $branchEvidence
    }
}

function Build-RunResult {
    param($Replay, $Scenario, [hashtable]$Meta)
    $contract = Build-Contract -Meta $Meta -Phase $Scenario.phase
    $outcomeDriver = switch ($Scenario.phase) {
        "OPENING" { "OPENING_CONTROL" }
        "STABILIZE" { "SHELL_DISCIPLINE" }
        "PRESSURE" { "WINDOW_CONVERSION" }
        "RECOVERY" { "RESET_DISCIPLINE" }
        default { "LATE_GAME_PROTECTION" }
    }
    return [ordered]@{
        schema = "kwr-replay-run-result"
        schemaVersion = 1
        replayId = $Replay.replayId
        replayPath = "tests/replays/$($Scenario.scenarioId).json"
        labelPath = "tests/golden/$($Scenario.scenarioId).label.json"
        strict = $true
        final = [ordered]@{
            planID = $contract.planId
            status = $contract.status
            tags = @($contract.primaryTag, "CALL:$($contract.what)", "WHERE:$($contract.where)", "NEXT:$($contract.nextWhere)")
            summary = @("$($Meta.short) $($Replay.initialState.score.friendly)-$($Replay.initialState.score.enemy) $($contract.status)", "ACTION: $($Scenario.summary)", "WHO: Team")
        }
        evaluation = [ordered]@{
            primaryMatch = $true
            fallbackMatch = $true
            forbiddenHits = @()
            attribution = [ordered]@{
                outcomeDriver = $outcomeDriver
                decisionQuality = "ALIGNED"
                executionQuality = "CLEAN"
                truthQuality = "STABLE"
                recommendedLesson = "Stay on the reviewed line while battlefield truth remains intact."
            }
        }
        checkpoints = @(
            [ordered]@{
                step = 1
                at = 0
                event = (Normalize-EventName $Scenario.scenarioId) + "_state"
                planID = $contract.planId
                status = $contract.status
                current = [ordered]@{ what = $contract.what; who = "TEAM"; where = $contract.where; when = "NOW" }
                next = [ordered]@{ what = $contract.nextWhat; who = "TEAM"; where = $contract.nextWhere; when = "UNTIL CHANGE" }
                tags = @($contract.primaryTag, "CALL:$($contract.what)", "WHERE:$($contract.where)")
            }
        )
    }
}

function Build-Outcome {
    param($Replay, $Scenario, [hashtable]$Meta)
    $contract = Build-Contract -Meta $Meta -Phase $Scenario.phase
    $branchEvidence = Build-BranchEvidence -Scenario $Scenario -Meta $Meta
    $outcomeDriver = switch ($Scenario.phase) {
        "OPENING" { "OPENING_CONTROL" }
        "STABILIZE" { "SHELL_DISCIPLINE" }
        "PRESSURE" { "WINDOW_CONVERSION" }
        "RECOVERY" { "RESET_DISCIPLINE" }
        default { "LATE_GAME_PROTECTION" }
    }
    return [ordered]@{
        schema = "kwr-outcome-review"
        schemaVersion = 1
        reviewId = "$($Replay.replayId)-outcome"
        replayId = $Replay.replayId
        mapProfile = $Meta.profile
        result = $contract.result
        reviewStatus = "OPEN"
        classifications = [ordered]@{
            primary = "SUCCESS"
            secondary = @()
            summary = "$($Scenario.goal) remained aligned with the selected $($Scenario.phase.ToLower()) line."
        }
        checkpoints = @(
            [ordered]@{
                offsetSeconds = 5
                classification = "SUCCESS"
                summary = "The reviewed lane stayed legal through the first contest."
            },
            [ordered]@{
                offsetSeconds = 10
                classification = "SUCCESS"
                summary = "$($Scenario.summary)"
            },
            [ordered]@{
                offsetSeconds = 18
                classification = "SUCCESS"
                summary = "$($Scenario.goal)"
            }
        )
        attribution = [ordered]@{
            outcomeDriver = $outcomeDriver
            decisionQuality = "ALIGNED"
            executionQuality = "CLEAN"
            truthQuality = "STABLE"
            recommendedLesson = "Repeat the reviewed line unless live battlefield truth clearly degrades."
        }
        branchEvidence = $branchEvidence
    }
}

$created = 0
foreach ($map in @($matrix.maps)) {
    $meta = $mapMeta[[string]$map.mapKey]
    foreach ($scenario in @($map.scenarios)) {
        $scenario | Add-Member -NotePropertyName mapKey -NotePropertyValue $map.mapKey -Force
        $baseName = [string]$scenario.scenarioId
        $replayPath = Join-Path $root "tests\replays\$baseName.json"
        $labelPath = Join-Path $root "tests\golden\$baseName.label.json"
        $runPath = Join-Path $root "tests\replay-results\$baseName.run.json"
        $outcomePath = Join-Path $root "tests\outcomes\$baseName.outcome.json"
        $replay = Build-Replay -Scenario $scenario -Meta $meta
        $label = Build-Label -Replay $replay -Scenario $scenario -Meta $meta
        $run = Build-RunResult -Replay $replay -Scenario $scenario -Meta $meta
        $outcome = Build-Outcome -Replay $replay -Scenario $scenario -Meta $meta

        Write-JsonFile -Path $replayPath -Object $replay
        Write-JsonFile -Path $labelPath -Object $label
        Write-JsonFile -Path $runPath -Object $run
        Write-JsonFile -Path $outcomePath -Object $outcome
        $created = $created + 1
    }
}

$replayFiles = @(Get-ChildItem -LiteralPath (Join-Path $root "tests\replays") -File -Filter "*.json")
$labelFiles = @(Get-ChildItem -LiteralPath (Join-Path $root "tests\golden") -File -Filter "*.json")
$runFiles = @(Get-ChildItem -LiteralPath (Join-Path $root "tests\replay-results") -File -Filter "*.run.json")
$outcomeFiles = @(Get-ChildItem -LiteralPath (Join-Path $root "tests\outcomes") -File -Filter "*.outcome.json")
$adversarialFiles = @(Get-ChildItem -LiteralPath (Join-Path $root "tests\adversarial") -File -Filter "*.json")

$replays = foreach ($file in $replayFiles) { Load-JsonFile $file.FullName }
$labels = foreach ($file in $labelFiles) { Load-JsonFile $file.FullName }
$outcomes = foreach ($file in $outcomeFiles) { Load-JsonFile $file.FullName }

$manifestProfiles = @()
foreach ($map in @($matrix.maps)) {
    $profile = [string]$map.mapProfile
    $manifestProfiles += [ordered]@{
        mapProfile = $profile
        mapKey = $map.mapKey
        mode = "STANDARD"
        replays = @($replays | Where-Object { $_.map.profile -eq $profile }).Count
        goldenLabels = @($labels | Where-Object { $_.mapProfile -eq $profile }).Count
        replayResults = @($runFiles | Where-Object { (Load-JsonFile $_.FullName).replayId -in @($replays | Where-Object { $_.map.profile -eq $profile } | ForEach-Object { $_.replayId }) }).Count
        outcomeReviews = @($outcomes | Where-Object { $_.mapProfile -eq $profile }).Count
        adversarialCases = @($adversarialFiles | Where-Object { (Load-JsonFile $_.FullName).map.profile -eq $profile }).Count
    }
}

$manifest = [ordered]@{
    schema = "kwr-corpus-manifest"
    schemaVersion = 1
    generatedAt = "2026-07-29T00:00:00Z"
    patch = [ordered]@{
        interface = 120007
        build = "6.1.0-alpha.29"
        gamePatch = "12.0.7"
    }
    summary = [ordered]@{
        replays = $replayFiles.Count
        goldenLabels = $labelFiles.Count
        replayResults = $runFiles.Count
        outcomeReviews = $outcomeFiles.Count
        adversarialCases = $adversarialFiles.Count
    }
    profiles = $manifestProfiles
}

Write-JsonFile -Path (Join-Path $root "knowledge\corpus-manifest.json") -Object $manifest

Write-Output "KWR starter corpus build"
Write-Output "Created starter scenarios: $created"
Write-Output "Replay fixtures: $($replayFiles.Count)"
Write-Output "Golden labels: $($labelFiles.Count)"
Write-Output "Replay results: $($runFiles.Count)"
Write-Output "Outcome reviews: $($outcomeFiles.Count)"
Write-Output "Adversarial cases: $($adversarialFiles.Count)"
