[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$errors = [System.Collections.Generic.List[string]]::new()

function Add-CorpusError {
    param([string]$Message)
    $script:errors.Add($Message)
}

function Assert-HasKeys {
    param(
        [Parameter(Mandatory = $true)] $Object,
        [Parameter(Mandatory = $true)][string[]]$Keys,
        [Parameter(Mandatory = $true)][string]$Label
    )

    foreach ($key in $Keys) {
        $property = $Object.PSObject.Properties[$key]
        if ($null -eq $property) {
            Add-CorpusError "$Label missing required field: $key"
        }
    }
}

function Load-JsonFile {
    param([Parameter(Mandatory = $true)][string]$Path)
    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    } catch {
        Add-CorpusError "Invalid JSON: $Path :: $($_.Exception.Message)"
        return $null
    }
}

$requiredPaths = @(
    "knowledge\schemas\replay-schema.json",
    "knowledge\schemas\golden-label-schema.json",
    "knowledge\schemas\replay-run-result-schema.json",
    "knowledge\schemas\benchmark-report-schema.json",
    "knowledge\schemas\corpus-manifest-schema.json",
    "knowledge\schemas\outcome-review-schema.json",
    "knowledge\schemas\rbg-scenario-matrix-schema.json",
    "knowledge\corpus-manifest.json",
    "knowledge\rbg-scenario-matrix.json",
    "knowledge\fixtures\replay-template.json",
    "knowledge\fixtures\golden-label-template.json",
    "knowledge\fixtures\adversarial-replay-template.json",
    "knowledge\fixtures\outcome-review-template.json",
    "tests\replays\README.md",
    "tests\golden\README.md",
    "tests\adversarial\README.md",
    "tests\replay-results\README.md",
    "tests\outcomes\README.md"
)

foreach ($relative in $requiredPaths) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $relative))) {
        Add-CorpusError "Missing corpus artifact: $relative"
    }
}

$replaySchemaPath = Join-Path $root "knowledge\schemas\replay-schema.json"
$labelSchemaPath = Join-Path $root "knowledge\schemas\golden-label-schema.json"
$runSchemaPath = Join-Path $root "knowledge\schemas\replay-run-result-schema.json"
$manifestSchemaPath = Join-Path $root "knowledge\schemas\corpus-manifest-schema.json"
$outcomeSchemaPath = Join-Path $root "knowledge\schemas\outcome-review-schema.json"
$scenarioMatrixPath = Join-Path $root "knowledge\rbg-scenario-matrix.json"
$replaySchema = if (Test-Path -LiteralPath $replaySchemaPath) { Load-JsonFile $replaySchemaPath }
$labelSchema = if (Test-Path -LiteralPath $labelSchemaPath) { Load-JsonFile $labelSchemaPath }
$runSchema = if (Test-Path -LiteralPath $runSchemaPath) { Load-JsonFile $runSchemaPath }
$manifestSchema = if (Test-Path -LiteralPath $manifestSchemaPath) { Load-JsonFile $manifestSchemaPath }
$outcomeSchema = if (Test-Path -LiteralPath $outcomeSchemaPath) { Load-JsonFile $outcomeSchemaPath }
$scenarioMatrix = if (Test-Path -LiteralPath $scenarioMatrixPath) { Load-JsonFile $scenarioMatrixPath }

if ($replaySchema) {
    Assert-HasKeys -Object $replaySchema -Keys @(
        "schema", "schemaVersion", "kind", "required", "timelineEventRequired",
        "expectedLabelRequired", "outcomeRequired", "checkpointRequired"
    ) -Label "Replay schema"
}

if ($labelSchema) {
    Assert-HasKeys -Object $labelSchema -Keys @(
        "schema", "schemaVersion", "kind", "required", "decisionRequired",
        "coverageRequired"
    ) -Label "Golden-label schema"
}

