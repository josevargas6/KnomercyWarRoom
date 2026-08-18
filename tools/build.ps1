[CmdletBinding()]
param(
    [string]$OutputDirectory = "C:\Users\josev\Desktop\KWR\Builds",
    [switch]$IncludeSentinel,
    [ValidateSet('production','development','local')]
    [string]$Channel = 'production',
    [switch]$SkipPackageAudit,
    [switch]$SkipReproducibilityAudit
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$validator = Join-Path $PSScriptRoot "validate.ps1"
$sentinelRoot = Join-Path $root "KWRSentinel"
$sourceTocPath = Join-Path $root "KnomercyWarRoom.toc"
$releaseManifest = Join-Path $PSScriptRoot "release-manifest.ps1"
. (Join-Path $PSScriptRoot "hash-utils.ps1")
. $releaseManifest

function New-ArtifactSummary {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $item = Get-Item -LiteralPath $Path
    $hash = Get-KwrFileSha256 -LiteralPath $Path
    return [pscustomobject]@{
        name = $item.Name
        size = [int64]$item.Length
        sha256 = $hash
    }
}

function New-KwrArchive {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceDirectory,
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    # ZIP metadata is part of the release artifact. Enumerate entries in a
    # canonical order and replace source mtimes with one valid ZIP timestamp so
    # two clean builds of the same payload are byte-for-byte identical.
    Add-Type -AssemblyName System.IO.Compression
    $sourceRoot = [IO.Path]::GetFullPath($SourceDirectory).TrimEnd('\', '/')
    $archiveRoot = Split-Path -Leaf $sourceRoot
    $entries = @(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
        ForEach-Object {
            $relativePath = $_.FullName.Substring($sourceRoot.Length).TrimStart('\', '/')
            [pscustomobject]@{
                File = $_
                ArchivePath = ($archiveRoot + '/' + $relativePath).Replace('\', '/')
            }
        } | Sort-Object ArchivePath)
    $fixedTimestamp = [DateTimeOffset]::new(2000, 1, 1, 0, 0, 0, [TimeSpan]::Zero)
    $destinationStream = [IO.File]::Open(
        $DestinationPath,
        [IO.FileMode]::CreateNew,
        [IO.FileAccess]::ReadWrite,
        [IO.FileShare]::None)
    $archive = $null
    try {
        $archive = [IO.Compression.ZipArchive]::new(
            $destinationStream,
            [IO.Compression.ZipArchiveMode]::Create,
            $false)
        foreach ($item in $entries) {
            $entry = $archive.CreateEntry(
                $item.ArchivePath,
                [IO.Compression.CompressionLevel]::Optimal)
            $entry.LastWriteTime = $fixedTimestamp
            $sourceStream = [IO.File]::OpenRead($item.File.FullName)
            $entryStream = $null
            try {
                $entryStream = $entry.Open()
                $sourceStream.CopyTo($entryStream)
            } finally {
                if ($entryStream) { $entryStream.Dispose() }
                $sourceStream.Dispose()
            }
        }
    } finally {
        if ($archive) { $archive.Dispose() }
        $destinationStream.Dispose()
    }
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [object]$Data
    )

    $Data | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Convert-DevelopmentSource {
    param([string]$RootPath, [ValidateSet('development','local')][string]$BuildChannel)
    $luaFiles = Get-ChildItem -LiteralPath $RootPath -Recurse -File -Filter '*.lua'
    foreach ($file in $luaFiles) {
        $content = Get-Content -LiteralPath $file.FullName -Raw
        $content = [regex]::Replace($content, '\bKWRSentinel\b', 'KWRSentinelDev')
        $content = [regex]::Replace($content, '\bKWR\b', 'KWRDev')
        $content = $content.Replace('KWR_', 'KWRDev_')
        $content = $content.Replace('BuildInfo.channel = "production"', ('BuildInfo.channel = "' + $BuildChannel + '"'))
        $content = $content.Replace('Sentinel.channel = "production"', ('Sentinel.channel = "' + $BuildChannel + '"'))
        Set-Content -LiteralPath $file.FullName -Value $content -Encoding UTF8
    }
}

function Invoke-NestedBuildForReproducibility {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BuildScriptPath,
        [Parameter(Mandatory = $true)]
        [string]$NestedOutputDirectory,
        [switch]$IncludeSentinel
    )

    # Compression output is runtime-specific. Reuse the current PowerShell host
    # instead of silently switching from pwsh to Windows PowerShell, otherwise
    # two byte-identical source trees can yield different ZIP streams.
    $currentHost = (Get-Process -Id $PID).Path
    & $currentHost -NoProfile -ExecutionPolicy Bypass -File $BuildScriptPath `
        -OutputDirectory $NestedOutputDirectory `
        $(if ($IncludeSentinel) { "-IncludeSentinel" }) `
        -SkipPackageAudit `
        -SkipReproducibilityAudit
    if ($LASTEXITCODE -ne 0) {
        throw "Nested reproducibility build failed."
    }
}

& $validator
if ($LASTEXITCODE -ne 0) {
    throw "Validation failed. Packages were not created."
}
$toc = Get-Content -LiteralPath $sourceTocPath
$version = (($toc | Where-Object { $_ -match "^## Version:" }) -replace "^## Version:\s*", "").Trim()
if ($Channel -eq 'production' -and $version -match '-(dev|local)') {
    throw "Production build cannot use development version: $version"
}
$safeVersion = $version.ToUpperInvariant().Replace(".", "_").Replace("-", "_")

[IO.Directory]::CreateDirectory($OutputDirectory) | Out-Null
$outputRoot = [IO.Path]::GetFullPath($OutputDirectory)
$distributionZip = Join-Path $outputRoot ("KnomercyWarRoom-{0}.zip" -f $version)
$developerZip = Join-Path $outputRoot ("KWR_{0}_DEVELOPER.zip" -f $safeVersion)
$sentinelZip = $null
$hasSentinel = $IncludeSentinel -and (Test-Path -LiteralPath $sentinelRoot)
if ($hasSentinel) {
    $sentinelToc = Get-Content -LiteralPath (Join-Path $sentinelRoot "KWRSentinel.toc")
    $sentinelVersion = (($sentinelToc | Where-Object { $_ -match "^## Version:" }) -replace "^## Version:\s*", "").Trim()
    $sentinelSafeVersion = $sentinelVersion.ToUpperInvariant().Replace(".", "_").Replace("-", "_")
    $sentinelZip = Join-Path $outputRoot ("KWR-Sentinel-{0}.zip" -f $sentinelVersion)
}
$hashFile = Join-Path $outputRoot ("KWR_{0}_SHA256.txt" -f $safeVersion)
$developerHashFile = Join-Path $outputRoot ("KWR_{0}_DEVELOPER_CHECKSUM.txt" -f $safeVersion)
$publicManifestFile = Join-Path $outputRoot ("KWR_{0}_PUBLIC_MANIFEST.json" -f $safeVersion)

$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$tempRoot = Join-Path $tempBase ("kwr-build-" + [guid]::NewGuid().ToString("N"))
[IO.Directory]::CreateDirectory($tempRoot) | Out-Null

try {
    $distributionRoot = Join-Path $tempRoot "distribution\KnomercyWarRoom"
    $developerRoot = Join-Path $tempRoot "developer\KnomercyWarRoom-Developer"
    $developerSource = Join-Path $developerRoot "src\KnomercyWarRoom"
    [IO.Directory]::CreateDirectory($distributionRoot) | Out-Null
    [IO.Directory]::CreateDirectory($developerSource) | Out-Null
    if ($hasSentinel) {
        [IO.Directory]::CreateDirectory((Join-Path $tempRoot "distribution\KWRSentinel")) | Out-Null
    }

    foreach ($directory in Get-ProductionPackageDirectories) {
        $sourceDirectory = Join-Path $root $directory
        if (-not (Test-Path -LiteralPath $sourceDirectory)) {
            throw "Production allowlist directory is missing: $directory"
        }
        Copy-Item -LiteralPath $sourceDirectory -Destination $distributionRoot -Recurse
    }
    Remove-ReleaseExcludedFiles -RootPath $distributionRoot
    foreach ($file in Get-ProductionPackageFiles) {
        $sourceFile = Join-Path $root $file
        if (-not (Test-Path -LiteralPath $sourceFile)) {
            throw "Production allowlist file is missing: $file"
        }
        Copy-Item -LiteralPath $sourceFile -Destination $distributionRoot
    }
$releaseTocPath = Join-Path $distributionRoot "KnomercyWarRoom.toc"
    Get-ReleaseTocLines -SourceTocPath $sourceTocPath |
        Set-Content -LiteralPath $releaseTocPath -Encoding ASCII
    if ($hasSentinel) {
        $sentinelDistributionRoot = Join-Path $tempRoot "distribution\KWRSentinel"
        foreach ($file in Get-SentinelProductionFiles) {
            $sourceFile = Join-Path $sentinelRoot $file
            if (-not (Test-Path -LiteralPath $sourceFile)) {
                throw "Sentinel production allowlist file is missing: $file"
            }
            Copy-Item -LiteralPath $sourceFile -Destination $sentinelDistributionRoot
        }
        if (-not (Test-Path -LiteralPath (Join-Path $sentinelDistributionRoot "KWRSentinel.toc"))) {
            throw "Sentinel package staging is missing KWRSentinel.toc."
        }
    }

    if ($Channel -ne 'production') {
        $devAddonRoot = Join-Path $tempRoot "development\KWR_Commander_Dev"
        Copy-Item -LiteralPath $distributionRoot -Destination $devAddonRoot -Recurse
        $devToc = Join-Path $devAddonRoot 'KnomercyWarRoom.toc'
        $devTocContent = Get-Content -LiteralPath $devToc -Raw
        $devTocContent = $devTocContent.Replace('## Title: |cff33aaffKnomercy War Room|r', '## Title: |cffffb347KWR Commander DEV|r')
        $devTocContent = $devTocContent.Replace('## SavedVariables: KWR_DB', '## SavedVariables: KWRDev_DB')
        $devTocContent += "`r`n## X-KWR-Channel: $Channel`r`n## X-KWR-Development: NOT FOR PRODUCTION USE`r`n"
        Set-Content -LiteralPath $devToc -Value $devTocContent -Encoding ASCII
        Rename-Item -LiteralPath $devToc -NewName 'KWR_Commander_Dev.toc'
        Convert-DevelopmentSource -RootPath $devAddonRoot -BuildChannel $Channel
        $devZip = Join-Path $outputRoot ("KWR_Commander_Dev_{0}.zip" -f $safeVersion)
        New-KwrArchive -SourceDirectory $devAddonRoot -DestinationPath $devZip
        if ($hasSentinel) {
            $devSentinelRoot = Join-Path $tempRoot "development\KWR_Sentinel_Dev"
            Copy-Item -LiteralPath $sentinelDistributionRoot -Destination $devSentinelRoot -Recurse
            $sentinelDevToc = Join-Path $devSentinelRoot 'KWRSentinel.toc'
            $sentinelDevContent = (Get-Content -LiteralPath $sentinelDevToc -Raw).Replace('## Title: |cff7fd7ffKWR Sentinel|r', '## Title: |cffffb347KWR Sentinel DEV|r').Replace('## SavedVariables: KWR_SENTINEL_DB', '## SavedVariables: KWRDev_SENTINEL_DB')
            $sentinelDevContent += "`r`n## X-KWR-Channel: $Channel`r`n## X-KWR-Development: NOT FOR PRODUCTION USE`r`n"
            Set-Content -LiteralPath $sentinelDevToc -Value $sentinelDevContent -Encoding ASCII
            Rename-Item -LiteralPath $sentinelDevToc -NewName 'KWR_Sentinel_Dev.toc'
            Convert-DevelopmentSource -RootPath $devSentinelRoot -BuildChannel $Channel
            $sentinelDevZip = Join-Path $outputRoot ("KWR_Sentinel_Dev_{0}.zip" -f $sentinelSafeVersion)
            New-KwrArchive -SourceDirectory $devSentinelRoot -DestinationPath $sentinelDevZip
            Write-Output "Sentinel development: $sentinelDevZip"
        }
        Write-Output "Development: $devZip"
    }

    foreach ($item in Get-ChildItem -LiteralPath $root -Force) {
        if ($item.Name -in @(
            ".git",
            ".pnpm-store",
            "artifacts",
            "node_modules"
        )) {
            continue
        }
        Copy-Item -LiteralPath $item.FullName -Destination $developerSource -Recurse
    }
    # Release-evidence receipts are generated from the final archive and refer
    # to that exact artifact. Excluding all of them keeps the developer source
    # package non-self-referential; package-audit explicitly validates this
    # omission mode while the checkout audit validates the receipts themselves.
    foreach ($generatedReceipt in @(
        "runtime-preflight.json",
        "field-test-readiness.json",
        "field-blocker-report.json",
        "candidate-package-report.json",
        "offline-completion-audit.json",
        "deployment-certification.json"
    )) {
        Remove-Item -LiteralPath (Join-Path $developerSource (Join-Path "knowledge" $generatedReceipt)) -Force -ErrorAction SilentlyContinue
    }
    # Field screenshots are immutable Git evidence, not executable developer
    # source. Keeping them in this archive adds tens of megabytes to every
    # clean reproducibility build and extracted-runtime audit without helping
    # an addon developer validate, test, or modify the package.
    $developerFieldEvidence = Join-Path $developerSource "docs\field-evidence"
    Remove-Item -LiteralPath $developerFieldEvidence -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath (Join-Path $root "DEVELOPMENT.md") -Destination (Join-Path $developerRoot "README.md")

    foreach ($path in @($distributionZip, $developerZip, $sentinelZip, $hashFile, $developerHashFile, $publicManifestFile)) {
        if (-not $path) {
            continue
        }
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Force
        }
    }

    Write-Output "KWR build checkpoint: compressing distribution archive"
    New-KwrArchive -SourceDirectory (Join-Path $tempRoot "distribution\KnomercyWarRoom") -DestinationPath $distributionZip
    Write-Output "KWR build checkpoint: compressing developer archive"
    New-KwrArchive -SourceDirectory (Join-Path $tempRoot "developer\KnomercyWarRoom-Developer") -DestinationPath $developerZip
    if ($hasSentinel) {
        Write-Output "KWR build checkpoint: compressing Sentinel archive"
        New-KwrArchive -SourceDirectory (Join-Path $tempRoot "distribution\KWRSentinel") -DestinationPath $sentinelZip
    }

    $distributionHash = Get-KwrFileSha256 -LiteralPath $distributionZip
    $developerHash = Get-KwrFileSha256 -LiteralPath $developerZip
    # Player-facing checksums must name only player-facing downloads.  The
    # developer ZIP and its checksum remain in the retention-bound CI artifact.
    $hashLines = @(
        "$distributionHash  $([IO.Path]::GetFileName($distributionZip))"
    )
    if ($hasSentinel) {
        $sentinelHash = Get-KwrFileSha256 -LiteralPath $sentinelZip
        $hashLines += "$sentinelHash  $([IO.Path]::GetFileName($sentinelZip))"
    }
    $hashLines | Set-Content -LiteralPath $hashFile -Encoding ASCII
    @("$developerHash  $([IO.Path]::GetFileName($developerZip))") |
        Set-Content -LiteralPath $developerHashFile -Encoding ASCII

    $distributionEntries = Get-DirectoryManifestEntries -RootPath $distributionRoot
    $developerEntries = Get-DirectoryManifestEntries -RootPath $developerRoot
    $distributionDigest = Get-ManifestDigest -Entries $distributionEntries
    $developerDigest = Get-ManifestDigest -Entries $developerEntries
    $sentinelEntries = @()
    $sentinelDigest = $null
    if ($hasSentinel) {
        $sentinelEntries = Get-DirectoryManifestEntries -RootPath $sentinelDistributionRoot
        $sentinelDigest = Get-ManifestDigest -Entries $sentinelEntries
    }

    $artifactSummaries = @(
        New-ArtifactSummary -Path $distributionZip
        New-ArtifactSummary -Path $developerZip
    )
    if ($hasSentinel) {
        $artifactSummaries += New-ArtifactSummary -Path $sentinelZip
    }

    $provenanceFile = Join-Path $outputRoot ("KWR_{0}_BUILD_PROVENANCE.json" -f $safeVersion)
    $sourceManifestFile = Join-Path $outputRoot ("KWR_{0}_SOURCE_MANIFEST.json" -f $safeVersion)
    $reproducibilityFile = Join-Path $outputRoot ("KWR_{0}_REPRODUCIBILITY.json" -f $safeVersion)

    $sourceManifest = [pscustomobject]@{
        candidate = $version
        productionAllowlist = [pscustomobject]@{
            directories = @(Get-ProductionPackageDirectories)
            files = @(Get-ProductionPackageFiles)
            sentinelFiles = @(Get-SentinelProductionFiles)
        }
        releaseExclusions = @(Get-ReleaseExcludedEntries)
        distribution = [pscustomobject]@{
            digest = $distributionDigest
            entryCount = $distributionEntries.Count
            entries = $distributionEntries
        }
        developer = [pscustomobject]@{
            digest = $developerDigest
            entryCount = $developerEntries.Count
            entries = $developerEntries
        }
        sentinel = if ($hasSentinel) {
            [pscustomobject]@{
                digest = $sentinelDigest
                entryCount = $sentinelEntries.Count
                entries = $sentinelEntries
            }
        } else {
            $null
        }
    }
    Write-JsonFile -Path $sourceManifestFile -Data $sourceManifest

    $publicArtifacts = @(
        New-ArtifactSummary -Path $distributionZip
    )
    if ($hasSentinel) {
        $publicArtifacts += New-ArtifactSummary -Path $sentinelZip
    }
    $publicManifest = [pscustomobject]@{
        schema = "kwr-public-release-manifest"
        schemaVersion = 1
        candidate = $version
        artifacts = $publicArtifacts
        distribution = [pscustomobject]@{
            digest = $distributionDigest
            entryCount = $distributionEntries.Count
        }
        sentinel = if ($hasSentinel) {
            [pscustomobject]@{
                digest = $sentinelDigest
                entryCount = $sentinelEntries.Count
            }
        } else {
            $null
        }
    }
    Write-JsonFile -Path $publicManifestFile -Data $publicManifest

    $provenance = [pscustomobject]@{
        candidate = $version
        builtAtUtc = (Get-Date).ToUniversalTime().ToString("o")
        sentinelIncluded = $hasSentinel
        outputArtifacts = $artifactSummaries
        sourceDigests = [pscustomobject]@{
            distribution = $distributionDigest
            developer = $developerDigest
            sentinel = $sentinelDigest
        }
        tools = [pscustomobject]@{
            powershell = [pscustomobject]@{
                edition = $PSVersionTable.PSEdition
                version = $PSVersionTable.PSVersion.ToString()
            }
            node = Get-ToolVersionInfo -CommandName "node" `
                -ExplicitPath $env:KWR_NODE_EXE
            npm = Get-ToolVersionInfo -CommandName "npm"
            fengari = Get-ToolVersionInfo -CommandName "fengari" `
                -Arguments @($env:KWR_FENGARI_CLI, "-v") `
                -ExplicitPath $env:KWR_FENGARI_CLI `
                -InvocationPath $env:KWR_NODE_EXE
        }
        git = Get-GitProvenance -RootPath $root
    }
    Write-JsonFile -Path $provenanceFile -Data $provenance

    if (-not $SkipReproducibilityAudit) {
        $reproTempRoot = Join-Path $tempBase ("kwr-repro-" + [guid]::NewGuid().ToString("N"))
        [IO.Directory]::CreateDirectory($reproTempRoot) | Out-Null
        try {
            Write-Output "KWR build checkpoint: starting clean reproducibility build"
            Invoke-NestedBuildForReproducibility `
                -BuildScriptPath (Join-Path $PSScriptRoot "build.ps1") `
                -NestedOutputDirectory $reproTempRoot `
                -IncludeSentinel:$IncludeSentinel
            $nestedSourceManifestFile = Join-Path $reproTempRoot ("KWR_{0}_SOURCE_MANIFEST.json" -f $safeVersion)
            if (-not (Test-Path -LiteralPath $nestedSourceManifestFile)) {
                throw "Nested build is missing the source manifest."
            }
            $nestedSourceManifest = Get-Content -LiteralPath $nestedSourceManifestFile -Raw | ConvertFrom-Json
            $comparison = New-Object System.Collections.Generic.List[object]
            $binaryMismatchCount = 0
            foreach ($artifact in $artifactSummaries) {
                $otherPath = Join-Path $reproTempRoot $artifact.name
                if (-not (Test-Path -LiteralPath $otherPath)) {
                    throw "Nested build is missing artifact: $($artifact.name)"
                }
                $otherSummary = New-ArtifactSummary -Path $otherPath
                $binaryMatch = $artifact.sha256 -eq $otherSummary.sha256
                if (-not $binaryMatch) {
                    $binaryMismatchCount += 1
                }
                $comparison.Add([pscustomobject]@{
                    artifact = $artifact.name
                    primarySha256 = $artifact.sha256
                    secondarySha256 = $otherSummary.sha256
                    binaryMatch = $binaryMatch
                })
            }

            # Compare canonical entry maps as well as their summary digests. The
            # manifest digest is an optimization; PowerShell object enumeration
            # can vary between clean temporary roots even when every staged file
            # path, size, and SHA-256 is identical.
            $distributionEntriesMatch = (ConvertTo-Json @($distributionEntries | Sort-Object path) -Compress -Depth 5) -eq (ConvertTo-Json @($nestedSourceManifest.distribution.entries | Sort-Object path) -Compress -Depth 5)
            $developerEntriesMatch = (ConvertTo-Json @($developerEntries | Sort-Object path) -Compress -Depth 5) -eq (ConvertTo-Json @($nestedSourceManifest.developer.entries | Sort-Object path) -Compress -Depth 5)
            $sentinelEntriesMatch = if ($hasSentinel) {
                (ConvertTo-Json @($sentinelEntries | Sort-Object path) -Compress -Depth 5) -eq (ConvertTo-Json @($nestedSourceManifest.sentinel.entries | Sort-Object path) -Compress -Depth 5)
            } else {
                $true
            }
            $sourceDigestMatches = [pscustomobject]@{
                distribution = ($distributionDigest -eq $nestedSourceManifest.distribution.digest) -or $distributionEntriesMatch
                developer = ($developerDigest -eq $nestedSourceManifest.developer.digest) -or $developerEntriesMatch
                sentinel = if ($hasSentinel) {
                    ($sentinelDigest -eq $nestedSourceManifest.sentinel.digest) -or $sentinelEntriesMatch
                } else {
                    $true
                }
            }
            if (-not $sourceDigestMatches.distribution -or -not $sourceDigestMatches.developer -or -not $sourceDigestMatches.sentinel) {
                throw "Reproducibility audit failed because staged source digests changed between clean builds."
            }

            if ($binaryMismatchCount -ne 0) {
                $comparison | Where-Object { -not $_.binaryMatch } |
                    Format-Table artifact, primarySha256, secondarySha256 -AutoSize |
                    Out-String | Write-Output
                throw "Reproducibility audit failed because deterministic archive bytes changed between clean builds."
            }
            $reproResult = "PASS"
            $notes = @(
                "Two clean builds were executed with the primary package audit intact and nested reproducibility/package-audit recursion disabled in the secondary pass."
            )
            $notes += "Canonical entry order and timestamps produced matching binary SHA-256 hashes for every archive."

            $reproducibility = [pscustomobject]@{
                candidate = $version
                result = $reproResult
                comparedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
                primarySourceDigests = [pscustomobject]@{
                    distribution = $distributionDigest
                    developer = $developerDigest
                    sentinel = $sentinelDigest
                }
                sourceDigestMatches = $sourceDigestMatches
                notes = $notes
                artifacts = $comparison
            }
            Write-JsonFile -Path $reproducibilityFile -Data $reproducibility
            Write-Output "KWR build checkpoint: reproducibility source comparison passed"
        } finally {
            if (Test-Path -LiteralPath $reproTempRoot) {
                $resolvedRepro = [IO.Path]::GetFullPath($reproTempRoot)
                if (-not $resolvedRepro.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase)) {
                    throw "Refusing to remove unexpected reproducibility path: $resolvedRepro"
                }
                Remove-Item -LiteralPath $resolvedRepro -Recurse -Force
            }
        }
    }

    Write-Output "Distribution: $distributionZip"
    Write-Output "Developer:    $developerZip"
    if ($hasSentinel) {
        Write-Output "Sentinel:     $sentinelZip"
    } elseif (Test-Path -LiteralPath $sentinelRoot) {
        Write-Output "Sentinel:     skipped (use -IncludeSentinel for the optional bundle)"
    }
    Write-Output "Hashes:       $hashFile"
    Write-Output "Source manifest: $sourceManifestFile"
    Write-Output "Build provenance: $provenanceFile"
    if (-not $SkipReproducibilityAudit) {
        Write-Output "Reproducibility: $reproducibilityFile"
    }

    if (-not $SkipPackageAudit) {
        Write-Output "KWR build checkpoint: starting extracted-package audit"
        & (Join-Path $PSScriptRoot "package-audit.ps1") `
            -OutputDirectory $outputRoot `
            -SkipReproducibilityCheck:$SkipReproducibilityAudit
        if ($LASTEXITCODE -ne 0) {
            throw "Package audit failed."
        }
    }
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        $resolvedTemp = [IO.Path]::GetFullPath($tempRoot)
        if (-not $resolvedTemp.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove unexpected build path: $resolvedTemp"
        }
        Remove-Item -LiteralPath $resolvedTemp -Recurse -Force
    }
}
