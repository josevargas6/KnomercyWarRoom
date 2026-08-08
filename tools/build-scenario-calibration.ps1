[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$matrixPath = Join-Path $root "knowledge\rbg-scenario-matrix.json"
$outcomesPath = Join-Path $root "tests\outcomes"
$labelsPath = Join-Path $root "tests\golden"
$jsonOutPath = Join-Path $root "knowledge\scenario-calibration.json"
$luaOutPath = Join-Path $root "Data\ScenarioCalibration.lua"

function Get-DisciplineRule {
    param(
        [string]$TopFailure
    )

    switch ($TopFailure) {
        "DECISION_ERROR" { return "Do not chase side value; protect the real score path first." }
        "EXECUTION_ERROR" { return "Do not trickle or split the hit; arrive on one timing." }
        "SENSOR_ERROR" { return "Re-verify objective truth before a long move or hard commit." }
        "OPPONENT_COUNTER" { return "Expect the counter route and keep the response reserve intact." }
        "MECHANICAL_LOSS" { return "Choose the cleaner line and avoid low-margin overreach." }
        "UNRESOLVED" { return "Keep the call reversible until clearer battlefield truth arrives." }
        default { return "Stay on the reviewed line unless live battlefield truth clearly breaks it." }
    }
}

function To-LuaLiteral {
    param(
        [Parameter(Mandatory = $true)]
        $Value,
        [int]$Indent = 0
    )

    $pad = " " * $Indent
    $nextPad = " " * ($Indent + 4)

    if ($null -eq $Value) {
        return "nil"
    }

    if ($Value -is [string]) {
        $escaped = $Value.Replace("\", "\\").Replace('"', '\"').Replace("`r", "\r").Replace("`n", "\n")
        return '"' + $escaped + '"'
    }

    if ($Value -is [bool]) {
        return ($Value.ToString().ToLowerInvariant())
    }

    if ($Value -is [int] -or $Value -is [long] -or $Value -is [double] -or $Value -is [decimal]) {
        return [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0}", $Value)
    }

    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string]) -and -not ($Value -is [System.Collections.IDictionary]) -and -not ($Value -is [psobject])) {
        $items = @($Value)
        if ($items.Count -eq 0) {
            return "{}"
        }
        $lines = @("{")
        foreach ($item in $items) {
            $lines += "$nextPad$(To-LuaLiteral -Value $item -Indent ($Indent + 4)),"
        }
        $lines += "$pad}"
        return ($lines -join "`n")
    }

    $properties = @()
    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($key in $Value.Keys) {
            $properties += [pscustomobject]@{ Name = [string]$key; Value = $Value[$key] }
        }
    } else {
        foreach ($property in $Value.PSObject.Properties) {
            $properties += [pscustomobject]@{ Name = [string]$property.Name; Value = $property.Value }
        }
    }

    if ($properties.Count -eq 0) {
        return "{}"
    }

    $lines = @("{")
    foreach ($property in ($properties | Sort-Object Name)) {
        $safeKey = if ($property.Name -match '^[A-Za-z_][A-Za-z0-9_]*$') {
            $property.Name
        } else {
            '["' + $property.Name.Replace("\", "\\").Replace('"', '\"') + '"]'
        }
        $lines += "$nextPad$safeKey = $(To-LuaLiteral -Value $property.Value -Indent ($Indent + 4)),"
    }
    $lines += "$pad}"
    return ($lines -join "`n")
}

function Add-CountValue {
    param(
        [Parameter(Mandatory = $true)]$Table,
        [Parameter(Mandatory = $true)][string]$Key
    )
    if (-not $Table.Contains($Key)) {
        $Table[$Key] = 0
    }
    $Table[$Key] += 1
}

function Get-PropertyPairs {
    param([Parameter(Mandatory = $true)]$Value)
    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($key in $Value.Keys) {
            [pscustomobject]@{ Name = [string]$key; Value = $Value[$key] }
        }
        return
    }
    foreach ($property in $Value.PSObject.Properties) {
        [pscustomobject]@{ Name = [string]$property.Name; Value = $property.Value }
    }
}

