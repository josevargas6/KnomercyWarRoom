[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PackageRoot,
    [Parameter(Mandatory = $true)]
    [string]$InstalledRoot,
    [string]$ReceiptPath,
    [switch]$Synchronize,
    [string]$ConfirmSynchronize = '',
    [string]$RollbackSnapshot = ''
)

$ErrorActionPreference = 'Stop'
$toolsRoot = [IO.Path]::GetFullPath($PSScriptRoot)
. (Join-Path $toolsRoot 'release-manifest.ps1')

function Resolve-ExistingDirectory {
    param([string]$Path, [string]$Label)

    $resolved = [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    if (-not (Test-Path -LiteralPath $resolved -PathType Container)) {
        throw "$Label directory is missing: $resolved"
    }
    return $resolved
}

function Get-EntryMap {
    param([string]$RootPath)

    $map = @{}
    foreach ($entry in Get-DirectoryManifestEntries -RootPath $RootPath) {
        $map[$entry.path.ToLowerInvariant()] = $entry
    }
    return $map
}

function Compare-Deployment {
    param([string]$SourceRoot, [string]$TargetRoot)

    $source = Get-EntryMap -RootPath $SourceRoot
    $target = Get-EntryMap -RootPath $TargetRoot
    $missing = [System.Collections.Generic.List[string]]::new()
    $changed = [System.Collections.Generic.List[string]]::new()
    $extra = [System.Collections.Generic.List[string]]::new()

    foreach ($key in $source.Keys) {
        if (-not $target.ContainsKey($key)) {
            $missing.Add($source[$key].path)
            continue
        }
        if ($source[$key].size -ne $target[$key].size -or
            $source[$key].sha256 -cne $target[$key].sha256) {
            $changed.Add($source[$key].path)
        }
    }
    foreach ($key in $target.Keys) {
        if (-not $source.ContainsKey($key)) {
            $extra.Add($target[$key].path)
        }
    }

    return [pscustomobject]@{
        packageEntries = $source.Count
        installedEntries = $target.Count
        missing = @($missing | Sort-Object)
        changed = @($changed | Sort-Object)
        extra = @($extra | Sort-Object)
        packageDigest = Get-ManifestDigest -Entries @($source.Values | Sort-Object path)
        installedDigest = Get-ManifestDigest -Entries @($target.Values | Sort-Object path)
    }
}

function Assert-SafeInstalledRoot {
    param([string]$Path)

    $leaf = Split-Path -Leaf $Path
    if ($leaf -notin @('KnomercyWarRoom', 'KWRSentinel')) {
        throw "Installed root must be exactly KnomercyWarRoom or KWRSentinel: $Path"
    }
    $toc = if ($leaf -eq 'KnomercyWarRoom') { 'KnomercyWarRoom.toc' } else { 'KWRSentinel.toc' }
    if (-not (Test-Path -LiteralPath (Join-Path $Path $toc) -PathType Leaf)) {
        throw "Installed root does not contain expected addon manifest ${toc}: $Path"
    }
}

function Remove-SafeExtraFile {
    param([string]$TargetRoot, [string]$RelativePath)

    $targetPrefix = $TargetRoot.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    $path = [IO.Path]::GetFullPath((Join-Path $TargetRoot $RelativePath))
    if (-not $path.StartsWith($targetPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove path outside installed root: $path"
    }
    Remove-Item -LiteralPath $path -Force
}

$packageRoot = Resolve-ExistingDirectory -Path $PackageRoot -Label 'Package root'
$installedRoot = Resolve-ExistingDirectory -Path $InstalledRoot -Label 'Installed root'
Assert-SafeInstalledRoot -Path $installedRoot
$before = Compare-Deployment -SourceRoot $packageRoot -TargetRoot $installedRoot

if ($Synchronize) {
    if ($ConfirmSynchronize -cne 'DEPLOY') {
        throw 'Synchronize requires ConfirmSynchronize=DEPLOY.'
    }
    $snapshot = Resolve-ExistingDirectory -Path $RollbackSnapshot -Label 'Rollback snapshot'
    if ((Get-Process -Name 'Wow' -ErrorAction SilentlyContinue).Count -gt 0) {
        throw 'World of Warcraft is running. Exit the client before synchronizing addon files.'
    }

    foreach ($entry in @($before.extra)) {
        Remove-SafeExtraFile -TargetRoot $installedRoot -RelativePath $entry
    }
    foreach ($file in Get-ChildItem -LiteralPath $packageRoot -Recurse -File) {
        $relative = Get-NormalizedRelativePath -RootPath $packageRoot -FullPath $file.FullName
        $destination = Join-Path $installedRoot $relative
        [IO.Directory]::CreateDirectory((Split-Path -Parent $destination)) | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
    }
    foreach ($directory in Get-ChildItem -LiteralPath $installedRoot -Recurse -Directory |
        Sort-Object FullName -Descending) {
        if ((Test-Path -LiteralPath $directory.FullName -PathType Container) -and
            @(Get-ChildItem -LiteralPath $directory.FullName -Force -ErrorAction SilentlyContinue).Count -eq 0) {
            Remove-Item -LiteralPath $directory.FullName -Force
        }
    }
    $after = Compare-Deployment -SourceRoot $packageRoot -TargetRoot $installedRoot
} else {
    $snapshot = $null
    $after = $before
}

$passed = $after.missing.Count -eq 0 -and
    $after.changed.Count -eq 0 -and
    $after.extra.Count -eq 0
$receipt = [ordered]@{
    schema = 'kwr-deployment-manifest-audit'
    schemaVersion = 1
    generatedAt = [DateTimeOffset]::UtcNow.ToString('o')
    packageRoot = $packageRoot
    installedRoot = $installedRoot
    synchronized = [bool]$Synchronize
    rollbackSnapshot = $snapshot
    before = $before
    after = $after
    result = if ($passed) { 'PASS' } else { 'FAIL' }
}

if ($ReceiptPath) {
    $resolvedReceipt = [IO.Path]::GetFullPath($ReceiptPath)
    [IO.Directory]::CreateDirectory((Split-Path -Parent $resolvedReceipt)) | Out-Null
    [IO.File]::WriteAllText(
        $resolvedReceipt,
        (($receipt | ConvertTo-Json -Depth 8) + [Environment]::NewLine),
        [Text.UTF8Encoding]::new($false)
    )
    Write-Output "Receipt: $resolvedReceipt"
}

Write-Output 'KWR deployment manifest audit'
Write-Output "Package entries: $($after.packageEntries)"
Write-Output "Installed entries: $($after.installedEntries)"
Write-Output "Missing: $($after.missing.Count)"
Write-Output "Changed: $($after.changed.Count)"
Write-Output "Extra: $($after.extra.Count)"
Write-Output "Result: $($receipt.result)"
if (-not $passed) {
    foreach ($entry in $after.missing) { Write-Error "Missing installed file: $entry" -ErrorAction Continue }
    foreach ($entry in $after.changed) { Write-Error "Changed installed file: $entry" -ErrorAction Continue }
    foreach ($entry in $after.extra) { Write-Error "Extra installed file: $entry" -ErrorAction Continue }
    exit 1
}
