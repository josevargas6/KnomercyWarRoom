$ErrorActionPreference = 'Stop'
$toc = Get-Content -LiteralPath 'KnomercyWarRoom.toc'
$version = (($toc | Where-Object { $_ -match '^## Version:' }) -replace '^## Version:\s*', '').Trim()
if (-not $version) {
    throw 'Could not resolve the Commander version from the TOC.'
}

$requiredFiles = @(
    'README.md',
    'CURSEFORGE_DESCRIPTION.md',
    'docs/SOCIAL_COPY.md',
    'docs/KWR_COMMANDER_DISCORD_CHANNEL_UPDATES.md',
    'docs/SENTINEL_DISCORD_CHANNEL_UPDATES.md'
)
foreach ($path in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing social copy file: $path"
    }
}

$copy = ($requiredFiles | ForEach-Object { Get-Content -LiteralPath $_ -Raw }) -join "`n"
$requiredPhrases = @(
    $version,
    'player-controlled',
    'field-test',
    'never auto-casts',
    'GitHub',
    'CurseForge',
    'Support'
)
foreach ($phrase in $requiredPhrases) {
    if ($copy -notmatch [regex]::Escape($phrase)) {
        throw "Social copy is missing required phrase: $phrase"
    }
}

$socialCopy = Get-Content -LiteralPath 'docs/SOCIAL_COPY.md' -Raw
foreach ($productSection in @('Commander', 'Sentinel')) {
    $sectionPattern = '(?ms)^##\s+' + [regex]::Escape($productSection) + '\s+(.*?)(?=^##\s+|\z)'
    $sectionMatch = [regex]::Match($socialCopy, $sectionPattern)
    if (-not $sectionMatch.Success -or $sectionMatch.Groups[1].Value -notmatch [regex]::Escape($version)) {
        throw "Social copy $productSection section does not identify the TOC candidate $version."
    }
}

# These are active release surfaces, not historical changelog records. Every
# version reference must resolve to the current TOC candidate so a version bump
# cannot leave a stale download, Discord, or CurseForge instruction behind.
$activeReleaseFiles = @(
    'CURSEFORGE_UPLOAD.md',
    'KWRSentinel/CURSEFORGE_UPLOAD.md',
    'docs/KWR_COMMANDER_DISCORD_CHANNEL_UPDATES.md',
    'docs/SENTINEL_DISCORD_CHANNEL_UPDATES.md'
)
foreach ($path in $activeReleaseFiles) {
    $content = Get-Content -LiteralPath $path -Raw
    $versions = [regex]::Matches($content, '6\.1\.0-alpha\.\d+') |
        ForEach-Object { $_.Value } |
        Select-Object -Unique
    foreach ($foundVersion in @($versions)) {
        if ($foundVersion -cne $version) {
            throw "Active release surface $path contains stale version: $foundVersion (expected $version)."
        }
    }
}

$secretPatterns = @(
    'discord(app)?\.com/api/webhooks/\d+/[A-Za-z0-9_-]+',
    '(?i)(token|api[_-]?key|secret)\s*[:=]\s*[^\s`]+',
    '(?i)OPENAI_API_KEY\s*=\s*[^\s`]+',
    '(?i)GITHUB_TOKEN\s*=\s*[^\s`]+'
)
foreach ($pattern in $secretPatterns) {
    if ($copy -match $pattern) {
        throw "Social copy resembles a credential or webhook: $pattern"
    }
}

Write-Output "KWR_SOCIAL_COPY_PASS files=$($requiredFiles.Count)"
