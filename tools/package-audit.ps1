[CmdletBinding()]
param(
    [string]$OutputDirectory = "C:\Users\josev\Desktop\KWR\Builds"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$toc = Get-Content -LiteralPath (Join-Path $root "KnomercyWarRoom.toc")
$version = (($toc | Where-Object { $_ -match "^## Version:" }) -replace "^## Version:\s*", "").Trim()
$safeVersion = $version.ToUpperInvariant().Replace(".", "_").Replace("-", "_")
$outputRoot = [IO.Path]::GetFullPath($OutputDirectory)
$distributionZip = Join-Path $outputRoot ("KWR_{0}_DISTRIBUTION.zip" -f $safeVersion)
$developerZip = Join-Path $outputRoot ("KWR_{0}_DEVELOPER.zip" -f $safeVersion)
$hashFile = Join-Path $outputRoot ("KWR_{0}_SHA256.txt" -f $safeVersion)

foreach ($path in @($distributionZip, $developerZip, $hashFile)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required package artifact is missing: $path"
    }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-ZipEntries {
    param([string]$Path)
    $archive = [IO.Compression.ZipFile]::OpenRead($Path)
    try {
        return @($archive.Entries | ForEach-Object { $_.FullName.Replace("\", "/") })
    } finally {
        $archive.Dispose()
    }
}

$distributionEntries = Get-ZipEntries $distributionZip
$developerEntries = Get-ZipEntries $developerZip

if (@($distributionEntries | Where-Object { $_ -notlike "KnomercyWarRoom/*" }).Count -gt 0) {
    throw "Distribution ZIP contains entries outside the KnomercyWarRoom root."
}
if ($distributionEntries -notcontains "KnomercyWarRoom/KnomercyWarRoom.toc") {
    throw "Distribution ZIP is missing the addon TOC."
}
if (@($distributionEntries | Where-Object { $_ -match "(^|/)(tests|tools|knowledge)/" }).Count -gt 0) {
    throw "Distribution ZIP contains developer-only directories."
}
if (@($distributionEntries | Where-Object { $_ -match "KWR_520|RC5_ReleaseReady|release-ready-candidate" }).Count -gt 0) {
    throw "Distribution ZIP contains legacy runtime content."
}
if (@($developerEntries | Where-Object { $_ -notlike "KnomercyWarRoom-Developer/*" }).Count -gt 0) {
    throw "Developer ZIP contains entries outside its expected root."
}
foreach ($required in @(
    "KnomercyWarRoom-Developer/src/KnomercyWarRoom/tests/smoke.lua",
    "KnomercyWarRoom-Developer/src/KnomercyWarRoom/tests/soak.lua",
    "KnomercyWarRoom-Developer/src/KnomercyWarRoom/tools/validate.ps1",
    "KnomercyWarRoom-Developer/src/KnomercyWarRoom/BATTLEGROUND_VERIFICATION.md"
)) {
    if ($developerEntries -notcontains $required) {
        throw "Developer ZIP is missing: $required"
    }
}

$expectedHashes = @{}
foreach ($line in Get-Content -LiteralPath $hashFile) {
    if ($line -match "^([A-Fa-f0-9]{64})\s+(.+)$") {
        $expectedHashes[$matches[2].Trim()] = $matches[1].ToUpperInvariant()
    }
}
foreach ($path in @($distributionZip, $developerZip)) {
    $name = [IO.Path]::GetFileName($path)
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    if ($expectedHashes[$name] -ne $actual) {
        throw "SHA-256 mismatch for $name"
    }
}

$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$tempRoot = Join-Path $tempBase ("kwr-package-audit-" + [guid]::NewGuid().ToString("N"))
[IO.Directory]::CreateDirectory($tempRoot) | Out-Null
try {
    Expand-Archive -LiteralPath $developerZip -DestinationPath $tempRoot
    $source = Join-Path $tempRoot "KnomercyWarRoom-Developer\src\KnomercyWarRoom"
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $source "tools\validate.ps1")
    if ($LASTEXITCODE -ne 0) { throw "Extracted developer validation failed." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $source "tools\knowledge-audit.ps1")
    if ($LASTEXITCODE -ne 0) { throw "Extracted developer knowledge audit failed." }

    $fengari = Get-Command "fengari.cmd" -ErrorAction SilentlyContinue
    $fengariPath = if ($fengari) { $fengari.Source } else {
        Join-Path $env:LOCALAPPDATA "Temp\kwr-lua-tools\node_modules\.bin\fengari.CMD"
    }
    if (-not (Test-Path -LiteralPath $fengariPath)) {
        throw "Fengari test runtime is required for extracted-package certification."
    }
    Push-Location $source
    try {
        & $fengariPath "tests\smoke.lua"
        if ($LASTEXITCODE -ne 0) { throw "Extracted developer smoke test failed." }
        & $fengariPath "tests\soak.lua"
        if ($LASTEXITCODE -ne 0) { throw "Extracted developer soak test failed." }
    } finally {
        Pop-Location
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

Write-Output "KWR PACKAGE AUDIT PASSED"
Write-Output "Distribution entries: $($distributionEntries.Count)"
Write-Output "Developer entries: $($developerEntries.Count)"
Write-Output "Hashes verified: 2"
Write-Output "Extracted smoke and soak: passed"
