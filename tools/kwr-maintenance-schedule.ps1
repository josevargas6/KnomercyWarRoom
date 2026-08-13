[CmdletBinding()]
param(
    [ValidateSet(
        "auto",
        "status",
        "daily",
        "patch-preflight",
        "patch-baseline",
        "patch-watch",
        "extended-reconciliation",
        "weekly-reconciliation",
        "biweekly-trends",
        "monthly-maintenance",
        "release-dry-run",
        "full-dry-run"
    )]
    [string]$Lane = "status",
    [ValidateSet("dry-run", "external")]
    [string]$Mode = "dry-run",
    [string]$ConfirmExternalWrites = "",
    [switch]$PostDiscord,
    [string]$OutputDirectory = "artifacts\scheduled-maintenance"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$tools = $PSScriptRoot
$outputRelative = $OutputDirectory.TrimStart("\", "/")
$outputPath = [IO.Path]::GetFullPath((Join-Path $root $outputRelative))
$runStarted = [DateTimeOffset]::UtcNow
$steps = [System.Collections.Generic.List[object]]::new()

function Get-CentralNow {
    $zone = $null
    foreach ($zoneId in @("Central Standard Time", "America/Chicago")) {
        try {
            $zone = [TimeZoneInfo]::FindSystemTimeZoneById($zoneId)
            break
        } catch {
            $zone = $null
        }
    }

    if (-not $zone) {
        return [DateTimeOffset]::Now
    }

    return [TimeZoneInfo]::ConvertTime([DateTimeOffset]::UtcNow, $zone)
}

function Resolve-AutoLane {
    $centralNow = Get-CentralNow
    $day = $centralNow.DayOfWeek
    $hour = $centralNow.Hour
    $minute = $centralNow.Minute

    if ($day -eq [DayOfWeek]::Monday -and $hour -eq 16 -and $minute -ge 20 -and $minute -le 40) {
        return "patch-preflight"
    }
    if ($day -eq [DayOfWeek]::Tuesday -and $hour -eq 8 -and $minute -ge 37 -and $minute -le 57) {
        return "patch-baseline"
    }
    if ($day -eq [DayOfWeek]::Tuesday -and $hour -ge 9 -and $hour -le 14) {
        return "patch-watch"
    }
    if (($day -eq [DayOfWeek]::Tuesday -and $hour -ge 15) -or
        ($day -eq [DayOfWeek]::Wednesday -and $hour -le 12)) {
        return "extended-reconciliation"
    }
    if ($day -eq [DayOfWeek]::Wednesday -and $hour -eq 13) {
        return "weekly-reconciliation"
    }
    if ($day -eq [DayOfWeek]::Thursday -and $hour -eq 10) {
        $week = [Globalization.ISOWeek]::GetWeekOfYear($centralNow.DateTime)
        if (($week % 2) -eq 0) {
            return "biweekly-trends"
        }
        return "status"
    }
    if ($centralNow.Day -eq 1) {
        return "monthly-maintenance"
    }

    return "daily"
}

function Test-SecretPresence {
    param([string]$Name)
    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        return "missing"
    }
    return "configured"
}

function Add-StepResult {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Status,
        [string]$Detail = ""
    )

    $steps.Add([ordered]@{
        name = $Name
        status = $Status
        detail = $Detail
    })
}

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action
    )

    Write-Output "==> $Name"
    try {
        & $Action
        Add-StepResult -Name $Name -Status "PASS"
    } catch {
        Add-StepResult -Name $Name -Status "FAIL" -Detail $_.Exception.Message
        throw
    }
}

function Invoke-RepoScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [string[]]$Arguments = @()
    )

    $scriptPath = Join-Path $tools $ScriptName
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        throw "Missing tool: $scriptPath"
    }

    & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$ScriptName failed with exit code $LASTEXITCODE."
    }
}

