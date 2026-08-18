[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$errors = [System.Collections.Generic.List[string]]::new()

function Add-AuditError {
    param([string]$Message)
    $script:errors.Add($Message)
}

function Get-TocEntries {
    param([string]$TocPath)

    return @(
        Get-Content -LiteralPath $TocPath |
            Where-Object { $_ -and $_ -notmatch '^\s*#' } |
            ForEach-Object { $_.Trim().Replace('/', '\\') } |
            Where-Object { $_ -notmatch '^##' }
    )
}

function Test-Toc {
    param([string]$TocPath, [string]$AddonRoot, [string]$Label)

    $entries = Get-TocEntries -TocPath $TocPath
    foreach ($entry in $entries) {
        $path = Join-Path $AddonRoot $entry
        if (-not (Test-Path -LiteralPath $path)) {
            Add-AuditError "$Label TOC entry is missing: $entry"
        }
    }
    foreach ($duplicate in @($entries | Group-Object | Where-Object Count -gt 1)) {
        Add-AuditError "$Label TOC path occurs more than once: $($duplicate.Name)"
    }
    return $entries
}

$commanderDirectories = @(
    'Core', 'Data', 'Rulesets', 'Compliance', 'Adapters', 'State',
    'Intelligence', 'Runtime', 'Features', 'UI'
)
$approvedRuntimeDirectories = @($commanderDirectories + 'KWRSentinel')
$developmentOnlyLua = @('Core\\Diagnostics.lua')
$commanderToc = Join-Path $root 'KnomercyWarRoom.toc'
$sentinelRoot = Join-Path $root 'KWRSentinel'
$sentinelToc = Join-Path $sentinelRoot 'KWRSentinel.toc'

$commanderEntries = Test-Toc -TocPath $commanderToc -AddonRoot $root -Label 'Commander'
if (Test-Path -LiteralPath $sentinelToc) {
    $sentinelEntries = Test-Toc -TocPath $sentinelToc -AddonRoot $sentinelRoot -Label 'Sentinel'
} else {
    Add-AuditError 'Sentinel TOC is missing.'
    $sentinelEntries = @()
}

$runtimeLua = foreach ($directory in $commanderDirectories) {
    $path = Join-Path $root $directory
    if (Test-Path -LiteralPath $path) {
        Get-ChildItem -LiteralPath $path -Recurse -File -Filter '*.lua'
    }
}
foreach ($file in $runtimeLua) {
    $relative = $file.FullName.Substring($root.Length + 1)
    if ($relative -in $developmentOnlyLua) {
        continue
    }
    if ($commanderEntries -notcontains $relative) {
        Add-AuditError "Production Lua is absent from Commander TOC: $relative"
    }
}

$sentinelLua = @(Get-ChildItem -LiteralPath $sentinelRoot -Recurse -File -Filter '*.lua')
foreach ($file in $sentinelLua) {
    $relative = $file.FullName.Substring($sentinelRoot.Length + 1)
    if ($sentinelEntries -notcontains $relative) {
        Add-AuditError "Production Lua is absent from Sentinel TOC: $relative"
    }
}

$forbiddenLuaName = '(?i)(\.bak|\.old|\.tmp|\.retired|placeholder)\.lua$'
foreach ($file in @($runtimeLua + $sentinelLua)) {
    if ($file.Name -match $forbiddenLuaName) {
        Add-AuditError "Production directory contains forbidden Lua material: $($file.FullName)"
    }
}

# A Retail package cannot carry promises of later implementation. Missing
# Blizzard truth is handled by an explicit adaptive call, but unfinished code
# must fail the source audit before it can reach a player package.
$unfinishedPattern = '(?i)\bTODO\b|\bFIXME\b|not implemented|future implementation|coming soon|\bstub\b|\bno[- ]op\b'
foreach ($file in @($runtimeLua + $sentinelLua)) {
    foreach ($hit in @(Select-String -LiteralPath $file.FullName -Pattern $unfinishedPattern)) {
        Add-AuditError "Production Lua contains unfinished behavior marker: $($hit.Path):$($hit.LineNumber)"
    }
}

$allLua = @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.lua' -Force | Where-Object {
    $relative = $_.FullName.Substring($root.Length + 1).Replace('/', '\\')
    $relative -notmatch '^(\.git|\.pnpm-store|artifacts|builds|node_modules|tmp|temp|coverage)\\'
})
foreach ($file in $allLua) {
    $relative = $file.FullName.Substring($root.Length + 1)
    $topDirectory = ($relative -split '[\\/]')[0]
    if ($topDirectory -notin @($approvedRuntimeDirectories + 'tests') -and
        $relative -notin @(
            'tools\replay-test-runner.lua',
            'tools\retail-savedvariables-export.lua'
        )) {
        Add-AuditError "Runtime Lua exists outside an approved architecture directory: $relative"
    }
}

foreach ($file in @($runtimeLua + $sentinelLua)) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    if ($content -match '@generated' -and
        ($content -notmatch 'canonical-input:' -or $content -notmatch 'generator:')) {
        Add-AuditError "Generated Lua lacks canonical-input and generator declarations: $($file.FullName)"
    }
}

$commanderNamespaceOwners = @($allLua | Select-String -Pattern '_G\.KWR\s*=' | ForEach-Object Path | Sort-Object -Unique)
if ($commanderNamespaceOwners.Count -ne 1 -or $commanderNamespaceOwners[0] -ne (Join-Path $root 'Core\Addon.lua')) {
    Add-AuditError 'Commander namespace ownership must be unique to Core/Addon.lua.'
}
$sentinelNamespaceOwners = @($allLua | Select-String -Pattern '_G\.KWRSentinel\s*=' | ForEach-Object Path | Sort-Object -Unique)
if ($sentinelNamespaceOwners.Count -ne 1 -or $sentinelNamespaceOwners[0] -ne (Join-Path $root 'KWRSentinel\Core.lua')) {
    Add-AuditError 'Sentinel namespace ownership must be unique to KWRSentinel/Core.lua.'
}

$sentinelDataDefinitions = @(
    Get-ChildItem -LiteralPath $sentinelRoot -Recurse -File -Filter '*.lua' |
        Where-Object { $_.FullName -match '\\(Data|Rulesets|Intelligence)\\' }
)
if ($sentinelDataDefinitions.Count -gt 0) {
    Add-AuditError 'Sentinel duplicates shared-data ownership; consume approved Commander data or an explicitly reviewed adapter instead.'
}

Write-Output "KWR source-drift audit"
Write-Output "Commander TOC entries: $($commanderEntries.Count)"
Write-Output "Sentinel TOC entries: $($sentinelEntries.Count)"
Write-Output "Errors: $($errors.Count)"
foreach ($errorText in $errors) {
    Write-Error $errorText -ErrorAction Continue
}
if ($errors.Count -gt 0) {
    exit 1
}
Write-Output 'SOURCE DRIFT AUDIT PASSED'