$replayFiles = @()
$labelFiles = @()
$runFiles = @()
$runRows = @()
$adversarialFiles = @()
$outcomeFiles = @()
$replayDir = Join-Path $root "tests\replays"
$labelDir = Join-Path $root "tests\golden"
$runDir = Join-Path $root "tests\replay-results"
$adversarialDir = Join-Path $root "tests\adversarial"
$outcomeDir = Join-Path $root "tests\outcomes"
if (Test-Path -LiteralPath $replayDir) {
    $replayFiles = @(Get-ChildItem -LiteralPath $replayDir -File -Filter "*.json")
}
if (Test-Path -LiteralPath $labelDir) {
    $labelFiles = @(Get-ChildItem -LiteralPath $labelDir -File -Filter "*.json")
}
if (Test-Path -LiteralPath $runDir) {
    $runFiles = @(Get-ChildItem -LiteralPath $runDir -File -Filter "*.run.json")
}
if (Test-Path -LiteralPath $adversarialDir) {
    $adversarialFiles = @(Get-ChildItem -LiteralPath $adversarialDir -File -Filter "*.json")
}
if (Test-Path -LiteralPath $outcomeDir) {
    $outcomeFiles = @(Get-ChildItem -LiteralPath $outcomeDir -File -Filter "*.outcome.json")
}

if ($replayFiles.Count -eq 0) {
    Add-CorpusError "No replay fixtures were found in tests\\replays."
}

foreach ($file in $replayFiles) {
    $replay = Load-JsonFile $file.FullName
    if (-not $replay -or -not $replaySchema) { continue }

    Assert-HasKeys -Object $replay -Keys $replaySchema.required -Label $file.Name
    if ($replay.source) { Assert-HasKeys -Object $replay.source -Keys $replaySchema.sourceRequired -Label "$($file.Name).source" }
    if ($replay.map) { Assert-HasKeys -Object $replay.map -Keys $replaySchema.mapRequired -Label "$($file.Name).map" }
    if ($replay.redaction) { Assert-HasKeys -Object $replay.redaction -Keys $replaySchema.redactionRequired -Label "$($file.Name).redaction" }
    if ($replay.initialState) { Assert-HasKeys -Object $replay.initialState -Keys $replaySchema.initialStateRequired -Label "$($file.Name).initialState" }
    if ($replay.expectedLabels) { Assert-HasKeys -Object $replay.expectedLabels -Keys $replaySchema.expectedLabelRequired -Label "$($file.Name).expectedLabels" }
    if ($replay.outcome) { Assert-HasKeys -Object $replay.outcome -Keys $replaySchema.outcomeRequired -Label "$($file.Name).outcome" }

    if ($replay.schema -ne $replaySchema.schema) {
        Add-CorpusError "$($file.Name) schema mismatch: expected $($replaySchema.schema)"
    }
    if ($replay.schemaVersion -ne $replaySchema.schemaVersion) {
        Add-CorpusError "$($file.Name) schemaVersion mismatch: expected $($replaySchema.schemaVersion)"
    }
    if ($replay.kind -ne $replaySchema.kind) {
        Add-CorpusError "$($file.Name) kind mismatch: expected $($replaySchema.kind)"
    }
    if ($replay.redaction -and $replay.redaction.secretValuesRemoved -ne $true) {
        Add-CorpusError "$($file.Name) does not declare secretValuesRemoved = true."
    }
    if ($replay.timeline -isnot [System.Collections.IEnumerable]) {
        Add-CorpusError "$($file.Name) timeline must be an array."
    } else {
        $index = 0
        $lastT = -1
        foreach ($event in @($replay.timeline)) {
            Assert-HasKeys -Object $event -Keys $replaySchema.timelineEventRequired -Label "$($file.Name).timeline[$index]"
            if ($event.t -lt $lastT) {
                Add-CorpusError "$($file.Name) timeline is not chronological at event index $index."
            }
            $lastT = $event.t
            $index += 1
        }
    }
    if ($replay.outcome -and $replay.outcome.checkpoints) {
        foreach ($checkpoint in @($replay.outcome.checkpoints)) {
            Assert-HasKeys -Object $checkpoint -Keys $replaySchema.checkpointRequired -Label "$($file.Name).checkpoint"
            if (@($replaySchema.classificationAllowlist) -notcontains $checkpoint.classification) {
                Add-CorpusError "$($file.Name) checkpoint classification is invalid: $($checkpoint.classification)"
            }
        }
    }
}