function Get-LatestArtifact {
    param([Parameter(Mandatory = $true)][string]$Pattern)

    $matches = @(
        Get-ChildItem -LiteralPath $outputPath -File -Filter $Pattern -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTimeUtc -Descending
    )
    if ($matches.Count -eq 0) {
        return $null
    }
    return $matches[0].FullName
}

function Invoke-ValidationGate {
    Invoke-Step "Validate architecture and release files" {
        Invoke-RepoScript -ScriptName "validate.ps1" -Arguments @("-Channel", "production")
    }
    Invoke-Step "Security audit" {
        Invoke-RepoScript -ScriptName "security-audit.ps1"
    }
    Invoke-Step "Knowledge audit" {
        Invoke-RepoScript -ScriptName "knowledge-audit.ps1"
    }
}

function Invoke-LuaGate {
    Invoke-Step "Deterministic Lua tests" {
        Invoke-RepoScript -ScriptName "test-lua.ps1" -Arguments @("-Suite", "All")
    }
}

function Invoke-OfflineCertificationGate {
    Invoke-Step "Autonomous offline certification" {
        # This is the single local support gate: runtime discovery, lifecycle
        # compilation, source/knowledge safety, Commander/Sentinel tests, and
        # performance receipt. Package construction remains a separate step so
        # maintenance receipts can distinguish code health from release output.
        Invoke-RepoScript -ScriptName "certify-offline.ps1" -Arguments @("-SkipBuild")
    }
}

function Invoke-CertifiedBuild {
    Invoke-Step "Build Commander and Sentinel packages" {
        New-Item -ItemType Directory -Force -Path $outputPath | Out-Null
        Invoke-RepoScript -ScriptName "build.ps1" -Arguments @(
            "-OutputDirectory", $outputPath,
            "-IncludeSentinel"
        )
    }
}

function Invoke-ReadinessReports {
    Invoke-Step "Runtime preflight report" {
        Invoke-RepoScript -ScriptName "runtime-preflight.ps1"
    }
    Invoke-Step "Candidate package report" {
        Invoke-RepoScript -ScriptName "candidate-package-report.ps1" -Arguments @(
            "-BuildOutputDirectory", $outputRelative
        )
    }
    Invoke-Step "Field readiness report" {
        Invoke-RepoScript -ScriptName "field-readiness-report.ps1"
    }
    Invoke-Step "Field blocker report" {
        Invoke-RepoScript -ScriptName "field-blocker-report.ps1"
    }
    Invoke-Step "Offline completion audit" {
        Invoke-RepoScript -ScriptName "offline-completion-audit.ps1"
    }
}

