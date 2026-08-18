[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$checks = 0
. (Join-Path $PSScriptRoot "hash-utils.ps1")

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

$hashProbe = Join-Path $root "tools\test-automation.ps1"
$nativeHash = (Get-FileHash -LiteralPath $hashProbe -Algorithm SHA256).Hash.ToUpperInvariant()
Assert-True -Condition ((Get-KwrFileSha256 -LiteralPath $hashProbe) -eq $nativeHash) `
    -Message "Shared SHA-256 utility disagrees with the native checksum."
function Get-FileHash { throw "forced module-load failure" }
Assert-True -Condition ((Get-KwrFileSha256 -LiteralPath $hashProbe) -eq $nativeHash) `
    -Message "Shared SHA-256 utility did not recover from a missing hash cmdlet."
Remove-Item -LiteralPath function:Get-FileHash -Force

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
    -Condition ($releaseWorkflow -notmatch 'repository_dispatch|/dispatches|BOT_DISPATCH_TOKEN|BOT_REPOSITORY') `
    -Message "Release workflow contains an unverified bot dispatch."
Assert-True `
    -Condition ($releaseWorkflow -match 'throw "Discord release announcement is not configured') `
    -Message "Release workflow can pass without the required Discord release announcement webhook."
Assert-True `
    -Condition ($releaseWorkflow -match 'sentinel-discord-announce\.ps1 -Section announcements -Version \$version -CommanderVersion \$commanderVersion') `
    -Message "Release workflow does not pass the current Commander version to the Sentinel announcement."

$commanderAnnouncement = @(& (Join-Path $root "tools\kwr-commander-discord-announce.ps1") `
    -Section announcements -Version "6.1.1-alpha.1" -DryRun) -join "`n"
Assert-True `
    -Condition ($commanderAnnouncement -match 'Commander 6\.1\.1-alpha\.1') `
    -Message "Commander announcement did not substitute the requested addon version."
Assert-True `
    -Condition ($commanderAnnouncement -match 'Retail 12\.1\.0 and 12\.0\.7') `
    -Message "Commander announcement rewrote supported WoW client versions."
