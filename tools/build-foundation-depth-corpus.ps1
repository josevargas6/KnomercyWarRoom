[CmdletBinding()]
param(
    [int]$ReviewedCasesPerScenario = 5,
    [int]$AdversarialCasesPerScenario = 1
)

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
    $Object | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Clone-Json {
    param([Parameter(Mandatory = $true)]$Object)
    return ($Object | ConvertTo-Json -Depth 14 | ConvertFrom-Json)
}

function Set-JsonProperty {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)]$Value
    )
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force
    } else {
        $property.Value = $Value
    }
}

function Get-VariantName {
    param([int]$Index)
    switch ($Index) {
        2 { return "reinforced_line" }
        3 { return "split_pressure" }
        4 { return "uncertain_window" }
        5 { return "late_clock" }
        default { return "variant_$Index" }
    }
}

function Get-VariantClassification {
    param([int]$Index)
    switch ($Index) {
        2 { return "SUCCESS" }
        3 { return "OPPONENT_COUNTER" }
        4 { return "UNRESOLVED" }
        5 { return "EXECUTION_ERROR" }
        default { return "SUCCESS" }
    }
}

function Get-VariantPressure {
    param([int]$Index)
    switch ($Index) {
        2 { return "HIGH" }
        3 { return "SPLIT" }
        4 { return "LOW_TRUTH" }
        5 { return "URGENT" }
        default { return "MEDIUM" }
    }
}

function Get-VariantAttribution {
    param([int]$Index)
    switch ($Index) {
        2 {
            return [ordered]@{
                outcomeDriver = "REINFORCED_LINE"
                decisionQuality = "ALIGNED"
                executionQuality = "CLEAN"
                truthQuality = "STABLE"
                recommendedLesson = "Reinforced lines should be repeated when support arrives on time."
            }
        }
        3 {
            return [ordered]@{
                outcomeDriver = "ENEMY_COUNTER_WINDOW"
                decisionQuality = "ALIGNED"
                executionQuality = "CONTESTED"
                truthQuality = "STABLE"
                recommendedLesson = "Respect the counter route and avoid equal split pressure into their preferred branch."
            }
        }
        4 {
            return [ordered]@{
                outcomeDriver = "LOW_TRUTH_STATE"
                decisionQuality = "CAUTIOUS"
                executionQuality = "HELD_BACK"
                truthQuality = "DEGRADED"
                recommendedLesson = "Keep the call reversible until objective and movement truth improve."
            }
        }
        5 {
            return [ordered]@{
                outcomeDriver = "EXECUTION_BREAK"
                decisionQuality = "ALIGNED"
                executionQuality = "FAILED"
                truthQuality = "STABLE"
                recommendedLesson = "The branch was defensible, but the team cannot trickle or miss the timing."
            }
        }
        default {
            return [ordered]@{
                outcomeDriver = "REVIEWED_LINE"
                decisionQuality = "ALIGNED"
                executionQuality = "CLEAN"
                truthQuality = "STABLE"
                recommendedLesson = "Repeat the reviewed line unless live truth degrades."
            }
        }
    }
}

function Update-Score {
    param(
        [Parameter(Mandatory = $true)]$Score,
        [int]$VariantIndex
    )
    if ($null -eq $Score.max) { return }
    if ([int]$Score.max -le 3) {
        switch ($VariantIndex) {
            2 { $Score.friendly = [Math]::Min([int]$Score.max, [int]$Score.friendly + 1) }
            3 { $Score.enemy = [Math]::Min([int]$Score.max, [int]$Score.enemy + 1) }
            4 { }
            5 {
                $Score.friendly = [Math]::Min([int]$Score.max, [int]$Score.friendly + 1)
                if ([int]$Score.enemy -gt 0) { $Score.enemy = [int]$Score.enemy - 1 }
            }
        }
        return
    }

    $delta = switch ($VariantIndex) {
        2 { 80 }
        3 { -45 }
        4 { 15 }
        5 { 140 }
        default { 25 }
    }
    $friendly = [int]$Score.friendly + $delta
    $enemy = [int]$Score.enemy + [Math]::Floor($delta / 3)
    $friendly = [Math]::Max(0, [Math]::Min([int]$Score.max, $friendly))
    $enemy = [Math]::Max(0, [Math]::Min([int]$Score.max, $enemy))
    $Score.friendly = $friendly
    $Score.enemy = $enemy
}

