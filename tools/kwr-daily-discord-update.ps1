[CmdletBinding()]
param(
    [ValidateSet("daily-progress", "ops")]
    [string]$Section = "daily-progress",
    [string]$WebhookUrl = $env:DISCORD_WEBHOOK_URL,
    [string]$Headline,
    [string[]]$Completed = @(),
    [string[]]$Next = @(),
    [string[]]$Ask = @(),
    [datetime]$ReportDate = (Get-Date),
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Read-JsonFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing $Label source: $Path"
    }

    $raw = Get-Content -LiteralPath $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        throw "$Label source is empty: $Path"
    }

    return $raw | ConvertFrom-Json
}

function Add-Bullets {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Lines,
        [Parameter(Mandatory = $true)]
        [string]$Heading,
        [string[]]$Items
    )

    $filtered = @($Items | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($filtered.Count -eq 0) {
        return
    }

    $Lines.Add($Heading)
    foreach ($item in $filtered) {
        $Lines.Add("- $item")
    }
}

function Join-Values {
    param(
        [AllowNull()]
        [object[]]$Items,
        [string]$Separator = ", "
    )

    $values = @($Items | Where-Object {
            $_ -ne $null -and -not [string]::IsNullOrWhiteSpace([string]$_)
        })
    if ($values.Count -eq 0) {
        return "none"
    }

    return ($values -join $Separator)
}

function Read-TextFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing $Label source: $Path"
    }

    $raw = Get-Content -LiteralPath $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        throw "$Label source is empty: $Path"
    }

    return $raw
}

function Get-MarkdownSectionBody {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Markdown,
        [Parameter(Mandatory = $true)]
        [string]$Heading
    )

    $pattern = '(?ms)^##\s+' + [regex]::Escape($Heading) + '\s*\r?\n(.*?)(?=^##\s+|\z)'
    $match = [regex]::Match($Markdown, $pattern)
    if (-not $match.Success) {
        throw "Could not find markdown section '$Heading'."
    }

    return $match.Groups[1].Value.Trim()
}

function Get-TopLevelMarkdownItems {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SectionBody,
        [int]$MaxItems = 3
    )

    $items = [System.Collections.Generic.List[string]]::new()
    foreach ($rawLine in ($SectionBody -split "`r?`n")) {
        $line = $rawLine.Trim()
        if ($line -match '^\d+\.\s+(.+)$') {
            $items.Add($matches[1].Trim())
        }
    }

    return @($items | Select-Object -First $MaxItems)
}

function Get-WorkflowContext {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkflowMarkdown
    )

    return [pscustomobject]@{
        currentLane = Get-TopLevelMarkdownItems -SectionBody (
            Get-MarkdownSectionBody -Markdown $WorkflowMarkdown -Heading "Current lane"
        ) -MaxItems 4
        readyNow = Get-TopLevelMarkdownItems -SectionBody (
            Get-MarkdownSectionBody -Markdown $WorkflowMarkdown -Heading "Ready to work right now"
        ) -MaxItems 4
        completed = Get-TopLevelMarkdownItems -SectionBody (
            Get-MarkdownSectionBody -Markdown $WorkflowMarkdown -Heading "Recently completed"
        ) -MaxItems 5
        issues = Get-TopLevelMarkdownItems -SectionBody (
            Get-MarkdownSectionBody -Markdown $WorkflowMarkdown -Heading "Newly discovered / still needs attention"
        ) -MaxItems 5
    }
}

