[CmdletBinding()]
param(
    [string]$OutFile = "knowledge\field-blocker-report.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$outPath = Join-Path $root $OutFile
$toc = Get-Content -LiteralPath (Join-Path $root "KnomercyWarRoom.toc") -Raw
$version = [regex]::Match($toc, "## Version:\s*(.+)").Groups[1].Value.Trim()
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
$deploymentCertified = $deploymentCertification -and
    $deploymentCertification.candidateVersion -eq $version -and
    $deploymentCertification.result -eq 'PASS' -and
    $deploymentCertification.commander.missing -eq 0 -and
    $deploymentCertification.commander.changed -eq 0 -and
    $deploymentCertification.commander.extra -eq 0 -and
    $deploymentCertification.sentinel.missing -eq 0 -and
    $deploymentCertification.sentinel.changed -eq 0 -and
    $deploymentCertification.sentinel.extra -eq 0 -and
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
            status = if ($offlineGatePassed) { "LIVE_ONLY" } else { "OFFLINE_OPEN" }
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
}

$json = $report | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText($outPath, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))

Write-Output "KWR field blocker report"
Write-Output "Candidate: $version"
Write-Output "Blocking defects: $(@($report.blockingDefects).Count)"
Write-Output "Recommended sessions: $(@($report.recommendedSessions).Count)"
Write-Output "Output: $outPath"
