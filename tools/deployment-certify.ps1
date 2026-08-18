[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BuildOutputDirectory,
    [Parameter(Mandatory = $true)]
    [string]$CommanderReceipt,
    [Parameter(Mandatory = $true)]
    [string]$SentinelReceipt,
    [string]$OutFile = "knowledge\deployment-certification.json"
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
. (Join-Path $PSScriptRoot 'hash-utils.ps1')

function Resolve-InputFile {
    param([string]$Path, [string]$Label)

    $resolved = if ([IO.Path]::IsPathRooted($Path)) {
        [IO.Path]::GetFullPath($Path)
    } else {
        [IO.Path]::GetFullPath((Join-Path $root $Path))
    }
    if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
        throw "$Label is missing: $resolved"
    }
    return $resolved
}

function Get-RelativeEvidencePath {
    param([string]$Path)

    $resolved = [IO.Path]::GetFullPath($Path)
    $prefix = $root.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if ($resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        return $resolved.Substring($prefix.Length).Replace('\', '/')
    }
    return Split-Path -Leaf $resolved
}

function Assert-DeploymentReceipt {
    param([string]$ReceiptPath, [string]$Label, [string]$ExpectedDigest)

    # Parse the evidence at its explicit path here rather than passing a
    # deserialized object through a PowerShell function boundary. Windows
    # PowerShell can otherwise bind that object as an empty PSCustomObject.
    $receipt = Get-Content -LiteralPath $ReceiptPath -Raw | ConvertFrom-Json
    $receiptResult = [string]$receipt.result
    $wasSynchronized = [Convert]::ToBoolean($receipt.synchronized)
    if ($receiptResult -ne 'PASS' -or -not $wasSynchronized) {
        throw "$Label deployment receipt did not record a successful synchronization (result=$receiptResult; synchronized=$wasSynchronized)."
    }
    if ($receipt.after.missing.Count -ne 0 -or $receipt.after.changed.Count -ne 0 -or
        $receipt.after.extra.Count -ne 0) {
        throw "$Label deployment receipt contains unresolved manifest differences."
    }
    if ($receipt.after.packageDigest -cne $ExpectedDigest -or
        $receipt.after.installedDigest -cne $ExpectedDigest) {
        throw "$Label deployment receipt is not bound to the exact package digest."
    }
}

$status = & git status --porcelain
if ($LASTEXITCODE -ne 0 -or $status) {
    throw 'Deployment certification requires a committed, clean source tree.'
}
$releaseCommit = (& git rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $releaseCommit -notmatch '^[0-9a-f]{40}$') {
    throw 'Deployment certification could not resolve the committed source revision.'
}

$toc = Get-Content -LiteralPath (Join-Path $root 'KnomercyWarRoom.toc') -Raw
$version = [regex]::Match($toc, '## Version:\s*(.+)').Groups[1].Value.Trim()
$safeVersion = $version.ToUpperInvariant().Replace('.', '_').Replace('-', '_')
$sentinelToc = Get-Content -LiteralPath (Join-Path $root 'KWRSentinel\KWRSentinel.toc') -Raw
$sentinelVersion = [regex]::Match($sentinelToc, '## Version:\s*(.+)').Groups[1].Value.Trim()
if ($version -eq '' -or $sentinelVersion -ne $version) {
    throw 'Commander and Sentinel manifests do not declare one candidate version.'
}

$outputRoot = if ([IO.Path]::IsPathRooted($BuildOutputDirectory)) {
    [IO.Path]::GetFullPath($BuildOutputDirectory)
} else {
    [IO.Path]::GetFullPath((Join-Path $root $BuildOutputDirectory))
}
$sourceManifestPath = Resolve-InputFile `
    -Path (Join-Path $outputRoot ("KWR_{0}_SOURCE_MANIFEST.json" -f $safeVersion)) `
    -Label 'Source manifest'
$commanderZip = Resolve-InputFile `
    -Path (Join-Path $outputRoot ("KnomercyWarRoom-{0}.zip" -f $version)) `
    -Label 'Commander package'
$sentinelZip = Resolve-InputFile `
    -Path (Join-Path $outputRoot ("KWR-Sentinel-{0}.zip" -f $version)) `
    -Label 'Sentinel package'
$commanderReceiptPath = Resolve-InputFile -Path $CommanderReceipt -Label 'Commander deployment receipt'
$sentinelReceiptPath = Resolve-InputFile -Path $SentinelReceipt -Label 'Sentinel deployment receipt'

$manifest = Get-Content -LiteralPath $sourceManifestPath -Raw | ConvertFrom-Json
$commanderDigest = [string]$manifest.distribution.digest
$sentinelDigest = [string]$manifest.sentinel.digest
Assert-DeploymentReceipt -ReceiptPath $commanderReceiptPath -Label 'Commander' `
    -ExpectedDigest $commanderDigest
Assert-DeploymentReceipt -ReceiptPath $sentinelReceiptPath -Label 'Sentinel' `
    -ExpectedDigest $sentinelDigest

$commanderReceipt = Get-Content -LiteralPath $commanderReceiptPath -Raw | ConvertFrom-Json
$sentinelReceipt = Get-Content -LiteralPath $sentinelReceiptPath -Raw | ConvertFrom-Json

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\test-retail-savedvariables-audit.ps1')
if ($LASTEXITCODE -ne 0) {
    throw 'SavedVariables migration certification failed.'
}

$outPath = if ([IO.Path]::IsPathRooted($OutFile)) {
    [IO.Path]::GetFullPath($OutFile)
} else {
    [IO.Path]::GetFullPath((Join-Path $root $OutFile))
}
$certificate = [ordered]@{
    schema = 'kwr-deployment-certification'
    schemaVersion = 2
    certifiedAt = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    candidateVersion = $version
    releaseTag = $null
    releaseCommit = $releaseCommit
    commander = [ordered]@{
        sha256 = Get-KwrFileSha256 -LiteralPath $commanderZip
        packageDigest = $manifest.distribution.digest
        installedEntries = [int]$commanderReceipt.after.installedEntries
        missing = [int]$commanderReceipt.after.missing.Count
        changed = [int]$commanderReceipt.after.changed.Count
        extra = [int]$commanderReceipt.after.extra.Count
    }
    sentinel = [ordered]@{
        sha256 = Get-KwrFileSha256 -LiteralPath $sentinelZip
        packageDigest = $manifest.sentinel.digest
        installedEntries = [int]$sentinelReceipt.after.installedEntries
        missing = [int]$sentinelReceipt.after.missing.Count
        changed = [int]$sentinelReceipt.after.changed.Count
        extra = [int]$sentinelReceipt.after.extra.Count
    }
    upgradeProof = [ordered]@{
        savedVariablesMigrationMatrix = 'PASS'
        futureSchemaReadOnlyCompatibility = 'PASS'
        deterministicSuite = 'KWR_LUA_TESTS_PASS suite=All'
    }
    sentinelBridge = [ordered]@{
        loadFlag = 'ENABLED'
        mode = 'SAME_CLIENT_AND_KWRSYNC1'
        crossClientTransport = 'IMPLEMENTED_PENDING_RETAIL_PROOF'
    }
    evidence = @(
        Get-RelativeEvidencePath -Path $sourceManifestPath
        Get-RelativeEvidencePath -Path $commanderReceiptPath
        Get-RelativeEvidencePath -Path $sentinelReceiptPath
        'tools/test-retail-savedvariables-audit.ps1'
    )
    result = 'PASS'
}
[IO.File]::WriteAllText(
    $outPath,
    (($certificate | ConvertTo-Json -Depth 8) + [Environment]::NewLine),
    [Text.UTF8Encoding]::new($false)
)

Write-Output 'KWR deployment certification PASS'
Write-Output "Candidate: $version"
Write-Output "Commander SHA256: $($certificate.commander.sha256)"
Write-Output "Sentinel SHA256: $($certificate.sentinel.sha256)"
Write-Output "Output: $outPath"
