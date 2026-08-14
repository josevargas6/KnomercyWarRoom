[CmdletBinding()]
param(
    [string]$BuildOutputDirectory = "artifacts\candidate-package\alpha29",
    [string]$OutFile = "knowledge\candidate-package-report.json",
    [ValidateSet('candidate', 'release')]
    [string]$EvidenceScope = 'candidate'
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$buildOutputPath = if ([IO.Path]::IsPathRooted($BuildOutputDirectory)) {
    $BuildOutputDirectory
} else {
    Join-Path $root $BuildOutputDirectory
}
$buildOutputRoot = [IO.Path]::GetFullPath($buildOutputPath)
$outPath = Join-Path $root $OutFile
$toc = Get-Content -LiteralPath (Join-Path $root "KnomercyWarRoom.toc") -Raw
$version = [regex]::Match($toc, "## Version:\s*(.+)").Groups[1].Value.Trim()
$safeVersion = $version.ToUpperInvariant().Replace(".", "_").Replace("-", "_")

$distributionZip = Join-Path $buildOutputRoot ("KWR_{0}_DISTRIBUTION.zip" -f $safeVersion)
$developerZip = Join-Path $buildOutputRoot ("KWR_{0}_DEVELOPER.zip" -f $safeVersion)
$hashFile = Join-Path $buildOutputRoot ("KWR_{0}_SHA256.txt" -f $safeVersion)
$sourceManifestFile = Join-Path $buildOutputRoot ("KWR_{0}_SOURCE_MANIFEST.json" -f $safeVersion)
$provenanceFile = Join-Path $buildOutputRoot ("KWR_{0}_BUILD_PROVENANCE.json" -f $safeVersion)
$reproducibilityFile = Join-Path $buildOutputRoot ("KWR_{0}_REPRODUCIBILITY.json" -f $safeVersion)
$packageAuditFile = Join-Path $buildOutputRoot ("KWR_{0}_PACKAGE_AUDIT.json" -f $safeVersion)

foreach ($path in @(
    $distributionZip,
    $developerZip,
    $hashFile,
    $sourceManifestFile,
    $provenanceFile,
    $reproducibilityFile
)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing candidate package artifact: $path"
    }
}

