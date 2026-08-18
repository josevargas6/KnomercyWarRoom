[CmdletBinding()]
param(
    [ValidateSet('production','release-candidate','beta','development','local')]
    [string]$Channel = 'production'
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$tocPath = Join-Path $root "KnomercyWarRoom.toc"
$sentinelTocPath = Join-Path $root "KWRSentinel\KWRSentinel.toc"
$releaseManifest = Join-Path $PSScriptRoot "release-manifest.ps1"
. $releaseManifest
$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

$tocVersionForChannel = if (Test-Path -LiteralPath $tocPath) {
    ((Get-Content -LiteralPath $tocPath | Where-Object { $_ -match '^## Version:' }) -replace '^## Version:\s*','').Trim()
} else { '' }
if ($Channel -eq 'production' -and $tocVersionForChannel -match '-(dev|local|beta|rc)') {
    Add-ValidationError "Production validation rejects prerelease channel suffix: $tocVersionForChannel"
}
if ($Channel -in @('development','local') -and $tocVersionForChannel -notmatch '-(dev|local|beta|rc)') {
    $warnings.Add("Development validation is using a production-shaped version; package promotion remains disabled.")
}

function Add-ValidationError {
    param([string]$Message)
    $script:errors.Add($Message)
}

foreach ($audit in @("source-drift-audit.ps1", "document-authority-audit.ps1")) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot $audit)
    if ($LASTEXITCODE -ne 0) {
        Add-ValidationError "$audit failed."
    }
}

foreach ($requiredTool in @(
    "deployment-manifest-audit.ps1",
    "deployment-certify.ps1",
    "test-deployment-manifest.ps1",
    "retail-savedvariables-audit.ps1",
    "retail-savedvariables-export.lua",
    "test-retail-savedvariables-audit.ps1"
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $requiredTool))) {
        Add-ValidationError "Required deployment-verification tool is missing: $requiredTool"
    }
}

