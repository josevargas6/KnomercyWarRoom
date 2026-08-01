$ErrorActionPreference = 'Stop'
$requiredFiles = @('README.md', 'CURSEFORGE_DESCRIPTION.md', 'docs/SOCIAL_COPY.md')
foreach ($path in $requiredFiles) { if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing social copy file: $path" } }
$copy = ($requiredFiles | ForEach-Object { Get-Content -LiteralPath $_ -Raw }) -join "`n"
foreach ($phrase in @('6.1.0-alpha.30','player-controlled','field-test','never auto-casts','GitHub','CurseForge','Discord','Support')) { if ($copy -notmatch [regex]::Escape($phrase)) { throw "Social copy is missing required phrase: $phrase" } }
Write-Output "KWR_SOCIAL_COPY_PASS files=$($requiredFiles.Count)"