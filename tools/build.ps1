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
. $releaseManifest

function New-ArtifactSummary {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $item = Get-Item -LiteralPath $Path
    $hash = Get-FileHash -LiteralPath $Path -Algorithm SHA256
    return [pscustomobject]@{
        name = $item.Name
        size = [int64]$item.Length
        sha256 = $hash.Hash.ToUpperInvariant()
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

    & powershell -NoProfile -ExecutionPolicy Bypass -File $BuildScriptPath `
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
$distributionZip = Join-Path $outputRoot ("KWR_{0}_DISTRIBUTION.zip" -f $safeVersion)
$developerZip = Join-Path $outputRoot ("KWR_{0}_DEVELOPER.zip" -f $safeVersion)
$sentinelZip = $null
$hasSentinel = $IncludeSentinel -and (Test-Path -LiteralPath $sentinelRoot)
if ($hasSentinel) {
    $sentinelToc = Get-Content -LiteralPath (Join-Path $sentinelRoot "KWRSentinel.toc")
    $sentinelVersion = (($sentinelToc | Where-Object { $_ -match "^## Version:" }) -replace "^## Version:\s*", "").Trim()
    $sentinelSafeVersion = $sentinelVersion.ToUpperInvariant().Replace(".", "_").Replace("-", "_")
    $sentinelZip = Join-Path $outputRoot ("KWRSentinel_{0}.zip" -f $sentinelSafeVersion)
}
$hashFile = Join-Path $outputRoot ("KWR_{0}_SHA256.txt" -f $safeVersion)

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

    foreach ($directory in @(
        "Core",
        "Data",
        "Rulesets",
        "Compliance",
        "Adapters",
        "State",
        "Intelligence",
        "Runtime",
        "Features",
        "UI"
    )) {
        Copy-Item -LiteralPath (Join-Path $root $directory) -Destination $distributionRoot -Recurse
    }
    Remove-ReleaseExcludedFiles -RootPath $distributionRoot
    foreach ($file in @(
        "KnomercyWarRoom.toc",
        "README.md",
        "CHANGELOG.md",
        "CURSEFORGE_DESCRIPTION.md",
        "DESIGN_CONTRACT.md",
        "BATTLEGROUND_VERIFICATION.md",
        "META_SOURCES.md",
        "RELEASE_READINESS.md",
        "THIRD_PARTY_NOTICES.md",
        "LICENSE"
    )) {
        Copy-Item -LiteralPath (Join-Path $root $file) -Destination $distributionRoot
    }
$releaseTocPath = Join-Path $distributionRoot "KnomercyWarRoom.toc"
    Get-ReleaseTocLines -SourceTocPath $sourceTocPath |
        Set-Content -LiteralPath $releaseTocPath -Encoding ASCII
    if ($hasSentinel) {
        $sentinelDistributionRoot = Join-Path $tempRoot "distribution\KWRSentinel"
        foreach ($item in Get-ChildItem -LiteralPath $sentinelRoot -Force) {
            Copy-Item -LiteralPath $item.FullName -Destination $sentinelDistributionRoot -Recurse
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
        Compress-Archive -LiteralPath $devAddonRoot -DestinationPath $devZip -CompressionLevel Optimal
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
            Compress-Archive -LiteralPath $devSentinelRoot -DestinationPath $sentinelDevZip -CompressionLevel Optimal
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
    Copy-Item -LiteralPath (Join-Path $root "DEVELOPMENT.md") -Destination (Join-Path $developerRoot "README.md")

    foreach ($path in @($distributionZip, $developerZip, $sentinelZip, $hashFile)) {
        if (-not $path) {
            continue
        }
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Force
        }
    }

    Compress-Archive -LiteralPath (Join-Path $tempRoot "distribution\KnomercyWarRoom") -DestinationPath $distributionZip -CompressionLevel Optimal
    Compress-Archive -LiteralPath (Join-Path $tempRoot "developer\KnomercyWarRoom-Developer") -DestinationPath $developerZip -CompressionLevel Optimal
    if ($hasSentinel) {
        Compress-Archive -LiteralPath (Join-Path $tempRoot "distribution\KWRSentinel") -DestinationPath $sentinelZip -CompressionLevel Optimal
    }

    $distributionHash = Get-FileHash -LiteralPath $distributionZip -Algorithm SHA256
    $developerHash = Get-FileHash -LiteralPath $developerZip -Algorithm SHA256
    $hashLines = @(
        "$($distributionHash.Hash)  $([IO.Path]::GetFileName($distributionZip))",
        "$($developerHash.Hash)  $([IO.Path]::GetFileName($developerZip))"
    )
    if ($hasSentinel) {
        $sentinelHash = Get-FileHash -LiteralPath $sentinelZip -Algorithm SHA256
        $hashLines += "$($sentinelHash.Hash)  $([IO.Path]::GetFileName($sentinelZip))"
    }
    $hashLines | Set-Content -LiteralPath $hashFile -Encoding ASCII

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

            $reproResult = if ($binaryMismatchCount -eq 0) { "PASS" } else { "PASS_WITH_DOCUMENTED_EXCEPTION" }
            $notes = @(
                "Two clean builds were executed with the primary package audit intact and nested reproducibility/package-audit recursion disabled in the secondary pass."
            )
            if ($binaryMismatchCount -eq 0) {
                $notes += "Binary SHA-256 hashes matched for every produced archive."
            } else {
                $notes += "Staged payload digests matched across clean builds, but PowerShell Compress-Archive did not produce byte-identical ZIP containers."
                $notes += "Package audit still validated the extracted payload, release exclusions, and extracted runtime smoke/soak on the primary build."
            }

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