function Get-OutcomeAttributionAggregate {
    param(
        [Parameter(Mandatory = $true)][string]$ScenarioId,
        [Parameter(Mandatory = $true)][string]$OutcomesPath
    )
    $drivers = [ordered]@{}
    $lessons = New-Object System.Collections.Generic.List[string]
    $files = @(Get-ChildItem -LiteralPath $OutcomesPath -Filter "$ScenarioId*.outcome.json" | Sort-Object Name)
    foreach ($file in $files) {
        $row = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
        $attribution = $row.attribution
        if (-not $attribution) { continue }
        $driver = [string]$attribution.outcomeDriver
        if (-not [string]::IsNullOrWhiteSpace($driver)) {
            Add-CountValue -Table $drivers -Key $driver
        }
        $lesson = [string]$attribution.recommendedLesson
        if (-not [string]::IsNullOrWhiteSpace($lesson) -and -not $lessons.Contains($lesson)) {
            [void]$lessons.Add($lesson)
        }
    }
    return [ordered]@{
        drivers = $drivers
        lessons = @($lessons)
    }
}

$matrix = Get-Content -LiteralPath $matrixPath -Raw | ConvertFrom-Json
$guidance = [ordered]@{
    DECISION_ERROR = "Do not chase side value; protect the real score path first."
    EXECUTION_ERROR = "Do not trickle or split the hit; arrive on one timing."
    SENSOR_ERROR = "Re-verify objective truth before a long move or hard commit."
    OPPONENT_COUNTER = "Expect the counter route and keep the response reserve intact."
    MECHANICAL_LOSS = "Choose the cleaner line and avoid low-margin overreach."
    UNRESOLVED = "Keep the call reversible until clearer battlefield truth arrives."
    SUCCESS = "Stay on the reviewed line unless live battlefield truth clearly breaks it."
}

