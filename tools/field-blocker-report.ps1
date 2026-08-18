[CmdletBinding()]
param(
    [string]$OutFile = "knowledge\field-blocker-report.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$outPath = Join-Path $root $OutFile
$toc = Get-Content -LiteralPath (Join-Path $root "KnomercyWarRoom.toc") -Raw
$version = [regex]::Match($toc, "## Version:\s*(.+)").Groups[1].Value.Trim()
$addonSource = Get-Content -LiteralPath (Join-Path $root "Core\Addon.lua") -Raw
$activeSchema = [int]([regex]::Match($addonSource, "KWR\.schemaVersion\s*=\s*(\d+)").Groups[1].Value)
$packageReportPath = Join-Path $root "knowledge\candidate-package-report.json"
$runtimePreflightPath = Join-Path $root "knowledge\runtime-preflight.json"
$packageReport = if (Test-Path -LiteralPath $packageReportPath) {
    Get-Content -LiteralPath $packageReportPath -Raw | ConvertFrom-Json
} else { $null }
$runtimePreflight = if (Test-Path -LiteralPath $runtimePreflightPath) {
    Get-Content -LiteralPath $runtimePreflightPath -Raw | ConvertFrom-Json
} else { $null }
$deploymentCertificationPath = Join-Path $root "knowledge\deployment-certification.json"
$deploymentCertification = if (Test-Path -LiteralPath $deploymentCertificationPath) {
    Get-Content -LiteralPath $deploymentCertificationPath -Raw | ConvertFrom-Json
} else { $null }
$retailCertificationPath = Join-Path $root "knowledge\retail-field-certification.json"
$retailCertification = if (Test-Path -LiteralPath $retailCertificationPath) {
    Get-Content -LiteralPath $retailCertificationPath -Raw | ConvertFrom-Json
} else { $null }
$attestationPath = Join-Path $root "knowledge\field-verification-attestation.json"
$fieldAttestation = if (Test-Path -LiteralPath $attestationPath) {
    Get-Content -LiteralPath $attestationPath -Raw | ConvertFrom-Json
} else { $null }
$fieldAttestationPassed = $fieldAttestation -and
    $fieldAttestation.result -eq 'PASS' -and
    $fieldAttestation.candidateVersion -eq $version -and
    [int]$fieldAttestation.completedBattlegrounds -ge 5 -and
    @($fieldAttestation.clearedGates).Count -ge 4
$attestationCandidateBound = $fieldAttestation -and
    $fieldAttestation.candidateVersion -eq $version
$releaseRiskAuthorized = $fieldAttestation -and
    $fieldAttestation.result -eq 'OWNER_AUTHORIZED_RELEASE_RISK' -and
    $attestationCandidateBound -and
    [int]$fieldAttestation.completedBattlegrounds -ge 5 -and
    @($fieldAttestation.clearedGates).Count -ge 4
$retailBinding = $retailCertification -and
    $retailCertification.binding.status -eq 'BOUND' -and
    $retailCertification.candidateVersion -eq $version -and
    [int]$retailCertification.candidateSchema -eq $activeSchema
$observedStabilityFailures = if ($retailCertification) {
    if ($null -ne $retailCertification.summary.observedStabilityFailedMatches) {
        [int]$retailCertification.summary.observedStabilityFailedMatches
    } else {
        [int]$retailCertification.summary.stabilityFailedMatches
    }
} else { 0 }
$boundStabilityFailures = if ($retailBinding) {
    [int]$retailCertification.summary.stabilityFailedMatches
} else { 0 }
$deploymentCertified = $deploymentCertification -and
    $deploymentCertification.candidateVersion -eq $version -and
    $deploymentCertification.result -eq 'PASS' -and
    $packageReport -and
    $deploymentCertification.commander.missing -eq 0 -and
    $deploymentCertification.commander.changed -eq 0 -and
    $deploymentCertification.commander.extra -eq 0 -and
    $deploymentCertification.commander.sha256 -eq $packageReport.distributionArtifact.sha256 -and
    $deploymentCertification.commander.packageDigest -eq $packageReport.sourceManifest.distributionDigest -and
    $deploymentCertification.sentinel.missing -eq 0 -and
    $deploymentCertification.sentinel.changed -eq 0 -and
    $deploymentCertification.sentinel.extra -eq 0 -and
    $deploymentCertification.sentinel.sha256 -eq $packageReport.sentinelArtifact.sha256 -and
    $deploymentCertification.sentinel.packageDigest -eq $packageReport.sourceManifest.sentinelDigest -and
    $deploymentCertification.upgradeProof.savedVariablesMigrationMatrix -eq 'PASS' -and
    $deploymentCertification.upgradeProof.futureSchemaReadOnlyCompatibility -eq 'PASS'
$offlineGatePassed = $packageReport -and
    $packageReport.candidateVersion -eq $version -and
    $packageReport.packageAudit.result -eq "PASS" -and
    $packageReport.environmentCertification.packageAuditInThisWorkspace -eq "CERTIFIED_IN_WORKSPACE" -and
    $runtimePreflight -and $runtimePreflight.candidateVersion -eq $version -and
    $runtimePreflight.packageAuditReady -eq $true

$report = [ordered]@{
    schema = "kwr-field-blocker-report"
    schemaVersion = 1
    generatedAt = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
    candidateVersion = $version
    blockingDefects = @(
        [ordered]@{
            id = "LIVE-TEAM-TRUTH"
            priority = "P1"
            status = if ($offlineGatePassed) { "LIVE_ONLY" } else { "OFFLINE_OPEN" }
            offlineStatus = if ($offlineGatePassed) { "PASS" } else { "BLOCKED" }
            title = "Expanded Team health and specialization provenance"
            liveProofNeeded = "one live battleground screenshot proving expanded Team health plus compact/expanded HIST agreement"
            bestMap = "TWINPEAKS"
            bestSession = "TP-TEAM-TRUTH"
        },
        [ordered]@{
            id = "LIVE-STABILITY"
            priority = "P1"
            # A candidate-bound failed review is a current confirmed defect.
            # Older unbound AAR rows establish why this live gate exists, but
            # cannot claim a defect in the newly deployed candidate.
            status = if ($boundStabilityFailures -gt 0) { "CONFIRMED_DEFECT" }
                elseif ($observedStabilityFailures -gt 0) { "HISTORICAL_UNBOUND_FAILURE" }
                elseif ($offlineGatePassed) { "LIVE_ONLY" } else { "OFFLINE_OPEN" }
            offlineStatus = if ($offlineGatePassed) { "PASS" } else { "BLOCKED" }
            title = "Flag-map command churn and AAR stability reporting"
            liveProofNeeded = "one complete clean flag match with /kwr verify, /kwr perf, and AAR showing stability pass"
            bestMap = "TWINPEAKS"
            bestSession = "TP-STABILITY"
        },
        [ordered]@{
            id = "LIVE-CARRIER-TARGET"
            priority = "P1"
            status = if ($offlineGatePassed) { "LIVE_ONLY" } else { "OFFLINE_OPEN" }
            offlineStatus = if ($offlineGatePassed) { "PASS" } else { "BLOCKED" }
            title = "Raw flag-event prose entering the command-target path"
            liveProofNeeded = "one carrier state-change capture showing canonical route/carrier target instead of prose"
            bestMap = "TWINPEAKS"
            bestSession = "TP-CARRIER-TARGET"
        },
        [ordered]@{
            id = "LIVE-READABILITY"
            priority = "P2"
            status = "OPEN"
            title = "Supported-resolution readability remains open"
            liveProofNeeded = "screenshots at supported scale showing no meaningful clipping across command center tabs"
            bestMap = "TWINPEAKS"
            bestSession = "TP-READABILITY"
        }
    )
    recommendedSessions = @(
        [ordered]@{
            sessionId = "TP-TEAM-TRUTH"
            purpose = "clear expanded Team trust defects first"
            maps = @("TWINPEAKS")
            clears = @("LIVE-TEAM-TRUTH")
        },
        [ordered]@{
            sessionId = "TP-STABILITY"
            purpose = "clear flag-match stability and AAR semantics"
            maps = @("TWINPEAKS", "WSG")
            clears = @("LIVE-STABILITY")
        },
        [ordered]@{
            sessionId = "TP-CARRIER-TARGET"
            purpose = "clear canonical flag command-target behavior during carrier events"
            maps = @("TWINPEAKS", "WSG")
            clears = @("LIVE-CARRIER-TARGET")
        },
        [ordered]@{
            sessionId = "RBG-MAP-CERT-1"
            purpose = "begin broader map-family live certification after current P1 blockers are cleared"
            maps = @("ARATHI", "GILNEAS", "DEEPWIND", "EOTS")
            clears = @("map-family live proof")
        },
        [ordered]@{
            sessionId = "RBG-MAP-CERT-2"
            purpose = "finish broader map-family live certification after current P1 blockers are cleared"
            maps = @("TEMPLE", "SILVERSHARD", "DEEPHAUL", "SEETHING")
            clears = @("map-family live proof")
        }
    )
    liveOnlyGates = @(
        if (-not $deploymentCertified) { "exact hashed package install and upgrade proof" }
        "taint and blocked-action safety proof",
        "lifecycle stability proof",
        "field performance budgets",
        "map-family battlefield proof",
        "evidence-backed decision quality"
    )
    offlineGate = [ordered]@{
        status = if ($offlineGatePassed) { "PASS" } else { "BLOCKED" }
        evidence = @(
            "knowledge/candidate-package-report.json",
            "knowledge/runtime-preflight.json"
        )
    }
    deploymentGate = [ordered]@{
        status = if ($deploymentCertified) { 'PASS' } else { 'BLOCKED' }
        evidence = 'knowledge/deployment-certification.json'
    }
    retailEvidenceGate = [ordered]@{
        status = if ($retailBinding -and $retailCertification.result -eq 'PASS') {
            'PASS'
        } else { 'BLOCKED' }
        binding = if ($retailCertification) {
            $retailCertification.binding.status
        } else { 'MISSING' }
        completedMatches = if ($retailCertification) {
            [int]$retailCertification.summary.completedMatches
        } else { 0 }
        stabilityFailedMatches = $observedStabilityFailures
        evidence = 'knowledge/retail-field-certification.json'
    }
}

if ($fieldAttestationPassed -or ($releaseRiskAuthorized -and $observedStabilityFailures -eq 0)) {
    # The owner has confirmed the live sessions, but the read-only journal did
    # not retain candidate-bound rows. Keep that instrumentation debt visible
    # without retaining the completed field gates as release blockers.
    $report.blockingDefects = @()
    $report.recommendedSessions = @()
    $report.liveOnlyGates = @(
        if (-not $deploymentCertified) { "exact hashed package install and upgrade proof" }
        "refinement: candidate-bound SavedVariables telemetry import"
        "refinement: KWR-251 ten-client Sentinel transport safety/value proof"
        "refinement: official 12.1 PvP tuning review"
    )
    $report.retailEvidenceGate = [ordered]@{
        status = if ($fieldAttestationPassed) { 'PASS' } else { 'AUTHORIZED_WITH_UNVERIFIED_EVIDENCE' }
        binding = if ($fieldAttestationPassed) { 'OWNER_ATTESTED' } else { 'OWNER_AUTHORIZED_UNVERIFIED' }
        completedMatches = [int]$fieldAttestation.completedBattlegrounds
        stabilityFailedMatches = 0
        evidence = 'knowledge/field-verification-attestation.json'
    }
    if ($releaseRiskAuthorized) {
        # The owner accepted the remaining package-audit automation delay for
        # this compatibility release. Preserve the exact manifest deployment
        # receipt and source smoke evidence as the release record, while
        # leaving an explicit refinement item rather than fabricating a PASS.
        $report.offlineGate = [ordered]@{
            status = 'AUTHORIZED_WITH_SOURCE_SMOKE_AND_MANIFEST_DEPLOYMENT'
            evidence = @(
                'knowledge/runtime-preflight.json',
                'knowledge/deployment-certification.json'
            )
        }
        $report.deploymentGate = [ordered]@{
            status = if ($deploymentCertified) { 'PASS' } else { 'AUTHORIZED_PENDING_RECEIPT_REVIEW' }
            evidence = 'knowledge/deployment-certification.json'
        }
    }
}
$report.fieldAttestation = [ordered]@{
    status = if ($fieldAttestationPassed) { 'PASS' } elseif ($releaseRiskAuthorized) { 'AUTHORIZED' } else { 'MISSING' }
    evidence = if ($fieldAttestationPassed -or $releaseRiskAuthorized) {
        'knowledge/field-verification-attestation.json'
    } else { $null }
}

$json = $report | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText($outPath, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))

Write-Output "KWR field blocker report"
Write-Output "Candidate: $version"
Write-Output "Blocking defects: $(@($report.blockingDefects).Count)"
Write-Output "Recommended sessions: $(@($report.recommendedSessions).Count)"
Write-Output "Output: $outPath"
