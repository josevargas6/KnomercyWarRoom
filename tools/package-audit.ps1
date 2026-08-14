[CmdletBinding()]
param(
    [string]$OutputDirectory = "C:\Users\josev\Desktop\KWR\Builds",
    [switch]$SkipReproducibilityCheck
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$releaseManifest = Join-Path $PSScriptRoot "release-manifest.ps1"
. $releaseManifest
$toc = Get-Content -LiteralPath (Join-Path $root "KnomercyWarRoom.toc")
$version = (($toc | Where-Object { $_ -match "^## Version:" }) -replace "^## Version:\s*", "").Trim()
$safeVersion = $version.ToUpperInvariant().Replace(".", "_").Replace("-", "_")
$outputRoot = [IO.Path]::GetFullPath($OutputDirectory)
$distributionZip = Join-Path $outputRoot ("KWR_{0}_DISTRIBUTION.zip" -f $safeVersion)
$developerZip = Join-Path $outputRoot ("KWR_{0}_DEVELOPER.zip" -f $safeVersion)
$sentinelRoot = Join-Path $root "KWRSentinel"
$sentinelZip = $null
if (Test-Path -LiteralPath $sentinelRoot) {
    $sentinelToc = Get-Content -LiteralPath (Join-Path $sentinelRoot "KWRSentinel.toc")
    $sentinelVersion = (($sentinelToc | Where-Object { $_ -match "^## Version:" }) -replace "^## Version:\s*", "").Trim()
    $sentinelSafeVersion = $sentinelVersion.ToUpperInvariant().Replace(".", "_").Replace("-", "_")
    $candidateSentinelZip = Join-Path $outputRoot ("KWRSentinel_{0}.zip" -f $sentinelSafeVersion)
    if (Test-Path -LiteralPath $candidateSentinelZip) {
        $sentinelZip = $candidateSentinelZip
    }
}
$hasSentinel = $sentinelZip -ne $null
$hashFile = Join-Path $outputRoot ("KWR_{0}_SHA256.txt" -f $safeVersion)
$developerHashFile = Join-Path $outputRoot ("KWR_{0}_DEVELOPER_CHECKSUM.txt" -f $safeVersion)
$sourceManifestFile = Join-Path $outputRoot ("KWR_{0}_SOURCE_MANIFEST.json" -f $safeVersion)
$provenanceFile = Join-Path $outputRoot ("KWR_{0}_BUILD_PROVENANCE.json" -f $safeVersion)
$reproducibilityFile = Join-Path $outputRoot ("KWR_{0}_REPRODUCIBILITY.json" -f $safeVersion)
$packageAuditFile = Join-Path $outputRoot ("KWR_{0}_PACKAGE_AUDIT.json" -f $safeVersion)

foreach ($path in @($distributionZip, $developerZip, $hashFile, $developerHashFile, $sourceManifestFile, $provenanceFile)) {
    if (-not $path) {
        continue
    }
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required package artifact is missing: $path"
    }
}
if (-not $SkipReproducibilityCheck -and -not (Test-Path -LiteralPath $reproducibilityFile)) {
    throw "Required package artifact is missing: $reproducibilityFile"
}