function New-DailyProgressMessage {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Readiness,
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Blockers,
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Audit,
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Workflow
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $dateStamp = $ReportDate.ToString("yyyy-MM-dd")
    $evidenceVersion = if ($Readiness.candidate.evidenceBaseline) {
        [string]$Readiness.candidate.evidenceBaseline
    } elseif ($Readiness.candidate.version) {
        [string]$Readiness.candidate.version
    } else {
        [string]$Blockers.candidateVersion
    }

    $lines.Add("KWR daily update - $dateStamp")
    if (-not [string]::IsNullOrWhiteSpace($Headline)) {
        $lines.Add($Headline.Trim())
    }

    $lines.Add("Build: $script:currentAddonVersion")
    if ($evidenceVersion -ne $script:currentAddonVersion) {
        $lines.Add("Evidence baseline: $evidenceVersion (refresh required for $script:currentAddonVersion).")
    }
    $lines.Add(
        "Offline base: $($Readiness.offlineStatus.supportedMaps) maps, " +
        "$($Readiness.offlineStatus.baseScenarios) base scenarios, " +
        "$($Readiness.offlineStatus.reviewedCorpus) reviewed cases, " +
        "$($Readiness.offlineStatus.adversarialCases) adversarial cases."
    )
    $lines.Add("Direction: $(Join-Values -Items $Workflow.currentLane -Separator ' -> ').")

    if ($Audit.offlinePrepared -eq $true -and $Audit.fieldTestingPrepared -eq $true) {
        $lines.Add("Status: offline preparation is complete; live certification is still blocked.")
    } else {
        $lines.Add("Status: offline preparation is still incomplete.")
    }

    $openBlockers = @($Blockers.blockingDefects | Where-Object { $_.status -eq "OPEN" })
    $blockerIds = @($openBlockers | Select-Object -First 4 -ExpandProperty id)
    $lines.Add("Current blocker focus: $(Join-Values -Items $blockerIds).")

    $sessions = @($Blockers.recommendedSessions | Select-Object -First 3)
    $sessionIds = @($sessions | ForEach-Object { $_.sessionId })
    $lines.Add("Next field sessions: $(Join-Values -Items $sessionIds).")

    $liveOnlyGates = @()
    foreach ($entry in @($Audit.remainingLiveOnlyBlockers)) {
        if ($entry.value -is [System.Collections.IEnumerable] -and
            -not ($entry.value -is [string])) {
            $liveOnlyGates += @($entry.value)
        }
    }

    $gates = @($liveOnlyGates |
        Where-Object { $_ -is [string] -and $_ -notmatch '^KWR-\d+$' -and $_ -ne "TP-D03" } |
        Select-Object -First 4)
    if ($gates.Count -gt 0) {
        $lines.Add("Still required: $(Join-Values -Items $gates).")
    }

    Add-Bullets -Lines $lines -Heading "Current workflow:" -Items $Workflow.readyNow
    Add-Bullets -Lines $lines -Heading "Known issues:" -Items $Workflow.issues
    Add-Bullets -Lines $lines -Heading "Repairs and changes made:" -Items $Workflow.completed
    Add-Bullets -Lines $lines -Heading "Session-specific completed today:" -Items $Completed
    Add-Bullets -Lines $lines -Heading "Session-specific next up:" -Items $Next
    Add-Bullets -Lines $lines -Heading "Needs from team:" -Items $Ask

    return ($lines -join [Environment]::NewLine).Trim()
}

function New-OpsMessage {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Readiness,
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Blockers,
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Audit,
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Workflow
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $dateStamp = $ReportDate.ToString("yyyy-MM-dd")
    $evidenceVersion = if ($Readiness.candidate.evidenceBaseline) {
        [string]$Readiness.candidate.evidenceBaseline
    } elseif ($Readiness.candidate.version) {
        [string]$Readiness.candidate.version
    } else {
        [string]$Blockers.candidateVersion
    }

    $openBlockers = @($Blockers.blockingDefects | Where-Object { $_.status -eq "OPEN" })
    $blockerSummary = @($openBlockers | Select-Object -First 4 | ForEach-Object {
            "$($_.id) $($_.bestSession)"
        })
    $sessionSummary = @($Blockers.recommendedSessions | Select-Object -First 3 |
        ForEach-Object { "$($_.sessionId): $($_.purpose)" })

    $lines.Add("KWR ops status - $dateStamp")
    $lines.Add("Candidate: $script:currentAddonVersion")
    if ($evidenceVersion -ne $script:currentAddonVersion) {
        $lines.Add("Evidence baseline: $evidenceVersion (refresh required for $script:currentAddonVersion).")
    }
    $lines.Add("Offline prepared: $(if ($Audit.offlinePrepared) { "YES" } else { "NO" })")
    $lines.Add("Field-testing prepared: $(if ($Audit.fieldTestingPrepared) { "YES" } else { "NO" })")
    $lines.Add(
        "Offline proof: validate=$($Readiness.offlineStatus.validatePassed), " +
        "knowledgeAudit=$($Readiness.offlineStatus.knowledgeAuditPassed), " +
        "corpusAudit=$($Readiness.offlineStatus.corpusAuditPassed), " +
        "benchmark=$($Readiness.offlineStatus.decisionBenchmarkPassed)."
    )
    $lines.Add("Direction: $(Join-Values -Items $Workflow.currentLane -Separator ' -> ').")
    $lines.Add("Open live blockers: $(Join-Values -Items $blockerSummary -Separator ' | ').")
    $lines.Add("Recommended sessions: $(Join-Values -Items $sessionSummary -Separator ' | ').")
    $lines.Add("Active known issues: $(Join-Values -Items $Workflow.issues -Separator ' | ').")
    $lines.Add("Recent repairs: $(Join-Values -Items $Workflow.completed -Separator ' | ').")
    $lines.Add("Required capture: /kwr verify, /kwr perf, AAR export, screenshots, Lua error and taint result.")

    return ($lines -join [Environment]::NewLine).Trim()
}

