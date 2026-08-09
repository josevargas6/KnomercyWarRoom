[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$audit = Join-Path $PSScriptRoot 'deployment-manifest-audit.ps1'
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('kwr-deployment-test-' + [guid]::NewGuid().ToString('N'))
$package = Join-Path $fixtureRoot 'package\KnomercyWarRoom'
$installed = Join-Path $fixtureRoot 'installed\KnomercyWarRoom'
$snapshot = Join-Path $fixtureRoot 'snapshot'

try {
    [IO.Directory]::CreateDirectory($package) | Out-Null
    [IO.Directory]::CreateDirectory($installed) | Out-Null
    [IO.Directory]::CreateDirectory($snapshot) | Out-Null
    Set-Content -LiteralPath (Join-Path $package 'KnomercyWarRoom.toc') -Value '## Version: test'
    Set-Content -LiteralPath (Join-Path $package 'Core.lua') -Value 'package'
    Set-Content -LiteralPath (Join-Path $installed 'KnomercyWarRoom.toc') -Value '## Version: test'
    Set-Content -LiteralPath (Join-Path $installed 'Core.lua') -Value 'changed'
    Set-Content -LiteralPath (Join-Path $installed 'stale.lua') -Value 'stale'

    $previousErrorPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $audit `
        -PackageRoot $package -InstalledRoot $installed *> $null
    $auditExitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorPreference
    if ($auditExitCode -eq 0) {
        throw 'Deployment audit accepted changed and extra files.'
    }

    & powershell -NoProfile -ExecutionPolicy Bypass -File $audit `
        -PackageRoot $package `
        -InstalledRoot $installed `
        -Synchronize `
        -ConfirmSynchronize DEPLOY `
        -RollbackSnapshot $snapshot
    if ($LASTEXITCODE -ne 0) {
        throw 'Deployment synchronization failed.'
    }
    if (Test-Path -LiteralPath (Join-Path $installed 'stale.lua')) {
        throw 'Deployment synchronization retained an extra file.'
    }
    if ((Get-Content -LiteralPath (Join-Path $installed 'Core.lua') -Raw).Trim() -ne 'package') {
        throw 'Deployment synchronization did not restore package content.'
    }
    Write-Output 'KWR_DEPLOYMENT_MANIFEST_TEST_PASS'
} finally {
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}
