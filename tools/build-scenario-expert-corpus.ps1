[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$matrixPath = Join-Path $root "knowledge\rbg-scenario-matrix.json"
$labelsPath = Join-Path $root "tests\golden"
$outcomesPath = Join-Path $root "tests\outcomes"
$jsonOutPath = Join-Path $root "knowledge\scenario-expert-corpus.json"
$luaOutPath = Join-Path $root "Data\ScenarioExpertCorpus.lua"

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
    try {
        $plain = ConvertTo-PlainData -Value $Object
        $jsonText = $plain | ConvertTo-Json -Depth 16
        Set-Content -LiteralPath $Path -Value $jsonText -Encoding UTF8
    } catch {
        Write-Output "Scenario expert corpus: JSON serialization failed"
        Write-Output $_.InvocationInfo.PositionMessage
        throw
    }
}

function Add-CountValue {
    param(
        [Parameter(Mandatory = $true)]$Table,
        [Parameter(Mandatory = $true)][string]$Key,
        [int]$Increment = 1
    )
    if (-not $Table.Contains($Key)) {
        $Table[$Key] = 0
    }
    $Table[$Key] += $Increment
}

function Add-UniqueString {
    param(
        [Parameter(Mandatory = $true)]$List,
        [string]$Value
    )
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return
    }
    if (-not $List.Contains($Value)) {
        [void]$List.Add($Value)
    }
}

function Get-CountKeysDescending {
    param([Parameter(Mandatory = $true)]$Table)
    $rows = foreach ($key in $Table.Keys) {
        [pscustomobject]@{
            Key = [string]$key
            Count = [int]$Table[$key]
        }
    }
    return @(
        $rows |
            Sort-Object -Property @{ Expression = "Count"; Descending = $true }, @{ Expression = "Key"; Descending = $false } |
            ForEach-Object { $_.Key }
    )
}

function Get-TopCountKey {
    param([Parameter(Mandatory = $true)]$Table)
    $keys = @(Get-CountKeysDescending -Table $Table)
    if ($keys.Count -gt 0) {
        return [string]$keys[0]
    }
    return $null
}

function Get-TopOperationalClassification {
    param([Parameter(Mandatory = $true)]$Table)
    $filtered = [ordered]@{}
    foreach ($key in $Table.Keys) {
        if ($key -notin @("SUCCESS", "UNRESOLVED")) {
            $filtered[$key] = $Table[$key]
        }
    }
    if ($filtered.Count -gt 0) {
        return Get-TopCountKey -Table $filtered
    }
    return Get-TopCountKey -Table $Table
}

function Get-DisciplineFocus {
    param(
        [string]$TopLossClassification,
        [string]$TopOutcomeDriver
    )
    if ($TopLossClassification -eq "EXECUTION_ERROR") {
        return "EXECUTION_DISCIPLINE"
    }
    if ($TopLossClassification -eq "OPPONENT_COUNTER") {
        return "COUNTER_READ"
    }
    if ($TopOutcomeDriver -eq "LOW_TRUTH_STATE") {
        return "TRUTH_DISCIPLINE"
    }
    if ($TopOutcomeDriver -eq "WINDOW_CONVERSION" -or
        $TopOutcomeDriver -eq "ENEMY_COUNTER_WINDOW") {
        return "WINDOW_DISCIPLINE"
    }
    return "SCORE_FLOOR_DISCIPLINE"
}

function Get-AgreementRate {
    param(
        [Parameter(Mandatory = $true)]$Table,
        [int]$Total
    )
    if ($Total -le 0) {
        return 0
    }
    $topKey = Get-TopCountKey -Table $Table
    if ([string]::IsNullOrWhiteSpace($topKey)) {
        return 0
    }
    return [Math]::Round(([double]$Table[$topKey] / [double]$Total), 4)
}

function Get-ReviewConfidence {
    param(
        [int]$ReviewedLabels,
        [double]$AgreementRate
    )
    if ($ReviewedLabels -ge 5 -and $AgreementRate -ge 0.8) {
        return "HIGH"
    }
    if ($ReviewedLabels -ge 3 -and $AgreementRate -ge 0.6) {
        return "MEDIUM"
    }
    if ($ReviewedLabels -ge 1) {
        return "LOW"
    }
    return "NONE"
}