function Update-OutcomeClassification {
    param(
        [Parameter(Mandatory = $true)]$Outcome,
        [int]$VariantIndex,
        [string]$ScenarioSummary
    )
    $classification = Get-VariantClassification -Index $VariantIndex
    $Outcome.classifications.primary = $classification
    $Outcome.classifications.summary = switch ($classification) {
        "SUCCESS" { "$ScenarioSummary stayed aligned and closed favorably." }
        "OPPONENT_COUNTER" { "$ScenarioSummary was challenged by an enemy counter pattern and remains useful for comparison." }
        "UNRESOLVED" { "$ScenarioSummary occurred under degraded truth and remains intentionally unresolved." }
        "EXECUTION_ERROR" { "$ScenarioSummary was reasonable, but the notional execution path failed the intended close." }
        default { "$ScenarioSummary remained useful for offline review." }
    }
    if ($Outcome.checkpoints.Count -gt 0) {
        $Outcome.checkpoints[0].classification = $classification
        $Outcome.checkpoints[0].summary = $Outcome.classifications.summary
    }
}

function Update-OutcomeAttribution {
    param(
        [Parameter(Mandatory = $true)]$Outcome,
        [Parameter(Mandatory = $true)]$Run,
        [int]$VariantIndex,
        [string]$ScenarioSummary,
        [string]$ScenarioGoal
    )
    $attribution = Get-VariantAttribution -Index $VariantIndex
    $classification = Get-VariantClassification -Index $VariantIndex

    Set-JsonProperty -Object $Outcome.classifications -Name "secondary" -Value @(
        $attribution.outcomeDriver,
        $attribution.executionQuality,
        $attribution.truthQuality
    )
    Set-JsonProperty -Object $Outcome -Name "attribution" -Value $attribution
    Set-JsonProperty -Object $Outcome -Name "checkpoints" -Value @(
        [ordered]@{
            offsetSeconds = 5
            classification = if ($classification -eq "UNRESOLVED") { "UNRESOLVED" } else { "SUCCESS" }
            summary = "Initial contest review: $ScenarioSummary"
        },
        [ordered]@{
            offsetSeconds = 10
            classification = $classification
            summary = $Outcome.classifications.summary
        },
        [ordered]@{
            offsetSeconds = 18
            classification = $classification
            summary = "Lesson: $($attribution.recommendedLesson)"
        }
    )

    Set-JsonProperty -Object $Run.evaluation -Name "attribution" -Value $attribution
    Set-JsonProperty -Object $Run.evaluation -Name "branchReview" -Value ([ordered]@{
        variantShape = Get-VariantName -Index $VariantIndex
        primaryClassification = $classification
        summary = $Outcome.classifications.summary
        lesson = $attribution.recommendedLesson
        goal = $ScenarioGoal
    })
    $Run.final.summary = @(
        "$($Run.final.summary[0])",
        "ACTION: $ScenarioSummary",
        "SHAPE: $(Get-VariantName -Index $VariantIndex)",
        "DRIVER: $($attribution.outcomeDriver)",
        "LESSON: $($attribution.recommendedLesson)"
    )
}

$matrix = Load-JsonFile (Join-Path $root "knowledge\rbg-scenario-matrix.json")

$createdReviewed = 0
$createdAdversarial = 0