$scenarios = New-Object System.Collections.Generic.List[object]
foreach ($map in @($matrix.maps)) {
    foreach ($scenario in @($map.scenarios)) {
        $files = @(Get-ChildItem -LiteralPath $outcomesPath -Filter "$($scenario.scenarioId)*.outcome.json" | Sort-Object Name)
        $labelFiles = @(Get-ChildItem -LiteralPath $labelsPath -Filter "$($scenario.scenarioId)*.label.json" | Sort-Object Name)
        $wins = 0
        $losses = 0
        $classifications = [ordered]@{}
        $familyCounts = [ordered]@{}
        $variantShapes = [ordered]@{}
        $counterSummaries = New-Object System.Collections.Generic.List[string]
        $comparisonIds = [ordered]@{}
        $responseIds = [ordered]@{}
        $outcomeDrivers = [ordered]@{}
        $lessonPatterns = New-Object System.Collections.Generic.List[string]
        $legalSignals = New-Object System.Collections.Generic.List[string]
        $invalidationSignals = New-Object System.Collections.Generic.List[string]
        $enemyCounters = New-Object System.Collections.Generic.List[string]
        foreach ($key in $guidance.Keys) {
            $classifications[$key] = 0
        }

        foreach ($file in $files) {
            $row = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
            if ($row.result -eq "VICTORY") {
                $wins += 1
            } elseif ($row.result -eq "DEFEAT") {
                $losses += 1
            }
            $primary = [string]$row.classifications.primary
            if (-not $classifications.Contains($primary)) {
                $classifications[$primary] = 0
            }
            $classifications[$primary] += 1
            $branchEvidence = $row.branchEvidence
            foreach ($tag in @($branchEvidence.familyTags)) {
                if (-not [string]::IsNullOrWhiteSpace([string]$tag)) {
                    Add-CountValue -Table $familyCounts -Key ([string]$tag)
                }
            }
            $variantShape = [string]$branchEvidence.variantShape
            if (-not [string]::IsNullOrWhiteSpace($variantShape)) {
                Add-CountValue -Table $variantShapes -Key $variantShape
            }
            $safeCounter = [string]$branchEvidence.safestCounter
            if (-not [string]::IsNullOrWhiteSpace($safeCounter) -and -not $counterSummaries.Contains($safeCounter)) {
                [void]$counterSummaries.Add($safeCounter)
            }
            foreach ($value in @($branchEvidence.doctrineComparisonIds)) {
                if (-not [string]::IsNullOrWhiteSpace([string]$value)) {
                    Add-CountValue -Table $comparisonIds -Key ([string]$value)
                }
            }
            foreach ($value in @($branchEvidence.doctrineResponseIds)) {
                if (-not [string]::IsNullOrWhiteSpace([string]$value)) {
                    Add-CountValue -Table $responseIds -Key ([string]$value)
                }
            }
            foreach ($value in @($branchEvidence.legalWhen)) {
                if (-not [string]::IsNullOrWhiteSpace([string]$value) -and -not $legalSignals.Contains([string]$value)) {
                    [void]$legalSignals.Add([string]$value)
                }
            }
            foreach ($value in @($branchEvidence.invalidatedBy)) {
                if (-not [string]::IsNullOrWhiteSpace([string]$value) -and -not $invalidationSignals.Contains([string]$value)) {
                    [void]$invalidationSignals.Add([string]$value)
                }
            }
            $enemyCounter = [string]$branchEvidence.expectedEnemyCounter
            if (-not [string]::IsNullOrWhiteSpace($enemyCounter) -and -not $enemyCounters.Contains($enemyCounter)) {
                [void]$enemyCounters.Add($enemyCounter)
            }
            $attribution = $row.attribution
            if ($attribution) {
                $driver = [string]$attribution.outcomeDriver
                if (-not [string]::IsNullOrWhiteSpace($driver)) {
                    Add-CountValue -Table $outcomeDrivers -Key $driver
                }
                $lesson = [string]$attribution.recommendedLesson
                if (-not [string]::IsNullOrWhiteSpace($lesson) -and -not $lessonPatterns.Contains($lesson)) {
                    [void]$lessonPatterns.Add($lesson)
                }
            }
        }

        foreach ($file in $labelFiles) {
            $row = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
            $branchEvidence = $row.branchEvidence
            foreach ($tag in @($branchEvidence.familyTags)) {
                if (-not [string]::IsNullOrWhiteSpace([string]$tag)) {
                    Add-CountValue -Table $familyCounts -Key ([string]$tag)
                }
            }
            $variantShape = [string]$branchEvidence.variantShape
            if (-not [string]::IsNullOrWhiteSpace($variantShape)) {
                Add-CountValue -Table $variantShapes -Key $variantShape
            }
            $safeCounter = [string]$branchEvidence.safestCounter
            if (-not [string]::IsNullOrWhiteSpace($safeCounter) -and -not $counterSummaries.Contains($safeCounter)) {
                [void]$counterSummaries.Add($safeCounter)
            }
            foreach ($value in @($branchEvidence.doctrineComparisonIds)) {
                if (-not [string]::IsNullOrWhiteSpace([string]$value)) {
                    Add-CountValue -Table $comparisonIds -Key ([string]$value)
                }
            }
            foreach ($value in @($branchEvidence.doctrineResponseIds)) {
                if (-not [string]::IsNullOrWhiteSpace([string]$value)) {
                    Add-CountValue -Table $responseIds -Key ([string]$value)
                }
            }
            foreach ($value in @($branchEvidence.legalWhen)) {
                if (-not [string]::IsNullOrWhiteSpace([string]$value) -and -not $legalSignals.Contains([string]$value)) {
                    [void]$legalSignals.Add([string]$value)
                }
            }
            foreach ($value in @($branchEvidence.invalidatedBy)) {
                if (-not [string]::IsNullOrWhiteSpace([string]$value) -and -not $invalidationSignals.Contains([string]$value)) {
                    [void]$invalidationSignals.Add([string]$value)
                }
            }
            $enemyCounter = [string]$branchEvidence.expectedEnemyCounter
            if (-not [string]::IsNullOrWhiteSpace($enemyCounter) -and -not $enemyCounters.Contains($enemyCounter)) {
                [void]$enemyCounters.Add($enemyCounter)
            }
        }

        $reviewedCases = $wins + $losses
        $winRate = if ($reviewedCases -gt 0) {
            [int][Math]::Round(($wins / [double]$reviewedCases) * 100.0, 0)
        } else { 0 }
        $topFailure = "NONE"
        $topFailureCount = -1
        foreach ($pair in $classifications.GetEnumerator()) {
            if ($pair.Key -eq "SUCCESS") { continue }
            if ($pair.Value -gt $topFailureCount) {
                $topFailure = [string]$pair.Key
                $topFailureCount = [int]$pair.Value
            }
        }
        if ($topFailureCount -le 0) {
            $topFailure = "SUCCESS"
        }

        $reviewConfidence = if ($reviewedCases -ge 5) {
            "HIGH"
        } elseif ($reviewedCases -ge 3) {
            "MEDIUM"
        } elseif ($reviewedCases -ge 1) {
            "LOW"
        } else {
            "NONE"
        }

        $scenarios.Add([ordered]@{
            scenarioId = [string]$scenario.scenarioId
            mapKey = [string]$map.mapKey
            mapProfile = [string]$map.mapProfile
            phase = [string]$scenario.phase
            summary = [string]$scenario.summary
            goal = [string]$scenario.goal
            reviewedCases = $reviewedCases
            wins = $wins
            losses = $losses
            winRate = $winRate
            primaryClassifications = $classifications
            topFailure = $topFailure
            disciplineRule = (Get-DisciplineRule -TopFailure $topFailure)
            reviewConfidence = $reviewConfidence
            branchFamilies = $familyCounts
            reviewedVariantShapes = $variantShapes
            doctrineComparisons = $comparisonIds
            doctrineResponses = $responseIds
            outcomeDrivers = $outcomeDrivers
            lessonPatterns = @($lessonPatterns)
            legalSignals = @($legalSignals)
            invalidationSignals = @($invalidationSignals)
            expectedEnemyCounters = @($enemyCounters)
            safeCounterPatterns = @($counterSummaries)
        })
    }
}

