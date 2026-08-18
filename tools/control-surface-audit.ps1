[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$manifestPath = Join-Path $root "knowledge\control-surface-manifest.json"
$errors = New-Object System.Collections.Generic.List[string]

function Add-ControlError {
    param([string]$Message)
    $errors.Add($Message)
}

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    Add-ControlError "Missing control-surface manifest."
} else {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($manifest.schema -ne "kwr-control-surface-manifest" -or
        [int]$manifest.schemaVersion -ne 1) {
        Add-ControlError "Control-surface manifest schema is unsupported."
    }
    foreach ($control in @($manifest.controls)) {
        $path = Join-Path $root $control.source
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            Add-ControlError "Control $($control.id) has no source file: $($control.source)"
            continue
        }
        $source = Get-Content -LiteralPath $path -Raw
        foreach ($pattern in @($control.patterns)) {
            if ($source -notmatch [regex]::Escape([string]$pattern)) {
                Add-ControlError "Control $($control.id) is missing required behavior '$pattern'."
            }
        }
    }
}

function Assert-SourceContains {
    param([string]$RelativePath, [string[]]$Patterns, [string]$Label)
    $path = Join-Path $root $RelativePath
    $source = ""
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        $source = Get-Content -LiteralPath $path -Raw
    }
    foreach ($pattern in $Patterns) {
        if ($source -notmatch $pattern) {
            Add-ControlError "$Label lacks required actionable-control guard: $pattern"
        }
    }
}

# Both button factories fail at construction if a callback is omitted. This
# turns a future inert button into an immediate test/QA failure instead of a
# silent Retail UI regression.
Assert-SourceContains "UI\Theme.lua" @(
    'type\(callback\) ~= "function"',
    'button:SetScript\("OnClick", callback\)'
) "Commander themed buttons"
Assert-SourceContains "KWRSentinel\Theme.lua" @(
    'type\(onClick\) ~= "function"',
    'button:SetScript\("OnClick", onClick\)'
) "Sentinel themed buttons"

# The only remaining production StopMovingOrSizing calls are centralized
# guarded paths. No individual Sentinel panel may invoke the protected call.
$sentinelUi = @("KWRSentinel\HUD.lua", "KWRSentinel\Options.lua", "KWRSentinel\Panels.lua")
foreach ($relativePath in $sentinelUi) {
    $source = Get-Content -LiteralPath (Join-Path $root $relativePath) -Raw
    if ($source -match 'StopMovingOrSizing') {
        Add-ControlError "$relativePath calls protected StopMovingOrSizing directly."
    }
    if ($source -notmatch 'Sentinel:FinishMove') {
        Add-ControlError "$relativePath does not use Sentinel's deferred drag completion gate."
    }
}
Assert-SourceContains "KWRSentinel\Core.lua" @(
    'InCombatLockdown',
    'pendingMoveStops',
    'PLAYER_REGEN_ENABLED'
) "Sentinel drag completion"

$commanderTheme = Get-Content -LiteralPath (Join-Path $root "UI\Theme.lua") -Raw
if ($commanderTheme -match 'callback or function\(\) end') {
    Add-ControlError "Commander button factory still permits an inert callback."
}
$sentinelTheme = Get-Content -LiteralPath (Join-Path $root "KWRSentinel\Theme.lua") -Raw
if ($sentinelTheme -match 'if onClick then') {
    Add-ControlError "Sentinel button factory still permits an inert callback."
}

Write-Output "KWR control-surface audit"
Write-Output "Manifest controls: $(@($manifest.controls).Count)"
Write-Output "Errors: $($errors.Count)"
foreach ($error in $errors) { Write-Error $error }
if ($errors.Count -gt 0) { exit 1 }
Write-Output "CONTROL SURFACE AUDIT PASSED"
