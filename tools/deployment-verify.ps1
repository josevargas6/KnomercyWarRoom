[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PackageManifest,
    [Parameter(Mandatory = $true)]
    [string]$InstalledAddonRoot
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $PackageManifest)) {
    throw "Package manifest does not exist: $PackageManifest"
}
if (-not (Test-Path -LiteralPath $InstalledAddonRoot)) {
    throw "Installed addon root does not exist: $InstalledAddonRoot"
}

$manifest = Get-Content -LiteralPath $PackageManifest -Raw | ConvertFrom-Json
$expected = @{}
foreach ($entry in @($manifest.distribution.entries)) {
    $expected[$entry.path.Replace('/', '\')] = $entry
}
$productionRoots = @($manifest.productionAllowlist.directories)
$errors = [System.Collections.Generic.List[string]]::new()
$actual = @{}
$installedRootFullPath = [IO.Path]::GetFullPath($InstalledAddonRoot).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
foreach ($file in Get-ChildItem -LiteralPath $InstalledAddonRoot -Recurse -File -Force) {
    $relative = $file.FullName.Substring($installedRootFullPath.Length + 1)
    $topLevel = ($relative -split '[\\/]')[0]
    if ($expected.ContainsKey($relative) -or $topLevel -in $productionRoots) {
        $actual[$relative] = [pscustomobject]@{
            size = [int64]$file.Length
            sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
        }
    }
}

foreach ($path in $expected.Keys) {
    if (-not $actual.ContainsKey($path)) {
        $errors.Add("Installed addon is missing package file: $path")
        continue
    }
    if ($actual[$path].size -ne [int64]$expected[$path].size -or
        $actual[$path].sha256 -ne $expected[$path].sha256) {
        $errors.Add("Installed addon differs from package manifest: $path")
    }
}
foreach ($path in $actual.Keys) {
    if (-not $expected.ContainsKey($path)) {
        $errors.Add("Installed addon contains extra production file: $path")
    }
}

Write-Output 'KWR deployment-manifest verification'
Write-Output "Expected production files: $($expected.Count)"
Write-Output "Installed production files: $($actual.Count)"
Write-Output "Errors: $($errors.Count)"
foreach ($errorText in $errors) {
    Write-Error $errorText -ErrorAction Continue
}
if ($errors.Count -gt 0) {
    exit 1
}
Write-Output 'DEPLOYMENT MANIFEST VERIFICATION PASSED'