foreach ($scenario in $scenarios) {
    $aggregate = Get-OutcomeAttributionAggregate -ScenarioId ([string]$scenario.scenarioId) -OutcomesPath $outcomesPath
    $scenario.outcomeDrivers = $aggregate.drivers
    $scenario.lessonPatterns = @($aggregate.lessons)
}

$mapSummaries = [ordered]@{}
foreach ($scenario in $scenarios) {
    $mapKey = [string]$scenario.mapKey
    $phase = [string]$scenario.phase
    if (-not $mapSummaries.Contains($mapKey)) {
        $mapSummaries[$mapKey] = [ordered]@{
            mapKey = $mapKey
            mapProfile = [string]$scenario.mapProfile
            scenarios = 0
            reviewedCases = 0
            wins = 0
            losses = 0
            topFailures = [ordered]@{}
            branchFamilies = [ordered]@{}
            doctrineComparisons = [ordered]@{}
            doctrineResponses = [ordered]@{}
            outcomeDrivers = [ordered]@{}
            lessonPatterns = New-Object System.Collections.Generic.List[string]
            legalSignals = New-Object System.Collections.Generic.List[string]
            invalidationSignals = New-Object System.Collections.Generic.List[string]
            expectedEnemyCounters = New-Object System.Collections.Generic.List[string]
            safeCounterPatterns = New-Object System.Collections.Generic.List[string]
            phaseSummaries = [ordered]@{}
        }
    }
    $mapSummary = $mapSummaries[$mapKey]
    $mapSummary.scenarios += 1
    $mapSummary.reviewedCases += [int]$scenario.reviewedCases
    $mapSummary.wins += [int]$scenario.wins
    $mapSummary.losses += [int]$scenario.losses
    Add-CountValue -Table $mapSummary.topFailures -Key ([string]$scenario.topFailure)
    foreach ($pair in @(Get-PropertyPairs -Value $scenario.branchFamilies)) {
        $value = 0
        if ([int]::TryParse([string]$pair.Value, [ref]$value)) {
            if (-not $mapSummary.branchFamilies.Contains($pair.Name)) {
                $mapSummary.branchFamilies[$pair.Name] = 0
            }
            $mapSummary.branchFamilies[$pair.Name] += $value
        }
    }
    foreach ($pair in @(Get-PropertyPairs -Value $scenario.doctrineComparisons)) {
        $value = 0
        if ([int]::TryParse([string]$pair.Value, [ref]$value)) {
            if (-not $mapSummary.doctrineComparisons.Contains($pair.Name)) {
                $mapSummary.doctrineComparisons[$pair.Name] = 0
            }
            $mapSummary.doctrineComparisons[$pair.Name] += $value
        }
    }
    foreach ($pair in @(Get-PropertyPairs -Value $scenario.doctrineResponses)) {
        $value = 0
        if ([int]::TryParse([string]$pair.Value, [ref]$value)) {
            if (-not $mapSummary.doctrineResponses.Contains($pair.Name)) {
                $mapSummary.doctrineResponses[$pair.Name] = 0
            }
            $mapSummary.doctrineResponses[$pair.Name] += $value
        }
    }
    foreach ($value in @($scenario.safeCounterPatterns)) {
        if ($value -and -not $mapSummary.safeCounterPatterns.Contains([string]$value)) {
            [void]$mapSummary.safeCounterPatterns.Add([string]$value)
        }
    }
    foreach ($pair in @(Get-PropertyPairs -Value $scenario.outcomeDrivers)) {
        $value = 0
        if ([int]::TryParse([string]$pair.Value, [ref]$value)) {
            if (-not $mapSummary.outcomeDrivers.Contains($pair.Name)) {
                $mapSummary.outcomeDrivers[$pair.Name] = 0
            }
            $mapSummary.outcomeDrivers[$pair.Name] += $value
        }
    }
    foreach ($value in @($scenario.lessonPatterns)) {
        if ($value -and -not $mapSummary.lessonPatterns.Contains([string]$value)) {
            [void]$mapSummary.lessonPatterns.Add([string]$value)
        }
    }
    foreach ($value in @($scenario.legalSignals)) {
        if ($value -and -not $mapSummary.legalSignals.Contains([string]$value)) {
            [void]$mapSummary.legalSignals.Add([string]$value)
        }
    }
    foreach ($value in @($scenario.invalidationSignals)) {
        if ($value -and -not $mapSummary.invalidationSignals.Contains([string]$value)) {
            [void]$mapSummary.invalidationSignals.Add([string]$value)
        }
    }
    foreach ($value in @($scenario.expectedEnemyCounters)) {
        if ($value -and -not $mapSummary.expectedEnemyCounters.Contains([string]$value)) {
            [void]$mapSummary.expectedEnemyCounters.Add([string]$value)
        }
    }

    if (-not $mapSummary.phaseSummaries.Contains($phase)) {
        $mapSummary.phaseSummaries[$phase] = [ordered]@{
            phase = $phase
            scenarios = 0
            reviewedCases = 0
            wins = 0
            losses = 0
            topFailures = [ordered]@{}
            branchFamilies = [ordered]@{}
            doctrineComparisons = [ordered]@{}
            doctrineResponses = [ordered]@{}
            outcomeDrivers = [ordered]@{}
            lessonPatterns = New-Object System.Collections.Generic.List[string]
            legalSignals = New-Object System.Collections.Generic.List[string]
            invalidationSignals = New-Object System.Collections.Generic.List[string]
            expectedEnemyCounters = New-Object System.Collections.Generic.List[string]
            safeCounterPatterns = New-Object System.Collections.Generic.List[string]
        }
    }
    $phaseSummary = $mapSummary.phaseSummaries[$phase]
    $phaseSummary.scenarios += 1
    $phaseSummary.reviewedCases += [int]$scenario.reviewedCases
    $phaseSummary.wins += [int]$scenario.wins
    $phaseSummary.losses += [int]$scenario.losses
    Add-CountValue -Table $phaseSummary.topFailures -Key ([string]$scenario.topFailure)
    foreach ($pair in @(Get-PropertyPairs -Value $scenario.branchFamilies)) {
        $value = 0
        if ([int]::TryParse([string]$pair.Value, [ref]$value)) {
            if (-not $phaseSummary.branchFamilies.Contains($pair.Name)) {
                $phaseSummary.branchFamilies[$pair.Name] = 0
            }
            $phaseSummary.branchFamilies[$pair.Name] += $value
        }
    }
    foreach ($pair in @(Get-PropertyPairs -Value $scenario.doctrineComparisons)) {
        $value = 0
        if ([int]::TryParse([string]$pair.Value, [ref]$value)) {
            if (-not $phaseSummary.doctrineComparisons.Contains($pair.Name)) {
                $phaseSummary.doctrineComparisons[$pair.Name] = 0
            }
            $phaseSummary.doctrineComparisons[$pair.Name] += $value
        }
    }
    foreach ($pair in @(Get-PropertyPairs -Value $scenario.doctrineResponses)) {
        $value = 0
        if ([int]::TryParse([string]$pair.Value, [ref]$value)) {
            if (-not $phaseSummary.doctrineResponses.Contains($pair.Name)) {
                $phaseSummary.doctrineResponses[$pair.Name] = 0
            }
            $phaseSummary.doctrineResponses[$pair.Name] += $value
        }
    }
    foreach ($value in @($scenario.safeCounterPatterns)) {
        if ($value -and -not $phaseSummary.safeCounterPatterns.Contains([string]$value)) {
            [void]$phaseSummary.safeCounterPatterns.Add([string]$value)
        }
    }
    foreach ($pair in @(Get-PropertyPairs -Value $scenario.outcomeDrivers)) {
        $value = 0
        if ([int]::TryParse([string]$pair.Value, [ref]$value)) {
            if (-not $phaseSummary.outcomeDrivers.Contains($pair.Name)) {
                $phaseSummary.outcomeDrivers[$pair.Name] = 0
            }
            $phaseSummary.outcomeDrivers[$pair.Name] += $value
        }
    }
    foreach ($value in @($scenario.lessonPatterns)) {
        if ($value -and -not $phaseSummary.lessonPatterns.Contains([string]$value)) {
            [void]$phaseSummary.lessonPatterns.Add([string]$value)
        }
    }
    foreach ($value in @($scenario.legalSignals)) {
        if ($value -and -not $phaseSummary.legalSignals.Contains([string]$value)) {
            [void]$phaseSummary.legalSignals.Add([string]$value)
        }
    }
    foreach ($value in @($scenario.invalidationSignals)) {
        if ($value -and -not $phaseSummary.invalidationSignals.Contains([string]$value)) {
            [void]$phaseSummary.invalidationSignals.Add([string]$value)
        }
    }
    foreach ($value in @($scenario.expectedEnemyCounters)) {
        if ($value -and -not $phaseSummary.expectedEnemyCounters.Contains([string]$value)) {
            [void]$phaseSummary.expectedEnemyCounters.Add([string]$value)
        }
    }
}

