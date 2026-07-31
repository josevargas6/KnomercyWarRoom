[CmdletBinding()]
param(
    [ValidateSet("auto", "status", "daily", "weekly-reconciliation", "biweekly-trends", "monthly-maintenance", "release-dry-run", "full-dry-run")]
    [string]$Lane = "status",
    [ValidateSet("dry-run", "external")]
    [string]$Mode = "dry-run",
    [string]$ConfirmExternalWrites = "",
    [switch]$PostDiscord,
    [switch]$NotifyBot,
    [string]$OutputDirectory = "artifacts\scheduled-maintenance",
    [string]$BotRepository = $env:KWR_BOT_REPOSITORY,
    [string]$BotDispatchToken = $env:KWR_BOT_DISPATCH_TOKEN
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$outputPath = [IO.Path]::GetFullPath((Join-Path $root $OutputDirectory.TrimStart("\", "/")))
$runStarted = [DateTimeOffset]::UtcNow
$steps = [System.Collections.Generic.List[object]]::new()

function Add-Step {
    param([string]$Name, [string]$Status, [string]$Detail = "")
    $steps.Add([ordered]@{ name = $Name; status = $Status; detail = $Detail })
}

function Invoke-Step {
    param([string]$Name, [scriptblock]$Action)
    Write-Output "==> $Name"
    try {
        & $Action
        Add-Step -Name $Name -Status "PASS"
    } catch {
        Add-Step -Name $Name -Status "FAIL" -Detail $_.Exception.Message
        throw
    }
}

function Invoke-Tool {
    param([string]$ScriptName, [string[]]$Arguments = @())
    $scriptPath = Join-Path $PSScriptRoot $ScriptName
    if (-not (Test-Path -LiteralPath $scriptPath)) { throw "Missing tool: $scriptPath" }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$ScriptName failed with exit code $LASTEXITCODE." }
}

function Get-CentralNow {
    try {
        $zone = [TimeZoneInfo]::FindSystemTimeZoneById("Central Standard Time")
        return [TimeZoneInfo]::ConvertTime([DateTimeOffset]::UtcNow, $zone)
    } catch {
        return [DateTimeOffset]::Now
    }
}

function Resolve-AutoLane {
    $centralNow = Get-CentralNow
    if ($centralNow.Day -eq 1) { return "monthly-maintenance" }
    if ($centralNow.DayOfWeek -eq [DayOfWeek]::Wednesday -and $centralNow.Hour -eq 13) { return "weekly-reconciliation" }
    if ($centralNow.DayOfWeek -eq [DayOfWeek]::Thursday -and $centralNow.Hour -eq 10) {
        $week = [Globalization.ISOWeek]::GetWeekOfYear($centralNow.DateTime)
        if (($week % 2) -eq 0) { return "biweekly-trends" }
    }
    return "daily"
}

function Get-LatestArtifact {
    param([string]$Pattern)
    $matches = @(Get-ChildItem -LiteralPath $outputPath -File -Filter $Pattern -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending)
    if ($matches.Count -eq 0) { return $null }
    return $matches[0].FullName
}

function Invoke-ValidationGate {
    Invoke-Step "Validate architecture and release files" { Invoke-Tool -ScriptName "validate.ps1" -Arguments @("-Channel", "production") }
    Invoke-Step "Security audit" { Invoke-Tool -ScriptName "security-audit.ps1" }
    Invoke-Step "Knowledge audit" { Invoke-Tool -ScriptName "knowledge-audit.ps1" }
    Invoke-Step "Deterministic Lua tests" { Invoke-Tool -ScriptName "test-lua.ps1" -Arguments @("-Suite", "All") }
}

function Invoke-Build {
    Invoke-Step "Build Commander and Sentinel packages" {
        New-Item -ItemType Directory -Force -Path $outputPath | Out-Null
        Invoke-Tool -ScriptName "build.ps1" -Arguments @("-OutputDirectory", $outputPath, "-IncludeSentinel")
    }
}

function Invoke-ReadinessReports {
    foreach ($entry in @(
        @{ Name = "Runtime preflight report"; Script = "runtime-preflight.ps1"; Args = @() },
        @{ Name = "Field readiness report"; Script = "field-readiness-report.ps1"; Args = @() },
        @{ Name = "Field blocker report"; Script = "field-blocker-report.ps1"; Args = @() },
        @{ Name = "Offline completion audit"; Script = "offline-completion-audit.ps1"; Args = @() }
    )) {
        Invoke-Step $entry.Name { Invoke-Tool -ScriptName $entry.Script -Arguments $entry.Args }
    }
}

function Invoke-DiscordDryRun {
    Invoke-Step "Discord daily-progress dry-run" { Invoke-Tool -ScriptName "kwr-daily-discord-update.ps1" -Arguments @("-Section", "daily-progress", "-DryRun") }
    Invoke-Step "Discord ops dry-run" { Invoke-Tool -ScriptName "kwr-daily-discord-update.ps1" -Arguments @("-Section", "ops", "-DryRun") }
}

function Invoke-DiscordPostIfRequested {
    if ($Mode -ne "external" -or -not $PostDiscord) { return }
    if ($ConfirmExternalWrites -cne "PUBLISH") { throw "Discord external writes require ConfirmExternalWrites=PUBLISH." }
    if (-not [string]::IsNullOrWhiteSpace($env:DISCORD_WEBHOOK_DAILY_PROGRESS)) {
        Invoke-Step "Post Discord daily-progress update" {
            $env:DISCORD_WEBHOOK_URL = $env:DISCORD_WEBHOOK_DAILY_PROGRESS
            Invoke-Tool -ScriptName "kwr-daily-discord-update.ps1" -Arguments @("-Section", "daily-progress")
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($env:DISCORD_WEBHOOK_OPS)) {
        Invoke-Step "Post Discord ops update" {
            $env:DISCORD_WEBHOOK_URL = $env:DISCORD_WEBHOOK_OPS
            Invoke-Tool -ScriptName "kwr-daily-discord-update.ps1" -Arguments @("-Section", "ops")
        }
    }
}

function Invoke-ReleaseDryRun {
    Invoke-Build
    $commanderArtifact = Get-LatestArtifact -Pattern "KWR_*_DISTRIBUTION.zip"
    $sentinelArtifact = Get-LatestArtifact -Pattern "KWRSentinel_*.zip"
    if (-not $commanderArtifact) { throw "No Commander distribution artifact was found in $outputPath." }
    if (-not $sentinelArtifact) { throw "No Sentinel artifact was found in $outputPath." }
    Invoke-Step "CurseForge Commander upload metadata dry-run" { Invoke-Tool -ScriptName "curseforge-upload-commander.ps1" -Arguments @("-ArtifactPath", $commanderArtifact, "-DryRun") }
    Invoke-Step "CurseForge Sentinel upload metadata dry-run" { Invoke-Tool -ScriptName "curseforge-upload-sentinel.ps1" -Arguments @("-ArtifactPath", $sentinelArtifact, "-DryRun") }
    foreach ($section in @("announcements", "support", "field-testing", "ops")) {
        Invoke-Step "Commander Discord $section announcement dry-run" { Invoke-Tool -ScriptName "kwr-commander-discord-announce.ps1" -Arguments @("-Section", $section, "-DryRun") }
        Invoke-Step "Sentinel Discord $section announcement dry-run" { Invoke-Tool -ScriptName "sentinel-discord-announce.ps1" -Arguments @("-Section", $section, "-DryRun") }
    }
}

function Invoke-BotNotification {
    if (-not $NotifyBot) { return }
    $payload = [ordered]@{
        event_type = "kwr_maintenance_schedule"
        client_payload = [ordered]@{ lane = $Lane; mode = $Mode; source = "KnomercyWarRoom maintenance scheduler"; started_at = $runStarted.ToString("yyyy-MM-ddTHH:mm:ssZ") }
    }
    if ($Mode -ne "external") {
        Invoke-Step "Sentinel Discord bot dispatch dry-run" { Write-Output ($payload | ConvertTo-Json -Depth 5) }
        return
    }
    if ($ConfirmExternalWrites -cne "PUBLISH") { throw "Bot dispatch requires ConfirmExternalWrites=PUBLISH." }
    if ([string]::IsNullOrWhiteSpace($BotRepository) -or [string]::IsNullOrWhiteSpace($BotDispatchToken)) { throw "Bot dispatch requires KWR_BOT_REPOSITORY and KWR_BOT_DISPATCH_TOKEN." }
    Invoke-Step "Notify Sentinel Discord bot repository" {
        $headers = @{ Authorization = "Bearer $BotDispatchToken"; Accept = "application/vnd.github+json"; "X-GitHub-Api-Version" = "2022-11-28" }
        Invoke-RestMethod -Method Post -Uri "https://api.github.com/repos/$BotRepository/dispatches" -Headers $headers -ContentType "application/json" -Body ($payload | ConvertTo-Json -Depth 5) | Out-Null
    }
}

function Write-Status {
    Write-Output "KWR automated maintenance schedule"
    Write-Output "Root: $root"
    Write-Output "Lane: $Lane"
    Write-Output "Mode: $Mode"
    Write-Output "Output: $outputPath"
    Write-Output "Central time: $((Get-CentralNow).ToString("yyyy-MM-dd HH:mm:ss zzz"))"
    foreach ($name in @("KWR_OWNER_NAME", "KWR_GITHUB_REPOSITORY", "KWR_DEFAULT_BRANCH", "KWR_PRODUCTION_BRANCH", "KWR_FAMILY_REPOSITORIES", "DISCORD_WEBHOOK_DAILY_PROGRESS", "DISCORD_WEBHOOK_OPS", "DISCORD_WEBHOOK_ANNOUNCEMENTS", "DISCORD_WEBHOOK_SUPPORT", "DISCORD_WEBHOOK_FIELD_TESTING", "KWR_BOT_REPOSITORY", "KWR_BOT_DISPATCH_TOKEN", "CURSEFORGE_COMMANDER_PROJECT_ID", "CURSEFORGE_SENTINEL_PROJECT_ID", "CURSEFORGE_API_TOKEN", "CURSEFORGE_GAME_VERSION_IDS")) {
        $value = [Environment]::GetEnvironmentVariable($name)
        $state = if ([string]::IsNullOrWhiteSpace($value)) { "missing" } else { "configured" }
        Write-Output ("{0}: {1}" -f $name, $state)
    }
}

function Write-Receipt {
    New-Item -ItemType Directory -Force -Path $outputPath | Out-Null
    $receiptPath = Join-Path $outputPath ("KWR_MAINTENANCE_{0}_{1}.json" -f $Lane.ToUpperInvariant().Replace("-", "_"), $runStarted.ToString("yyyyMMddTHHmmssZ"))
    $receipt = [ordered]@{ schema = "kwr-maintenance-schedule-run"; schemaVersion = 1; lane = $Lane; mode = $Mode; startedAt = $runStarted.ToString("yyyy-MM-ddTHH:mm:ssZ"); finishedAt = ([DateTimeOffset]::UtcNow).ToString("yyyy-MM-ddTHH:mm:ssZ"); root = $root; outputDirectory = $outputPath; steps = @($steps) }
    [IO.File]::WriteAllText($receiptPath, (($receipt | ConvertTo-Json -Depth 8) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
    Write-Output "Receipt: $receiptPath"
}

if ($Mode -eq "external" -and $ConfirmExternalWrites -cne "PUBLISH") { throw "External mode requires ConfirmExternalWrites=PUBLISH." }
if ($Lane -eq "auto") { $Lane = Resolve-AutoLane; Write-Output "Resolved auto lane: $Lane" }

try {
    switch ($Lane) {
        "status" { Invoke-Step "Capability status" { Write-Status } }
        "daily" { Invoke-ValidationGate; Invoke-Build; Invoke-ReadinessReports; Invoke-DiscordDryRun; Invoke-DiscordPostIfRequested; Invoke-BotNotification }
        "weekly-reconciliation" { Invoke-ValidationGate; Invoke-ReleaseDryRun; Invoke-ReadinessReports; Invoke-DiscordDryRun; Invoke-DiscordPostIfRequested; Invoke-BotNotification }
        "biweekly-trends" { Invoke-Step "Biweekly trend anchor" { Write-Output "Biweekly trend lane active." }; Invoke-ValidationGate; Invoke-ReadinessReports; Invoke-DiscordDryRun; Invoke-DiscordPostIfRequested; Invoke-BotNotification }
        "monthly-maintenance" { Invoke-Step "Capability status" { Write-Status }; Invoke-ValidationGate; Invoke-ReleaseDryRun; Invoke-ReadinessReports; Invoke-DiscordDryRun; Invoke-DiscordPostIfRequested; Invoke-BotNotification }
        "release-dry-run" { Invoke-ValidationGate; Invoke-ReleaseDryRun; Invoke-BotNotification }
        "full-dry-run" { Invoke-ValidationGate; Invoke-ReleaseDryRun; Invoke-ReadinessReports; Invoke-DiscordDryRun; Invoke-DiscordPostIfRequested; Invoke-BotNotification; Invoke-Step "Capability status" { Write-Status } }
    }
} finally {
    Write-Receipt
}
