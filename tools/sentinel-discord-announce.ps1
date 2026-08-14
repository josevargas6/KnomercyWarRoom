[CmdletBinding()]
param(
    [ValidateSet("announcements", "support", "field-testing", "ops")]
    [string]$Section = "announcements",
    [string]$WebhookUrl = $env:DISCORD_WEBHOOK_URL,
    [string]$Version = "",
    [string]$CommanderVersion = "",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$sourcePath = Join-Path $root "docs\SENTINEL_DISCORD_CHANNEL_UPDATES.md"

if ([string]::IsNullOrWhiteSpace($CommanderVersion)) {
    $commanderTocPath = Join-Path $root "KnomercyWarRoom.toc"
    $commanderVersionLine = Get-Content -LiteralPath $commanderTocPath |
        Where-Object { $_ -match "^## Version:" } |
        Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($commanderVersionLine)) {
        throw "Could not determine Commander version from $commanderTocPath."
    }
    $CommanderVersion = ($commanderVersionLine -replace "^## Version:\s*", "").Trim()
}

if (-not (Test-Path -LiteralPath $sourcePath)) {
    throw "Missing Discord update source: $sourcePath"
}

$sectionMap = @{
    "announcements" = "#announcements"
    "support" = "#kwr-support"
    "field-testing" = "#kwr-field-testing"
    "ops" = "Restricted Ops Thread"
}

$heading = [regex]::Escape($sectionMap[$Section])
$source = Get-Content -LiteralPath $sourcePath -Raw
$pattern = '(?ms)^##\s+' + $heading + '\s*```text\s*(.*?)\s*```'
$match = [regex]::Match($source, $pattern)
if (-not $match.Success) {
    throw "Could not find Discord message block for section '$Section'."
}

$message = $match.Groups[1].Value.Trim()
if (-not [string]::IsNullOrWhiteSpace($Version)) {
    $message = $message -replace '\d+\.\d+\.\d+-alpha\.\d+', $Version
    $message = $message -replace '\d+_\d+_\d+_ALPHA_\d+', ($Version.ToUpperInvariant().Replace('.', '_').Replace('-', '_'))
}
$message = [regex]::Replace(
    $message,
    'Commander\s+\d+\.\d+\.\d+-alpha\.\d+',
    "Commander $CommanderVersion"
)
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
$allowedWebhookHosts = @("discord.com", "canary.discord.com", "ptb.discord.com", "discordapp.com")
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

Write-Output "Posted Sentinel Discord update for '$Section'."
