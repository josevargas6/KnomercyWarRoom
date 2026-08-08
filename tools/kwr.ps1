[CmdletBinding()]
param(
    [Parameter(Position = 0)] [ValidateSet('status','validate','deploy-development','deploy-sandbox')] [string]$Command = 'status',
    [ValidateSet('production','release-candidate','beta','development','local')] [string]$Channel,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$toc = Join-Path $root 'KnomercyWarRoom.toc'
$version = ((Get-Content -LiteralPath $toc | Where-Object { $_ -match '^## Version:' }) -replace '^## Version:\s*','').Trim()
$git = Get-Command git -ErrorAction SilentlyContinue
$isRepository = $git -and (Test-Path -LiteralPath (Join-Path $root '.git'))
$branch = if ($isRepository) { ((& git -C $root branch --show-current 2>$null) -join '').Trim() } else { 'unknown' }
$commit = if ($isRepository) { ((& git -C $root rev-parse --short HEAD 2>$null) -join '').Trim() } else { 'unknown' }
$dirty = if ($isRepository) { [bool]((& git -C $root status --porcelain 2>$null) -join '') } else { $true }
$resolvedChannel = if ($dirty) { 'local' } elseif ($Channel) { $Channel } else { 'development' }
$targetRoot = Join-Path (Split-Path -Parent (Split-Path -Parent $root)) 'AddOns'
$target = if ($Command -eq 'deploy-sandbox') { Join-Path $targetRoot 'KnomercyWarRoom_Sandbox' } else { Join-Path $targetRoot 'KnomercyWarRoom_Dev' }

if ($Command -eq 'status') {
    Write-Output 'KWR DEVELOPMENT ENVIRONMENT'
    Write-Output "Repository: $root"
    Write-Output "Branch: $branch"
    Write-Output "Commit: $commit"
    Write-Output "Working tree: $(if ($dirty) { 'dirty' } else { 'clean' })"
    Write-Output "Channel: $resolvedChannel"
    Write-Output "Commander: $version"
    Write-Output "Deployment: $target"
    Write-Output 'Production release: DISABLED (use protected GitHub workflow)'
    exit 0
}

if ($Command -eq 'validate') {
    & (Join-Path $PSScriptRoot 'validate.ps1') -Channel $resolvedChannel
    exit $LASTEXITCODE
}

if ($Command -like 'deploy-*') {
    if ($resolvedChannel -eq 'production') {
        throw 'Refusing deployment: production deployment requires the protected GitHub release workflow.'
    }
    if ($WhatIf) { Write-Output "Would deploy development package to $target"; exit 0 }
    $buildOutput = Join-Path $root 'artifacts\development-deploy'
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'build.ps1') -OutputDirectory $buildOutput -Channel development -SkipPackageAudit -SkipReproducibilityAudit
    if ($LASTEXITCODE -ne 0) { throw 'Development build failed; deployment was not attempted.' }
    $archive = Get-ChildItem -LiteralPath $buildOutput -Filter 'KWR_Commander_Dev_*.zip' | Select-Object -First 1
    if (-not $archive) { throw 'Development build did not produce a Commander DEV archive.' }
    $resolvedTargetRoot = [IO.Path]::GetFullPath($targetRoot).TrimEnd('\') + '\'
    $resolvedTarget = [IO.Path]::GetFullPath($target)
    if (-not $resolvedTarget.StartsWith($resolvedTargetRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing deployment outside the AddOns directory.' }
    if (Test-Path -LiteralPath $resolvedTarget) { Remove-Item -LiteralPath $resolvedTarget -Recurse -Force }
    Expand-Archive -LiteralPath $archive.FullName -DestinationPath $targetRoot -Force
    Write-Output "Development package deployed to $resolvedTarget"
}
