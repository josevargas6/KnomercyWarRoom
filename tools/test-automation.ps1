[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$checks = 0

function Assert-True {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Condition,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $script:checks++
    if (-not $Condition) {
        throw $Message
    }
}

function Assert-Throws {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $threw = $false
    try {
        & $Action
    } catch {
        $threw = $true
    }
    Assert-True -Condition $threw -Message $Message
}

. (Join-Path $PSScriptRoot "curseforge-upload-http.ps1")

Assert-CurseForgeProjectId -ProjectId "1632632"
$checks++
Assert-Throws -Action {
    Assert-CurseForgeProjectId -ProjectId "30cd47c7-4f43-4852-9936-3ea3a8b77a65"
} -Message "CurseForge UUID project id was accepted."

$fileId = Assert-CurseForgeUploadResponse `
    -HttpStatus "200" `
    -ResponseBody '{"id":20402}'
Assert-True -Condition ($fileId -eq 20402) -Message "Valid CurseForge response did not return its file id."
Assert-Throws -Action {
    Assert-CurseForgeUploadResponse `
        -HttpStatus "302" `
        -ResponseBody '<h2>Object moved to /error</h2>'
} -Message "CurseForge redirect error was accepted."
Assert-Throws -Action {
    Assert-CurseForgeUploadResponse -HttpStatus "200" -ResponseBody '<html>Error</html>'
} -Message "CurseForge HTML response was accepted."
Assert-Throws -Action {
    Assert-CurseForgeUploadResponse -HttpStatus "200" -ResponseBody '{"status":"ok"}'
} -Message "CurseForge response without a file id was accepted."

$maintenanceWorkflow = Get-Content -LiteralPath (
    Join-Path $root ".github\workflows\kwr-automated-maintenance.yml"
) -Raw
Assert-True `
    -Condition ($maintenanceWorkflow -match '\$maintenanceParameters\s*=\s*@\{') `
    -Message "Maintenance workflow does not use named hashtable splatting."
Assert-True `
    -Condition ($maintenanceWorkflow -match '@maintenanceParameters') `
    -Message "Maintenance workflow does not invoke the runner with named parameters."
Assert-True `
    -Condition ($maintenanceWorkflow -notmatch '\$args\s*=') `
    -Message "Maintenance workflow reintroduced the automatic args array."
Assert-True `
    -Condition ($maintenanceWorkflow -match '\$mode\s*=\s*"dry-run"') `
    -Message "Scheduled maintenance does not default to dry-run."
Assert-True `
    -Condition ($maintenanceWorkflow -match '\$postDiscord\s*=\s*\$false') `
    -Message "Scheduled maintenance defaults to a Discord write."
Assert-True `
    -Condition ($maintenanceWorkflow -match '\$notifyBot\s*=\s*\$false') `
    -Message "Scheduled maintenance defaults to a bot dispatch."

$releaseWorkflow = Get-Content -LiteralPath (
    Join-Path $root ".github\workflows\release.yml"
) -Raw
Assert-True `
    -Condition ($releaseWorkflow -match 'CURSEFORGE_PROJECT_ID:\s*"1632632"') `
    -Message "Commander release workflow does not use public project id 1632632."
Assert-True `
    -Condition ($releaseWorkflow -match 'CURSEFORGE_PROJECT_ID:\s*"1614463"') `
    -Message "Sentinel release workflow does not use public project id 1614463."
Assert-True `
    -Condition ($releaseWorkflow -match 'automation_role\s*=\s*"discord-execution-transport"') `
    -Message "Release dispatch does not declare the constrained Discord execution role."
Assert-True `
    -Condition ($releaseWorkflow -match 'codex_handoff\s*=\s*"github-review-only"') `
    -Message "Release dispatch does not declare the GitHub-review-only Codex boundary."

$maintenanceScript = Get-Content -LiteralPath (
    Join-Path $root "tools\kwr-maintenance-schedule.ps1"
) -Raw
Assert-True `
    -Condition ($maintenanceScript -match 'automation_role\s*=\s*"discord-execution-transport"') `
    -Message "Maintenance dispatch does not declare the constrained Discord execution role."
Assert-True `
    -Condition ($maintenanceScript -match 'codex_handoff\s*=\s*"github-review-only"') `
    -Message "Maintenance dispatch does not declare the GitHub-review-only Codex boundary."

foreach ($workflow in @(
    "ci.yml",
    "deploy.yml",
    "kwr-automated-maintenance.yml",
    "kwr-daily-discord.yml",
    "release.yml",
    "sentinel-release-ops.yml"
)) {
    Assert-True `
        -Condition (Test-Path -LiteralPath (Join-Path $root ".github\workflows\$workflow")) `
        -Message "Required automation workflow is missing: $workflow"
}

foreach ($requiredPath in @(
    "docs\SOCIAL_COPY.md",
    "docs\WORKFLOW_NOW.md",
    "tests\golden\twin_peaks_recovery_sample.label.json",
    "tools\kwr-daily-discord-update.ps1",
    "tools\replay-test-runner.lua",
    "tools\test-lua.ps1",
    "tools\test-social-copy.ps1"
)) {
    Assert-True `
        -Condition (Test-Path -LiteralPath (Join-Path $root $requiredPath)) `
        -Message "Workflow dependency is missing: $requiredPath"
}

$dailyDiscordWorkflow = Get-Content -LiteralPath (
    Join-Path $root ".github\workflows\kwr-daily-discord.yml"
) -Raw
Assert-True `
    -Condition ($dailyDiscordWorkflow -notmatch '(?m)^\s*if:.*secrets\.') `
    -Message "Daily Discord workflow references secrets directly in an if expression."
Assert-True `
    -Condition ($dailyDiscordWorkflow -match '(?m)^\s*if:.*env\.DISCORD_WEBHOOK_DAILY_PROGRESS') `
    -Message "Daily Discord workflow does not gate the daily webhook through job env."
Assert-True `
    -Condition ($dailyDiscordWorkflow -match '(?m)^\s*if:.*env\.DISCORD_WEBHOOK_OPS') `
    -Message "Daily Discord workflow does not gate the ops webhook through job env."

$dailyDryRun = @(& (Join-Path $root "tools\kwr-daily-discord-update.ps1") `
    -Section daily-progress -DryRun) -join "`n"
$addonVersion = ((Get-Content -LiteralPath (Join-Path $root "KnomercyWarRoom.toc") |
    Where-Object { $_ -match '^## Version:' }) -replace '^## Version:\s*', '').Trim()
Assert-True `
    -Condition ($dailyDryRun -match ('Build:\s+' + [regex]::Escape($addonVersion))) `
    -Message "Daily update does not use the current addon manifest version."
Assert-True `
    -Condition ($dailyDryRun -match 'Evidence baseline:\s+6\.1\.0-alpha\.29') `
    -Message "Daily update does not disclose the stale field-evidence baseline."

$releaseWorkflow = Get-Content -LiteralPath (
    Join-Path $root ".github\workflows\release.yml"
) -Raw
Assert-True `
    -Condition ($releaseWorkflow -match 'CurseForge upload blocked: CURSEFORGE_GAME_VERSION_IDS') `
    -Message "Release automation must fail closed when CurseForge game-version IDs are missing or invalid."
Assert-True `
    -Condition ($releaseWorkflow -notmatch 'game-version metadata omitted') `
    -Message "Release automation must not omit CurseForge game-version metadata."
Assert-True `
    -Condition ($releaseWorkflow -match 'ref:\s*\$\{\{ inputs\.release_tag \|\| github\.ref_name \}\}') `
    -Message "Release automation must check out the requested release tag."
Assert-True `
    -Condition ($releaseWorkflow -match 'git describe --tags --exact-match HEAD') `
    -Message "Release automation must prove that the checked-out commit is exactly tagged."

$maintenanceWorkflow = Get-Content -LiteralPath (
    Join-Path $root ".github\workflows\kwr-automated-maintenance.yml"
) -Raw
$sentinelReleaseWorkflow = Get-Content -LiteralPath (
    Join-Path $root ".github\workflows\sentinel-release-ops.yml"
) -Raw
foreach ($secretAlias in @("OPS_HOOK", "WEBHOOK_ANNOUNCEMENTS", "WEBHOOK_SUPPORT", "FIELD_TESTING")) {
    Assert-True `
        -Condition (($maintenanceWorkflow + $dailyDiscordWorkflow + $sentinelReleaseWorkflow) -match [regex]::Escape("secrets.$secretAlias")) `
        -Message "Configured Discord secret alias is not wired: $secretAlias"
}

$workflowFiles = Get-ChildItem -Path (Join-Path $root ".github\workflows\*.y*ml") -File
foreach ($workflowFile in $workflowFiles) {
    $workflowSource = Get-Content -LiteralPath $workflowFile.FullName -Raw
    Assert-True `
        -Condition ($workflowSource -notmatch '(?m)^\s*uses:\s+[^\s#]+@v\d+(?:\s|$)') `
        -Message "Workflow contains a moving major-version action tag: $($workflowFile.Name)"
}

Write-Output "KWR_AUTOMATION_TEST_PASS checks=$checks"