$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$readinessPath = Join-Path $root "knowledge\field-test-readiness.json"
$blockerPath = Join-Path $root "knowledge\field-blocker-report.json"
$auditPath = Join-Path $root "knowledge\offline-completion-audit.json"
$workflowPath = Join-Path $root "docs\WORKFLOW_NOW.md"
$tocPath = Join-Path $root "KnomercyWarRoom.toc"

$toc = Read-TextFile -Path $tocPath -Label "addon manifest"
$tocVersionMatch = [regex]::Match($toc, '(?m)^## Version:\s*(.+?)\s*$')
if (-not $tocVersionMatch.Success) {
    throw "Addon manifest does not declare a version."
}
$script:currentAddonVersion = $tocVersionMatch.Groups[1].Value.Trim()

$readiness = Read-JsonFile -Path $readinessPath -Label "field readiness"
$blockers = Read-JsonFile -Path $blockerPath -Label "field blocker"
$audit = Read-JsonFile -Path $auditPath -Label "offline completion audit"
$workflowMarkdown = Read-TextFile -Path $workflowPath -Label "workflow status"
$workflow = Get-WorkflowContext -WorkflowMarkdown $workflowMarkdown

$message = switch ($Section) {
    "daily-progress" {
        New-DailyProgressMessage -Readiness $readiness -Blockers $blockers -Audit $audit -Workflow $workflow
    }
    "ops" {
        New-OpsMessage -Readiness $readiness -Blockers $blockers -Audit $audit -Workflow $workflow
    }
}

if ([string]::IsNullOrWhiteSpace($message)) {
    throw "Generated Discord message was empty."
}

if ($message.Length -gt 2000) {
    throw "Generated Discord message exceeds 2000 characters."
}

if ($DryRun -or [string]::IsNullOrWhiteSpace($WebhookUrl)) {
    Write-Output "DRY RUN: Discord section '$Section'"
    Write-Output $message
    if (-not $DryRun -and [string]::IsNullOrWhiteSpace($WebhookUrl)) {
        throw "No webhook was provided. Set DISCORD_WEBHOOK_URL or pass -WebhookUrl to post."
    }
    exit 0
}

$webhookUri = $null
if (-not [Uri]::TryCreate($WebhookUrl, [UriKind]::Absolute, [ref]$webhookUri)) {
    throw "Discord webhook URL is not a valid absolute URI."
}

$allowedWebhookHosts = @(
    "discord.com",
    "canary.discord.com",
    "ptb.discord.com",
    "discordapp.com"
)

if ($webhookUri.Scheme -ne "https" -or
    $allowedWebhookHosts -notcontains $webhookUri.Host.ToLowerInvariant() -or
    $webhookUri.AbsolutePath -notmatch '^/api/webhooks/\d+/[A-Za-z0-9_-]+/?$') {
    throw "Discord webhook URL must use HTTPS and an approved Discord webhook endpoint."
}

$payload = @{ content = $message } | ConvertTo-Json -Depth 4
Invoke-RestMethod `
    -Method Post `
    -Uri $WebhookUrl `
    -ContentType "application/json" `
    -Body $payload | Out-Null

Write-Output "Posted KWR Discord update for '$Section'."