$sentinelAnnouncement = @(& (Join-Path $root "tools\sentinel-discord-announce.ps1") `
    -Section announcements -Version "6.1.1-alpha.1" -CommanderVersion "6.0.9" -DryRun) -join "`n"
Assert-True `
    -Condition ($sentinelAnnouncement -match 'Sentinel 6\.1\.1-alpha\.1') `
    -Message "Sentinel announcement did not substitute the requested addon version."
Assert-True `
    -Condition ($sentinelAnnouncement -match 'Commander 6\.0\.9') `
    -Message "Sentinel announcement replaced a distinct Commander version with its own version."
Assert-True `
    -Condition ($sentinelAnnouncement -match 'Retail 12\.1\.0 and 12\.0\.7') `
    -Message "Sentinel announcement rewrote supported WoW client versions."

$sentinelBridge = Get-Content -LiteralPath (
    Join-Path $root "KWRSentinel\Bridge.lua"
) -Raw
Assert-True `
    -Condition ($sentinelBridge -notmatch 'C_Spell\.GetSpellCooldown|(?<![A-Za-z_])GetSpellCooldown\s*\(') `
    -Message "Sentinel Bridge must not calculate Retail cooldown values that can be secret/tainted."
Assert-True `
    -Condition ($sentinelBridge -notmatch 'GetReleaseTimeRemaining|GetCorpseRecoveryDelay') `
    -Message "Sentinel Bridge must not calculate Retail release timers that can be secret/tainted."

$maintenanceScript = Get-Content -LiteralPath (
    Join-Path $root "tools\kwr-maintenance-schedule.ps1"
) -Raw
Assert-True `
    -Condition ($maintenanceScript -notmatch 'repository_dispatch|/dispatches|BotDispatch|BotRepository|NotifyBot') `
    -Message "Maintenance includes an unverified bot dispatch."
Assert-True `
    -Condition ($maintenanceScript -match 'Invoke-OfflineCertificationGate') `
    -Message "Maintenance does not use the unified offline certification gate."

$ciWorkflow = Get-Content -LiteralPath (Join-Path $root ".github\workflows\ci.yml") -Raw
Assert-True `
    -Condition ($ciWorkflow -match 'certify-offline\.ps1\s+-SkipBuild') `
    -Message "CI does not execute the unified offline certification gate."

$buildScript = Get-Content -LiteralPath (Join-Path $root "tools\build.ps1") -Raw
Assert-True `
    -Condition ($buildScript -match 'Sort-Object ArchivePath') `
    -Message "Build archives do not use canonical entry ordering."
Assert-True `
    -Condition ($buildScript -match '\$entry\.LastWriteTime\s*=\s*\$fixedTimestamp') `
    -Message "Build archives do not normalize entry timestamps."
Assert-True `
    -Condition ($buildScript -notmatch 'PASS_WITH_DOCUMENTED_EXCEPTION|Compress-Archive did not produce byte-identical') `
    -Message "Build still permits a non-deterministic ZIP-container exception."

$releaseSurfaceAudit = Get-Content -LiteralPath (
    Join-Path $root "tools\audit-release-surfaces.ps1"
) -Raw
Assert-True `
    -Condition ($releaseSurfaceAudit -match 'release_authority\s*=\s*"main"') `
    -Message "Release-surface audit does not identify main as release authority."
Assert-True `
    -Condition ($releaseSurfaceAudit -match 'ABSENT_RETIRED') `
    -Message "Release-surface audit does not tolerate a retired develop branch."
Assert-True `
    -Condition ($releaseSurfaceAudit -match 'OPTIONAL_INTENTIONALLY_ABSENT_ALLOWED') `
    -Message "Release-surface audit does not encode optional Beacon installation policy."

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
    "tools\deployment-certify.ps1",
    "tools\replay-test-runner.lua",
    "tools\test-lua.ps1",
    "tools\test-social-copy.ps1"
    "tools\hash-utils.ps1"
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
Assert-True `
    -Condition ($releaseWorkflow -match '\$publicAssets\s*=\s*@\(') `
    -Message "Release automation must use an explicit player-facing asset allowlist."
Assert-True `
    -Condition ($releaseWorkflow -notmatch 'gh release (?:upload|create) \$releaseTag artifacts/\*') `
    -Message "Release automation must never publish every build artifact."
Assert-True `
    -Condition ($releaseWorkflow -match 'PUBLIC_MANIFEST\.json') `
    -Message "Release automation must publish the player-facing manifest."
Assert-True `
    -Condition ($releaseWorkflow -match '\$isPrerelease\s*=\s*\$version\.Contains\(''-''\)') `
    -Message "Release automation must derive GitHub channel from the semantic version."
Assert-True `
    -Condition ($releaseWorkflow -match 'gh release edit \$releaseTag --prerelease=false --latest') `
    -Message "Stable publication must clear prerelease state and mark the release latest."
Assert-True `
    -Condition ($releaseWorkflow -match 'gh release create \$releaseTag \$publicAssets --latest') `
    -Message "Stable publication must create a latest GitHub release."
Assert-True `
    -Condition (([regex]::Matches($releaseWorkflow, '-ReleaseType \$releaseType')).Count -eq 2) `
    -Message "Commander and Sentinel CurseForge uploads must receive the derived release type."

Assert-True `
    -Condition ($ciWorkflow -match 'name:\s*kwr-developer-') `
    -Message "CI must retain developer packages in a separate private artifact."
Assert-True `
    -Condition ($ciWorkflow -match 'KWR_\*_DEVELOPER\.zip') `
    -Message "CI developer artifact does not retain the developer ZIP."
Assert-True `
    -Condition ($ciWorkflow -match 'retention-days:\s*30') `
    -Message "CI artifact retention must be bounded."

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

$candidateReportTool = Get-Content -LiteralPath (
    Join-Path $root "tools\candidate-package-report.ps1"
) -Raw
Assert-True `
    -Condition ($candidateReportTool -notmatch 'C:\\Users\\') `
    -Message "Candidate package reporting contains a machine-specific user path."
Assert-True `
    -Condition ($candidateReportTool -match 'backupFolderSuggestion.*\$version') `
    -Message "Candidate package backup guidance is pinned to a stale version."

$taskContracts = @(Get-ChildItem -LiteralPath (Join-Path $root 'docs\tasks') -Recurse -File -Filter 'KWR-*.md')
$taskIds = @($taskContracts | ForEach-Object {
    $taskSource = Get-Content -LiteralPath $_.FullName -Raw
    Assert-True `
        -Condition ($taskSource -match '(?m)^id:\s*(KWR-(?:[A-Z]+-)?\d+)\s*$') `
        -Message "Task contract lacks a valid ID: $($_.Name)"
    $taskId = $Matches[1]
    Assert-True `
        -Condition ($_.Name.StartsWith($taskId + '-', [StringComparison]::OrdinalIgnoreCase)) `
        -Message "Task filename does not match its declared ID: $($_.Name) -> $taskId"
    $taskId
})
Assert-True `
    -Condition (@($taskIds | Group-Object | Where-Object Count -gt 1).Count -eq 0) `
    -Message "Authoritative task IDs must be unique across active and completed contracts."

Write-Output "KWR_AUTOMATION_TEST_PASS checks=$checks"