$expectedHashes = @{}
foreach ($line in Get-Content -LiteralPath $hashFile) {
    if ($line -match "^([A-Fa-f0-9]{64})\s+(.+)$") {
        $expectedHashes[$matches[2].Trim()] = $matches[1].ToUpperInvariant()
    }
}
$developerHashes = @{}
foreach ($line in Get-Content -LiteralPath $developerHashFile) {
    if ($line -match "^([A-Fa-f0-9]{64})\s+(.+)$") {
        $developerHashes[$matches[2].Trim()] = $matches[1].ToUpperInvariant()
    }
}
if ($sentinelZip) {
    $sentinelName = [IO.Path]::GetFileName($sentinelZip)
    if (-not $expectedHashes.ContainsKey($sentinelName)) {
        $sentinelZip = $null
    }
}
$hasSentinel = $sentinelZip -ne $null

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [object]$Data
    )

    $Data | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-ZipEntries {
    param([string]$Path)
    $archive = [IO.Compression.ZipFile]::OpenRead($Path)
    try {
        return @($archive.Entries | ForEach-Object { $_.FullName.Replace("\", "/") })
    } finally {
        $archive.Dispose()
    }
}

function Get-FengariInvocation {
    function Get-NodeExecutablePath {
        $candidates = New-Object System.Collections.Generic.List[string]

        if ($env:KWR_NODE_EXE) {
            $candidates.Add($env:KWR_NODE_EXE)
        }

        foreach ($commandName in @("node.exe", "node")) {
            $command = Get-Command $commandName -ErrorAction SilentlyContinue
            if ($command) {
                $candidates.Add($command.Source)
            }
        }

        foreach ($candidate in @(
            (Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe"),
            (Join-Path $env:LOCALAPPDATA "Programs\nodejs\node.exe")
        )) {
            if ($candidate) {
                $candidates.Add($candidate)
            }
        }

        foreach ($candidate in $candidates | Select-Object -Unique) {
            if ($candidate -and (Test-Path -LiteralPath $candidate)) {
                return [IO.Path]::GetFullPath($candidate)
            }
        }

        return $null
    }

    function Get-WorkspaceMirroredLuaToolsRoot {
        param(
            [Parameter(Mandatory = $true)]
            [string]$SourceLuaToolsRoot
        )

        $mirrorRoot = Join-Path $root "artifacts\tool-cache\kwr-lua-tools"
        $mirrorNodeModules = Join-Path $mirrorRoot "node_modules"
        $sourceNodeModules = Join-Path $SourceLuaToolsRoot "node_modules"
        $sourceCli = Join-Path $sourceNodeModules ".pnpm\fengari-node-cli@0.1.0\node_modules\fengari-node-cli\src\lua-cli.js"
        $mirrorCli = Join-Path $mirrorNodeModules ".pnpm\fengari-node-cli@0.1.0\node_modules\fengari-node-cli\src\lua-cli.js"

        if (-not (Test-Path -LiteralPath $mirrorCli)) {
            if (Test-Path -LiteralPath $mirrorNodeModules) {
                Remove-Item -LiteralPath $mirrorNodeModules -Recurse -Force
            }
            [IO.Directory]::CreateDirectory($mirrorRoot) | Out-Null
            foreach ($directory in Get-ChildItem -LiteralPath $sourceNodeModules -Recurse -Directory -Force -ErrorAction SilentlyContinue) {
                $relativePath = $directory.FullName.Substring($sourceNodeModules.Length).TrimStart('\')
                [IO.Directory]::CreateDirectory((Join-Path $mirrorNodeModules $relativePath)) | Out-Null
            }
            foreach ($file in Get-ChildItem -LiteralPath $sourceNodeModules -Recurse -File -Force -ErrorAction SilentlyContinue) {
                $relativePath = $file.FullName.Substring($sourceNodeModules.Length).TrimStart('\')
                $destinationPath = Join-Path $mirrorNodeModules $relativePath
                $destinationDirectory = Split-Path -Parent $destinationPath
                [IO.Directory]::CreateDirectory($destinationDirectory) | Out-Null
                try {
                    Copy-Item -LiteralPath $file.FullName -Destination $destinationPath -Force -ErrorAction Stop
                } catch {
                    continue
                }
            }
        }

        if (-not (Test-Path -LiteralPath $sourceCli) -or -not (Test-Path -LiteralPath $mirrorCli)) {
            throw "Unable to mirror the local Fengari runtime into the workspace cache."
        }

        return $mirrorRoot
    }

    $explicitNode = $env:KWR_NODE_EXE
    $explicitCli = $env:KWR_FENGARI_CLI
    if ($explicitNode -and
        $explicitCli -and
        (Test-Path -LiteralPath $explicitNode) -and
        (Test-Path -LiteralPath $explicitCli)) {
        return @{
            Command = [IO.Path]::GetFullPath($explicitNode)
            Arguments = @([IO.Path]::GetFullPath($explicitCli))
            NodePath = $null
        }
    }

    $luaToolsRoot = Join-Path $env:LOCALAPPDATA "Temp\kwr-lua-tools"
    $standardNodeModules = Join-Path $luaToolsRoot "node_modules"
    $standardCli = Join-Path $standardNodeModules "fengari-node-cli\src\lua-cli.js"
    $standardFengariPackage = Join-Path $standardNodeModules "fengari\package.json"
    if ((Test-Path -LiteralPath $standardCli -PathType Leaf) -and
        (Test-Path -LiteralPath $standardFengariPackage -PathType Leaf)) {
        $nodePath = Get-NodeExecutablePath
        if (-not $nodePath) {
            throw "Node.js is required for Fengari package-audit smoke tests."
        }
        return @{
            Command = $nodePath
            Arguments = @($standardCli)
            NodePath = $standardNodeModules
        }
    }

    $pnpmRoot = Join-Path $luaToolsRoot "node_modules\.pnpm"
    $sharedNodeModules = Join-Path $pnpmRoot "node_modules"
    $cliScript = Get-ChildItem -LiteralPath $pnpmRoot -Recurse -Filter "lua-cli.js" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -like "*fengari-node-cli*" } |
        Select-Object -First 1
    $fengariPackage = Get-ChildItem -LiteralPath $pnpmRoot -Directory -Filter "fengari@*" -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        Select-Object -First 1

    if ($cliScript -and $fengariPackage) {
        $nodePath = Get-NodeExecutablePath
        if (-not $nodePath) {
            throw "Node.js is required for Fengari package-audit smoke tests."
        }
        $effectiveLuaToolsRoot = $luaToolsRoot
        if ($cliScript.FullName -like ($luaToolsRoot + "*")) {
            $effectiveLuaToolsRoot = Get-WorkspaceMirroredLuaToolsRoot -SourceLuaToolsRoot $luaToolsRoot
        }
        $effectivePnpmRoot = Join-Path $effectiveLuaToolsRoot "node_modules\.pnpm"
        $effectiveCliScript = Get-ChildItem -LiteralPath $effectivePnpmRoot -Recurse -Filter "lua-cli.js" -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -like "*fengari-node-cli*" } |
            Select-Object -First 1
        $effectiveFengariPackage = Get-ChildItem -LiteralPath $effectivePnpmRoot -Directory -Filter "fengari@*" -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending |
            Select-Object -First 1
        if (-not $effectiveCliScript -or -not $effectiveFengariPackage) {
            throw "Fengari runtime mirror is incomplete."
        }
        $sharedNodeModules = Join-Path $effectivePnpmRoot "node_modules"
        $packageNodeModules = Get-ChildItem -LiteralPath $effectivePnpmRoot -Directory -ErrorAction SilentlyContinue |
            ForEach-Object { Join-Path $_.FullName "node_modules" } |
            Where-Object { Test-Path -LiteralPath $_ }
        $nodePaths = @(
            (Join-Path $effectiveFengariPackage.FullName "node_modules")
            $sharedNodeModules
        ) + $packageNodeModules
        $nodePaths = $nodePaths |
            Where-Object { $_ -and (Test-Path -LiteralPath $_) } |
            Select-Object -Unique
        return @{
            Command = $nodePath
            Arguments = @($effectiveCliScript.FullName)
            NodePath = ($nodePaths -join ";")
        }
    }

    $fengari = Get-Command "fengari.cmd" -ErrorAction SilentlyContinue
    if ($fengari) {
        return @{
            Command = $fengari.Source
            Arguments = @()
            NodePath = $null
        }
    }

    $fallback = Join-Path $luaToolsRoot "node_modules\.bin\fengari.CMD"
    if (Test-Path -LiteralPath $fallback) {
        return @{
            Command = $fallback
            Arguments = @()
            NodePath = $null
        }
    }

    throw "Fengari test runtime is required for extracted-package certification."
}

function Invoke-FengariScript {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Invocation,
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string]$ExpectedMarker
    )

    $previousNodePath = $env:NODE_PATH
    try {
        if ($Invocation.NodePath) {
            $env:NODE_PATH = if ([string]::IsNullOrWhiteSpace($previousNodePath)) {
                $Invocation.NodePath
            } else {
                $Invocation.NodePath + ";" + $previousNodePath
            }
        }
        $output = @(& $Invocation.Command @($Invocation.Arguments + @($ScriptPath)) 2>&1)
        $exitCode = [int]$LASTEXITCODE
        $output | Out-Host
        if ($exitCode -ne 0) {
            return $exitCode
        }
        if (-not ($output -match [regex]::Escape($ExpectedMarker))) {
            Write-Output "ERROR: Fengari completed without required pass marker '$ExpectedMarker': $ScriptPath"
            return 1
        }
        return 0
    } finally {
        $env:NODE_PATH = $previousNodePath
    }
}

function New-PackageHarnessScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$AddonRoot,
        [Parameter(Mandatory = $true)]
        [string]$DriverRoot,
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    $normalizedAddonRoot = $AddonRoot.Replace("\", "/")
    $normalizedDriverRoot = $DriverRoot.Replace("\", "/")
    $normalizedScriptPath = $ScriptPath.Replace("\", "/")
    $content = @"
_G.KWR_TEST_ROOT = [[$normalizedAddonRoot]]
_G.KWR_TEST_DRIVER_ROOT = [[$normalizedDriverRoot]]
_G.KWR_TEST_RELEASE_ONLY = true
dofile([[$normalizedScriptPath]])
"@
    Set-Content -LiteralPath $Path -Value $content -Encoding UTF8
}

$distributionEntries = Get-ZipEntries $distributionZip
$developerEntries = Get-ZipEntries $developerZip
$sentinelEntries = if ($hasSentinel) { Get-ZipEntries $sentinelZip } else { @() }
$releaseExcludedEntries = Get-ReleaseExcludedArchiveEntries -ArchiveRoot "KnomercyWarRoom"

if (@($distributionEntries | Where-Object { $_ -notlike "KnomercyWarRoom/*" }).Count -gt 0) {
    throw "Distribution ZIP contains entries outside the KnomercyWarRoom root."
}
if ($distributionEntries -notcontains "KnomercyWarRoom/KnomercyWarRoom.toc") {
    throw "Distribution ZIP is missing the addon TOC."
}
foreach ($entry in $releaseExcludedEntries) {
    if ($distributionEntries -contains $entry) {
        throw "Distribution ZIP still contains release-excluded content: $entry"
    }
}
if ($hasSentinel) {
    if (@($sentinelEntries | Where-Object { $_ -notlike "KWRSentinel/*" }).Count -gt 0) {
        throw "Sentinel ZIP contains entries outside the KWRSentinel root."
    }
    if ($sentinelEntries -notcontains "KWRSentinel/KWRSentinel.toc") {
        throw "Sentinel ZIP is missing the addon TOC."
    }
    $sentinelTocRuntimeFiles = Get-Content -LiteralPath (Join-Path $sentinelRoot "KWRSentinel.toc") |
        Where-Object { $_ -and $_ -notmatch '^##' }
    foreach ($runtimeFile in $sentinelTocRuntimeFiles) {
        $archivePath = "KWRSentinel/" + $runtimeFile.Replace("\", "/")
        if ($sentinelEntries -notcontains $archivePath) {
            throw "Sentinel ZIP is missing the TOC-required runtime file: $runtimeFile"
        }
    }
}
if (@($distributionEntries | Where-Object { $_ -match "(^|/)(tests|tools|knowledge)/" }).Count -gt 0) {
    throw "Distribution ZIP contains developer-only directories."
}
$productionDirectories = @(Get-ProductionPackageDirectories)
$productionFiles = @(Get-ProductionPackageFiles)
foreach ($entry in $distributionEntries) {
    if ($entry.EndsWith('/')) {
        continue
    }
    $relative = $entry -replace '^KnomercyWarRoom/', ''
    $topLevel = ($relative -split '/')[0]
    if ($relative -notin $productionFiles -and $topLevel -notin $productionDirectories) {
        throw "Distribution ZIP contains a file outside the production allowlist: $relative"
    }
}
foreach ($requiredFile in $productionFiles) {
    if ($distributionEntries -notcontains ("KnomercyWarRoom/" + $requiredFile)) {
        throw "Distribution ZIP is missing allowlisted production file: $requiredFile"
    }
}
if (@($distributionEntries | Where-Object { $_ -match "KWR_520|RC5_ReleaseReady|release-ready-candidate" }).Count -gt 0) {
    throw "Distribution ZIP contains legacy runtime content."
}
$distributionToc = Get-ZipEntries $distributionZip |
    Where-Object { $_ -eq "KnomercyWarRoom/KnomercyWarRoom.toc" }
if (-not $distributionToc) {
    throw "Distribution ZIP TOC lookup failed."
}

$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$tempRoot = Join-Path $tempBase ("kwr-package-audit-" + [guid]::NewGuid().ToString("N"))
[IO.Directory]::CreateDirectory($tempRoot) | Out-Null
try {
    $distributionExtract = Join-Path $tempRoot "distribution"
    Expand-Archive -LiteralPath $distributionZip -DestinationPath $distributionExtract
    $distributionAddonRoot = Join-Path $distributionExtract "KnomercyWarRoom"
    $distributionTocPath = Join-Path $distributionExtract "KnomercyWarRoom\KnomercyWarRoom.toc"
    $distributionTocText = Get-Content -LiteralPath $distributionTocPath -Raw
    foreach ($entry in Get-ReleaseExcludedEntries) {
        if ($distributionTocText -match [regex]::Escape($entry)) {
            throw "Distribution TOC still references release-excluded content: $entry"
        }
        if (Test-Path -LiteralPath (Join-Path $distributionExtract ("KnomercyWarRoom\" + $entry))) {
            throw "Distribution extract still contains release-excluded content: $entry"
        }
    }

    $fengari = Get-FengariInvocation
    $distributionSmokeHarness = Join-Path $tempRoot "distribution-smoke.lua"
    $distributionSoakHarness = Join-Path $tempRoot "distribution-soak.lua"
    New-PackageHarnessScript -Path $distributionSmokeHarness -AddonRoot $distributionAddonRoot -DriverRoot (Join-Path $root "tests") -ScriptPath (Join-Path $root "tests\smoke.lua")
    New-PackageHarnessScript -Path $distributionSoakHarness -AddonRoot $distributionAddonRoot -DriverRoot (Join-Path $root "tests") -ScriptPath (Join-Path $root "tests\soak.lua")
    $distributionSmokeExit = Invoke-FengariScript -Invocation $fengari `
        -ScriptPath $distributionSmokeHarness -ExpectedMarker "KWR_SMOKE_PASS"
    if ($distributionSmokeExit -ne 0) { throw "Extracted distribution smoke test failed." }
    $distributionSoakExit = Invoke-FengariScript -Invocation $fengari `
        -ScriptPath $distributionSoakHarness -ExpectedMarker "KWR_SOAK_PASS"
    if ($distributionSoakExit -ne 0) { throw "Extracted distribution soak test failed." }

    if ($hasSentinel) {
        $sentinelExtract = Join-Path $tempRoot "sentinel"
        Expand-Archive -LiteralPath $sentinelZip -DestinationPath $sentinelExtract
        $sentinelAddonRoot = Join-Path $sentinelExtract "KWRSentinel"
        $sentinelHarness = Join-Path $tempRoot "sentinel-transport.lua"
        $sentinelTestPath = (Join-Path $root "tests\sentinel-transport.lua").Replace("\", "/")
        $sentinelRootPath = $sentinelAddonRoot.Replace("\", "/")
        Set-Content -LiteralPath $sentinelHarness -Encoding UTF8 -Value @(
            "KWR_SENTINEL_TEST_ROOT = [[$sentinelRootPath]]",
            "dofile([[$sentinelTestPath]])"
        )
        $sentinelTransportExit = Invoke-FengariScript -Invocation $fengari `
            -ScriptPath $sentinelHarness -ExpectedMarker "KWR_SENTINEL_TRANSPORT_PASS"
        if ($sentinelTransportExit -ne 0) { throw "Extracted Sentinel transport test failed." }
    }
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        $resolved = [IO.Path]::GetFullPath($tempRoot)
        if (-not $resolved.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove unexpected audit path: $resolved"
        }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}

if (@($developerEntries | Where-Object { $_ -notlike "KnomercyWarRoom-Developer/*" }).Count -gt 0) {
    throw "Developer ZIP contains entries outside its expected root."
}
foreach ($required in @(
    "KnomercyWarRoom-Developer/src/KnomercyWarRoom/tests/smoke.lua",
    "KnomercyWarRoom-Developer/src/KnomercyWarRoom/tests/sentinel-transport.lua",
    "KnomercyWarRoom-Developer/src/KnomercyWarRoom/tests/soak.lua",
    "KnomercyWarRoom-Developer/src/KnomercyWarRoom/tools/validate.ps1",
    "KnomercyWarRoom-Developer/src/KnomercyWarRoom/BATTLEGROUND_VERIFICATION.md"
)) {
    if ($developerEntries -notcontains $required) {
        throw "Developer ZIP is missing: $required"
    }
}

foreach ($path in @($distributionZip, $sentinelZip)) {
    if (-not $path) {
        continue
    }
    $name = [IO.Path]::GetFileName($path)
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    if ($expectedHashes[$name] -ne $actual) {
        throw "SHA-256 mismatch for $name"
    }
}
$developerName = [IO.Path]::GetFileName($developerZip)
$developerActual = (Get-FileHash -LiteralPath $developerZip -Algorithm SHA256).Hash
if ($developerHashes[$developerName] -ne $developerActual) {
    throw "SHA-256 mismatch for $developerName"
}

$sourceManifest = Get-Content -LiteralPath $sourceManifestFile -Raw | ConvertFrom-Json
$provenance = Get-Content -LiteralPath $provenanceFile -Raw | ConvertFrom-Json
$reproducibility = $null
if (Test-Path -LiteralPath $reproducibilityFile) {
    $reproducibility = Get-Content -LiteralPath $reproducibilityFile -Raw | ConvertFrom-Json
}
if (-not $sourceManifest.distribution.digest) {
    throw "Source manifest is missing the distribution digest."
}
if (-not $provenance.outputArtifacts -or $provenance.outputArtifacts.Count -lt 2) {
    throw "Build provenance is missing artifact summaries."
}
if (-not $SkipReproducibilityCheck -and -not $reproducibility) {
    throw "Reproducibility report is required for the default package audit."
}
if ($reproducibility -and $reproducibility.result -notlike "PASS*") {
    throw "Reproducibility report is not PASS-compatible."
}

$tempRoot = Join-Path $tempBase ("kwr-package-audit-dev-" + [guid]::NewGuid().ToString("N"))
[IO.Directory]::CreateDirectory($tempRoot) | Out-Null
try {
    Write-Output "KWR package-audit checkpoint: extracting developer archive ($($developerEntries.Count) entries)"
    Expand-Archive -LiteralPath $developerZip -DestinationPath $tempRoot
    $source = Join-Path $tempRoot "KnomercyWarRoom-Developer\src\KnomercyWarRoom"
    Write-Output "KWR package-audit checkpoint: validating extracted developer source"
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $source "tools\validate.ps1")
    if ($LASTEXITCODE -ne 0) { throw "Extracted developer validation failed." }
    Write-Output "KWR package-audit checkpoint: auditing extracted developer knowledge"
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $source "tools\knowledge-audit.ps1") -AllowGeneratedEvidenceOmission
    if ($LASTEXITCODE -ne 0) { throw "Extracted developer knowledge audit failed." }

    $fengari = Get-FengariInvocation
    Push-Location $source
    try {
        Write-Output "KWR package-audit checkpoint: running extracted developer smoke"
        $smokeExit = Invoke-FengariScript -Invocation $fengari `
            -ScriptPath "tests\smoke.lua" -ExpectedMarker "KWR_SMOKE_PASS"
        if ($smokeExit -ne 0) { throw "Extracted developer smoke test failed." }
        Write-Output "KWR package-audit checkpoint: running extracted developer soak"
        $soakExit = Invoke-FengariScript -Invocation $fengari `
            -ScriptPath "tests\soak.lua" -ExpectedMarker "KWR_SOAK_PASS"
        if ($soakExit -ne 0) { throw "Extracted developer soak test failed." }
    } finally {
        Pop-Location
    }
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Write-Output "KWR package-audit checkpoint: removing extracted developer workspace"
        $resolved = [IO.Path]::GetFullPath($tempRoot)
        if (-not $resolved.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove unexpected audit path: $resolved"
        }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}

Write-Output "KWR PACKAGE AUDIT PASSED"
Write-Output "Distribution entries: $($distributionEntries.Count)"
Write-Output "Developer entries: $($developerEntries.Count)"
if ($hasSentinel) {
    Write-Output "Sentinel entries: $($sentinelEntries.Count)"
}
$hashCount = if ($hasSentinel) { 3 } else { 2 }
Write-Output "Hashes verified: $hashCount"
Write-Output "Extracted distribution smoke and soak: passed"
Write-Output "Extracted developer smoke and soak: passed"
if ($SkipReproducibilityCheck) {
    Write-Output "Reproducibility check: skipped by request"
} else {
    Write-Output "Reproducibility check: PASS-compatible"
}

$packageAudit = [pscustomobject]@{
    candidate = $version
    auditedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    result = "PASS"
    outputDirectory = $outputRoot
    distributionEntries = $distributionEntries.Count
    developerEntries = $developerEntries.Count
    sentinelEntries = if ($hasSentinel) { $sentinelEntries.Count } else { $null }
    hashesVerified = $hashCount
    extractedDistributionRuntime = "PASS"
    extractedDeveloperRuntime = "PASS"
    reproducibilityCheck = if ($SkipReproducibilityCheck) { "SKIPPED_BY_REQUEST" } else { "PASS_COMPATIBLE" }
}
Write-JsonFile -Path $packageAuditFile -Data $packageAudit
