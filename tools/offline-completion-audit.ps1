[CmdletBinding()]
param(
    [string]$OutFile = "knowledge\offline-completion-audit.json",
    [string]$SourceCertificationReceiptPath = ""
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$outPath = Join-Path $root $OutFile
$toc = Get-Content -LiteralPath (Join-Path $root "KnomercyWarRoom.toc") -Raw
$version = [regex]::Match($toc, "## Version:\s*(.+)").Groups[1].Value.Trim()
$readiness = Get-Content -LiteralPath (Join-Path $root "knowledge\field-test-readiness.json") -Raw | ConvertFrom-Json
$blockers = Get-Content -LiteralPath (Join-Path $root "knowledge\field-blocker-report.json") -Raw | ConvertFrom-Json
$candidatePackage = Get-Content -LiteralPath (Join-Path $root "knowledge\candidate-package-report.json") -Raw | ConvertFrom-Json
$runtimePreflight = Get-Content -LiteralPath (Join-Path $root "knowledge\runtime-preflight.json") -Raw | ConvertFrom-Json
$sourceCertification = [ordered]@{
    result = 'UNAVAILABLE'
    receipt = $null
    meaning = 'A source-suite receipt is separate from clean-source/public-release eligibility.'
}
if ($SourceCertificationReceiptPath) {
    $receiptPath = if ([IO.Path]::IsPathRooted($SourceCertificationReceiptPath)) {
        [IO.Path]::GetFullPath($SourceCertificationReceiptPath)
    } else {
        Join-Path $root $SourceCertificationReceiptPath
    }
    if (Test-Path -LiteralPath $receiptPath -PathType Leaf) {
        $receipt = Get-Content -LiteralPath $receiptPath -Raw
        $sourceCertification.receipt = $receiptPath
        $sourceCertification.result = if ($receipt -match '(?m)^KWR OFFLINE SOURCE CERTIFICATION PASS\s*$') {
            'PASS'
        } else {
            'FAIL_OR_INCOMPLETE'
        }
    }
}
$offlinePrepared = $blockers.offlineGate.status -eq 'PASS' -and
    $candidatePackage.candidateVersion -eq $version -and
    $runtimePreflight.candidateVersion -eq $version -and
    $readiness.offlineStatus.candidateSourceBound -eq $true -and
    $readiness.offlineStatus.candidateArtifactVerified -eq $true -and
    $readiness.offlineStatus.validatePassed -eq $true -and
    $readiness.offlineStatus.knowledgeAuditPassed -eq $true -and
    $readiness.offlineStatus.corpusAuditPassed -eq $true -and
    $readiness.offlineStatus.decisionBenchmarkPassed -eq $true
$fieldTestingPrepared = $offlinePrepared -and $blockers.deploymentGate.status -eq 'PASS'
$remainingBlockers = @(
    $blockers.blockingDefects | ForEach-Object { $_.id }
) + @($blockers.liveOnlyGates)

$report = [ordered]@{
    schema = "kwr-offline-completion-audit"
    schemaVersion = 1
    generatedAt = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
    candidateVersion = $version
    offlinePrepared = $offlinePrepared
    fieldTestingPrepared = $fieldTestingPrepared
    remainingOfflineBlockers = @($readiness.offlineStatus.eligibilityBlockers)
    statusMeaning = 'Full clean-source release eligibility. A separately authorized diagnostic field install is recorded in its own deployment receipt.'
    offlineEvidence = [ordered]@{
        sourceCertification = $sourceCertification
        supportedMaps = $readiness.offlineStatus.supportedMaps
        baseScenarios = $readiness.offlineStatus.baseScenarios
        reviewedCorpus = $readiness.offlineStatus.reviewedCorpus
        adversarialCases = $readiness.offlineStatus.adversarialCases
        reviewedScenarioCalibration = $readiness.offlineStatus.reviewedScenarioCalibration
        adversarialScenarioCalibration = $readiness.offlineStatus.adversarialScenarioCalibration
        candidatePackageReportPresent = $true
        runtimePreflightPresent = $true
        packageAuditReady = [bool]$runtimePreflight.packageAuditReady
        packageAuditWorkspaceStatus = $candidatePackage.environmentCertification.packageAuditInThisWorkspace
        # These retain legacy names but are the combined clean-source/package
        # eligibility gate, not a statement that the individual source suites
        # were not executed. See sourceCertification above for that receipt.
        cleanEligibilityValidatePassed = $readiness.offlineStatus.validatePassed
        cleanEligibilityKnowledgeAuditPassed = $readiness.offlineStatus.knowledgeAuditPassed
        cleanEligibilityCorpusAuditPassed = $readiness.offlineStatus.corpusAuditPassed
        cleanEligibilityDecisionBenchmarkPassed = $readiness.offlineStatus.decisionBenchmarkPassed
    }
    remainingLiveOnlyBlockers = @($remainingBlockers | Select-Object -Unique)
    environmentLimits = @(
        "Lua, LuaJIT, and Fengari are not directly on PATH in this Codex environment.",
        "The repository Lua runner discovers the readable cached Node and Fengari runtime without changing PATH.",
        "Live Retail behavior, secure-action proof, and field performance remain external to this workspace."
    )
}

$json = $report | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText($outPath, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))

Write-Output "KWR offline completion audit"
Write-Output "Candidate: $version"
Write-Output "Offline prepared: $($report.offlinePrepared)"
Write-Output "Field testing prepared: $($report.fieldTestingPrepared)"
Write-Output "Output: $outPath"
