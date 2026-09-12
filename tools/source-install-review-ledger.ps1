[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ReviewPacket,
    [Parameter(Mandatory = $true)][string]$ReviewDirectory,
    [Parameter(Mandatory = $true)][string]$OutputFile,
    [switch]$RequireComplete
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
. (Join-Path $PSScriptRoot 'hash-utils.ps1')
function Resolve-KwrPath { param([Parameter(Mandatory = $true)][string]$Path) if ([IO.Path]::IsPathRooted($Path)) { [IO.Path]::GetFullPath($Path) } else { Join-Path $root $Path } }
function Get-KwrHash { param([Parameter(Mandatory = $true)][string]$Path) Get-KwrFileSha256 -LiteralPath $Path }

$packetPath = Resolve-KwrPath $ReviewPacket
$reviewPath = Resolve-KwrPath $ReviewDirectory
$outputPath = Resolve-KwrPath $OutputFile
if (-not (Test-Path -LiteralPath $packetPath -PathType Leaf)) { throw "Review packet not found: $packetPath" }
if (-not (Test-Path -LiteralPath $reviewPath -PathType Container)) { throw "Review directory not found: $reviewPath" }
$packet = Get-Content -LiteralPath $packetPath -Raw | ConvertFrom-Json
if ($packet.schema -ne 'kwr-source-install-review-packet' -or $packet.schemaVersion -ne 1) { throw "Unsupported review packet: $packetPath" }
$packetHash = Get-KwrHash $packetPath
$allowedDispositions = @('PRESERVE_SOURCE', 'MERGE_INSTALLED', 'REMOVE_SOURCE_ENTRY', 'REGENERATE_PROJECTION', 'DEFER')
$records = @{}
$invalid = [System.Collections.Generic.List[object]]::new()
foreach ($file in @(Get-ChildItem -LiteralPath $reviewPath -Filter '*.source-install-review.json' -File | Sort-Object Name)) {
    try {
        $record = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
        $key = "$($record.addon)|$($record.path)"
        if (-not $record.addon -or -not $record.path -or -not $record.reviewer -or -not $record.reviewer.id -or -not $record.reviewer.role -or -not $record.reviewedAt) { throw 'Missing addon/path/named reviewer/review timestamp.' }
        $reviewedAt = [DateTime]::MinValue
        if (-not [DateTime]::TryParse([string]$record.reviewedAt, [ref]$reviewedAt)) { throw 'Review timestamp is invalid.' }
        if ($record.packetSha256 -ne $packetHash) { throw 'Packet hash does not match.' }
        if (-not ($allowedDispositions -contains $record.disposition)) { throw "Unsupported disposition '$($record.disposition)'." }
        if (@($record.evidence).Count -lt 1) { throw 'At least one evidence item is required.' }
        if ($records.ContainsKey($key)) { throw "Duplicate review record for $key." }
        $expected = @($packet.entries | Where-Object { $_.addon -eq $record.addon -and $_.path -eq $record.path })
        if ($expected.Count -ne 1) { throw "Record does not identify exactly one packet entry: $key." }
        if ($record.sourceSha256 -ne $expected[0].sourceSha256 -or $record.installedSha256 -ne $expected[0].installedSha256) { throw 'Source or installed hash does not match packet.' }
        $records[$key] = [pscustomobject]@{ record = $record; path = $file.FullName }
    } catch {
        $invalid.Add([pscustomobject]@{ path = $file.FullName; reason = $_.Exception.Message })
    }
}

$rows = foreach ($entry in @($packet.entries | Sort-Object addon,path)) {
    $key = "$($entry.addon)|$($entry.path)"
    $review = $records[$key]
    $disposition = if ($review) { [string]$review.record.disposition } else { $null }
    [pscustomobject]@{
        addon = $entry.addon
        path = $entry.path
        reviewPriority = $entry.reviewPriority
        sourceSha256 = $entry.sourceSha256
        installedSha256 = $entry.installedSha256
        reviewStatus = if ($review) { if ($disposition -eq 'DEFER') { 'deferred' } else { 'reviewed' } } else { 'missing' }
        disposition = $disposition
        reviewer = if ($review) { $review.record.reviewer } else { $null }
        evidence = if ($review) { @($review.record.evidence) } else { @() }
        recordPath = if ($review) { $review.path } else { $null }
    }
}
$reviewed = @($rows | Where-Object reviewStatus -eq 'reviewed')
$deferred = @($rows | Where-Object reviewStatus -eq 'deferred')
$missing = @($rows | Where-Object reviewStatus -eq 'missing')
$report = [pscustomobject]@{
    schema = 'kwr-source-install-review-ledger-report'
    schemaVersion = 1
    generatedAt = [DateTime]::UtcNow.ToString('o')
    source = [pscustomobject]@{ packetPath = $packetPath; packetSha256 = $packetHash; ledgerToolSha256 = Get-KwrHash $PSCommandPath }
    policy = 'A review is valid only when it binds the packet and file hashes, names a reviewer and role, records a timestamp, cites evidence, and uses an allowed disposition. DEFER never closes a source/install reconciliation gate. This validator never copies, installs, deletes, or accepts code.'
    summary = [pscustomobject]@{ total = @($rows).Count; reviewed = $reviewed.Count; deferred = $deferred.Count; missing = $missing.Count; invalid = $invalid.Count; complete = ($missing.Count -eq 0 -and $deferred.Count -eq 0 -and $invalid.Count -eq 0) }
    invalidRecords = @($invalid)
    rows = @($rows)
}
$parent = Split-Path -Parent $outputPath
if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $outputPath -Encoding UTF8
Write-Output "KWR source/install review ledger"
Write-Output "Total=$($report.summary.total) reviewed=$($report.summary.reviewed) deferred=$($report.summary.deferred) missing=$($report.summary.missing) invalid=$($report.summary.invalid) complete=$($report.summary.complete)"
Write-Output "Report: $outputPath"
if ($RequireComplete -and -not $report.summary.complete) { throw 'Source/install review ledger is incomplete.' }