$adversarialReplayIds = @{}
foreach ($file in $adversarialFiles) {
    $replay = Load-JsonFile $file.FullName
    if (-not $replay -or -not $replaySchema) { continue }
    Assert-HasKeys -Object $replay -Keys $replaySchema.required -Label $file.Name
    if ($replay.replayId) {
        $adversarialReplayIds[$replay.replayId] = $true
    }
}

$knownReplayIds = @{}
foreach ($file in $replayFiles) {
    $replay = Load-JsonFile $file.FullName
    if ($replay -and $replay.replayId) {
        $knownReplayIds[$replay.replayId] = $true
    }
}
foreach ($key in $adversarialReplayIds.Keys) {
    $knownReplayIds[$key] = $true
}

foreach ($file in $labelFiles) {
    $label = Load-JsonFile $file.FullName
    if (-not $label -or -not $labelSchema) { continue }

    Assert-HasKeys -Object $label -Keys $labelSchema.required -Label $file.Name
    if ($label.reviewers) {
        foreach ($reviewer in @($label.reviewers)) {
            Assert-HasKeys -Object $reviewer -Keys $labelSchema.reviewerRequired -Label "$($file.Name).reviewer"
        }
    }
    if ($label.decision) { Assert-HasKeys -Object $label.decision -Keys $labelSchema.decisionRequired -Label "$($file.Name).decision" }
    if ($label.coverage) { Assert-HasKeys -Object $label.coverage -Keys $labelSchema.coverageRequired -Label "$($file.Name).coverage" }

    if ($label.schema -ne $labelSchema.schema) {
        Add-CorpusError "$($file.Name) schema mismatch: expected $($labelSchema.schema)"
    }
    if ($label.schemaVersion -ne $labelSchema.schemaVersion) {
        Add-CorpusError "$($file.Name) schemaVersion mismatch: expected $($labelSchema.schemaVersion)"
    }
    if ($label.kind -ne $labelSchema.kind) {
        Add-CorpusError "$($file.Name) kind mismatch: expected $($labelSchema.kind)"
    }
    if ($label.replayId -and -not $knownReplayIds.ContainsKey($label.replayId)) {
        Add-CorpusError "$($file.Name) references unknown replayId: $($label.replayId)"
    }
}

foreach ($file in $runFiles) {
    $run = Load-JsonFile $file.FullName
    if (-not $run -or -not $runSchema) { continue }
    $runRows += $run
    Assert-HasKeys -Object $run -Keys $runSchema.required -Label $file.Name
    if ($run.final) { Assert-HasKeys -Object $run.final -Keys $runSchema.finalRequired -Label "$($file.Name).final" }
    if ($run.evaluation) { Assert-HasKeys -Object $run.evaluation -Keys $runSchema.evaluationRequired -Label "$($file.Name).evaluation" }
    foreach ($checkpoint in @($run.checkpoints)) {
        Assert-HasKeys -Object $checkpoint -Keys $runSchema.checkpointRequired -Label "$($file.Name).checkpoint"
    }
    if ($run.schema -ne $runSchema.schema) {
        Add-CorpusError "$($file.Name) schema mismatch: expected $($runSchema.schema)"
    }
    if ($run.replayId -and -not $knownReplayIds.ContainsKey($run.replayId)) {
        Add-CorpusError "$($file.Name) references unknown replayId: $($run.replayId)"
    }
}

foreach ($file in $outcomeFiles) {
    $review = Load-JsonFile $file.FullName
    if (-not $review -or -not $outcomeSchema) { continue }
    Assert-HasKeys -Object $review -Keys $outcomeSchema.required -Label $file.Name
    if ($review.classifications) {
        Assert-HasKeys -Object $review.classifications -Keys $outcomeSchema.classificationRequired -Label "$($file.Name).classifications"
    }
    foreach ($checkpoint in @($review.checkpoints)) {
        Assert-HasKeys -Object $checkpoint -Keys $outcomeSchema.checkpointRequired -Label "$($file.Name).checkpoint"
        if (@($outcomeSchema.classificationAllowlist) -notcontains $checkpoint.classification) {
            Add-CorpusError "$($file.Name) has invalid checkpoint classification: $($checkpoint.classification)"
        }
    }
    if ($review.classifications -and @($outcomeSchema.classificationAllowlist) -notcontains $review.classifications.primary) {
        Add-CorpusError "$($file.Name) has invalid primary classification: $($review.classifications.primary)"
    }
    if ($review.replayId -and -not $knownReplayIds.ContainsKey($review.replayId)) {
        Add-CorpusError "$($file.Name) references unknown replayId: $($review.replayId)"
    }
}

