[CmdletBinding()]
param(
    [string]$OutFile = "knowledge\field-test-readiness.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$outPath = Join-Path $root $OutFile

$matrix = Get-Content -LiteralPath (Join-Path $root "knowledge\rbg-scenario-matrix.json") -Raw | ConvertFrom-Json
$manifest = Get-Content -LiteralPath (Join-Path $root "knowledge\corpus-manifest.json") -Raw | ConvertFrom-Json
$scenarioCalibration = Get-Content -LiteralPath (Join-Path $root "knowledge\scenario-calibration.json") -Raw | ConvertFrom-Json
$adversarialCalibration = Get-Content -LiteralPath (Join-Path $root "knowledge\scenario-adversarial-calibration.json") -Raw | ConvertFrom-Json
$runtimePreflightPath = Join-Path $root "knowledge\runtime-preflight.json"
$runtimePreflight = if (Test-Path -LiteralPath $runtimePreflightPath) {
    Get-Content -LiteralPath $runtimePreflightPath -Raw | ConvertFrom-Json
} else {
    $null
}
$toc = Get-Content -LiteralPath (Join-Path $root "KnomercyWarRoom.toc") -Raw
$version = [regex]::Match($toc, "## Version:\s*(.+)").Groups[1].Value.Trim()
$packageReportPath = Join-Path $root "knowledge\candidate-package-report.json"
$packageReport = if (Test-Path -LiteralPath $packageReportPath) {
    Get-Content -LiteralPath $packageReportPath -Raw | ConvertFrom-Json
} else { $null }
$offlineGatePassed = $packageReport -and
    $packageReport.candidateVersion -eq $version -and
    $packageReport.packageAudit.result -eq "PASS" -and
    $packageReport.environmentCertification.packageAuditInThisWorkspace -eq "CERTIFIED_IN_WORKSPACE"
$captureMatrixPath = Join-Path $root "docs\CANDIDATE_FIELD_CAPTURE_MATRIX_2026-07-29.md"
$captureMatrix = if (Test-Path -LiteralPath $captureMatrixPath) {
    Get-Content -LiteralPath $captureMatrixPath -Raw
} else {
    ""
}
$evidenceBaselineMatch = [regex]::Match($captureMatrix, '(?m)^Candidate:\s*(.+)$')
$evidenceBaselineRaw = $evidenceBaselineMatch.Groups[1].Value.Trim()
# The capture matrix is human-readable Markdown, but downstream automation
# needs only the semantic candidate version—not delimiters or revision notes.
$evidenceBaseline = [regex]::Match($evidenceBaselineRaw, '^`?([^`\s(]+)').Groups[1].Value.Trim()
if ([string]::IsNullOrWhiteSpace($evidenceBaseline)) {
    $evidenceBaseline = $version
}
$runtimeAvailable = $runtimePreflight `
    -and $runtimePreflight.packageAuditReady

$mapRows = New-Object System.Collections.Generic.List[object]
foreach ($map in @($matrix.maps)) {
    $scenarioIds = @($map.scenarios | ForEach-Object { $_.scenarioId })
    $reviewed = @($scenarioCalibration.scenarios | Where-Object { $_.mapKey -eq $map.mapKey })
    $adversarial = @($adversarialCalibration.scenarios | Where-Object { $_.mapKey -eq $map.mapKey })
    $reviewedCases = 0
    foreach ($row in $reviewed) { $reviewedCases += ($row.reviewedCases -as [int]) }
    $adversarialCases = 0
    foreach ($row in $adversarial) { $adversarialCases += ($row.adversarialCases -as [int]) }
    $mapRows.Add([ordered]@{
        mapKey = [string]$map.mapKey
        profile = [string]$map.mapProfile
        scenarioCount = @($map.scenarios).Count
        reviewedCases = $reviewedCases
        adversarialCases = $adversarialCases
        liveStatus = "LIVE REQUIRED"
        requiredLiveProof = @(
            "one clean opener capture",
            "one mid-match state change capture",
            "one recovery or pressure capture",
            "match-end scoreboard and AAR agreement",
            "/kwr verify and /kwr perf in the same session"
        )
    })
}

$report = [ordered]@{
    schema = "kwr-field-test-readiness"
    schemaVersion = 1
    generatedAt = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
    candidate = [ordered]@{
        addon = "Knomercy War Room"
        version = $version
        build = $version
        evidenceBaseline = $evidenceBaseline
        date = [DateTime]::UtcNow.ToString("yyyy-MM-dd")
    }
    offlineStatus = [ordered]@{
        supportedMaps = @($matrix.maps).Count
        baseScenarios = @($scenarioCalibration.scenarios).Count
        reviewedCorpus = ($manifest.summary.replays -as [int])
        adversarialCases = ($manifest.summary.adversarialCases -as [int])
        reviewedScenarioCalibration = @($scenarioCalibration.scenarios).Count
        adversarialScenarioCalibration = @($adversarialCalibration.scenarios).Count
        validatePassed = [bool]$offlineGatePassed
        knowledgeAuditPassed = [bool]$offlineGatePassed
        corpusAuditPassed = [bool]$offlineGatePassed
        decisionBenchmarkPassed = [bool]$offlineGatePassed
        deterministicLuaRuntimeAvailable = [bool]$runtimeAvailable
        gateEvidence = @(
            "knowledge/candidate-package-report.json",
            "knowledge/runtime-preflight.json"
        )
    }
    liveRequirements = [ordered]@{
        exactPackageRequired = $true
        requiredEvidence = @(
            "field-test log",
            "/kwr verify",
            "/kwr perf",
            "AAR export",
            "Lua error and taint result",
            "surface screenshots",
            "sanitized event export",
            "issue/task ID for every failure"
        )
        stopConditions = @(
            "Lua error",
            "taint or blocked action",
            "fabricated fact",
            "false high-confidence commit",
            "required reload",
            "identity merge",
            "unbounded history/work",
            "protected-assignment violation",
            "refresh above 10 ms hard maximum"
        )
        remainingLiveBlockers = @(
            "Retail lifecycle stability",
            "secure-action and taint proof",
            "field performance budgets",
            "supported-resolution readability proof",
            "map-family battlefield verification",
            "evidence-backed decision quality"
        )
    }
    maps = $mapRows
    blockingConditions = @(
        "No field certification without exact hashed package evidence.",
        "Any code, data, TOC, or package change invalidates affected live evidence.",
        "Offline readiness does not certify live behavior by itself."
    )
}

$json = $report | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText($outPath, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))

Write-Output "KWR field readiness report"
Write-Output "Maps: $(@($matrix.maps).Count)"
Write-Output "Scenarios: $(@($scenarioCalibration.scenarios).Count)"
Write-Output "Reviewed corpus: $($manifest.summary.replays)"
Write-Output "Adversarial cases: $($manifest.summary.adversarialCases)"
Write-Output "Output: $outPath"
