$ErrorActionPreference = 'Stop'

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
    '6.1.0-alpha.33',
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
    if (-not $sectionMatch.Success -or $sectionMatch.Groups[1].Value -notmatch '6\.1\.0-alpha\.33') {
        throw "Social copy $productSection section does not identify the current Alpha 33 candidate."
    }
}

$releaseUpdates = Get-Content -LiteralPath 'docs/KWR_COMMANDER_DISCORD_CHANNEL_UPDATES.md' -Raw
$releaseUpdates += Get-Content -LiteralPath 'docs/SENTINEL_DISCORD_CHANNEL_UPDATES.md' -Raw
foreach ($staleVersion in @('6.1.0-alpha.32', '6.1.0-alpha.29', '6.1.0-alpha.25')) {
    if ($releaseUpdates -match [regex]::Escape($staleVersion)) {
        throw "Release channel copy contains stale candidate version: $staleVersion"
    }
}
foreach ($staleReceipt in @('8558795', '8558797')) {
    if ($releaseUpdates -match [regex]::Escape($staleReceipt)) {
        throw "Release channel copy contains stale CurseForge receipt: $staleReceipt"
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