function New-ObjectArray {
    param($Values)
    $items = New-Object System.Collections.Generic.List[object]
    foreach ($value in $Values) {
        $items.Add($value) | Out-Null
    }
    return $items.ToArray()
}

function ConvertTo-PlainData {
    param([Parameter(Mandatory = $true)]$Value)

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [string] -or $Value -is [bool] -or
        $Value -is [int] -or $Value -is [long] -or
        $Value -is [double] -or $Value -is [decimal]) {
        return $Value
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $copy = [ordered]@{}
        foreach ($key in $Value.Keys) {
            $copy[[string]$key] = ConvertTo-PlainData -Value $Value[$key]
        }
        return $copy
    }

    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        $items = @()
        foreach ($item in $Value) {
            $items += ,(ConvertTo-PlainData -Value $item)
        }
        return $items
    }

    $properties = $Value.PSObject.Properties
    if ($properties.Count -gt 0) {
        $copy = [ordered]@{}
        foreach ($property in $properties) {
            $copy[[string]$property.Name] = ConvertTo-PlainData -Value $property.Value
        }
        return $copy
    }

    return [string]$Value
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

    if ($Value -is [System.Collections.IEnumerable] -and
        -not ($Value -is [string]) -and
        -not ($Value -is [System.Collections.IDictionary]) -and
        -not ($Value -is [psobject])) {
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

$matrix = Load-JsonFile -Path $matrixPath
$scenarioRows = New-Object System.Collections.Generic.List[object]

foreach ($map in @($matrix.maps)) {
    foreach ($scenario in @($map.scenarios)) {
        $labelFiles = @(Get-ChildItem -LiteralPath $labelsPath -Filter "$($scenario.scenarioId)*.label.json" | Sort-Object Name)
        $outcomeFiles = @(Get-ChildItem -LiteralPath $outcomesPath -Filter "$($scenario.scenarioId)*.outcome.json" | Sort-Object Name)

        $primaryActions = [ordered]@{}
        $fallbackActions = [ordered]@{}
        $forbiddenActions = [ordered]@{}
        $mustStay = [ordered]@{}
        $requiredCapabilities = [ordered]@{}
        $successConditions = [ordered]@{}
        $abortConditions = [ordered]@{}
        $familyTags = [ordered]@{}
        $comparisonIds = [ordered]@{}
        $responseIds = [ordered]@{}
        $reviewerRoles = [ordered]@{}
        $classifications = [ordered]@{}
        $outcomeDrivers = [ordered]@{}
        $legalSignals = New-Object System.Collections.Generic.List[string]
        $invalidationSignals = New-Object System.Collections.Generic.List[string]
        $evidenceFocus = New-Object System.Collections.Generic.List[string]
        $lessonPatterns = New-Object System.Collections.Generic.List[string]
        $expectedEnemyCounters = [ordered]@{}
        $safestCounters = [ordered]@{}

        foreach ($labelFile in $labelFiles) {
            $label = Load-JsonFile -Path $labelFile.FullName
            foreach ($reviewer in @($label.reviewers)) {
                Add-CountValue -Table $reviewerRoles -Key ([string]$reviewer.role)
            }
            foreach ($value in @($label.decision.acceptablePrimaryActions)) {
                Add-CountValue -Table $primaryActions -Key ([string]$value)
            }
            foreach ($value in @($label.decision.acceptableFallbackActions)) {
                Add-CountValue -Table $fallbackActions -Key ([string]$value)
            }
            foreach ($value in @($label.decision.forbiddenActions)) {
                Add-CountValue -Table $forbiddenActions -Key ([string]$value)
            }
            foreach ($value in @($label.decision.mustStay)) {
                Add-CountValue -Table $mustStay -Key ([string]$value)
            }
            foreach ($value in @($label.decision.requiredCapabilities)) {
                Add-CountValue -Table $requiredCapabilities -Key ([string]$value)
            }
            foreach ($value in @($label.decision.successConditions)) {
                Add-CountValue -Table $successConditions -Key ([string]$value)
            }
            foreach ($value in @($label.decision.abortConditions)) {
                Add-CountValue -Table $abortConditions -Key ([string]$value)
            }

            $branchEvidence = if ($label.branchEvidence) {
                $label.branchEvidence
            } else {
                $label.coverage.branchEvidence
            }

            foreach ($value in @($branchEvidence.familyTags)) {
                Add-CountValue -Table $familyTags -Key ([string]$value)
            }
            foreach ($value in @($branchEvidence.doctrineComparisonIds)) {
                Add-CountValue -Table $comparisonIds -Key ([string]$value)
            }
            foreach ($value in @($branchEvidence.doctrineResponseIds)) {
                Add-CountValue -Table $responseIds -Key ([string]$value)
            }
            if ($branchEvidence.primaryComparisonId) {
                Add-CountValue -Table $comparisonIds -Key ([string]$branchEvidence.primaryComparisonId) -Increment 2
            }
            if ($branchEvidence.primaryResponseId) {
                Add-CountValue -Table $responseIds -Key ([string]$branchEvidence.primaryResponseId) -Increment 2
            }
            if ($branchEvidence.expectedEnemyCounter) {
                Add-CountValue -Table $expectedEnemyCounters -Key ([string]$branchEvidence.expectedEnemyCounter)
            }
            if ($branchEvidence.safestCounter) {
                Add-CountValue -Table $safestCounters -Key ([string]$branchEvidence.safestCounter)
            }
            foreach ($value in @($branchEvidence.legalWhen)) {
                Add-UniqueString -List $legalSignals -Value ([string]$value)
            }
            foreach ($value in @($branchEvidence.invalidatedBy)) {
                Add-UniqueString -List $invalidationSignals -Value ([string]$value)
            }
            foreach ($value in @($branchEvidence.evidenceFocus)) {
                Add-UniqueString -List $evidenceFocus -Value ([string]$value)
            }
        }

        foreach ($outcomeFile in $outcomeFiles) {
            $outcome = Load-JsonFile -Path $outcomeFile.FullName
            Add-CountValue -Table $classifications -Key ([string]$outcome.classifications.primary)
            if ($outcome.attribution -and $outcome.attribution.outcomeDriver) {
                Add-CountValue -Table $outcomeDrivers -Key ([string]$outcome.attribution.outcomeDriver)
            }
            if ($outcome.attribution -and $outcome.attribution.recommendedLesson) {
                Add-UniqueString -List $lessonPatterns -Value ([string]$outcome.attribution.recommendedLesson)
            }
        }

        $reviewedLabels = @($labelFiles).Count
        $agreementRate = Get-AgreementRate -Table $primaryActions -Total $reviewedLabels
        $topLossClassification = Get-TopOperationalClassification -Table $classifications
        $topOutcomeDriver = Get-TopCountKey -Table $outcomeDrivers
        $disciplineFocus = Get-DisciplineFocus `
            -TopLossClassification $topLossClassification `
            -TopOutcomeDriver $topOutcomeDriver
        $scenarioRow = [ordered]@{
            scenarioId = [string]$scenario.scenarioId
            mapKey = [string]$map.mapKey
            mapProfile = [string]$map.mapProfile
            phase = [string]$scenario.phase
            seasonStatus = if ($scenario.PSObject.Properties.Name -contains "seasonStatus") {
                [string]$scenario.seasonStatus
            } else {
                "CURRENT_REVIEWED"
            }
            summary = [string]$scenario.summary
            goal = [string]$scenario.goal
            reviewedLabels = $reviewedLabels
            reviewConfidence = Get-ReviewConfidence -ReviewedLabels $reviewedLabels -AgreementRate $agreementRate
            agreementRate = $agreementRate
            consensusPrimaryAction = Get-TopCountKey -Table $primaryActions
            consensusFallbackAction = Get-TopCountKey -Table $fallbackActions
            preferredComparisonId = Get-TopCountKey -Table $comparisonIds
            preferredResponseId = Get-TopCountKey -Table $responseIds
            safestCounter = Get-TopCountKey -Table $safestCounters
            expectedEnemyCounter = Get-TopCountKey -Table $expectedEnemyCounters
            consensusPrimaryActions = New-ObjectArray (Get-CountKeysDescending -Table $primaryActions)
            consensusFallbackActions = New-ObjectArray (Get-CountKeysDescending -Table $fallbackActions)
            forbiddenActions = New-ObjectArray (Get-CountKeysDescending -Table $forbiddenActions)
            mustStay = New-ObjectArray (Get-CountKeysDescending -Table $mustStay)
            requiredCapabilities = New-ObjectArray (Get-CountKeysDescending -Table $requiredCapabilities)
            successConditions = New-ObjectArray (Get-CountKeysDescending -Table $successConditions)
            abortConditions = New-ObjectArray (Get-CountKeysDescending -Table $abortConditions)
            familyTags = New-ObjectArray (Get-CountKeysDescending -Table $familyTags)
            doctrineComparisonIds = New-ObjectArray (Get-CountKeysDescending -Table $comparisonIds)
            doctrineResponseIds = New-ObjectArray (Get-CountKeysDescending -Table $responseIds)
            legalSignals = New-ObjectArray $legalSignals
            invalidationSignals = New-ObjectArray $invalidationSignals
            evidenceFocus = New-ObjectArray $evidenceFocus
            reviewerRoles = New-ObjectArray (Get-CountKeysDescending -Table $reviewerRoles)
            classifications = $classifications
            outcomeDrivers = $outcomeDrivers
            topLossClassification = $topLossClassification
            topOutcomeDriver = $topOutcomeDriver
            disciplineFocus = $disciplineFocus
            recommendedLesson = if ($lessonPatterns.Count -gt 0) {
                [string]$lessonPatterns[0]
            } else {
                "Stay on the reviewed line while battlefield truth remains intact."
            }
            lessonPatterns = New-ObjectArray $lessonPatterns
        }
        $scenarioRows.Add([pscustomobject]$scenarioRow) | Out-Null
    }
}

Write-Output "Scenario expert corpus: aggregated scenario rows $($scenarioRows.Count)"

$mapRows = New-Object System.Collections.Generic.List[object]
foreach ($map in @($matrix.maps)) {
    $rows = @($scenarioRows | Where-Object { $_.mapKey -eq $map.mapKey })
    $phaseSummaries = [ordered]@{}
    foreach ($phase in @("OPENING", "STABILIZE", "PRESSURE", "RECOVERY", "ENDGAME")) {
        $phaseRows = @($rows | Where-Object { $_.phase -eq $phase })
        $phaseSummaries[$phase] = [ordered]@{
            phase = $phase
            scenarios = $phaseRows.Count
            reviewedLabels = @($phaseRows | Measure-Object -Property reviewedLabels -Sum).Sum
            averageAgreementRate = if ($phaseRows.Count -gt 0) {
                [Math]::Round((@($phaseRows | Measure-Object -Property agreementRate -Average).Average), 4)
            } else {
                0
            }
            reviewConfidence = if (($phaseRows | Where-Object { $_.reviewConfidence -eq "HIGH" }).Count -eq $phaseRows.Count -and $phaseRows.Count -gt 0) {
                "HIGH"
            } elseif (($phaseRows | Where-Object { $_.reviewConfidence -in @("HIGH", "MEDIUM") }).Count -eq $phaseRows.Count -and $phaseRows.Count -gt 0) {
                "MEDIUM"
            } else {
                "LOW"
            }
        }
    }

    $mapRows.Add([pscustomobject][ordered]@{
        mapKey = [string]$map.mapKey
        mapProfile = [string]$map.mapProfile
        scenarios = $rows.Count
        reviewedLabels = @($rows | Measure-Object -Property reviewedLabels -Sum).Sum
        averageAgreementRate = if ($rows.Count -gt 0) {
            [Math]::Round((@($rows | Measure-Object -Property agreementRate -Average).Average), 4)
        } else {
            0
        }
        reviewConfidence = if (($rows | Where-Object { $_.reviewConfidence -eq "HIGH" }).Count -eq $rows.Count -and $rows.Count -gt 0) {
            "HIGH"
        } elseif (($rows | Where-Object { $_.reviewConfidence -in @("HIGH", "MEDIUM") }).Count -eq $rows.Count -and $rows.Count -gt 0) {
            "MEDIUM"
        } else {
            "LOW"
        }
        phaseSummaries = $phaseSummaries
    }) | Out-Null
}

Write-Output "Scenario expert corpus: aggregated map rows $($mapRows.Count)"

$jsonShared = [ordered]@{}
$jsonShared["minimumReviewedLabels"] = 5
$jsonShared["consensusPolicy"] = "scenario-first then map-phase fallback"
$jsonSharedBands = [ordered]@{}
$jsonSharedBands["HIGH"] = 0.8
$jsonSharedBands["MEDIUM"] = 0.6
$jsonSharedBands["LOW"] = 0.0
$jsonShared["reviewAgreementBands"] = $jsonSharedBands

$json = [ordered]@{}
$json["schema"] = "kwr-scenario-expert-corpus"
$json["schemaVersion"] = 1
$json["generatedAt"] = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
$json["shared"] = $jsonShared
$json["scenarios"] = $scenarioRows.ToArray()
$json["maps"] = $mapRows.ToArray()

Write-JsonFile -Path $jsonOutPath -Object $json

$scenarioIndex = [ordered]@{}
foreach ($row in $scenarioRows.ToArray()) {
    $scenarioIndex[[string]$row.scenarioId] = $row
}
$mapIndex = [ordered]@{}
foreach ($row in $mapRows.ToArray()) {
    $mapIndex[[string]$row.mapKey] = $row
}

$luaData = ConvertTo-PlainData -Value ([pscustomobject]@{
    shared = $json.shared
    maps = $mapIndex
    scenarios = $scenarioIndex
})

$lua = @"
local _, KWR = ...

local ScenarioExpertCorpus = {}
KWR.ScenarioExpertCorpus = ScenarioExpertCorpus

local phaseIndex = nil

local DATA = $(To-LuaLiteral -Value $luaData -Indent 0)

function ScenarioExpertCorpus:Count()
    local count = 0
    for _ in pairs(DATA.scenarios or {}) do count = count + 1 end
    return count
end

function ScenarioExpertCorpus:Get(scenarioID)
    local row = DATA.scenarios and DATA.scenarios[scenarioID]
    return row and KWR.Util:Copy(row) or nil
end

function ScenarioExpertCorpus:GetMapSummary(mapKey)
    mapKey = KWR.Util:Upper(mapKey, nil, 24)
    local row = mapKey and DATA.maps and DATA.maps[mapKey] or nil
    return row and KWR.Util:Copy(row) or nil
end

function ScenarioExpertCorpus:GetMapPhaseSummary(mapKey, phase)
    mapKey = KWR.Util:Upper(mapKey, nil, 24)
    phase = KWR.Util:Upper(phase, nil, 24)
    local row = mapKey and phase and DATA.maps and DATA.maps[mapKey]
    row = row and row.phaseSummaries and row.phaseSummaries[phase] or nil
    return row and KWR.Util:Copy(row) or nil
end

function ScenarioExpertCorpus:GetByMapAndPhase(mapKey, phase)
    mapKey = KWR.Util:Upper(mapKey, nil, 24)
    phase = KWR.Util:Upper(phase, nil, 24)
    if not mapKey or not phase then
        return nil
    end
    if not phaseIndex then
        phaseIndex = {}
        for _, row in pairs(DATA.scenarios or {}) do
            if row.mapKey and row.phase
                and row.reviewConfidence == "HIGH"
                and row.seasonStatus ~= "PENDING_SEASON_REVIEW" then
                phaseIndex[row.mapKey] = phaseIndex[row.mapKey] or {}
                local current = phaseIndex[row.mapKey][row.phase]
                if not current or tostring(row.scenarioId) < tostring(current.scenarioId) then
                    phaseIndex[row.mapKey][row.phase] = row
                end
            end
        end
    end
    local row = phaseIndex[mapKey] and phaseIndex[mapKey][phase] or nil
    return row and KWR.Util:Copy(row) or nil
end

function ScenarioExpertCorpus:Shared()
    return KWR.Util:Copy(DATA.shared or {})
end

KWR:RegisterModule("ScenarioExpertCorpus", ScenarioExpertCorpus)
"@

Set-Content -LiteralPath $luaOutPath -Value $lua -Encoding UTF8

Write-Output "KWR scenario expert corpus build"
Write-Output "Scenario rows: $($scenarioRows.Count)"
Write-Output "Map rows: $($mapRows.Count)"
