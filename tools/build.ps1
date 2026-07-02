[CmdletBinding()]
param(
    [string]$OutputDirectory = "C:\Users\josev\Desktop\KWR\Builds"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$validator = Join-Path $PSScriptRoot "validate.ps1"

& $validator
if ($LASTEXITCODE -ne 0) {
    throw "Validation failed. Packages were not created."
}

$toc = Get-Content -LiteralPath (Join-Path $root "KnomercyWarRoom.toc")
$version = (($toc | Where-Object { $_ -match "^## Version:" }) -replace "^## Version:\s*", "").Trim()
$safeVersion = $version.ToUpperInvariant().Replace(".", "_").Replace("-", "_")

[IO.Directory]::CreateDirectory($OutputDirectory) | Out-Null
$outputRoot = [IO.Path]::GetFullPath($OutputDirectory)
$distributionZip = Join-Path $outputRoot ("KWR_{0}_DISTRIBUTION.zip" -f $safeVersion)
$developerZip = Join-Path $outputRoot ("KWR_{0}_DEVELOPER.zip" -f $safeVersion)
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

    foreach ($directory in @("Core", "Data", "Runtime", "Features", "UI")) {
        Copy-Item -LiteralPath (Join-Path $root $directory) -Destination $distributionRoot -Recurse
    }
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

    foreach ($item in Get-ChildItem -LiteralPath $root -Force) {
        if ($item.Name -in @(".git", "artifacts", "node_modules")) {
            continue
        }
        Copy-Item -LiteralPath $item.FullName -Destination $developerSource -Recurse
    }
    Copy-Item -LiteralPath (Join-Path $root "DEVELOPMENT.md") -Destination (Join-Path $developerRoot "README.md")

    foreach ($path in @($distributionZip, $developerZip, $hashFile)) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Force
        }
    }

    Compress-Archive -LiteralPath (Join-Path $tempRoot "distribution\KnomercyWarRoom") -DestinationPath $distributionZip -CompressionLevel Optimal
    Compress-Archive -LiteralPath (Join-Path $tempRoot "developer\KnomercyWarRoom-Developer") -DestinationPath $developerZip -CompressionLevel Optimal

    $distributionHash = Get-FileHash -LiteralPath $distributionZip -Algorithm SHA256
    $developerHash = Get-FileHash -LiteralPath $developerZip -Algorithm SHA256
    @(
        "$($distributionHash.Hash)  $([IO.Path]::GetFileName($distributionZip))",
        "$($developerHash.Hash)  $([IO.Path]::GetFileName($developerZip))"
    ) | Set-Content -LiteralPath $hashFile -Encoding ASCII

    Write-Output "Distribution: $distributionZip"
    Write-Output "Developer:    $developerZip"
    Write-Output "Hashes:       $hashFile"

    & (Join-Path $PSScriptRoot "package-audit.ps1") -OutputDirectory $outputRoot
    if ($LASTEXITCODE -ne 0) {
        throw "Package audit failed."
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
