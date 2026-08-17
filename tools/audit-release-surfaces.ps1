[CmdletBinding()]
param(
    [string]$Repository = "josevargas6/KnomercyWarRoom",
    [string]$ReleaseTag = "v6.1.0"
)

$ErrorActionPreference = "Stop"
$headers = @{
    Accept = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}
$apiRoot = "https://api.github.com/repos/$Repository"
$findings = New-Object System.Collections.Generic.List[string]
$developmentBranchState = "ABSENT_RETIRED"
$developmentComparison = $null

function Add-Finding {
    param([string]$Message)
    $findings.Add($Message)
}

function Invoke-GitHubRead {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        [switch]$AllowNotFound
    )
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            return Invoke-RestMethod -Headers $headers -Uri $Uri -TimeoutSec 20
        } catch {
            $statusCode = $null
            if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }
            if ($AllowNotFound -and $statusCode -eq 404) { return $null }
            if ($attempt -eq 3) { throw }
            Start-Sleep -Seconds $attempt
        }
    }
}

function Get-GitHubFileContent {
    param([Parameter(Mandatory = $true)][string]$Path)
    $response = Invoke-GitHubRead -Uri "$apiRoot/contents/$Path`?ref=main"
    return [Text.Encoding]::UTF8.GetString(
        [Convert]::FromBase64String($response.content))
}

$release = $null
try {
    $release = Invoke-GitHubRead -Uri "$apiRoot/releases/tags/$ReleaseTag"
    $expectsPrerelease = $ReleaseTag.Substring(1) -match '-'
    if ([bool]$release.prerelease -ne $expectsPrerelease) {
        Add-Finding "Release $ReleaseTag channel does not match its semantic version."
    }
    if ($release.assets.Count -lt 1) { Add-Finding "Release $ReleaseTag has no GitHub assets." }
} catch {
    Add-Finding "Unable to read release $ReleaseTag after bounded retries: $($_.Exception.Message)"
}

try {
    $workflow = Get-GitHubFileContent -Path ".github/workflows/release.yml"
    if ($workflow -notmatch 'CURSEFORGE_PROJECT_ID:\s*"1632632"') {
        Add-Finding "main release workflow does not contain Commander numeric CurseForge project id 1632632."
    }
    if ($workflow -notmatch 'CURSEFORGE_PROJECT_ID:\s*"1614463"') {
        Add-Finding "main release workflow does not contain Sentinel numeric CurseForge project id 1614463."
    }
    if ($workflow -notmatch 'curseforge-upload-commander\.ps1' -or
        $workflow -notmatch 'curseforge-upload-sentinel\.ps1') {
        Add-Finding "main release workflow does not invoke both guarded CurseForge uploaders."
    } else {
        $validatorSource = Get-GitHubFileContent -Path "tools/curseforge-upload-http.ps1"
        if ($validatorSource -notmatch 'function\s+Assert-CurseForgeUploadResponse' -or
            $validatorSource -notmatch 'without a positive file id' -or
            $validatorSource -notmatch 'without a valid JSON response') {
            Add-Finding "main CurseForge upload helper does not fail closed on an unverified response."
        }
    }
} catch {
    Add-Finding "Unable to verify main release automation after bounded retries: $($_.Exception.Message)"
}

# `main` is the sole release authority. `develop` is an optional historical
# lane, so its retirement must not crash or block an otherwise valid audit.
# When it still exists, record ancestry for cleanup without treating it as a
# promotion source.
try {
    $developmentBranch = Invoke-GitHubRead `
        -Uri "$apiRoot/branches/develop" `
        -AllowNotFound
    if ($developmentBranch) {
        $developmentBranchState = "PRESENT_NON_AUTHORITATIVE"
        try {
            $comparison = Invoke-GitHubRead `
                -Uri "$apiRoot/compare/main...develop"
            $developmentComparison = [pscustomobject]@{
                status = $comparison.status
                ahead_by = $comparison.ahead_by
                behind_by = $comparison.behind_by
            }
        } catch {
            $developmentBranchState = "PRESENT_COMPARISON_UNAVAILABLE"
        }
    }
} catch {
    $statusCode = $null
    if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
        $statusCode = [int]$_.Exception.Response.StatusCode
    }
    if ($statusCode -ne 404) {
        $developmentBranchState = "UNKNOWN_NON_BLOCKING"
    }
}

foreach ($path in @(
    "tools/sentinel-discord-announce.ps1",
    "docs/KWR_COMMANDER_DISCORD_CHANNEL_UPDATES.md",
    "docs/SENTINEL_DISCORD_CHANNEL_UPDATES.md"
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot "..\$path") -PathType Leaf)) {
        Add-Finding "Missing Discord communication source: $path"
    }
}

[pscustomobject]@{
    repository = $Repository
    release = $ReleaseTag
    github_release_assets = $release.assets.Count
    github_release_url = $release.html_url
    release_authority = "main"
    development_branch_policy = "NON_AUTHORITATIVE_OPTIONAL"
    development_branch_state = $developmentBranchState
    development_comparison = $developmentComparison
    estate_policy = [pscustomobject]@{
        commander = "REQUIRED"
        sentinel = "REQUIRED_EMBEDDED_PACKAGE"
        beacon = "OPTIONAL_INTENTIONALLY_ABSENT_ALLOWED"
        maps = "OPTIONAL"
        scorecard = "OPTIONAL"
    }
    findings = @($findings)
    status = if ($findings.Count -eq 0) { "PASS" } else { "BLOCKED" }
} | ConvertTo-Json -Depth 5

if ($findings.Count -gt 0) { exit 2 }
