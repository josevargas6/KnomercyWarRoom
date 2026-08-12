[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$required = @(
    "Data\SourceRegistry.lua",
    "Data\PatchData.lua",
    "Data\RBGMapProfiles.lua",
    "Data\Capabilities.lua",
    "Data\Compositions.lua",
    "Data\BattlePlans.lua",
    "Data\Counters.lua",
    "Data\KnowledgeManifest.lua",
    "knowledge\README.md",
    "knowledge\patch-template.json",
    "knowledge\schemas\replay-schema.json",
    "knowledge\schemas\golden-label-schema.json",
    "knowledge\schemas\replay-run-result-schema.json",
    "knowledge\schemas\benchmark-report-schema.json",
    "knowledge\schemas\corpus-manifest-schema.json",
    "knowledge\schemas\outcome-review-schema.json",
    "knowledge\schemas\rbg-foundation-schema.json",
    "knowledge\schemas\rbg-scenario-matrix-schema.json",
    "knowledge\schemas\scenario-calibration-schema.json",
    "knowledge\schemas\scenario-adversarial-calibration-schema.json",
    "knowledge\schemas\scenario-expert-corpus-schema.json",
    "knowledge\schemas\season2-rbg-simulation-corpus-schema.json",
    "knowledge\schemas\runtime-preflight-schema.json",
    "knowledge\schemas\field-test-readiness-schema.json",
    "knowledge\schemas\field-blocker-report-schema.json",
    "knowledge\schemas\candidate-package-report-schema.json",
    "knowledge\schemas\offline-completion-audit-schema.json",
    "knowledge\corpus-manifest.json",
    "knowledge\rbg-foundation.json",
    "knowledge\rbg-scenario-matrix.json",
    "knowledge\scenario-calibration.json",
    "knowledge\scenario-adversarial-calibration.json",
    "knowledge\scenario-expert-corpus.json",
    "knowledge\season2-rbg-simulation-corpus.json",
    "knowledge\runtime-preflight.json",
    "knowledge\field-test-readiness.json",
    "knowledge\field-blocker-report.json",
    "knowledge\candidate-package-report.json",
    "knowledge\offline-completion-audit.json",
    "knowledge\fixtures\replay-template.json",
    "knowledge\fixtures\golden-label-template.json",
    "knowledge\fixtures\adversarial-replay-template.json",
    "knowledge\fixtures\outcome-review-template.json",
    "docs\FIELD_MACHINE_PREP_2026-07-29.md",
    "docs\CANDIDATE_PACKAGE_TRUTH_PACK_2026-07-29.md"
)

$errors = [System.Collections.Generic.List[string]]::new()
foreach ($relative in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $relative))) {
        $errors.Add("Missing knowledge artifact: $relative")
    }
}

$patchSource = Get-Content -LiteralPath (Join-Path $root "Data\PatchData.lua") -Raw
$tocSource = Get-Content -LiteralPath (Join-Path $root "KnomercyWarRoom.toc") -Raw
$interface = [regex]::Match($tocSource, "## Interface:\s*(\d+)").Groups[1].Value
if ($patchSource -notmatch [regex]::Escape("interface = $interface")) {
    $errors.Add("Active patch data does not match TOC interface $interface.")
}
if ($patchSource -notmatch 'officialHotfixReviewed\s*=\s*"\d{4}-\d{2}-\d{2}"') {
    $errors.Add("Active patch pack has no dated official hotfix review.")
}

$templatePath = Join-Path $root "knowledge\patch-template.json"
try {
    $template = Get-Content -LiteralPath $templatePath -Raw | ConvertFrom-Json
    if ($null -eq $template.apiChanges -or $null -eq $template.gameplayChanges) {
        $errors.Add("Patch template does not separate API changes from gameplay changes.")
    }
    if (($template.capabilityCategoryReview.minimumSignals -lt 3) -or
        ($template.capabilityCategoryReview.minimumBattlefieldEffects -lt 3)) {
        $errors.Add("Patch template capability review minimums are below three.")
    }
} catch {
    $errors.Add("Patch template JSON is invalid: $($_.Exception.Message)")
}

