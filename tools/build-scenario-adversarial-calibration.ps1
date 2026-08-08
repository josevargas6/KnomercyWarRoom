[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$matrixPath = Join-Path $root "knowledge\rbg-scenario-matrix.json"
$adversarialPath = Join-Path $root "tests\adversarial"
$jsonOutPath = Join-Path $root "knowledge\scenario-adversarial-calibration.json"
$luaOutPath = Join-Path $root "Data\ScenarioAdversarialCalibration.lua"

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

function Get-DisciplineRule {
    param(
        [string]$SafePrimaryAction,
        [string]$ForbiddenCommit
    )

    if ($ForbiddenCommit -eq "CALL:FULL_COMMIT") {
        return "Do not full send from degraded truth; protect the score floor first."
    }
    if ($SafePrimaryAction -eq "PLAN:CHECK") {
        return "Re-check battlefield truth and keep the move reversible before expanding."
    }
    return "Keep the safest reviewed line until live truth reopens the commit."
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

function Is-UsefulEscalation {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
    if ($Value -eq "uncertainty discipline") { return $false }
    return $true
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

function Get-TruthDisciplineAggregate {
    param(
        [Parameter(Mandatory = $true)][string]$ScenarioId,
        [Parameter(Mandatory = $true)][string]$AdversarialPath
    )
    $lessons = New-Object System.Collections.Generic.List[string]
    $files = @(Get-ChildItem -LiteralPath $AdversarialPath -Filter "$ScenarioId-adversarial-*.json" | Sort-Object Name)
    foreach ($file in $files) {
        $row = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
        $attribution = $row.outcome.attribution
        if (-not $attribution) { continue }
        $lesson = [string]$attribution.recommendedLesson
        if (-not [string]::IsNullOrWhiteSpace($lesson) -and -not $lessons.Contains($lesson)) {
            [void]$lessons.Add($lesson)
        }
    }
    return @($lessons)
}

$matrix = Get-Content -LiteralPath $matrixPath -Raw | ConvertFrom-Json
$principles = [ordered]@{
    safePrimary = "Prefer the smallest legal action that preserves the score path."
    safeFallback = "Fallback to HOLD or CHECK before expanding from partial truth."
    forbiddenCommit = "Do not full-commit from contradictory or incomplete public facts."
    anchorCoverage = "Keep required defenders or carrier support planted until truth improves."
}

$scenarios = New-Object System.Collections.Generic.List[object]
foreach ($map in @($matrix.maps)) {
    foreach ($scenario in @($map.scenarios)) {
        $files = @(Get-ChildItem -LiteralPath $adversarialPath -Filter "$($scenario.scenarioId)-adversarial-*.json" | Sort-Object Name)
        $primaryActions = New-Object System.Collections.Generic.List[string]
        $fallbackActions = New-Object System.Collections.Generic.List[string]
        $forbiddenActions = New-Object System.Collections.Generic.List[string]
        $mustStay = New-Object System.Collections.Generic.List[string]
        $truthRisks = New-Object System.Collections.Generic.List[string]
        $escalations = New-Object System.Collections.Generic.List[string]
        $familyCounts = [ordered]@{}
        $truthStressCounts = [ordered]@{}
        $safeCounterPatterns = New-Object System.Collections.Generic.List[string]
        $comparisonIds = [ordered]@{}
        $responseIds = [ordered]@{}
        $truthDisciplinePatterns = New-Object System.Collections.Generic.List[string]

        foreach ($file in $files) {
            $row = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
            foreach ($value in @($row.expectedLabels.primaryActions)) {
                if ($value -and -not $primaryActions.Contains([string]$value)) { [void]$primaryActions.Add([string]$value) }
            }
            foreach ($value in @($row.expectedLabels.fallbackActions)) {
                if ($value -and -not $fallbackActions.Contains([string]$value)) { [void]$fallbackActions.Add([string]$value) }
            }
            foreach ($value in @($row.expectedLabels.forbiddenActions)) {
                if ($value -and -not $forbiddenActions.Contains([string]$value)) { [void]$forbiddenActions.Add([string]$value) }
            }
            foreach ($value in @($row.expectedLabels.mustStay)) {
                if ($value -and -not $mustStay.Contains([string]$value)) { [void]$mustStay.Add([string]$value) }
            }
            $initialTruth = [string]$row.initialState.evidenceQuality
            if ($initialTruth -and -not $truthRisks.Contains($initialTruth)) { [void]$truthRisks.Add($initialTruth) }
            $branchEvidence = $row.expectedLabels.branchEvidence
            foreach ($tag in @($branchEvidence.familyTags)) {
                if (-not [string]::IsNullOrWhiteSpace([string]$tag)) {
                    Add-CountValue -Table $familyCounts -Key ([string]$tag)
                }
            }
            $truthStress = [string]$branchEvidence.truthStress
            if (-not [string]::IsNullOrWhiteSpace($truthStress)) {
                Add-CountValue -Table $truthStressCounts -Key $truthStress
            }
            $safeCounter = [string]$branchEvidence.safestCounter
            if (-not [string]::IsNullOrWhiteSpace($safeCounter) -and -not $safeCounterPatterns.Contains($safeCounter)) {
                [void]$safeCounterPatterns.Add($safeCounter)
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
            $attribution = $row.outcome.attribution
            if ($attribution) {
                $lesson = [string]$attribution.recommendedLesson
                if (-not [string]::IsNullOrWhiteSpace($lesson) -and -not $truthDisciplinePatterns.Contains($lesson)) {
                    [void]$truthDisciplinePatterns.Add($lesson)
                }
            }
            foreach ($checkpoint in @($row.outcome.checkpoints)) {
                $summary = [string]$checkpoint.summary
                if ($summary -and $summary -match "safe requirement is (.+)$") {
                    $value = $Matches[1].Trim(".")
                    if ((Is-UsefulEscalation -Value $value) -and -not $escalations.Contains($value)) {
                        [void]$escalations.Add($value)
                    }
                }
            }
        }

        $safePrimaryAction = if ($primaryActions.Count -gt 0) { $primaryActions[0] } else { "PLAN:CHECK" }
        $safeFallbackAction = if ($fallbackActions.Count -gt 0) { $fallbackActions[0] } else { "CALL:HOLD" }
        $forbiddenCommit = if ($forbiddenActions.Count -gt 0) { $forbiddenActions[0] } else { "CALL:FULL_COMMIT" }
        $truthRisk = if ($truthRisks.Count -gt 0) { [string]::Join("/", $truthRisks) } else { "LOW" }
        $escalateWhen = if ($escalations.Count -gt 0) {
            "Escalate only when " + $escalations[0] + "."
        } else {
            "Escalate only when battlefield truth becomes explicit and the scoring path stays covered."
        }

        $scenarios.Add([ordered]@{
            scenarioId = [string]$scenario.scenarioId
            mapKey = [string]$map.mapKey
            mapProfile = [string]$map.mapProfile
            phase = [string]$scenario.phase
            adversarialCases = $files.Count
            truthRisk = $truthRisk
            safePrimaryAction = $safePrimaryAction
            safeFallbackAction = $safeFallbackAction
            forbiddenCommit = $forbiddenCommit
            mustStay = @($mustStay)
            disciplineRule = (Get-DisciplineRule -SafePrimaryAction $safePrimaryAction -ForbiddenCommit $forbiddenCommit)
            escalateWhen = $escalateWhen
            branchFamilies = $familyCounts
            truthStress = $truthStressCounts
            doctrineComparisons = $comparisonIds
            doctrineResponses = $responseIds
            truthDisciplinePatterns = @($truthDisciplinePatterns)
            safeCounterPatterns = @($safeCounterPatterns)
        })
    }
}

foreach ($scenario in $scenarios) {
    $scenario.truthDisciplinePatterns = @(Get-TruthDisciplineAggregate -ScenarioId ([string]$scenario.scenarioId) -AdversarialPath $adversarialPath)
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
            adversarialCases = 0
            truthRisk = New-Object System.Collections.Generic.List[string]
            forbiddenCommits = New-Object System.Collections.Generic.List[string]
            branchFamilies = [ordered]@{}
            truthStress = [ordered]@{}
            doctrineComparisons = [ordered]@{}
            doctrineResponses = [ordered]@{}
            truthDisciplinePatterns = New-Object System.Collections.Generic.List[string]
            safeCounterPatterns = New-Object System.Collections.Generic.List[string]
            phaseSummaries = [ordered]@{}
        }
    }
    $mapSummary = $mapSummaries[$mapKey]
    $mapSummary.scenarios += 1
    $mapSummary.adversarialCases += [int]$scenario.adversarialCases
    if ($scenario.truthRisk -and -not $mapSummary.truthRisk.Contains([string]$scenario.truthRisk)) {
        [void]$mapSummary.truthRisk.Add([string]$scenario.truthRisk)
    }
    if ($scenario.forbiddenCommit -and -not $mapSummary.forbiddenCommits.Contains([string]$scenario.forbiddenCommit)) {
        [void]$mapSummary.forbiddenCommits.Add([string]$scenario.forbiddenCommit)
    }
    foreach ($pair in @(Get-PropertyPairs -Value $scenario.branchFamilies)) {
        $value = 0
        if ([int]::TryParse([string]$pair.Value, [ref]$value)) {
            if (-not $mapSummary.branchFamilies.Contains($pair.Name)) {
                $mapSummary.branchFamilies[$pair.Name] = 0
            }
            $mapSummary.branchFamilies[$pair.Name] += $value
        }
    }
    foreach ($pair in @(Get-PropertyPairs -Value $scenario.truthStress)) {
        $value = 0
        if ([int]::TryParse([string]$pair.Value, [ref]$value)) {
            if (-not $mapSummary.truthStress.Contains($pair.Name)) {
                $mapSummary.truthStress[$pair.Name] = 0
            }
            $mapSummary.truthStress[$pair.Name] += $value
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
    foreach ($value in @($scenario.truthDisciplinePatterns)) {
        if ($value -and -not $mapSummary.truthDisciplinePatterns.Contains([string]$value)) {
            [void]$mapSummary.truthDisciplinePatterns.Add([string]$value)
        }
    }

    if (-not $mapSummary.phaseSummaries.Contains($phase)) {
        $mapSummary.phaseSummaries[$phase] = [ordered]@{
            phase = $phase
            scenarios = 0
            adversarialCases = 0
            truthRisk = New-Object System.Collections.Generic.List[string]
            forbiddenCommits = New-Object System.Collections.Generic.List[string]
            branchFamilies = [ordered]@{}
            truthStress = [ordered]@{}
            doctrineComparisons = [ordered]@{}
            doctrineResponses = [ordered]@{}
            truthDisciplinePatterns = New-Object System.Collections.Generic.List[string]
            safeCounterPatterns = New-Object System.Collections.Generic.List[string]
        }
    }
    $phaseSummary = $mapSummary.phaseSummaries[$phase]
    $phaseSummary.scenarios += 1
    $phaseSummary.adversarialCases += [int]$scenario.adversarialCases
    if ($scenario.truthRisk -and -not $phaseSummary.truthRisk.Contains([string]$scenario.truthRisk)) {
        [void]$phaseSummary.truthRisk.Add([string]$scenario.truthRisk)
    }
    if ($scenario.forbiddenCommit -and -not $phaseSummary.forbiddenCommits.Contains([string]$scenario.forbiddenCommit)) {
        [void]$phaseSummary.forbiddenCommits.Add([string]$scenario.forbiddenCommit)
    }
    foreach ($pair in @(Get-PropertyPairs -Value $scenario.branchFamilies)) {
        $value = 0
        if ([int]::TryParse([string]$pair.Value, [ref]$value)) {
            if (-not $phaseSummary.branchFamilies.Contains($pair.Name)) {
                $phaseSummary.branchFamilies[$pair.Name] = 0
            }
            $phaseSummary.branchFamilies[$pair.Name] += $value
        }
    }
    foreach ($pair in @(Get-PropertyPairs -Value $scenario.truthStress)) {
        $value = 0
        if ([int]::TryParse([string]$pair.Value, [ref]$value)) {
            if (-not $phaseSummary.truthStress.Contains($pair.Name)) {
                $phaseSummary.truthStress[$pair.Name] = 0
            }
            $phaseSummary.truthStress[$pair.Name] += $value
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
    foreach ($value in @($scenario.truthDisciplinePatterns)) {
        if ($value -and -not $phaseSummary.truthDisciplinePatterns.Contains([string]$value)) {
            [void]$phaseSummary.truthDisciplinePatterns.Add([string]$value)
        }
    }
}

$artifact = [ordered]@{
    schema = "kwr-scenario-adversarial-calibration"
    schemaVersion = 1
    generatedAt = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
    shared = [ordered]@{
        minimumAdversarialCases = 1
        disciplinePrinciples = $principles
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
'local ScenarioAdversarialCalibration = {}'
'KWR.ScenarioAdversarialCalibration = ScenarioAdversarialCalibration'
''
'local phaseIndex = nil'
''
('local DATA = ' + (To-LuaLiteral -Value $luaData))
''
'function ScenarioAdversarialCalibration:Count()'
'    local count = 0'
'    for _ in pairs(DATA.scenarios or {}) do count = count + 1 end'
'    return count'
'end'
''
'function ScenarioAdversarialCalibration:Get(scenarioID)'
'    local row = DATA.scenarios and DATA.scenarios[scenarioID]'
'    return row and KWR.Util:Copy(row) or nil'
'end'
''
'function ScenarioAdversarialCalibration:GetMapSummary(mapKey)'
'    mapKey = KWR.Util:Upper(mapKey, nil, 24)'
'    local row = mapKey and DATA.maps and DATA.maps[mapKey] or nil'
'    return row and KWR.Util:Copy(row) or nil'
'end'
''
'function ScenarioAdversarialCalibration:GetMapPhaseSummary(mapKey, phase)'
'    mapKey = KWR.Util:Upper(mapKey, nil, 24)'
'    phase = KWR.Util:Upper(phase, nil, 24)'
'    local row = mapKey and phase and DATA.maps and DATA.maps[mapKey]'
'    row = row and row.phaseSummaries and row.phaseSummaries[phase] or nil'
'    return row and KWR.Util:Copy(row) or nil'
'end'
''
'function ScenarioAdversarialCalibration:GetByMapAndPhase(mapKey, phase)'
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
'function ScenarioAdversarialCalibration:Shared()'
'    return KWR.Util:Copy(DATA.shared or {})'
'end'
''
'KWR:RegisterModule("ScenarioAdversarialCalibration", ScenarioAdversarialCalibration)'
) -join "`n"
[IO.File]::WriteAllText($luaOutPath, $lua + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))

Write-Output "KWR scenario adversarial calibration build"
Write-Output "Scenario rows: $($scenarios.Count)"
Write-Output "JSON: $jsonOutPath"
Write-Output "Lua: $luaOutPath"
