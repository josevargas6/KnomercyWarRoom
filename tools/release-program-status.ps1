[CmdletBinding()]
param(
    [string]$OutFile = 'knowledge\release-program-status.json',
    [string]$EvidenceCandidateVersion = '6.1.1-alpha.14',
    [string]$RecoveryReport = 'artifacts\source-recovery-accounting-20260912-r10.json',
    [string]$ParityReport = 'artifacts\replay-semantic-parity-r10-20260912.json',
    [string]$DiscrepancyReport = 'artifacts\replay-discrepancy-r10-20260912.json',
    [string]$AdjudicationReport = 'artifacts\replay-adjudication-review-r7-20260912.json',
    [string]$ReconciliationLedger = 'artifacts\release-source-reconciliation-20260912-r10.json'
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
function Read-Receipt([string]$Path) {
    $full = if ([IO.Path]::IsPathRooted($Path)) { $Path } else { Join-Path $root $Path }
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { return $null }
    return Get-Content -LiteralPath $full -Raw | ConvertFrom-Json
}
function Bool([object]$Value) { return $Value -eq $true }

$candidate = Read-Receipt 'knowledge\candidate-package-report.json'
$offline = Read-Receipt 'knowledge\offline-completion-audit.json'
$recovery = Read-Receipt $RecoveryReport
$parity = Read-Receipt $ParityReport
$discrepancy = Read-Receipt $DiscrepancyReport
$adjudication = Read-Receipt $AdjudicationReport
$reconciliation = Read-Receipt $ReconciliationLedger
$packageAudit = if ($candidate -and $candidate.packageAudit -and $candidate.packageAudit.path) {
    Read-Receipt ([string]$candidate.packageAudit.path)
} else { $null }
$dirty = @(& git -C $root status --porcelain)
$evidenceBound = $candidate -and $candidate.candidateVersion -eq $EvidenceCandidateVersion
$reconciliationPass = $evidenceBound -and $reconciliation -and $reconciliation.summary -and `
    $reconciliation.summary.match -gt 0 -and $reconciliation.summary.changed -eq 0 `
    -and $reconciliation.summary.installedOnly -eq 0
$primaryPass = $evidenceBound -and $discrepancy -and $discrepancy.summary.total -gt 0 `
    -and $discrepancy.summary.primary -eq $discrepancy.summary.total `
    -and $discrepancy.summary.fallback -eq 0 -and $discrepancy.summary.unmatched -eq 0 `
    -and $discrepancy.summary.forbidden -eq 0

$stages = @(
    [ordered]@{ id='KWR-281-source-reconciliation'; status=if ($reconciliationPass) {'PASS'} else {'OPEN'}; evidence=$ReconciliationLedger },
    [ordered]@{ id='KWR-295-source-package-parity'; status=if ($evidenceBound -and (Bool $parity.pass)) {'PASS'} else {'OPEN'}; evidence=$ParityReport },
    [ordered]@{ id='KWR-295-strict-primary'; status=if ($primaryPass) {'PASS'} else {'OPEN'}; evidence=$DiscrepancyReport },
    [ordered]@{ id='KWR-295-named-adjudications'; status=if ($evidenceBound -and (Bool $adjudication.summary.complete)) {'PASS'} else {'OPEN'}; evidence=$AdjudicationReport },
    [ordered]@{ id='OVR-22-package-audit'; status=if ($packageAudit -and $packageAudit.result -eq 'PASS') {'PASS'} else {'OPEN'}; evidence=if ($candidate) {$candidate.packageAudit.path} else {$null} },
    [ordered]@{ id='OVR-22-clean-provenance'; status=if ($dirty.Count -eq 0) {'PASS'} else {'OPEN'}; evidence='git status --porcelain' },
    [ordered]@{ id='offline-release-eligibility'; status=if (Bool $offline.offlinePrepared) {'PASS'} else {'OPEN'}; evidence='knowledge/offline-completion-audit.json' }
)
foreach ($index in 0..12) {
    $package = 'P{0:D2}' -f $index
    # Each P00-P12 specification now contains source-bound implementation or
    # capture-tooling evidence.  IN_PROGRESS is intentionally not a pass: the
    # package-specific acceptance and external review gates still control that.
    $implemented = $index -ge 0 -and $index -le 12
    $packageStatus = if ($package -eq 'P00' -and $evidenceBound -and (Bool $recovery.summary.complete)) {'PASS'} elseif ($implemented) {'IN_PROGRESS'} else {'PLANNED'}
    $stages += [ordered]@{
        id = ('KWR-297-' + $package)
        status = $packageStatus
        evidence = if ($package -eq 'P00') { $RecoveryReport } elseif ($implemented) { 'docs/tasks/kwr-297/' + $package + '-' + @{
            P01='facts-context-capabilities'; P02='objective-engines'; P03='routes-assignments-formation'; P04='tactical-alternatives'; P05='command-lifecycle-secure-ui'; P06='aar-outcomes-learning'; P07='performance-scheduling'; P08='memory-persistence-packaging'; P09='commander-ux'; P10='sentinel-protocol'; P11='replay-certification-release'; P12='field-quality-comparison'
        }[$package] + '.md' } else { 'docs/tasks/KWR-297-s-tier-completion-packages.md' }
    }
}
foreach ($id in @('KWR-297-P13/KWR-298', 'KWR-297-P14/KWR-299')) {
    $stages += [ordered]@{
        id = $id
        status = 'IN_PROGRESS'
        evidence = if ($id -match 'P13') {'docs/tasks/KWR-298-commander-callout-card-rebuild.md'} else {'docs/tasks/KWR-299-command-followthrough-feedback.md'}
    }
}
$report = [ordered]@{
    schema='kwr-release-program-status'; schemaVersion=1; generatedAt=[DateTime]::UtcNow.ToString('o')
    candidate=[ordered]@{ version=$candidate.candidateVersion; candidateID=$candidate.candidateID; distributionSha256=$candidate.distributionArtifact.sha256; buildDirectory=$candidate.buildOutputDirectory }
    evidenceBinding=[ordered]@{ candidateVersion=$EvidenceCandidateVersion; matchesCandidate=[bool]$evidenceBound; recovery=$RecoveryReport; parity=$ParityReport; discrepancy=$DiscrepancyReport; reconciliation=$ReconciliationLedger }
    stages=$stages
    strictReplay=if ($discrepancy) {$discrepancy.summary} else {$null}
    adjudications=if ($adjudication) {$adjudication.summary} else {$null}
    sourceInstallReconciliation=if ($reconciliation) {$reconciliation.summary} else {$null}
    dirtyWorktreeEntries=$dirty.Count
    releaseEligible=(@($stages | Where-Object status -ne 'PASS').Count -eq 0)
    policy='Diagnostic field readiness is separate from release eligibility. This report never converts missing tactical review, a dirty worktree, or unverified field evidence into a pass.'
}
$out = if ([IO.Path]::IsPathRooted($OutFile)) { $OutFile } else { Join-Path $root $OutFile }
[IO.Directory]::CreateDirectory((Split-Path -Parent $out)) | Out-Null
$report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $out -Encoding UTF8
Write-Output "KWR release program status: eligible=$($report.releaseEligible); open=$(@($stages | Where-Object status -ne 'PASS').Count)"
Write-Output "Output: $out"
