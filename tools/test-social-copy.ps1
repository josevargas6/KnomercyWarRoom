$ErrorActionPreference = 'Stop'

$requiredFiles = @('README.md', 'CURSEFORGE_DESCRIPTION.md', 'docs/SOCIAL_COPY.md')
foreach ($path in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing social copy file: $path"
    }
}

$copy = ($requiredFiles | ForEach-Object { Get-Content -LiteralPath $_ -Raw }) -join "`n"
$requiredPhrases = @(
    '6.1.0-alpha.32',
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