foreach ($map in @($matrix.maps)) {
    foreach ($scenario in @($map.scenarios)) {
        $baseName = [string]$scenario.scenarioId
        $baseReplayPath = Join-Path $root "tests\replays\$baseName.json"
        $baseLabelPath = Join-Path $root "tests\golden\$baseName.label.json"
        $baseRunPath = Join-Path $root "tests\replay-results\$baseName.run.json"
        $baseOutcomePath = Join-Path $root "tests\outcomes\$baseName.outcome.json"

        if (-not (Test-Path -LiteralPath $baseReplayPath)) { continue }

        $baseReplay = Load-JsonFile $baseReplayPath
        $baseLabel = Load-JsonFile $baseLabelPath
        $baseRun = Load-JsonFile $baseRunPath
        $baseOutcome = Load-JsonFile $baseOutcomePath

        foreach ($variantIndex in 2..$ReviewedCasesPerScenario) {
            $variantName = Get-VariantName -Index $variantIndex
            $variantBase = "$baseName-$variantName"
            $replayPath = Join-Path $root "tests\replays\$variantBase.json"
            $labelPath = Join-Path $root "tests\golden\$variantBase.label.json"
            $runPath = Join-Path $root "tests\replay-results\$variantBase.run.json"
            $outcomePath = Join-Path $root "tests\outcomes\$variantBase.outcome.json"

            $replay = Clone-Json $baseReplay
            $label = Clone-Json $baseLabel
            $run = Clone-Json $baseRun
            $outcome = Clone-Json $baseOutcome

            $replay.replayId = "$($baseReplay.replayId.Substring(0, $baseReplay.replayId.Length - 3))" + ("{0:d3}" -f $variantIndex)
            $replay.source.type = "synthetic_mutation"
            $replay.source.provenance = "offline_foundation_depth_pack"
            $replay.source.verified = $true
            $replay.capturedAt = "2026-07-29T0$variantIndex`:00:00Z"
            $replay.initialState.evidenceQuality = if ($variantIndex -eq 4) { "MEDIUM" } else { "HIGH" }
            Update-Score -Score $replay.initialState.score -VariantIndex $variantIndex
            $replay.timeline = @(
                [ordered]@{
                    t = 0
                    event = ($scenario.scenarioId -replace '-', '_') + "_variant_" + $variantIndex + "_state"
                    facts = [ordered]@{
                        phase = $scenario.phase
                        summary = $scenario.summary
                        variant = $variantName
                        goal = $scenario.goal
                    }
                },
                [ordered]@{
                    t = 8
                    event = ($scenario.scenarioId -replace '-', '_') + "_variant_" + $variantIndex + "_window"
                    facts = [ordered]@{
                        objective = @($baseRun.checkpoints)[0].current.where
                        pressure = Get-VariantPressure -Index $variantIndex
                        truth = $replay.initialState.evidenceQuality
                    }
                },
                [ordered]@{
                    t = 18
                    event = ($scenario.scenarioId -replace '-', '_') + "_variant_" + $variantIndex + "_resolution"
                    facts = [ordered]@{
                        classification = Get-VariantClassification -Index $variantIndex
                        result = $outcome.result
                    }
                }
            )
            $replay.expectedLabels.rationale = "$($scenario.summary) Variant $variantIndex uses the $variantName pressure shape to expand offline comparison coverage."

            $label.labelId = "$($replay.replayId)-label"
            $label.replayId = $replay.replayId
            $label.reviewers[0].reviewerId = "offline-foundation-pack"
            $label.rationale = "$($scenario.summary) Variant $variantIndex covers the $variantName shape."
            if ($label.PSObject.Properties["branchEvidence"] -and $label.branchEvidence) {
                Set-JsonProperty -Object $label.branchEvidence -Name "variantShape" -Value $variantName
                Set-JsonProperty -Object $label.branchEvidence -Name "variantClassification" -Value (Get-VariantClassification -Index $variantIndex)
            }
            if ($label.coverage -and $label.coverage.PSObject.Properties["branchEvidence"] -and $label.coverage.branchEvidence) {
                Set-JsonProperty -Object $label.coverage.branchEvidence -Name "variantShape" -Value $variantName
                Set-JsonProperty -Object $label.coverage.branchEvidence -Name "variantClassification" -Value (Get-VariantClassification -Index $variantIndex)
            }
            if ($variantIndex -eq 4) {
                $label.decision.forceUncertaintyWhen = @("objective_truth_missing", "movement_truth_ambiguous")
                $label.coverage.truthBand = "MEDIUM"
            }

            $run.replayId = $replay.replayId
            $run.replayPath = "tests/replays/$variantBase.json"
            $run.labelPath = "tests/golden/$variantBase.label.json"
            $run.final.summary = @("$($map.mapKey) variant $variantIndex $($run.final.status)")
            $run.checkpoints[0].event = $replay.timeline[0].event

            $outcome.reviewId = "$($replay.replayId)-outcome"
            $outcome.replayId = $replay.replayId
            Update-OutcomeClassification -Outcome $outcome -VariantIndex $variantIndex -ScenarioSummary $scenario.summary
            Update-OutcomeAttribution -Outcome $outcome -Run $run -VariantIndex $variantIndex -ScenarioSummary $scenario.summary -ScenarioGoal $scenario.goal
            if ($outcome.PSObject.Properties["branchEvidence"] -and $outcome.branchEvidence) {
                Set-JsonProperty -Object $outcome.branchEvidence -Name "variantShape" -Value $variantName
                Set-JsonProperty -Object $outcome.branchEvidence -Name "variantClassification" -Value (Get-VariantClassification -Index $variantIndex)
            }

            Write-JsonFile -Path $replayPath -Object $replay
            Write-JsonFile -Path $labelPath -Object $label
            Write-JsonFile -Path $runPath -Object $run
            Write-JsonFile -Path $outcomePath -Object $outcome
            $createdReviewed = $createdReviewed + 1
        }

        foreach ($adversarialIndex in 1..$AdversarialCasesPerScenario) {
            $adversarialBase = "$baseName-adversarial-$("{0:d2}" -f $adversarialIndex)"
            $adversarialPath = Join-Path $root "tests\adversarial\$adversarialBase.json"
            $adversarialReplay = Clone-Json $baseReplay
            $adversarialReplay.replayId = "$baseName-adversarial-$("{0:d3}" -f $adversarialIndex)"
            $adversarialReplay.source.type = "synthetic_mutation"
            $adversarialReplay.source.provenance = "offline_adversarial_pack"
            $adversarialReplay.source.verified = $true
            $adversarialReplay.redaction.status = "SYNTHETIC"
            $adversarialReplay.initialState.evidenceQuality = "LOW"
            $adversarialReplay.expectedLabels.primaryActions = @("PLAN:CHECK")
            $adversarialReplay.expectedLabels.fallbackActions = @("CALL:HOLD", "WHERE:FIELD")
            $adversarialReplay.expectedLabels.forbiddenActions = @("CALL:FULL_COMMIT")
            $adversarialReplay.expectedLabels.rationale = "$($scenario.summary) adversarial truth case: maintain the safest check path when battlefield truth is incomplete."
            if ($adversarialReplay.expectedLabels.PSObject.Properties["branchEvidence"] -and $adversarialReplay.expectedLabels.branchEvidence) {
                Set-JsonProperty -Object $adversarialReplay.expectedLabels.branchEvidence -Name "truthStress" -Value "ADVERSARIAL"
                Set-JsonProperty -Object $adversarialReplay.expectedLabels.branchEvidence -Name "safestCounter" -Value "preserve the safer path until battlefield truth improves."
            }
            $adversarialReplay.outcome.result = "UNKNOWN"
            $adversarialReplay.outcome.reviewStatus = "OPEN"
            if (-not $adversarialReplay.outcome.PSObject.Properties["classifications"] -or -not $adversarialReplay.outcome.classifications) {
                Set-JsonProperty -Object $adversarialReplay.outcome -Name "classifications" -Value ([ordered]@{
                    primary = "UNRESOLVED"
                    summary = "Truth is intentionally degraded and the safe line remains unresolved."
                    secondary = @()
                })
            }
            Set-JsonProperty -Object $adversarialReplay.outcome.classifications -Name "primary" -Value "UNRESOLVED"
            Set-JsonProperty -Object $adversarialReplay.outcome.classifications -Name "summary" -Value "Truth is intentionally degraded and the safe line remains unresolved."
            Set-JsonProperty -Object $adversarialReplay.outcome.classifications -Name "secondary" -Value @("LOW_TRUTH_STATE", "HELD_BACK", "DEGRADED")
            Set-JsonProperty -Object $adversarialReplay.outcome -Name "checkpoints" -Value @(
                [ordered]@{
                    offsetSeconds = 5
                    classification = "UNRESOLVED"
                    summary = "Initial truth review: battlefield facts are too incomplete for expansion."
                },
                [ordered]@{
                    offsetSeconds = 10
                    classification = "UNRESOLVED"
                    summary = "Truth is intentionally degraded; the safe requirement is uncertainty discipline."
                },
                [ordered]@{
                    offsetSeconds = 18
                    classification = "UNRESOLVED"
                    summary = "Lesson: keep the move reversible until battlefield truth improves."
                }
            )
            Set-JsonProperty -Object $adversarialReplay.outcome -Name "attribution" -Value ([ordered]@{
                outcomeDriver = "LOW_TRUTH_STATE"
                decisionQuality = "CAUTIOUS"
                executionQuality = "HELD_BACK"
                truthQuality = "DEGRADED"
                recommendedLesson = "Protect the score floor and refuse full-commit calls from partial truth."
            })
            if ($adversarialReplay.outcome.PSObject.Properties["branchEvidence"] -and $adversarialReplay.outcome.branchEvidence) {
                Set-JsonProperty -Object $adversarialReplay.outcome.branchEvidence -Name "truthStress" -Value "ADVERSARIAL"
                Set-JsonProperty -Object $adversarialReplay.outcome.branchEvidence -Name "variantClassification" -Value "UNRESOLVED"
            }
            if ($adversarialReplay.initialState.PSObject.Properties["objectives"]) {
                $adversarialReplay.initialState.objectives = [ordered]@{}
            }
            $adversarialReplay.timeline = @(
                [ordered]@{
                    t = 0
                    event = ($scenario.scenarioId -replace '-', '_') + "_adversarial_state"
                    facts = [ordered]@{
                        phase = $scenario.phase
                        summary = $scenario.summary
                        truth = "LOW"
                        objectiveKnowledge = "PARTIAL"
                    }
                },
                [ordered]@{
                    t = 9
                    event = ($scenario.scenarioId -replace '-', '_') + "_adversarial_conflict"
                    facts = [ordered]@{
                        pressure = "AMBIGUOUS"
                        carrierTruth = "UNKNOWN"
                        movementTruth = "PARTIAL"
                    }
                }
            )

            Write-JsonFile -Path $adversarialPath -Object $adversarialReplay
            $createdAdversarial = $createdAdversarial + 1
        }
    }
}

& (Join-Path $root "tools\build-starter-corpus.ps1") | Out-Null

Write-Output "KWR foundation depth corpus build"
Write-Output "Created reviewed variants: $createdReviewed"
Write-Output "Created adversarial variants: $createdAdversarial"
