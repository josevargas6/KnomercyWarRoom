[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
. (Join-Path $PSScriptRoot 'hash-utils.ps1')
$temp = Join-Path ([IO.Path]::GetTempPath()) ("kwr-field-readiness-" + [guid]::NewGuid().ToString("N"))
try {
    New-Item -ItemType Directory -Force -Path $temp | Out-Null
    $version = ((Get-Content -LiteralPath (Join-Path $root "KnomercyWarRoom.toc") |
        Where-Object { $_ -match '^## Version:' }) -replace '^## Version:\s*', '').Trim()
    $packageReport = Join-Path $temp "package-report.json"
    [ordered]@{
        candidateVersion = $version
        packageAudit = [ordered]@{ result = "PASS" }
        environmentCertification = [ordered]@{ packageAuditInThisWorkspace = "CERTIFIED_IN_WORKSPACE" }
        # Deliberately absent: buildProvenance. A PASS report without a readable,
        # clean source binding must never authorize field readiness.
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $packageReport -Encoding UTF8
    $out = Join-Path $temp "field-readiness.json"
    & (Join-Path $PSScriptRoot "field-readiness-report.ps1") `
        -OutFile $out -CandidatePackageReportPath $packageReport
    if ($LASTEXITCODE -ne 0) { throw "Field-readiness report generation failed." }
    $report = Get-Content -LiteralPath $out -Raw | ConvertFrom-Json
    if ($report.offlineStatus.candidateSourceBound -ne $false) {
        throw "A package report without build provenance was treated as source-bound."
    }
    if ($report.offlineStatus.candidateArtifactVerified -ne $false) {
        throw "A package report without a matching distribution ZIP was treated as artifact-bound."
    }
    foreach ($gate in @("validatePassed", "knowledgeAuditPassed", "corpusAuditPassed", "decisionBenchmarkPassed")) {
        if ($report.offlineStatus.$gate -ne $false) {
            throw "Offline gate '$gate' passed without a clean, matching build provenance."
        }
    }
    if (-not [IO.Path]::IsPathRooted($out) -or -not (Test-Path -LiteralPath $out)) {
        throw "Field-readiness report did not honor an absolute output path."
    }
    # External archives/provenance must be usable without pretending a dirty
    # build is release-eligible. These fixture files never become real receipts.
    $fixtureArchive = Join-Path $temp 'external.zip'
    [IO.File]::WriteAllText($fixtureArchive, 'fixture archive bytes')
    $fixtureProvenance = Join-Path $temp 'provenance.json'
    @{ git = @{ available=$true; dirty=$true; commit=$report.offlineStatus.currentCommit } } |
        ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $fixtureProvenance -Encoding UTF8
    @{
        candidateVersion=$version
        distributionArtifact=@{path=$fixtureArchive;sha256=(Get-KwrFileSha256 -LiteralPath $fixtureArchive)}
        buildProvenance=@{path=$fixtureProvenance}
        packageAudit=@{result='PASS'}
        environmentCertification=@{packageAuditInThisWorkspace='CERTIFIED_IN_WORKSPACE'}
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $packageReport -Encoding UTF8
    & (Join-Path $PSScriptRoot 'field-readiness-report.ps1') -OutFile $out -CandidatePackageReportPath $packageReport
    $report = Get-Content -Raw $out | ConvertFrom-Json
    if (-not $report.offlineStatus.candidateArtifactVerified -or
        $report.offlineStatus.candidateSourceBound -or $report.offlineStatus.fullEligibilityPassed) {
        throw 'External path resolution or dirty-source eligibility failed.'
    }
    [IO.File]::AppendAllText($fixtureArchive, 'tamper')
    & (Join-Path $PSScriptRoot 'field-readiness-report.ps1') -OutFile $out -CandidatePackageReportPath $packageReport
    $report = Get-Content -Raw $out | ConvertFrom-Json
    if ($report.offlineStatus.candidateArtifactVerified) { throw 'Modified archive passed its old hash.' }
    Write-Output "KWR field-readiness report test passed"
} finally {
    $temporaryRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (-not [IO.Path]::GetFullPath($temp).StartsWith($temporaryRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Unexpected readiness test cleanup path.'
    }
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