$manifestPath = Join-Path $root "knowledge\corpus-manifest.json"
$manifest = if (Test-Path -LiteralPath $manifestPath) { Load-JsonFile $manifestPath }
if ($manifest -and $manifestSchema) {
    Assert-HasKeys -Object $manifest -Keys $manifestSchema.required -Label "corpus-manifest.json"
    if ($manifest.summary) {
        Assert-HasKeys -Object $manifest.summary -Keys $manifestSchema.summaryRequired -Label "corpus-manifest.json.summary"
        if ($manifest.summary.replays -ne $replayFiles.Count) {
            Add-CorpusError "Corpus manifest replay count does not match tests\\replays."
        }
        if ($manifest.summary.goldenLabels -ne $labelFiles.Count) {
            Add-CorpusError "Corpus manifest golden label count does not match tests\\golden."
        }
        if ($manifest.summary.replayResults -ne $runFiles.Count) {
            Add-CorpusError "Corpus manifest replay result count does not match tests\\replay-results."
        }
        if ($manifest.summary.outcomeReviews -ne $outcomeFiles.Count) {
            Add-CorpusError "Corpus manifest outcome review count does not match tests\\outcomes."
        }
        if ($manifest.summary.adversarialCases -ne $adversarialFiles.Count) {
            Add-CorpusError "Corpus manifest adversarial count does not match tests\\adversarial."
        }
    }
    foreach ($profile in @($manifest.profiles)) {
        Assert-HasKeys -Object $profile -Keys $manifestSchema.profileRequired -Label "corpus-manifest.json.profile"
    }
}

if ($scenarioMatrix) {
    $targetPerMap = [int]$scenarioMatrix.targetBaseScenariosPerMap
    foreach ($map in @($scenarioMatrix.maps)) {
        $profile = [string]$map.mapProfile
        $replayCount = @($replayFiles | Where-Object {
            $row = Load-JsonFile $_.FullName
            $row -and $row.map -and $row.map.profile -eq $profile
        }).Count
        $labelCount = @($labelFiles | Where-Object {
            $row = Load-JsonFile $_.FullName
            $row -and $row.mapProfile -eq $profile
        }).Count
        $outcomeCount = @($outcomeFiles | Where-Object {
            $row = Load-JsonFile $_.FullName
            $row -and $row.mapProfile -eq $profile
        }).Count
        $replayIds = @($replayFiles | ForEach-Object {
            $row = Load-JsonFile $_.FullName
            if ($row -and $row.map -and $row.map.profile -eq $profile) { $row.replayId }
        })
        $runCount = @($runRows | Where-Object { $replayIds -contains $_.replayId }).Count

        if ($replayCount -lt $targetPerMap) {
            Add-CorpusError "Profile $profile has fewer than $targetPerMap replay fixtures."
        }
        if ($labelCount -lt $targetPerMap) {
            Add-CorpusError "Profile $profile has fewer than $targetPerMap golden labels."
        }
        if ($runCount -lt $targetPerMap) {
            Add-CorpusError "Profile $profile has fewer than $targetPerMap replay results."
        }
        if ($outcomeCount -lt $targetPerMap) {
            Add-CorpusError "Profile $profile has fewer than $targetPerMap outcome reviews."
        }
    }
}

Write-Output "KWR corpus audit"
Write-Output "Replay fixtures: $($replayFiles.Count)"
Write-Output "Golden labels: $($labelFiles.Count)"
Write-Output "Replay results: $($runFiles.Count)"
Write-Output "Outcome reviews: $($outcomeFiles.Count)"
Write-Output "Adversarial cases: $($adversarialFiles.Count)"
Write-Output "Errors: $($errors.Count)"
foreach ($errorText in $errors) {
    Write-Error $errorText -ErrorAction Continue
}
if ($errors.Count -gt 0) { exit 1 }
Write-Output "CORPUS AUDIT PASSED"