$planSource = Get-Content -LiteralPath (Join-Path $root "Data\BattlePlans.lua") -Raw
$supportedMaps = @("ARATHI","GILNEAS","DEEPWIND","EOTS","WSG","TWINPEAKS","TEMPLE","SILVERSHARD","DEEPHAUL","SEETHING")
foreach ($map in $supportedMaps) {
    if ($planSource -notmatch [regex]::Escape("$map = {")) {
        $errors.Add("No battle-plan family for $map.")
    }
}

$rbgProfilesSource = Get-Content -LiteralPath (Join-Path $root "Data\RBGMapProfiles.lua") -Raw
foreach ($map in $supportedMaps) {
    if ($rbgProfilesSource -notmatch [regex]::Escape("$map = {")) {
        $errors.Add("No all-RBG profile for $map.")
    }
}

$doctrineSource = Get-Content -LiteralPath (Join-Path $root "Data\DoctrineComparisons.lua") -Raw
if ($doctrineSource -notmatch 'local function appendAdvancedCoverage') {
    $errors.Add("Doctrine comparison library is missing advanced all-map branch expansion coverage.")
}

$sourceRegistry = Get-Content -LiteralPath (Join-Path $root "Data\SourceRegistry.lua") -Raw
foreach ($authority in @("LIVE","REFERENCE","META","EDITORIAL","RESEARCH","SIGNAL","LEARNED")) {
    if ($sourceRegistry -notmatch [regex]::Escape("authority = `"$authority`"")) {
        $errors.Add("Missing source authority tier: $authority.")
    }
}

$foundationSchemaPath = Join-Path $root "knowledge\schemas\rbg-foundation-schema.json"
$foundationPath = Join-Path $root "knowledge\rbg-foundation.json"
try {
    $foundationSchema = Get-Content -LiteralPath $foundationSchemaPath -Raw | ConvertFrom-Json
    $foundation = Get-Content -LiteralPath $foundationPath -Raw | ConvertFrom-Json
    foreach ($key in @($foundationSchema.required)) {
        if ($null -eq $foundation.PSObject.Properties[$key]) {
            $errors.Add("RBG foundation missing required field: $key")
        }
    }
    foreach ($key in @($foundationSchema.sharedRequired)) {
        if ($null -eq $foundation.shared.PSObject.Properties[$key]) {
            $errors.Add("RBG foundation shared block missing field: $key")
        }
    }
    if (@($foundation.maps).Count -ne $supportedMaps.Count) {
        $errors.Add("RBG foundation map count does not match supported map count.")
    }
    foreach ($mapKey in $supportedMaps) {
        $row = @($foundation.maps | Where-Object { $_.mapKey -eq $mapKey }) | Select-Object -First 1
        if ($null -eq $row) {
            $errors.Add("RBG foundation missing map row: $mapKey")
            continue
        }
        foreach ($key in @($foundationSchema.mapRequired)) {
            if ($null -eq $row.PSObject.Properties[$key]) {
                $errors.Add("RBG foundation map $mapKey missing field: $key")
            }
        }
        foreach ($key in @($foundationSchema.corpusMinimumRequired)) {
            if ($null -eq $row.corpusMinimum.PSObject.Properties[$key]) {
                $errors.Add("RBG foundation map $mapKey missing corpus minimum field: $key")
            }
        }
    }
} catch {
    $errors.Add("RBG foundation JSON is invalid: $($_.Exception.Message)")
}

$scenarioMatrixSchemaPath = Join-Path $root "knowledge\schemas\rbg-scenario-matrix-schema.json"
$scenarioMatrixPath = Join-Path $root "knowledge\rbg-scenario-matrix.json"
try {
    $scenarioSchema = Get-Content -LiteralPath $scenarioMatrixSchemaPath -Raw | ConvertFrom-Json
    $scenarioMatrix = Get-Content -LiteralPath $scenarioMatrixPath -Raw | ConvertFrom-Json
    foreach ($key in @($scenarioSchema.required)) {
        if ($null -eq $scenarioMatrix.PSObject.Properties[$key]) {
            $errors.Add("RBG scenario matrix missing required field: $key")
        }
    }
    foreach ($key in @($scenarioSchema.sharedRequired)) {
        if ($null -eq $scenarioMatrix.shared.PSObject.Properties[$key]) {
            $errors.Add("RBG scenario matrix shared block missing field: $key")
        }
    }
    if ($scenarioMatrix.targetBaseScenariosPerMap -lt 5) {
        $errors.Add("RBG scenario matrix targetBaseScenariosPerMap is below five.")
    }
    if (@($scenarioMatrix.maps).Count -ne $supportedMaps.Count) {
        $errors.Add("RBG scenario matrix map count does not match supported map count.")
    }
    foreach ($mapKey in $supportedMaps) {
        $row = @($scenarioMatrix.maps | Where-Object { $_.mapKey -eq $mapKey }) | Select-Object -First 1
        if ($null -eq $row) {
            $errors.Add("RBG scenario matrix missing map row: $mapKey")
            continue
        }
        foreach ($key in @($scenarioSchema.mapRequired)) {
            if ($null -eq $row.PSObject.Properties[$key]) {
                $errors.Add("RBG scenario matrix map $mapKey missing field: $key")
            }
        }
        if (@($row.scenarios).Count -lt $scenarioMatrix.targetBaseScenariosPerMap) {
            $errors.Add("RBG scenario matrix map $mapKey has fewer than target scenarios.")
        }
        foreach ($scenario in @($row.scenarios)) {
            foreach ($key in @($scenarioSchema.scenarioRequired)) {
                if ($null -eq $scenario.PSObject.Properties[$key]) {
                    $errors.Add("RBG scenario matrix map $mapKey has scenario missing field: $key")
                }
            }
        }
    }
} catch {
    $errors.Add("RBG scenario matrix JSON is invalid: $($_.Exception.Message)")
}

$scenarioCalibrationSchemaPath = Join-Path $root "knowledge\schemas\scenario-calibration-schema.json"
$scenarioCalibrationPath = Join-Path $root "knowledge\scenario-calibration.json"
try {
    $scenarioCalibrationSchema = Get-Content -LiteralPath $scenarioCalibrationSchemaPath -Raw | ConvertFrom-Json
    $scenarioCalibration = Get-Content -LiteralPath $scenarioCalibrationPath -Raw | ConvertFrom-Json
    foreach ($key in @($scenarioCalibrationSchema.required)) {
        if ($null -eq $scenarioCalibration.PSObject.Properties[$key]) {
            $errors.Add("Scenario calibration missing required field: $key")
        }
    }
    foreach ($key in @($scenarioCalibrationSchema.sharedRequired)) {
        if ($null -eq $scenarioCalibration.shared.PSObject.Properties[$key]) {
            $errors.Add("Scenario calibration shared block missing field: $key")
        }
    }
    $scenarioRows = @($scenarioCalibration.scenarios)
    $eligibleScenarioCount = @($scenarioMatrix.maps | ForEach-Object {
        @($_.scenarios | Where-Object { $_.seasonStatus -ne "PENDING_SEASON_REVIEW" }).Count
    } | Measure-Object -Sum).Sum
    $targetScenarioCount = [int]$eligibleScenarioCount
    if ($scenarioRows.Count -lt $targetScenarioCount) {
        $errors.Add("Scenario calibration covers fewer than $targetScenarioCount base scenarios.")
    }
    $mapRows = @($scenarioCalibration.maps)
    if ($mapRows.Count -ne $supportedMaps.Count) {
        $errors.Add("Scenario calibration map summary count does not match supported map count.")
    }
    foreach ($mapKey in $supportedMaps) {
        $mapRow = @($mapRows | Where-Object { $_.mapKey -eq $mapKey }) | Select-Object -First 1
        if ($null -eq $mapRow) {
            $errors.Add("Scenario calibration missing map summary for $mapKey.")
            continue
        }
        $eligibleForMap = [int](@($scenarioMatrix.maps | Where-Object { $_.mapKey -eq $mapKey } |
            ForEach-Object { @($_.scenarios | Where-Object { $_.seasonStatus -ne "PENDING_SEASON_REVIEW" }).Count } |
            Select-Object -First 1)[0])
        if (($mapRow.scenarios -as [int]) -lt $eligibleForMap) {
            $errors.Add("Scenario calibration map summary $mapKey has fewer reviewed scenarios than the active matrix.")
        }
        foreach ($phase in @("OPENING", "STABILIZE", "PRESSURE", "RECOVERY", "ENDGAME")) {
            if ($null -eq $mapRow.phaseSummaries.PSObject.Properties[$phase]) {
                $errors.Add("Scenario calibration map summary $mapKey missing phase summary $phase.")
            }
        }
    }
    foreach ($row in $scenarioRows) {
        foreach ($key in @($scenarioCalibrationSchema.scenarioRequired)) {
            if ($null -eq $row.PSObject.Properties[$key]) {
                $errors.Add("Scenario calibration row missing field: $key")
            }
        }
        if (($row.reviewedCases -as [int]) -lt 5) {
            $errors.Add("Scenario calibration row $($row.scenarioId) has fewer than five reviewed cases.")
        }
    }
} catch {
    $errors.Add("Scenario calibration JSON is invalid: $($_.Exception.Message)")
}

$scenarioAdversarialSchemaPath = Join-Path $root "knowledge\schemas\scenario-adversarial-calibration-schema.json"
$scenarioAdversarialPath = Join-Path $root "knowledge\scenario-adversarial-calibration.json"
try {
    $scenarioAdversarialSchema = Get-Content -LiteralPath $scenarioAdversarialSchemaPath -Raw | ConvertFrom-Json
    $scenarioAdversarial = Get-Content -LiteralPath $scenarioAdversarialPath -Raw | ConvertFrom-Json
    foreach ($key in @($scenarioAdversarialSchema.required)) {
        if ($null -eq $scenarioAdversarial.PSObject.Properties[$key]) {
            $errors.Add("Scenario adversarial calibration missing required field: $key")
        }
    }
    foreach ($key in @($scenarioAdversarialSchema.sharedRequired)) {
        if ($null -eq $scenarioAdversarial.shared.PSObject.Properties[$key]) {
            $errors.Add("Scenario adversarial calibration shared block missing field: $key")
        }
    }
    $scenarioRows = @($scenarioAdversarial.scenarios)
    $eligibleScenarioCount = @($scenarioMatrix.maps | ForEach-Object {
        @($_.scenarios | Where-Object { $_.seasonStatus -ne "PENDING_SEASON_REVIEW" }).Count
    } | Measure-Object -Sum).Sum
    $targetScenarioCount = [int]$eligibleScenarioCount
    if ($scenarioRows.Count -lt $targetScenarioCount) {
        $errors.Add("Scenario adversarial calibration covers fewer than $targetScenarioCount base scenarios.")
    }
    $mapRows = @($scenarioAdversarial.maps)
    if ($mapRows.Count -ne $supportedMaps.Count) {
        $errors.Add("Scenario adversarial calibration map summary count does not match supported map count.")
    }
    foreach ($mapKey in $supportedMaps) {
        $mapRow = @($mapRows | Where-Object { $_.mapKey -eq $mapKey }) | Select-Object -First 1
        if ($null -eq $mapRow) {
            $errors.Add("Scenario adversarial calibration missing map summary for $mapKey.")
            continue
        }
        $eligibleForMap = [int](@($scenarioMatrix.maps | Where-Object { $_.mapKey -eq $mapKey } |
            ForEach-Object { @($_.scenarios | Where-Object { $_.seasonStatus -ne "PENDING_SEASON_REVIEW" }).Count } |
            Select-Object -First 1)[0])
        if (($mapRow.scenarios -as [int]) -lt $eligibleForMap) {
            $errors.Add("Scenario adversarial calibration map summary $mapKey has fewer reviewed scenarios than the active matrix.")
        }
        foreach ($phase in @("OPENING", "STABILIZE", "PRESSURE", "RECOVERY", "ENDGAME")) {
            if ($null -eq $mapRow.phaseSummaries.PSObject.Properties[$phase]) {
                $errors.Add("Scenario adversarial calibration map summary $mapKey missing phase summary $phase.")
            }
        }
    }
    foreach ($row in $scenarioRows) {
        foreach ($key in @($scenarioAdversarialSchema.scenarioRequired)) {
            if ($null -eq $row.PSObject.Properties[$key]) {
                $errors.Add("Scenario adversarial calibration row missing field: $key")
            }
        }
        if (($row.adversarialCases -as [int]) -lt 1) {
            $errors.Add("Scenario adversarial calibration row $($row.scenarioId) has no adversarial case.")
        }
    }
} catch {
    $errors.Add("Scenario adversarial calibration JSON is invalid: $($_.Exception.Message)")
}

$scenarioExpertSchemaPath = Join-Path $root "knowledge\schemas\scenario-expert-corpus-schema.json"
$scenarioExpertPath = Join-Path $root "knowledge\scenario-expert-corpus.json"
try {
    $scenarioExpertSchema = Get-Content -LiteralPath $scenarioExpertSchemaPath -Raw | ConvertFrom-Json
    $scenarioExpert = Get-Content -LiteralPath $scenarioExpertPath -Raw | ConvertFrom-Json
    foreach ($key in @($scenarioExpertSchema.required)) {
        if ($null -eq $scenarioExpert.PSObject.Properties[$key]) {
            $errors.Add("Scenario expert corpus missing required field: $key")
        }
    }
    foreach ($key in @($scenarioExpertSchema.sharedRequired)) {
        if ($null -eq $scenarioExpert.shared.PSObject.Properties[$key]) {
            $errors.Add("Scenario expert corpus shared block missing field: $key")
        }
    }
    $scenarioRows = @($scenarioExpert.scenarios)
    $targetScenarioCount = @($supportedMaps).Count * [int]$scenarioMatrix.targetBaseScenariosPerMap
    if ($scenarioRows.Count -lt $targetScenarioCount) {
        $errors.Add("Scenario expert corpus covers fewer than $targetScenarioCount base scenarios.")
    }
    $mapRows = @($scenarioExpert.maps)
    if ($mapRows.Count -ne $supportedMaps.Count) {
        $errors.Add("Scenario expert corpus map summary count does not match supported map count.")
    }
    foreach ($mapKey in $supportedMaps) {
        $mapRow = @($mapRows | Where-Object { $_.mapKey -eq $mapKey }) | Select-Object -First 1
        if ($null -eq $mapRow) {
            $errors.Add("Scenario expert corpus missing map summary for $mapKey.")
            continue
        }
        if (($mapRow.scenarios -as [int]) -lt [int]$scenarioMatrix.targetBaseScenariosPerMap) {
            $errors.Add("Scenario expert corpus map summary $mapKey has too few scenarios.")
        }
        foreach ($phase in @("OPENING", "STABILIZE", "PRESSURE", "RECOVERY", "ENDGAME")) {
            if ($null -eq $mapRow.phaseSummaries.PSObject.Properties[$phase]) {
                $errors.Add("Scenario expert corpus map summary $mapKey missing phase summary $phase.")
            }
        }
    }
    foreach ($row in $scenarioRows) {
        if ($row.seasonStatus -eq "PENDING_SEASON_REVIEW") {
            continue
        }
        foreach ($key in @($scenarioExpertSchema.scenarioRequired)) {
            if ($null -eq $row.PSObject.Properties[$key]) {
                $errors.Add("Scenario expert corpus row missing field: $key")
            }
        }
        if (($row.reviewedLabels -as [int]) -lt 5) {
            $errors.Add("Scenario expert corpus row $($row.scenarioId) has fewer than five reviewed labels.")
        }
    }
} catch {
    $errors.Add("Scenario expert corpus JSON is invalid: $($_.Exception.Message)")
}

$runtimePreflightSchemaPath = Join-Path $root "knowledge\schemas\runtime-preflight-schema.json"
$runtimePreflightPath = Join-Path $root "knowledge\runtime-preflight.json"
try {
    $runtimePreflightSchema = Get-Content -LiteralPath $runtimePreflightSchemaPath -Raw | ConvertFrom-Json
    $runtimePreflight = Get-Content -LiteralPath $runtimePreflightPath -Raw | ConvertFrom-Json
    foreach ($key in @($runtimePreflightSchema.required)) {
        if ($null -eq $runtimePreflight.PSObject.Properties[$key]) {
            $errors.Add("Runtime preflight missing required field: $key")
        }
    }
    foreach ($key in @($runtimePreflightSchema.nodeRequired)) {
        if ($null -eq $runtimePreflight.node.PSObject.Properties[$key]) {
            $errors.Add("Runtime preflight node block missing field: $key")
        }
    }
    foreach ($key in @($runtimePreflightSchema.fengariRequired)) {
        if ($null -eq $runtimePreflight.fengari.PSObject.Properties[$key]) {
            $errors.Add("Runtime preflight fengari block missing field: $key")
        }
    }
    foreach ($key in @($runtimePreflightSchema.localLuaToolsRequired)) {
        if ($null -eq $runtimePreflight.localLuaTools.PSObject.Properties[$key]) {
            $errors.Add("Runtime preflight localLuaTools block missing field: $key")
        }
    }
    $activeVersion = [regex]::Match($tocSource, "## Version:\s*(.+)").Groups[1].Value.Trim()
    if ($runtimePreflight.candidateVersion -ne $activeVersion) {
        $errors.Add("Runtime preflight version does not match the active TOC version.")
    }
} catch {
    $errors.Add("Runtime preflight JSON is invalid: $($_.Exception.Message)")
}

$fieldReadinessSchemaPath = Join-Path $root "knowledge\schemas\field-test-readiness-schema.json"
$fieldReadinessPath = Join-Path $root "knowledge\field-test-readiness.json"
try {
    $fieldReadinessSchema = Get-Content -LiteralPath $fieldReadinessSchemaPath -Raw | ConvertFrom-Json
    $fieldReadiness = Get-Content -LiteralPath $fieldReadinessPath -Raw | ConvertFrom-Json
    foreach ($key in @($fieldReadinessSchema.required)) {
        if ($null -eq $fieldReadiness.PSObject.Properties[$key]) {
            $errors.Add("Field readiness report missing required field: $key")
        }
    }
    foreach ($key in @($fieldReadinessSchema.offlineStatusRequired)) {
        if ($null -eq $fieldReadiness.offlineStatus.PSObject.Properties[$key]) {
            $errors.Add("Field readiness offlineStatus missing field: $key")
        }
    }
    foreach ($key in @($fieldReadinessSchema.liveRequirementsRequired)) {
        if ($null -eq $fieldReadiness.liveRequirements.PSObject.Properties[$key]) {
            $errors.Add("Field readiness liveRequirements missing field: $key")
        }
    }
    foreach ($row in @($fieldReadiness.maps)) {
        foreach ($key in @($fieldReadinessSchema.mapRequired)) {
            if ($null -eq $row.PSObject.Properties[$key]) {
                $errors.Add("Field readiness map row missing field: $key")
            }
        }
    }
} catch {
    $errors.Add("Field readiness JSON is invalid: $($_.Exception.Message)")
}

$fieldBlockerSchemaPath = Join-Path $root "knowledge\schemas\field-blocker-report-schema.json"
$fieldBlockerPath = Join-Path $root "knowledge\field-blocker-report.json"
try {
    $fieldBlockerSchema = Get-Content -LiteralPath $fieldBlockerSchemaPath -Raw | ConvertFrom-Json
    $fieldBlocker = Get-Content -LiteralPath $fieldBlockerPath -Raw | ConvertFrom-Json
    foreach ($key in @($fieldBlockerSchema.required)) {
        if ($null -eq $fieldBlocker.PSObject.Properties[$key]) {
            $errors.Add("Field blocker report missing required field: $key")
        }
    }
    foreach ($row in @($fieldBlocker.blockingDefects)) {
        foreach ($key in @($fieldBlockerSchema.blockerRequired)) {
            if ($null -eq $row.PSObject.Properties[$key]) {
                $errors.Add("Field blocker row missing field: $key")
            }
        }
    }
    foreach ($row in @($fieldBlocker.recommendedSessions)) {
        foreach ($key in @($fieldBlockerSchema.sessionRequired)) {
            if ($null -eq $row.PSObject.Properties[$key]) {
                $errors.Add("Field blocker recommended session missing field: $key")
            }
        }
    }
} catch {
    $errors.Add("Field blocker report JSON is invalid: $($_.Exception.Message)")
}

$candidatePackageSchemaPath = Join-Path $root "knowledge\schemas\candidate-package-report-schema.json"
$candidatePackagePath = Join-Path $root "knowledge\candidate-package-report.json"
try {
    $candidatePackageSchema = Get-Content -LiteralPath $candidatePackageSchemaPath -Raw | ConvertFrom-Json
    $candidatePackage = Get-Content -LiteralPath $candidatePackagePath -Raw | ConvertFrom-Json
    foreach ($key in @($candidatePackageSchema.required)) {
        if ($null -eq $candidatePackage.PSObject.Properties[$key]) {
            $errors.Add("Candidate package report missing required field: $key")
        }
    }
    foreach ($key in @($candidatePackageSchema.artifactRequired)) {
        if ($null -eq $candidatePackage.distributionArtifact.PSObject.Properties[$key]) {
            $errors.Add("Candidate package distribution artifact missing field: $key")
        }
        if ($null -eq $candidatePackage.developerArtifact.PSObject.Properties[$key]) {
            $errors.Add("Candidate package developer artifact missing field: $key")
        }
    }
    foreach ($key in @($candidatePackageSchema.manifestRequired)) {
        if ($null -eq $candidatePackage.sourceManifest.PSObject.Properties[$key]) {
            $errors.Add("Candidate package source manifest missing field: $key")
        }
    }
    foreach ($key in @($candidatePackageSchema.reproducibilityRequired)) {
        if ($null -eq $candidatePackage.reproducibility.PSObject.Properties[$key]) {
            $errors.Add("Candidate package reproducibility missing field: $key")
        }
    }
    foreach ($key in @($candidatePackageSchema.environmentRequired)) {
        if ($null -eq $candidatePackage.environmentCertification.PSObject.Properties[$key]) {
            $errors.Add("Candidate package environment certification missing field: $key")
        }
    }
    foreach ($key in @($candidatePackageSchema.operatorPathsRequired)) {
        if ($null -eq $candidatePackage.operatorPaths.PSObject.Properties[$key]) {
            $errors.Add("Candidate package operator paths missing field: $key")
        }
    }
    foreach ($key in @($candidatePackageSchema.fieldBindingRequired)) {
        if ($null -eq $candidatePackage.fieldEvidenceBinding.PSObject.Properties[$key]) {
            $errors.Add("Candidate package field evidence binding missing field: $key")
        }
    }
    $activeVersion = [regex]::Match($tocSource, "## Version:\s*(.+)").Groups[1].Value.Trim()
    if ($candidatePackage.candidateVersion -ne $activeVersion) {
        $errors.Add("Candidate package report version does not match the active TOC version.")
    }
    if (-not $candidatePackage.distributionArtifact.sha256) {
        $errors.Add("Candidate package report is missing the distribution SHA256.")
    }
} catch {
    $errors.Add("Candidate package report JSON is invalid: $($_.Exception.Message)")
}

$offlineCompletionSchemaPath = Join-Path $root "knowledge\schemas\offline-completion-audit-schema.json"
$offlineCompletionPath = Join-Path $root "knowledge\offline-completion-audit.json"
try {
    $offlineCompletionSchema = Get-Content -LiteralPath $offlineCompletionSchemaPath -Raw | ConvertFrom-Json
    $offlineCompletion = Get-Content -LiteralPath $offlineCompletionPath -Raw | ConvertFrom-Json
    foreach ($key in @($offlineCompletionSchema.required)) {
        if ($null -eq $offlineCompletion.PSObject.Properties[$key]) {
            $errors.Add("Offline completion audit missing required field: $key")
        }
    }
    foreach ($key in @($offlineCompletionSchema.evidenceRequired)) {
        if ($null -eq $offlineCompletion.offlineEvidence.PSObject.Properties[$key]) {
            $errors.Add("Offline completion audit evidence missing field: $key")
        }
    }
} catch {
    $errors.Add("Offline completion audit JSON is invalid: $($_.Exception.Message)")
}

try {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "tools\season2-rbg-simulation-audit.ps1")
    if ($LASTEXITCODE -ne 0) { $errors.Add("Season 2 simulation corpus audit failed.") }
} catch {
    $errors.Add("Season 2 simulation corpus audit failed: $($_.Exception.Message)")
}

$deploymentCertificationPath = Join-Path $root "knowledge\deployment-certification.json"
try {
    $deploymentCertification = Get-Content -LiteralPath $deploymentCertificationPath -Raw | ConvertFrom-Json
    foreach ($key in @('schema', 'schemaVersion', 'candidateVersion', 'releaseTag', 'commander', 'sentinel', 'upgradeProof', 'result')) {
        if ($null -eq $deploymentCertification.PSObject.Properties[$key]) {
            $errors.Add("Deployment certification missing required field: $key")
        }
    }
    $activeVersion = [regex]::Match($tocSource, "## Version:\s*(.+)").Groups[1].Value.Trim()
    if ($deploymentCertification.candidateVersion -eq $activeVersion) {
        if ($deploymentCertification.result -ne 'PASS') {
            $errors.Add('Current-candidate deployment certification is not PASS.')
        }
        foreach ($product in @($deploymentCertification.commander, $deploymentCertification.sentinel)) {
            if ($product.missing -ne 0 -or $product.changed -ne 0 -or $product.extra -ne 0 -or -not $product.sha256) {
                $errors.Add('Deployment certification contains missing, changed, extra, or unhashed files.')
            }
        }
        if ($deploymentCertification.upgradeProof.savedVariablesMigrationMatrix -ne 'PASS' -or
            $deploymentCertification.upgradeProof.futureSchemaReadOnlyCompatibility -ne 'PASS') {
            $errors.Add('Deployment certification lacks upgrade and future-schema proof.')
        }
    }
} catch {
    $errors.Add("Deployment certification JSON is invalid: $($_.Exception.Message)")
}

$retailCertificationPath = Join-Path $root "knowledge\retail-field-certification.json"
try {
    $retailCertification = Get-Content -LiteralPath $retailCertificationPath -Raw | ConvertFrom-Json
    foreach ($key in @('schema', 'schemaVersion', 'candidateVersion', 'candidateSchema', 'source', 'binding', 'summary', 'matches', 'provenGates', 'missingGates', 'result')) {
        if ($null -eq $retailCertification.PSObject.Properties[$key]) {
            $errors.Add("Retail field certification missing required field: $key")
        }
    }
    if ($retailCertification.source.PSObject.Properties.Name -contains 'path') {
        $errors.Add('Retail field certification exposes a local SavedVariables path.')
    }
    if ($retailCertification.result -notin @('PASS', 'BLOCKED')) {
        $errors.Add('Retail field certification result is neither PASS nor BLOCKED.')
    }
    if ($retailCertification.binding.status -eq 'BOUND' -and
        (-not $retailCertification.binding.schemaMatches -or
         -not $retailCertification.binding.deploymentVersionMatches -or
         -not $retailCertification.binding.writtenAfterCertification)) {
        $errors.Add('Retail field certification claims BOUND without all binding conditions.')
    }
} catch {
    $errors.Add("Retail field certification JSON is invalid: $($_.Exception.Message)")
}

Write-Output "KWR knowledge audit"
Write-Output "Errors: $($errors.Count)"
foreach ($errorText in $errors) {
    Write-Error $errorText -ErrorAction Continue
}
if ($errors.Count -gt 0) { exit 1 }
Write-Output "KNOWLEDGE AUDIT PASSED"
