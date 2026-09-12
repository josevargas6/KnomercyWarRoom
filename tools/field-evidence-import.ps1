[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$CaptureFile,
    [Parameter(Mandatory = $true)][string]$CandidatePackageReport,
    [Parameter(Mandatory = $true)][string]$OutputFile,
    [string]$ExistingRecordsDirectory = ""
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
. (Join-Path $PSScriptRoot 'hash-utils.ps1')

function Resolve-KwrPath([string]$Path) {
    if ([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
    return Join-Path $root $Path
}
function Read-Json([string]$Path, [string]$Label) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "$Label is missing: $Path" }
    try { return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json }
    catch { throw "$Label is not valid JSON: $Path" }
}
function Require-Text([object]$Value, [string]$Label) {
    if ([string]::IsNullOrWhiteSpace([string]$Value)) { throw "Missing required capture field: $Label" }
    return [string]$Value
}

$capturePath = Resolve-KwrPath $CaptureFile
$reportPath = Resolve-KwrPath $CandidatePackageReport
$outputPath = Resolve-KwrPath $OutputFile
$capture = Read-Json $capturePath 'Capture'
$report = Read-Json $reportPath 'Candidate package report'
if ($report.schema -ne 'kwr-candidate-package-report' -or $report.schemaVersion -ne 1) {
    throw "Unsupported candidate package report: $reportPath"
}
$candidateID = Require-Text $capture.candidateID 'candidateID'
$mapKey = Require-Text $capture.mapKey 'mapKey'
$bracket = Require-Text $capture.bracket 'bracket'
$sessionID = Require-Text $capture.sessionID 'sessionID'
$clientBuild = Require-Text $capture.clientBuild 'clientBuild'
$capturedAt = Require-Text $capture.capturedAt 'capturedAt'
try { [DateTime]::Parse($capturedAt) | Out-Null } catch { throw 'capturedAt must be a timestamp.' }
$expectedCandidateID = if ($report.fieldEvidenceBinding.candidateID) {
    [string]$report.fieldEvidenceBinding.candidateID
} elseif ($report.candidateID) {
    [string]$report.candidateID
} else {
    # Backward-compatible path for historical package reports that predate the
    # runtime candidate ID field.
    [string]$report.fieldEvidenceBinding.candidateVersion
}
if ($candidateID -ne $expectedCandidateID) {
    throw "Capture candidateID does not match package report: $candidateID"
}
$archiveHash = Require-Text $report.fieldEvidenceBinding.distributionSha256 'distributionSha256'
if ($archiveHash -notmatch '^[A-Fa-f0-9]{64}$') { throw 'Package report has an invalid distribution SHA-256.' }
$artifactPath = Require-Text $report.distributionArtifact.path 'distributionArtifact.path'
$resolvedArtifact = Resolve-KwrPath $artifactPath
if (-not (Test-Path -LiteralPath $resolvedArtifact -PathType Leaf)) { throw "Candidate archive is missing: $resolvedArtifact" }
if ((Get-KwrFileSha256 -LiteralPath $resolvedArtifact) -ne $archiveHash.ToUpperInvariant()) {
    throw 'Candidate archive hash does not match the package report.'
}
$captureHash = Get-KwrFileSha256 -LiteralPath $capturePath
$recordID = '{0}:{1}:{2}' -f $candidateID, $sessionID, $captureHash
if ($ExistingRecordsDirectory) {
    $existingPath = Resolve-KwrPath $ExistingRecordsDirectory
    if (-not (Test-Path -LiteralPath $existingPath -PathType Container)) { throw "Existing records directory is missing: $existingPath" }
    foreach ($file in Get-ChildItem -LiteralPath $existingPath -Filter '*.field-evidence.json' -File) {
        $existing = Read-Json $file.FullName 'Existing evidence envelope'
        if ($existing.recordID -eq $recordID) { throw "Duplicate capture record: $recordID" }
        if ($existing.candidate -and $existing.candidate.archiveSha256 -and
            $existing.candidate.archiveSha256 -ne $archiveHash.ToUpperInvariant()) {
            throw "Mixed candidate archive hashes in evidence directory: $existingPath"
        }
        if ($existing.capture -and $existing.capture.sessionID -eq $sessionID -and
            $existing.capture.candidateID -eq $candidateID) {
            throw "Duplicate candidate/session capture: $candidateID / $sessionID"
        }
    }
}
$parent = Split-Path -Parent $outputPath
if (-not $parent -or -not (Test-Path -LiteralPath $parent -PathType Container)) { throw "Output parent must already exist: $parent" }
if (Test-Path -LiteralPath $outputPath) { throw "Refusing to overwrite evidence envelope: $outputPath" }
$envelope = [ordered]@{
    schema = 'kwr-field-evidence-envelope'; schemaVersion = 1
    recordID = $recordID; importedAtUtc = [DateTime]::UtcNow.ToString('o')
    policy = 'Raw capture remains unchanged. This envelope binds local JSON evidence to one verified package hash; it grants no field/release pass.'
    candidate = [ordered]@{ candidateID=$candidateID; archiveSha256=$archiveHash.ToUpperInvariant(); packageReportSha256=(Get-KwrFileSha256 -LiteralPath $reportPath); packageReport=$reportPath; archive=$resolvedArtifact }
    capture = [ordered]@{ captureSha256=$captureHash; rawPath=$capturePath; sessionID=$sessionID; mapKey=$mapKey; bracket=$bracket; clientBuild=$clientBuild; capturedAt=$capturedAt; roleContext=$capture.roleContext; observationCoverage=$capture.observationCoverage; capabilities=$capture.capabilities }
    status = 'UNREVIEWED_FIELD_EVIDENCE'
}
[IO.File]::WriteAllText($outputPath, (($envelope | ConvertTo-Json -Depth 10) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
Write-Output "KWR_FIELD_EVIDENCE_IMPORT_PASS record=$recordID output=$outputPath"