$artifact = [ordered]@{
    schema = "kwr-scenario-calibration"
    schemaVersion = 1
    generatedAt = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
    shared = [ordered]@{
        minimumReviewedCases = 5
        classificationGuidance = $guidance
    }
    maps = @($mapSummaries.Values)
    scenarios = $scenarios
}

$json = $artifact | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText($jsonOutPath, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))

$scenarioMap = [ordered]@{}
foreach ($scenario in $scenarios) {
    $scenarioMap[[string]$scenario.scenarioId] = $scenario
}
$luaData = [ordered]@{
    shared = $artifact.shared
    maps = $mapSummaries
    scenarios = $scenarioMap
}

$lua = @(
'local _, KWR = ...'
''
'local ScenarioCalibration = {}'
'KWR.ScenarioCalibration = ScenarioCalibration'
''
'local phaseIndex = nil'
''
('local DATA = ' + (To-LuaLiteral -Value $luaData))
''
'function ScenarioCalibration:Count()'
'    local count = 0'
'    for _ in pairs(DATA.scenarios or {}) do count = count + 1 end'
'    return count'
'end'
''
'function ScenarioCalibration:Get(scenarioID)'
'    local row = DATA.scenarios and DATA.scenarios[scenarioID]'
'    return row and KWR.Util:Copy(row) or nil'
'end'
''
'function ScenarioCalibration:GetMapSummary(mapKey)'
'    mapKey = KWR.Util:Upper(mapKey, nil, 24)'
'    local row = mapKey and DATA.maps and DATA.maps[mapKey] or nil'
'    return row and KWR.Util:Copy(row) or nil'
'end'
''
'function ScenarioCalibration:GetMapPhaseSummary(mapKey, phase)'
'    mapKey = KWR.Util:Upper(mapKey, nil, 24)'
'    phase = KWR.Util:Upper(phase, nil, 24)'
'    local row = mapKey and phase and DATA.maps and DATA.maps[mapKey]'
'    row = row and row.phaseSummaries and row.phaseSummaries[phase] or nil'
'    return row and KWR.Util:Copy(row) or nil'
'end'
''
'function ScenarioCalibration:GetByMapAndPhase(mapKey, phase)'
'    mapKey = KWR.Util:Upper(mapKey, nil, 24)'
'    phase = KWR.Util:Upper(phase, nil, 24)'
'    if not mapKey or not phase then'
'        return nil'
'    end'
'    if not phaseIndex then'
'        phaseIndex = {}'
'        for _, row in pairs(DATA.scenarios or {}) do'
'            if row.mapKey and row.phase then'
'                phaseIndex[row.mapKey] = phaseIndex[row.mapKey] or {}'
'                phaseIndex[row.mapKey][row.phase] = row'
'            end'
'        end'
'    end'
'    local row = phaseIndex[mapKey] and phaseIndex[mapKey][phase] or nil'
'    return row and KWR.Util:Copy(row) or nil'
'end'
''
'function ScenarioCalibration:Shared()'
'    return KWR.Util:Copy(DATA.shared or {})'
'end'
''
'KWR:RegisterModule("ScenarioCalibration", ScenarioCalibration)'
) -join "`n"
[IO.File]::WriteAllText($luaOutPath, $lua + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))

Write-Output "KWR scenario calibration build"
Write-Output "Scenario rows: $($scenarios.Count)"
Write-Output "JSON: $jsonOutPath"
Write-Output "Lua: $luaOutPath"
