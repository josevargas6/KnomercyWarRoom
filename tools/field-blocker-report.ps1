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
            id = "KWR-032"
            priority = "P1"
            status = if ($offlineGatePassed) { "LIVE_ONLY" } else { "OFFLINE_OPEN" }
            offlineStatus = if ($offlineGatePassed) { "PASS" } else { "BLOCKED" }
            title = "Expanded Team health and specialization provenance"
            liveProofNeeded = "one live battleground screenshot proving expanded Team health plus compact/expanded HIST agreement"
            bestMap = "TWINPEAKS"
            bestSession = "TP-TEAM-TRUTH"
        },
        [ordered]@{
            id = "KWR-033"
            priority = "P1"
            status = if ($offlineGatePassed) { "LIVE_ONLY" } else { "OFFLINE_OPEN" }
            offlineStatus = if ($offlineGatePassed) { "PASS" } else { "BLOCKED" }
            title = "Flag-map command churn and AAR stability reporting"
            liveProofNeeded = "one complete clean flag match with /kwr verify, /kwr perf, and AAR showing stability pass"
            bestMap = "TWINPEAKS"
            bestSession = "TP-STABILITY"
        },
        [ordered]@{
            id = "KWR-034"
            priority = "P1"
            status = if ($offlineGatePassed) { "LIVE_ONLY" } else { "OFFLINE_OPEN" }
            offlineStatus = if ($offlineGatePassed) { "PASS" } else { "BLOCKED" }
            title = "Raw flag-event prose entering the command-target path"
            liveProofNeeded = "one carrier state-change capture showing canonical route/carrier target instead of prose"
            bestMap = "TWINPEAKS"
            bestSession = "TP-CARRIER-TARGET"
        },
        [ordered]@{
            id = "TP-D03"
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
            clears = @("KWR-032")
        },
        [ordered]@{
            sessionId = "TP-STABILITY"
            purpose = "clear flag-match stability and AAR semantics"
            maps = @("TWINPEAKS", "WSG")
            clears = @("KWR-033")
        },
        [ordered]@{
            sessionId = "TP-CARRIER-TARGET"
            purpose = "clear canonical flag command-target behavior during carrier events"
            maps = @("TWINPEAKS", "WSG")
            clears = @("KWR-034")
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
        "exact hashed package install and upgrade proof",
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
}

$json = $report | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText($outPath, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))

Write-Output "KWR field blocker report"
Write-Output "Candidate: $version"
Write-Output "Blocking defects: $(@($report.blockingDefects).Count)"
Write-Output "Recommended sessions: $(@($report.recommendedSessions).Count)"
Write-Output "Output: $outPath"