function Get-ReportPath {
    param([string]$Path)
    $fullPath = [IO.Path]::GetFullPath($Path)
    $rootPrefix = $root.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if ($fullPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        return $fullPath.Substring($rootPrefix.Length).Replace('\', '/')
    }
    return Split-Path -Leaf $fullPath
}

function New-ArtifactReport {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $item = Get-Item -LiteralPath $Path
    $hash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
    return [ordered]@{
        name = $item.Name
        path = Get-ReportPath -Path $item.FullName
        size = [int64]$item.Length
        sha256 = $hash
    }
}

$distributionArtifact = New-ArtifactReport -Path $distributionZip
$developerArtifact = New-ArtifactReport -Path $developerZip
$sourceManifest = Get-Content -LiteralPath $sourceManifestFile -Raw | ConvertFrom-Json
$provenance = Get-Content -LiteralPath $provenanceFile -Raw | ConvertFrom-Json
$reproducibility = Get-Content -LiteralPath $reproducibilityFile -Raw | ConvertFrom-Json
$hashLines = [System.IO.File]::ReadAllLines($hashFile)
$packageAudit = $null
if (Test-Path -LiteralPath $packageAuditFile) {
    $packageAudit = Get-Content -LiteralPath $packageAuditFile -Raw | ConvertFrom-Json
}
$runtimePreflightPath = Join-Path $root "knowledge\runtime-preflight.json"
$runtimePreflight = $null
if (Test-Path -LiteralPath $runtimePreflightPath) {
    $runtimePreflight = Get-Content -LiteralPath $runtimePreflightPath -Raw | ConvertFrom-Json
}

$workspaceNode = Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe"
$packageAuditStatus = "BLOCKED_RUNTIME_DISCOVERY"
$runtimeBlocker = if ($packageAudit -and $packageAudit.result -eq "PASS") {
    $packageAuditStatus = "CERTIFIED_IN_WORKSPACE"
    $null
} elseif ($runtimePreflight -and $runtimePreflight.packageAuditReady) {
    $packageAuditStatus = "READY_TO_CERTIFY"
    "Runtime preflight found a readable deterministic Lua runtime. Package-audit can be rerun for final extracted-runtime certification."
} elseif ($runtimePreflight -and $runtimePreflight.localLuaTools.present -and -not $runtimePreflight.localLuaTools.packageReadable) {
    $packageAuditStatus = "BLOCKED_RUNTIME_FILE_ACCESS"
    "Package audit in this shell is currently blocked because the local Fengari package files exist but are not readable from this machine state."
} elseif (Test-Path -LiteralPath $workspaceNode) {
    "Package audit in this shell was blocked because the current audit path could not discover a Fengari CLI runtime automatically, even though a bundled Node executable exists outside normal PATH."
} else {
    "Package audit in this shell was blocked because no discoverable Node/Fengari runtime was available."
}

$report = [ordered]@{
    schema = "kwr-candidate-package-report"
    schemaVersion = 1
    generatedAt = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
    candidateVersion = $version
    buildOutputDirectory = Get-ReportPath -Path $buildOutputRoot
    distributionArtifact = $distributionArtifact
    developerArtifact = $developerArtifact
    hashManifest = [ordered]@{
        path = Get-ReportPath -Path $hashFile
        lines = @($hashLines)
    }
    sourceManifest = [ordered]@{
        path = Get-ReportPath -Path $sourceManifestFile
        distributionDigest = $sourceManifest.distribution.digest
        distributionEntryCount = $sourceManifest.distribution.entryCount
        developerDigest = $sourceManifest.developer.digest
        developerEntryCount = $sourceManifest.developer.entryCount
    }
    buildProvenance = [ordered]@{
        path = Get-ReportPath -Path $provenanceFile
        builtAtUtc = $provenance.builtAtUtc
        sentinelIncluded = [bool]$provenance.sentinelIncluded
        powershellEdition = $provenance.tools.powershell.edition
        powershellVersion = $provenance.tools.powershell.version
        nodeAvailableOnBuildPath = [bool]$provenance.tools.node.available
        npmAvailableOnBuildPath = [bool]$provenance.tools.npm.available
        fengariAvailableOnBuildPath = [bool]$provenance.tools.fengari.available
        gitAvailable = [bool]$provenance.git.available
    }
    reproducibility = [ordered]@{
        path = Get-ReportPath -Path $reproducibilityFile
        result = $reproducibility.result
        distributionDigestMatch = [bool]$reproducibility.sourceDigestMatches.distribution
        developerDigestMatch = [bool]$reproducibility.sourceDigestMatches.developer
        notes = @($reproducibility.notes)
    }
    packageAudit = if ($packageAudit) {
        [ordered]@{
            path = Get-ReportPath -Path $packageAuditFile
            auditedAtUtc = $packageAudit.auditedAtUtc
            result = $packageAudit.result
            hashesVerified = $packageAudit.hashesVerified
            distributionEntries = $packageAudit.distributionEntries
            developerEntries = $packageAudit.developerEntries
            extractedDistributionRuntime = $packageAudit.extractedDistributionRuntime
            extractedDeveloperRuntime = $packageAudit.extractedDeveloperRuntime
            reproducibilityCheck = $packageAudit.reproducibilityCheck
        }
    } else {
        $null
    }
    environmentCertification = [ordered]@{
        buildExecuted = $true
        packageAuditInThisWorkspace = $packageAuditStatus
        runtimeBlocker = $runtimeBlocker
        runtimePreflightPath = if ($runtimePreflight) {
            Get-ReportPath -Path $runtimePreflightPath
        } else { $null }
        notes = @(
            "The exact distribution and developer ZIPs were created in this workspace.",
            "The reproducibility report was created in this workspace.",
            $(if ($packageAuditStatus -eq "CERTIFIED_IN_WORKSPACE") {
                "Extracted-runtime package certification was completed in this workspace."
            } elseif ($packageAuditStatus -eq "READY_TO_CERTIFY") {
                "Runtime discovery is ready; extracted-runtime package certification still needs a fresh package-audit run."
            } else {
                "The package-audit step stopped at runtime discovery instead of proving extracted-runtime certification here."
            }),
            "Live install and upgrade proof still require real client execution and field evidence."
        )
    }
    operatorPaths = [ordered]@{
        addonsRoot = "World of Warcraft\\_retail_\\Interface\\AddOns"
        kwrInstallFolder = "World of Warcraft\\_retail_\\Interface\\AddOns\\KnomercyWarRoom"
        savedVariablesFolder = "World of Warcraft\\_retail_\\WTF\\Account\\<ACCOUNT>\\SavedVariables"
        savedVariablesFilePattern = "KnomercyWarRoom.lua and KnomercyWarRoom.lua.bak"
        backupFolderSuggestion = "World of Warcraft\\_retail_\\WTF\\Account\\<ACCOUNT>\\SavedVariables\\KWR_Backups\\$version"
    }
    fieldEvidenceBinding = [ordered]@{
        candidateVersion = $version
        distributionSha256 = $distributionArtifact.sha256
        evidenceScope = $EvidenceScope
        canonicalArtifact = if ($EvidenceScope -eq 'release') {
            [IO.Path]::GetFileName($outPath)
        } else {
            "Generated tagged-release evidence artifact"
        }
        requiredProof = @(
            "Screenshot or text capture of installed TOC version.",
            "Recorded distribution ZIP SHA256 used for install.",
            "Backup location for pre-session SavedVariables.",
            "Proof whether the session was clean install or upgrade install.",
            "Any /kwr verify, bug, screenshot, or AAR evidence tied to this same hash."
        )
    }
}

$json = $report | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText($outPath, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))

Write-Output "KWR candidate package report"
Write-Output "Candidate: $version"
Write-Output "Evidence scope: $EvidenceScope"
Write-Output "Build output: $buildOutputRoot"
Write-Output "Distribution SHA256: $($report.distributionArtifact.sha256)"
Write-Output "Output: $outPath"
