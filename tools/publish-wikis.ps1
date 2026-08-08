param(
    [string]$CommanderWiki = "josevargas6/KnomercyWarRoom.wiki",
    [string]$SentinelWiki = "josevargas6/KWRSentinel.wiki",
    [string]$OutputDirectory = (Join-Path $env:TEMP "kwr-wiki-publish")
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$token = $env:WIKI_PUBLISH_TOKEN
if ([string]::IsNullOrWhiteSpace($token) -and (Get-Command gh -ErrorAction SilentlyContinue)) {
    $token = gh auth token
}
if ([string]::IsNullOrWhiteSpace($token)) {
    throw "WIKI_PUBLISH_TOKEN or an authenticated gh session is required."
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$authenticatedHost = if (-not [string]::IsNullOrWhiteSpace($env:WIKI_PUBLISH_TOKEN)) {
    "https://x-access-token:$token@github.com"
} else {
    gh auth setup-git | Out-Null
    "https://github.com"
}

function Sync-Wiki {
    param(
        [string]$Repository,
        [string]$GuideSource,
        [string]$GuideName,
        [string]$HomeSource,
        [string]$Message
    )

    $folderName = ($Repository -replace "/", "-")
    $folder = Join-Path $OutputDirectory $folderName
    if (Test-Path -LiteralPath $folder) {
        Remove-Item -LiteralPath $folder -Recurse -Force
    }
    $url = "$authenticatedHost/$Repository.git"
    git clone $url $folder
    Copy-Item -LiteralPath (Join-Path $root $GuideSource) -Destination (Join-Path $folder $GuideName) -Force
    Copy-Item -LiteralPath (Join-Path $root $HomeSource) -Destination (Join-Path $folder "Home.md") -Force
    git -C $folder config user.name "KWR Documentation Automation"
    git -C $folder config user.email "41898282+github-actions[bot]@users.noreply.github.com"
    git -C $folder add $GuideName Home.md
    git -C $folder diff --cached --quiet
    if ($LASTEXITCODE -eq 0) {
        Write-Output "$Repository is already synchronized."
        return
    }
    git -C $folder commit -m $Message
    git -C $folder push $url master
    Write-Output "Published $Repository."
}

Sync-Wiki $CommanderWiki "docs/KWR_USER_GUIDE_WIKI.md" "Commander-and-Sentinel-User-Guide.md" "docs/wiki-home-commander.md" "Synchronize Commander and Sentinel user guide"
Sync-Wiki $SentinelWiki "docs/SENTINEL_USER_GUIDE_WIKI.md" "KWR-Sentinel-User-Guide.md" "docs/wiki-home-sentinel.md" "Synchronize Sentinel user guide"
