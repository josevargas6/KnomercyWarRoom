[CmdletBinding()]
param(
    [string]$BuildInfoPath = "D:\\Program Files\\World of Warcraft\\.build.info",
    [string]$CommanderTocPath,
    [string]$SentinelTocPath,
    [string]$PatchDataPath,
    [string]$OutFile = "knowledge\\client-build-preflight.json",
    [switch]$FailOnMismatch
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))

if (-not $CommanderTocPath) { $CommanderTocPath = Join-Path $root "KnomercyWarRoom.toc" }
if (-not $SentinelTocPath) { $SentinelTocPath = Join-Path $root "KWRSentinel\\KWRSentinel.toc" }
if (-not $PatchDataPath) { $PatchDataPath = Join-Path $root "Data\\PatchData.lua" }
if (-not [IO.Path]::IsPathRooted($OutFile)) { $OutFile = Join-Path $root $OutFile }

function Require-File {
    param([string]$Path, [string]$Label)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Label is missing: $Path"
    }
}

function Get-TocMetadata {
    param([string]$Path, [string]$Label)

    Require-File $Path $Label
    $source = Get-Content -LiteralPath $Path -Raw
    $interfacesMatch = [regex]::Match($source, '(?m)^## Interface:\s*([\d,\s]+)$')
    $versionMatch = [regex]::Match($source, '(?m)^## Version:\s*(.+)$')
    if (-not $interfacesMatch.Success -or -not $versionMatch.Success) {
        throw "$Label does not declare one Interface and Version field: $Path"
    }
    return [ordered]@{
        path = [IO.Path]::GetFullPath($Path)
        version = $versionMatch.Groups[1].Value.Trim()
        interfaces = @($interfacesMatch.Groups[1].Value -split ',' |
            ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' })
    }
}

function Get-ActiveClientBuild {
    param([string]$Path)

    Require-File $Path "World of Warcraft .build.info"
    $lines = @(Get-Content -LiteralPath $Path | Where-Object { $_.Trim() })
    if ($lines.Count -lt 2) { throw "World of Warcraft .build.info has no product rows: $Path" }
    $headers = @($lines[0] -split '\|' | ForEach-Object { ($_ -replace '!.*$', '').Trim() })
    $rows = foreach ($line in $lines | Select-Object -Skip 1) {
        # PowerShell's negative max-substrings value retains one unsplit field.
        # Omit it: .build.info has no escaped pipe representation.
        $values = @($line -split '\|')
        $row = [ordered]@{}
        for ($index = 0; $index -lt $headers.Count; $index++) {
            $row[$headers[$index]] = if ($index -lt $values.Count) { $values[$index].Trim() } else { "" }
        }
        [pscustomobject]$row
    }
    $row = @($rows | Where-Object { $_.Product -eq 'wow' -and $_.Active -eq '1' }) | Select-Object -First 1
    if (-not $row) { throw "World of Warcraft .build.info has no active Retail (wow) product row." }
    $match = [regex]::Match([string]$row.Version, '^(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)\.(?<build>\d+)$')
    if (-not $match.Success) { throw "Active Retail version is not a supported four-part version: $($row.Version)" }
    $major = [int]$match.Groups['major'].Value
    $minor = [int]$match.Groups['minor'].Value
    $patch = [int]$match.Groups['patch'].Value
    return [ordered]@{
        buildInfoPath = [IO.Path]::GetFullPath($Path)
        version = [string]$row.Version
        patchVersion = "$major.$minor.$patch"
        interface = ($major * 10000) + ($minor * 100) + $patch
    }
}

function Get-ActivePatchMetadata {
    param([string]$Path)

    Require-File $Path "PatchData.lua"
    $source = Get-Content -LiteralPath $Path -Raw
    $activeMatch = [regex]::Match($source, 'activePatch\s*=\s*"(?<patch>[^"]+)"')
    if (-not $activeMatch.Success) { throw "PatchData.lua does not declare activePatch." }
    $activePatch = $activeMatch.Groups['patch'].Value
    $packPattern = '\["' + [regex]::Escape($activePatch) + '"\]\s*=\s*\{(?<body>[\s\S]*?)(?=^\s{4}\["|\z)'
    $packMatch = [regex]::Match($source, $packPattern, [Text.RegularExpressions.RegexOptions]::Multiline)
    if (-not $packMatch.Success) { throw "PatchData.lua has no pack for activePatch $activePatch." }
    $interfaceMatch = [regex]::Match($packMatch.Groups['body'].Value, '(?m)^\s*interface\s*=\s*(?<interface>\d+)\s*,')
    if (-not $interfaceMatch.Success) { throw "Active patch pack $activePatch has no interface field." }
    return [ordered]@{
        path = [IO.Path]::GetFullPath($Path)
        activePatch = $activePatch
        interface = [int]$interfaceMatch.Groups['interface'].Value
    }
}

$client = Get-ActiveClientBuild $BuildInfoPath
$commander = Get-TocMetadata $CommanderTocPath "Commander TOC"
$sentinel = Get-TocMetadata $SentinelTocPath "Sentinel TOC"
$patchData = Get-ActivePatchMetadata $PatchDataPath

$checks = @(
    [ordered]@{ name = "active-patch-matches-client"; pass = $patchData.activePatch -eq $client.patchVersion; expected = $client.patchVersion; actual = $patchData.activePatch },
    [ordered]@{ name = "active-patch-interface-matches-client"; pass = $patchData.interface -eq $client.interface; expected = $client.interface; actual = $patchData.interface },
    [ordered]@{ name = "commander-declares-client-interface"; pass = $commander.interfaces -contains "$($client.interface)"; expected = $client.interface; actual = $commander.interfaces },
    [ordered]@{ name = "sentinel-declares-client-interface"; pass = $sentinel.interfaces -contains "$($client.interface)"; expected = $client.interface; actual = $sentinel.interfaces },
    [ordered]@{ name = "companion-versions-match"; pass = $commander.version -eq $sentinel.version; expected = $commander.version; actual = $sentinel.version }
)
$passed = @($checks | Where-Object { -not $_.pass }).Count -eq 0
$status = if ($passed) { "PASS_METADATA_ONLY" } elseif ($patchData.activePatch -ne $client.patchVersion -or $patchData.interface -ne $client.interface) { "MISMATCH_ACTIVE_PATCH" } else { "UNSUPPORTED_CLIENT_INTERFACE" }
$report = [ordered]@{
    schema = "kwr-client-build-preflight"
    schemaVersion = 1
    generatedAt = [DateTime]::UtcNow.ToString("o")
    status = $status
    scope = "Installed-client and source-metadata comparison only; this does not prove addon load, API behavior, package identity, taint safety, or release readiness."
    client = $client
    patchData = $patchData
    commander = $commander
    sentinel = $sentinel
    checks = $checks
    nextStep = if ($passed) { "Run this check against the clean tagged package before live verification, then capture actual addon load and API behavior in Retail." } else { "Do not certify this client. Update the reviewed patch data and both package TOCs only after an official compatibility review." }
}

[IO.Directory]::CreateDirectory((Split-Path -Parent $OutFile)) | Out-Null
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutFile -Encoding utf8
Write-Output "KWR client-build preflight: $status"
Write-Output "Client: $($client.version) (interface $($client.interface))"
Write-Output "Report: $OutFile"
if ($FailOnMismatch -and -not $passed) { exit 1 }