function Validate-TocBundle {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TocPath,
        [Parameter(Mandatory = $true)]
        [string]$RootPath,
        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $toc = Get-Content -LiteralPath $TocPath
    $entries = @(
        $toc |
            Where-Object { $_ -and $_ -notmatch "^\s*#" } |
            ForEach-Object { $_.Trim().Replace("/", "\") } |
            Where-Object { $_ -notmatch "^##" }
    )

    foreach ($entry in $entries) {
        if (-not (Test-Path -LiteralPath (Join-Path $RootPath $entry))) {
            Add-ValidationError "$Label TOC entry is missing: $entry"
        }
    }

    $duplicates = @($entries | Group-Object | Where-Object Count -gt 1)
    foreach ($duplicate in $duplicates) {
        Add-ValidationError "$Label duplicate TOC entry: $($duplicate.Name)"
    }

    return $toc
}

if (-not (Test-Path -LiteralPath $tocPath)) {
    Add-ValidationError "KnomercyWarRoom.toc is missing."
} else {
    $toc = Validate-TocBundle -TocPath $tocPath -RootPath $root -Label "KWR"
    $entries = @(
        $toc |
            Where-Object { $_ -and $_ -notmatch "^\s*#" } |
            ForEach-Object { $_.Trim().Replace("/", "\") } |
            Where-Object { $_ -notmatch "^##" }
    )

    $runtimeDirectories = @(
        "Core",
        "Data",
        "Rulesets",
        "Compliance",
        "Adapters",
        "State",
        "Intelligence",
        "Runtime",
        "Features",
        "UI"
    )
    $runtimeLua = foreach ($directory in $runtimeDirectories) {
        $path = Join-Path $root $directory
        if (Test-Path -LiteralPath $path) {
            Get-ChildItem -LiteralPath $path -Recurse -File -Filter "*.lua"
        }
    }
    foreach ($file in $runtimeLua) {
        $relative = $file.FullName.Substring($root.Length + 1)
        if ((Get-ReleaseExcludedEntries) -contains $relative) {
            continue
        }
        if ($entries -notcontains $relative) {
            Add-ValidationError "Runtime Lua file is not loaded by the TOC: $relative"
        }
    }

    $tocVersion = ($toc | Where-Object { $_ -match "^## Version:" }) -replace "^## Version:\s*", ""
    $addonSource = Get-Content -LiteralPath (Join-Path $root "Core\Addon.lua") -Raw
    if ($addonSource -notmatch [regex]::Escape('KWR.version = "' + $tocVersion + '"')) {
        Add-ValidationError "TOC and Core/Addon.lua versions do not match."
    }
}

if (Test-Path -LiteralPath $sentinelTocPath) {
    $sentinelRoot = Split-Path -Parent $sentinelTocPath
    $sentinelToc = Validate-TocBundle -TocPath $sentinelTocPath -RootPath $sentinelRoot -Label "KWRSentinel"
    $sentinelVersion = (($sentinelToc | Where-Object { $_ -match '^## Version:' }) `
        -replace '^## Version:\s*', '').Trim()
    $sentinelCore = Get-Content -LiteralPath (Join-Path $sentinelRoot 'Core.lua') -Raw
    if ($sentinelCore -notmatch [regex]::Escape('Sentinel.version = "' + $sentinelVersion + '"')) {
        Add-ValidationError "Sentinel TOC and Core.lua versions do not match."
    }
    if ($tocVersion -and $sentinelVersion -cne $tocVersion) {
        Add-ValidationError "Commander and embedded Sentinel versions do not match."
    }

    $sentinelPanels = Get-Content -LiteralPath (Join-Path $sentinelRoot 'Panels.lua') -Raw
    if ($sentinelPanels -match 'SecureUnitButtonTemplate|macrotext1|macrotext2|/targetexact|/focus') {
        Add-ValidationError "Sentinel enemy tracker must remain visual-only."
    }
    $sentinelUiSource = @(
        Get-Content -LiteralPath (Join-Path $sentinelRoot 'MinimapButton.lua') -Raw
        $sentinelPanels
    ) -join "`n"
    if ($sentinelUiSource -match 'Interface\\\\AddOns\\\\KnomercyWarRoom') {
        Add-ValidationError "Standalone Sentinel UI depends on Commander assets."
    }
    $sentinelSurfaceSource = @(
        $sentinelCore
        Get-Content -LiteralPath (Join-Path $sentinelRoot 'Options.lua') -Raw
        $sentinelUiSource
    ) -join "`n"
    if ($sentinelSurfaceSource -match
        'CreateTracker|UpdateTracker|TEAM TRACKER|ENEMY TRACKER|panels\.team|panels\.enemy|Show team tracker|Show enemy tracker') {
        Add-ValidationError "Standalone Sentinel exposes out-of-scope team or enemy tracker panels."
    }
    $sentinelNativeUi = Get-Content -LiteralPath (Join-Path $sentinelRoot 'NativeUI.lua') -Raw
    if ($sentinelNativeUi -match 'ToggleRaidFrames|CompactRaid') {
        Add-ValidationError "Standalone Sentinel exposes an inert or protected raid-frame command."
    }
    $sentinelBridge = Get-Content -LiteralPath (Join-Path $sentinelRoot 'Bridge.lua') -Raw
    if ($sentinelBridge -notmatch 'if value == nil then return "UNKNOWN" end' -or
        $sentinelBridge -match 'releaseTimeRemaining\(\) or 0') {
        Add-ValidationError "Sentinel bridge does not preserve unknown cooldown state."
    }
    if ($sentinelBridge -notmatch 'elseif \(not view\.watch\.name or view\.watch\.name == ""\)') {
        Add-ValidationError "Sentinel bridge can overwrite an unresolved reviewed target."
    }
}

foreach ($retailTocPath in @($tocPath, $sentinelTocPath)) {
    if (-not (Test-Path -LiteralPath $retailTocPath)) {
        continue
    }
    $interfaceLine = Get-Content -LiteralPath $retailTocPath |
        Where-Object { $_ -match "^## Interface:" } |
        Select-Object -First 1
    $interfaceIds = @(($interfaceLine -replace "^## Interface:\s*", "") -split "," |
        ForEach-Object { $_.Trim() })
    foreach ($requiredInterface in @("120007", "120100")) {
        if ($interfaceIds -notcontains $requiredInterface) {
            Add-ValidationError "Retail TOC $retailTocPath is missing supported interface $requiredInterface."
        }
    }
}

$ignoredLuaRoots = @(
    (Join-Path $root "artifacts"),
    (Join-Path $root "node_modules"),
    (Join-Path $root ".pnpm-store"),
    (Join-Path $root ".git")
) | ForEach-Object {
    [IO.Path]::GetFullPath($_).TrimEnd("\", "/") + [IO.Path]::DirectorySeparatorChar
}
$luaFiles = @(
    Get-ChildItem -LiteralPath $root -Recurse -File -Filter "*.lua" |
        Where-Object {
            $fullPath = [IO.Path]::GetFullPath($_.FullName)
            -not ($ignoredLuaRoots | Where-Object {
                $fullPath.StartsWith(
                    $_, [StringComparison]::OrdinalIgnoreCase)
            })
        }
)

$nonAsciiHits = @($luaFiles | Select-String -Pattern "[^\x00-\x7F]")
foreach ($hit in $nonAsciiHits) {
    Add-ValidationError "Unsupported non-ASCII runtime glyph: $($hit.Path):$($hit.LineNumber)"
}

$legacyPattern = "KWR_520|RC2|RC4|CommanderUI|SensorManager|release-ready-candidate"
$legacyHits = @($luaFiles | Select-String -Pattern $legacyPattern)
foreach ($hit in $legacyHits) {
    Add-ValidationError "Legacy patch marker: $($hit.Path):$($hit.LineNumber)"
}

# Every shipped control must have a real action and every drag surface must
# use the shared combat-safe completion path. Keep this in the standard
# validator so package builds and CI cannot omit the surface contract.
& (Join-Path $PSScriptRoot "control-surface-audit.ps1")
if ($LASTEXITCODE -ne 0) {
    Add-ValidationError "Control-surface audit failed."
}

$forbiddenPattern = "\bSendChatMessage\b|\bSendAddonMessage\b|\bSetBinding[A-Za-z]*\s*\(|\bSaveBindings\s*\(|\bTargetUnit\s*\(|\bFocusUnit\s*\(|\bAssistUnit\s*\(|\bSpellTargetUnit\s*\(|\bCastSpell[A-Za-z]*\s*\(|\bUseAction\s*\(|\bRunMacro\s*\(|\bRunMacroText\s*\(|\bCombatLogGetCurrentEventInfo\s*\("
$commOwners = @(
    (Join-Path $root "Runtime\CommanderComm.lua"),
    (Join-Path $root "KWRSentinel\Comm.lua"),
    (Join-Path $root "tests\smoke.lua"),
    # The deterministic recipient harness mocks the same restricted API only
    # to prove the production owner rejects unsafe packets.
    (Join-Path $root "tests\sentinel-transport.lua")
)
$forbiddenHits = @($luaFiles | Select-String -Pattern $forbiddenPattern |
    Where-Object {
        $isApprovedCommCall = $_.Path -in $commOwners -and
            $_.Line -match '\bSendAddonMessage\b'
        -not $isApprovedCommCall
    })
foreach ($hit in $forbiddenHits) {
    Add-ValidationError "Forbidden protected/communication API: $($hit.Path):$($hit.LineNumber)"
}

foreach ($owner in $commOwners) {
    if (-not (Test-Path -LiteralPath $owner)) {
        Add-ValidationError "Approved transport owner is missing: $owner"
        continue
    }
    $source = Get-Content -LiteralPath $owner -Raw
    if ($source -notmatch 'KWRSync1') {
        Add-ValidationError "Transport owner does not use approved KWRSync1 prefix: $owner"
    }
    if ($source -match '\bSendChatMessage\b|\bWHISPER\b.*SendAddonMessage') {
        Add-ValidationError "Transport owner contains visible-chat transport: $owner"
    }
}

$commApiHits = @($luaFiles | Select-String -Pattern '\bRegisterAddonMessagePrefix\b|\bSendAddonMessage\b')
foreach ($hit in $commApiHits) {
    if ($hit.Path -notin $commOwners) {
        Add-ValidationError "Communication API exists outside approved transport owner: $($hit.Path):$($hit.LineNumber)"
    }
}

$safeAuraAdapterPath = Join-Path $root "Adapters\SafeAuraAdapter.lua"
$rawAuraHits = @(
    $runtimeLua |
        Where-Object { $_.FullName -ne $safeAuraAdapterPath } |
        Select-String -Pattern "\bC_UnitAuras\b|\bUnitAura\s*\(|\bAuraUtil\b"
)
foreach ($hit in $rawAuraHits) {
    Add-ValidationError "Raw aura API exists outside SafeAuraAdapter: $($hit.Path):$($hit.LineNumber)"
}

$safeCombatLogAdapterPath = Join-Path $root "Adapters\SafeCombatLogAdapter.lua"
$rawCombatLogHits = @(
    $runtimeLua |
        Where-Object { $_.FullName -ne $safeCombatLogAdapterPath } |
        Select-String -Pattern "\bCombatLogGetCurrentEventInfo\s*\("
)
foreach ($hit in $rawCombatLogHits) {
    Add-ValidationError "Raw combat-log API exists outside SafeCombatLogAdapter: $($hit.Path):$($hit.LineNumber)"
}

$spellCallHits = @(
    $runtimeLua |
        Where-Object { $_.FullName -notlike "*\Data\CommandVocabulary.lua" } |
        Select-String -Pattern "Kidney now|Solar Beam now|Kick now|Blind now|Press X|Use macro"
)
foreach ($hit in $spellCallHits) {
    Add-ValidationError "Spell-specific commander instruction text: $($hit.Path):$($hit.LineNumber)"
}

$midnightBlockedEvents = @($runtimeLua | Select-String -Pattern '"COMBAT_LOG_EVENT_UNFILTERED"')
foreach ($hit in $midnightBlockedEvents) {
    Add-ValidationError "Midnight-blocked combat-log subscription: $($hit.Path):$($hit.LineNumber)"
}

$removedRetailEvents = @($runtimeLua | Select-String -Pattern '"UNIT_HEALTH_FREQUENT"')
foreach ($hit in $removedRetailEvents) {
    Add-ValidationError "Removed Retail event subscription: $($hit.Path):$($hit.LineNumber)"
}

$secretHealthTextReads = @($runtimeLua | Select-String -Pattern '\bhealthText:GetText\s*\(')
foreach ($hit in $secretHealthTextReads) {
    Add-ValidationError "Secret-backed health text must be write-only: $($hit.Path):$($hit.LineNumber)"
}

$secureMacroHits = @(
    $luaFiles |
        Where-Object {
            $_.FullName -notlike "*\UI\CombatRoster.lua" -and
            $_.FullName -notlike "*\UI\QuickCalls.lua"
        } |
        Select-String -Pattern 'SetAttribute\s*\(\s*"macrotext'
)
foreach ($hit in $secureMacroHits) {
    Add-ValidationError "Secure macro exists outside its reviewed UI owners: $($hit.Path):$($hit.LineNumber)"
}

$quickCallsPath = Join-Path $root "UI\QuickCalls.lua"
if (Test-Path -LiteralPath $quickCallsPath) {
    $quickCallsSource = Get-Content -LiteralPath $quickCallsPath -Raw
    foreach ($phrase in @(
        "INC PRIMARY",
        "HELP HOME",
        "STOP FLAG",
        "PEEL CARRIER",
        "ROTATE NOW",
        "HOLD POSITION"
    )) {
        if ($quickCallsSource -notmatch [regex]::Escape('"' + $phrase + '"')) {
            Add-ValidationError "Reviewed Quick Call phrase is missing: $phrase"
        }
    }
    if ($quickCallsSource -notmatch 'if\s+not\s+APPROVED\[callText\]') {
        Add-ValidationError "Quick Calls do not reject phrases outside the reviewed allowlist."
    }
    $quickMacroCount = ([regex]::Matches(
        $quickCallsSource,
        'SetAttribute\s*\(\s*"macrotext1"'
    )).Count
    if ($quickMacroCount -ne 1) {
        Add-ValidationError "Expected one reviewed Quick Call macro binding; found $quickMacroCount."
    }
}

$tickerHits = @(
    $luaFiles |
        Where-Object {
            $_.FullName -notlike "*\Runtime\MatchRuntime.lua" -and
            $_.FullName -notlike "*\KWRSentinel\Observer.lua"
        } |
        Select-String -Pattern "C_Timer\.NewTicker"
)
foreach ($hit in $tickerHits) {
    Add-ValidationError "Ticker exists outside MatchRuntime: $($hit.Path):$($hit.LineNumber)"
}

$matchRuntimePath = Join-Path $root "Runtime\MatchRuntime.lua"
if (Test-Path -LiteralPath $matchRuntimePath) {
    $matchRuntimeSource = Get-Content -LiteralPath $matchRuntimePath -Raw
    if ($matchRuntimeSource -match "\bUnregisterEvent\s*\(") {
        Add-ValidationError "MatchRuntime must keep event subscriptions stable after initialization."
    }
    if ($matchRuntimeSource -match "\bSetActiveEvents\b") {
        Add-ValidationError "Legacy dynamic MatchRuntime event switching was reintroduced."
    }
}

$uiFiles = @(Get-ChildItem -LiteralPath (Join-Path $root "UI") -Recurse -File -Filter "*.lua")
$uiSensorHits = @($uiFiles | Select-String -Pattern "KWR\.Sensors|C_UIWidgetManager|C_AreaPoiInfo|C_PvP\.")
foreach ($hit in $uiSensorHits) {
    Add-ValidationError "UI directly reads battlefield APIs: $($hit.Path):$($hit.LineNumber)"
}

$slashCount = @($luaFiles | Select-String -Pattern "SLASH_KWR1\s*=").Count
if ($slashCount -ne 1) {
    Add-ValidationError "Expected exactly one primary /kwr slash registration; found $slashCount."
}

$requiredDocs = @(
    "README.md",
    "CHANGELOG.md",
    "ARCHITECTURE.md",
    "DEVELOPMENT.md",
    "QA_CHECKLIST.md",
    "CURSEFORGE_DESCRIPTION.md",
    "THIRD_PARTY_NOTICES.md",
    "META_SOURCES.md",
    "DESIGN_CONTRACT.md",
    "RELEASE_READINESS.md",
    "BATTLEGROUND_VERIFICATION.md",
    "LICENSE"
)
foreach ($document in $requiredDocs) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $document))) {
        Add-ValidationError "Required release document is missing: $document"
    }
}

$displayVersion = if ($tocVersion) { $tocVersion } else { "unknown" }
Write-Output "KWR $displayVersion validation"
Write-Output "Root: $root"
Write-Output "Lua files: $($luaFiles.Count)"
Write-Output "Errors: $($errors.Count)"
Write-Output "Warnings: $($warnings.Count)"

foreach ($warning in $warnings) {
    Write-Warning $warning
}
foreach ($validationError in $errors) {
    Write-Error $validationError -ErrorAction Continue
}

if ($errors.Count -gt 0) {
    exit 1
}

Write-Output "VALIDATION PASSED"
exit 0
