[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$required = @(
    "Data\SourceRegistry.lua",
    "Data\PatchData.lua",
    "Data\Capabilities.lua",
    "Data\Compositions.lua",
    "Data\BattlePlans.lua",
    "Data\Counters.lua",
    "Data\KnowledgeManifest.lua",
    "knowledge\README.md",
    "knowledge\patch-template.json"
)

$errors = [System.Collections.Generic.List[string]]::new()
foreach ($relative in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $relative))) {
        $errors.Add("Missing knowledge artifact: $relative")
    }
}

$patchSource = Get-Content -LiteralPath (Join-Path $root "Data\PatchData.lua") -Raw
$tocSource = Get-Content -LiteralPath (Join-Path $root "KnomercyWarRoom.toc") -Raw
$interface = [regex]::Match($tocSource, "## Interface:\s*(\d+)").Groups[1].Value
if ($patchSource -notmatch [regex]::Escape("interface = $interface")) {
    $errors.Add("Active patch data does not match TOC interface $interface.")
}
if ($patchSource -notmatch 'officialHotfixReviewed\s*=\s*"\d{4}-\d{2}-\d{2}"') {
    $errors.Add("Active patch pack has no dated official hotfix review.")
}

$templatePath = Join-Path $root "knowledge\patch-template.json"
try {
    $template = Get-Content -LiteralPath $templatePath -Raw | ConvertFrom-Json
    if ($null -eq $template.apiChanges -or $null -eq $template.gameplayChanges) {
        $errors.Add("Patch template does not separate API changes from gameplay changes.")
    }
    if (($template.capabilityCategoryReview.minimumSignals -lt 3) -or
        ($template.capabilityCategoryReview.minimumBattlefieldEffects -lt 3)) {
        $errors.Add("Patch template capability review minimums are below three.")
    }
} catch {
    $errors.Add("Patch template JSON is invalid: $($_.Exception.Message)")
}

$planSource = Get-Content -LiteralPath (Join-Path $root "Data\BattlePlans.lua") -Raw
foreach ($map in @("ARATHI","GILNEAS","DEEPWIND","EOTS","WSG","TWINPEAKS","TEMPLE","SILVERSHARD","DEEPHAUL","SEETHING")) {
    if ($planSource -notmatch [regex]::Escape("$map = {")) {
        $errors.Add("No battle-plan family for $map.")
    }
}

$sourceRegistry = Get-Content -LiteralPath (Join-Path $root "Data\SourceRegistry.lua") -Raw
foreach ($authority in @("LIVE","REFERENCE","META","EDITORIAL","RESEARCH","SIGNAL","LEARNED")) {
    if ($sourceRegistry -notmatch [regex]::Escape("authority = `"$authority`"")) {
        $errors.Add("Missing source authority tier: $authority.")
    }
}

Write-Output "KWR knowledge audit"
Write-Output "Errors: $($errors.Count)"
foreach ($errorText in $errors) {
    Write-Error $errorText -ErrorAction Continue
}
if ($errors.Count -gt 0) { exit 1 }
Write-Output "KNOWLEDGE AUDIT PASSED"