function Invoke-DiscordStatus {
    Invoke-Step "Discord daily-progress dry-run" {
        Invoke-RepoScript -ScriptName "kwr-daily-discord-update.ps1" -Arguments @(
            "-Section", "daily-progress",
            "-DryRun"
        )
    }
    Invoke-Step "Discord ops dry-run" {
        Invoke-RepoScript -ScriptName "kwr-daily-discord-update.ps1" -Arguments @(
            "-Section", "ops",
            "-DryRun"
        )
    }

    if ($Mode -ne "external" -or -not $PostDiscord) {
        return
    }
    if ($ConfirmExternalWrites -cne "PUBLISH") {
        throw "Discord external writes require ConfirmExternalWrites=PUBLISH."
    }

    if (-not [string]::IsNullOrWhiteSpace($env:DISCORD_WEBHOOK_DAILY_PROGRESS)) {
        Invoke-Step "Post Discord daily-progress update" {
            $env:DISCORD_WEBHOOK_URL = $env:DISCORD_WEBHOOK_DAILY_PROGRESS
            Invoke-RepoScript -ScriptName "kwr-daily-discord-update.ps1" -Arguments @("-Section", "daily-progress")
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($env:DISCORD_WEBHOOK_OPS)) {
        Invoke-Step "Post Discord ops update" {
            $env:DISCORD_WEBHOOK_URL = $env:DISCORD_WEBHOOK_OPS
            Invoke-RepoScript -ScriptName "kwr-daily-discord-update.ps1" -Arguments @("-Section", "ops")
        }
    }
}

function Invoke-ReleaseDryRun {
    Invoke-CertifiedBuild
    $commanderArtifact = Get-LatestArtifact -Pattern "KWR_*_DISTRIBUTION.zip"
    $sentinelArtifact = Get-LatestArtifact -Pattern "KWRSentinel_*.zip"

    if (-not $commanderArtifact) {
        throw "No Commander distribution artifact was found in $outputPath."
    }
    if (-not $sentinelArtifact) {
        throw "No Sentinel artifact was found in $outputPath."
    }

    Invoke-Step "CurseForge Commander upload metadata dry-run" {
        Invoke-RepoScript -ScriptName "curseforge-upload-commander.ps1" -Arguments @(
            "-ArtifactPath", $commanderArtifact,
            "-DryRun"
        )
    }
    Invoke-Step "CurseForge Sentinel upload metadata dry-run" {
        Invoke-RepoScript -ScriptName "curseforge-upload-sentinel.ps1" -Arguments @(
            "-ArtifactPath", $sentinelArtifact,
            "-DryRun"
        )
    }
    foreach ($section in @("announcements", "support", "field-testing", "ops")) {
        Invoke-Step "Commander Discord $section announcement dry-run" {
            Invoke-RepoScript -ScriptName "kwr-commander-discord-announce.ps1" -Arguments @(
                "-Section", $section,
                "-DryRun"
            )
        }
        Invoke-Step "Sentinel Discord $section announcement dry-run" {
            Invoke-RepoScript -ScriptName "sentinel-discord-announce.ps1" -Arguments @(
                "-Section", $section,
                "-DryRun"
            )
        }
    }
}

function Write-Status {
    Write-Output "KWR automated maintenance schedule"
    Write-Output "Root: $root"
    Write-Output "Lane: $Lane"
    Write-Output "Mode: $Mode"
    Write-Output "Output: $outputPath"
    Write-Output "Central time: $((Get-CentralNow).ToString("yyyy-MM-dd HH:mm:ss zzz"))"
    foreach ($name in @(
        "KWR_OWNER_NAME",
        "KWR_GITHUB_REPOSITORY",
        "KWR_DEFAULT_BRANCH",
        "KWR_PRODUCTION_BRANCH",
        "KWR_FAMILY_REPOSITORIES",
        "DISCORD_WEBHOOK_DAILY_PROGRESS",
        "DISCORD_WEBHOOK_OPS",
        "DISCORD_WEBHOOK_ANNOUNCEMENTS",
        "DISCORD_WEBHOOK_SUPPORT",
        "DISCORD_WEBHOOK_FIELD_TESTING",
        "CURSEFORGE_COMMANDER_PROJECT_ID",
        "CURSEFORGE_SENTINEL_PROJECT_ID",
        "CURSEFORGE_API_TOKEN",
        "CURSEFORGE_GAME_VERSION_IDS"
    )) {
        Write-Output ("{0}: {1}" -f $name, (Test-SecretPresence -Name $name))
    }
}

function Write-Receipt {
    New-Item -ItemType Directory -Force -Path $outputPath | Out-Null
    $receiptPath = Join-Path $outputPath ("KWR_MAINTENANCE_{0}_{1}.json" -f $Lane.ToUpperInvariant().Replace("-", "_"), $runStarted.ToString("yyyyMMddTHHmmssZ"))
    $receipt = [ordered]@{
        schema = "kwr-maintenance-schedule-run"
        schemaVersion = 1
        lane = $Lane
        mode = $Mode
        startedAt = $runStarted.ToString("yyyy-MM-ddTHH:mm:ssZ")
        finishedAt = ([DateTimeOffset]::UtcNow).ToString("yyyy-MM-ddTHH:mm:ssZ")
        root = $root
        outputDirectory = $outputPath
        steps = @($steps)
    }
    [IO.File]::WriteAllText(
        $receiptPath,
        (($receipt | ConvertTo-Json -Depth 8) + [Environment]::NewLine),
        [Text.UTF8Encoding]::new($false)
    )
    Write-Output "Receipt: $receiptPath"
}

if ($Mode -eq "external" -and $ConfirmExternalWrites -cne "PUBLISH") {
    throw "External mode requires ConfirmExternalWrites=PUBLISH."
}

if ($Lane -eq "auto") {
    $Lane = Resolve-AutoLane
    Write-Output "Resolved auto lane: $Lane"
}

try {
    switch ($Lane) {
        "status" {
            Invoke-Step "Capability status" { Write-Status }
        }
        "daily" {
            Invoke-OfflineCertificationGate
            Invoke-Step "Security audit" { Invoke-RepoScript -ScriptName "security-audit.ps1" }
            Invoke-CertifiedBuild
            Invoke-ReadinessReports
            Invoke-DiscordStatus
        }
        "patch-preflight" {
            Invoke-Step "Capability status" { Write-Status }
            Invoke-ValidationGate
            Invoke-DiscordStatus
        }
        "patch-baseline" {
            Invoke-ValidationGate
            Invoke-CertifiedBuild
            Invoke-DiscordStatus
        }
        "patch-watch" {
            Invoke-Step "Fast validation" {
                Invoke-RepoScript -ScriptName "validate.ps1" -Arguments @("-Channel", "production")
            }
            Invoke-Step "Knowledge audit" {
                Invoke-RepoScript -ScriptName "knowledge-audit.ps1"
            }
            Invoke-DiscordStatus
        }
        "extended-reconciliation" {
            Invoke-OfflineCertificationGate
            Invoke-Step "Security audit" { Invoke-RepoScript -ScriptName "security-audit.ps1" }
            Invoke-ReleaseDryRun
            Invoke-ReadinessReports
            Invoke-DiscordStatus
        }
        "weekly-reconciliation" {
            Invoke-OfflineCertificationGate
            Invoke-Step "Security audit" { Invoke-RepoScript -ScriptName "security-audit.ps1" }
            Invoke-ReleaseDryRun
            Invoke-ReadinessReports
            Invoke-DiscordStatus
        }
        "biweekly-trends" {
            Invoke-Step "Biweekly trend anchor" {
                Write-Output "Biweekly trend lane active. Compare this receipt against the previous active Thursday receipt."
            }
            Invoke-OfflineCertificationGate
            Invoke-Step "Security audit" { Invoke-RepoScript -ScriptName "security-audit.ps1" }
            # Readiness includes a candidate-package report. Build the exact
            # Commander and Sentinel archives first so this lane never audits
            # a nonexistent placeholder path on a clean hosted runner.
            Invoke-CertifiedBuild
            Invoke-ReadinessReports
            Invoke-DiscordStatus
        }
        "monthly-maintenance" {
            Invoke-Step "Capability status" { Write-Status }
            Invoke-OfflineCertificationGate
            Invoke-Step "Security audit" { Invoke-RepoScript -ScriptName "security-audit.ps1" }
            Invoke-ReleaseDryRun
            Invoke-ReadinessReports
            Invoke-DiscordStatus
        }
        "release-dry-run" {
            Invoke-OfflineCertificationGate
            Invoke-Step "Security audit" { Invoke-RepoScript -ScriptName "security-audit.ps1" }
            Invoke-ReleaseDryRun
        }
        "full-dry-run" {
            Invoke-OfflineCertificationGate
            Invoke-Step "Security audit" { Invoke-RepoScript -ScriptName "security-audit.ps1" }
            Invoke-ReleaseDryRun
            Invoke-ReadinessReports
            Invoke-DiscordStatus
            Invoke-Step "Capability status" { Write-Status }
        }
    }
} finally {
    Write-Receipt
}
