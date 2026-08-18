[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SavedVariablesPath,
    [string]$DeploymentCertificationPath = "knowledge\deployment-certification.json",
    [string]$OutFile = "knowledge\retail-field-certification.json",
    [string]$ExportFile
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
. (Join-Path $PSScriptRoot "hash-utils.ps1")
$savedPath = [IO.Path]::GetFullPath($SavedVariablesPath)
$deploymentPath = if ([IO.Path]::IsPathRooted($DeploymentCertificationPath)) {
    [IO.Path]::GetFullPath($DeploymentCertificationPath)
} else {
    [IO.Path]::GetFullPath((Join-Path $root $DeploymentCertificationPath))
}
$outPath = if ([IO.Path]::IsPathRooted($OutFile)) {
    [IO.Path]::GetFullPath($OutFile)
} else {
    [IO.Path]::GetFullPath((Join-Path $root $OutFile))
}

foreach ($required in @($savedPath, $deploymentPath)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "Required certification input is missing: $required"
    }
}

$addonSource = Get-Content -LiteralPath (Join-Path $root "Core\Addon.lua") -Raw
$candidateVersion = [regex]::Match(
    $addonSource, 'KWR\.version\s*=\s*"([^"]+)"').Groups[1].Value
$candidateSchema = [int][regex]::Match(
    $addonSource, 'KWR\.schemaVersion\s*=\s*(\d+)').Groups[1].Value
$deployment = Get-Content -LiteralPath $deploymentPath -Raw | ConvertFrom-Json
$savedItem = Get-Item -LiteralPath $savedPath
$savedHash = Get-KwrFileSha256 -LiteralPath $savedPath

function Find-RetailEvidenceRuntime {
    $pathNode = Get-Command "node" -ErrorAction SilentlyContinue
    $pathFengari = Get-Command "fengari" -ErrorAction SilentlyContinue
    if ($pathNode -and $pathFengari) {
        return [pscustomobject]@{
            Mode = "Cli"
            Command = $pathFengari.Source
            Node = $pathNode.Source
            Cli = $null
        }
    }
    $nodeCandidates = @(
        $env:KWR_NODE_EXE,
        (Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe"),
        (Join-Path $env:ProgramFiles "nodejs\node.exe")
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) }
    $node = $nodeCandidates | Select-Object -First 1
    $cliCandidates = @()
    if ($env:KWR_FENGARI_CLI) { $cliCandidates += $env:KWR_FENGARI_CLI }
    $toolsRoot = Join-Path $env:LOCALAPPDATA "Temp\kwr-lua-tools"
    if (Test-Path -LiteralPath $toolsRoot -PathType Container) {
        $cliCandidates += Get-ChildItem -LiteralPath $toolsRoot -Recurse -Filter "lua-cli.js" `
            -ErrorAction SilentlyContinue | ForEach-Object FullName
    }
    $cli = $cliCandidates | Where-Object {
        $_ -and (Test-Path -LiteralPath $_ -PathType Leaf)
    } | Select-Object -First 1
    if (-not $node -or -not $cli) {
        throw "Cached Node.js/Fengari runtime is required for Retail SavedVariables certification."
    }
    return [pscustomobject]@{
        Mode = "NodeCli"
        Command = $node
        Node = $node
        Cli = $cli
    }
}

$exportLines = if ($ExportFile) {
    Get-Content -LiteralPath ([IO.Path]::GetFullPath($ExportFile))
} else {
    $runtime = Find-RetailEvidenceRuntime
    $previousNodePath = $env:NODE_PATH
    try {
        $pnpmRoot = Join-Path $env:LOCALAPPDATA "Temp\kwr-lua-tools\node_modules\.pnpm"
        if (Test-Path -LiteralPath $pnpmRoot -PathType Container) {
            $env:NODE_PATH = @(
                Get-ChildItem -LiteralPath $pnpmRoot -Directory -ErrorAction SilentlyContinue |
                    ForEach-Object { Join-Path $_.FullName "node_modules" } |
                    Where-Object { Test-Path -LiteralPath $_ }
            ) -join ";"
        }
        $exporter = Join-Path $PSScriptRoot "retail-savedvariables-export.lua"
        $output = if ($runtime.Mode -eq "Cli") {
            & $runtime.Command $exporter $savedPath 2>&1
        } else {
            & $runtime.Node $runtime.Cli $exporter $savedPath 2>&1
        }
        if ($LASTEXITCODE -ne 0) {
            throw "SavedVariables exporter failed: $($output -join [Environment]::NewLine)"
        }
        @($output)
    } finally {
        $env:NODE_PATH = $previousNodePath
    }
}

$meta = $null
$matches = @()
foreach ($line in @($exportLines)) {
    # PowerShell's negative split count keeps the complete string instead of
    # splitting it. Use the normal tab split so exporter META/MATCH records are
    # actually decoded (and retain the empty fields the exporter emits).
    $fields = @([string]$line -split "`t")
    if ($fields[0] -eq "META" -and $fields.Count -ge 4) {
        $meta = [pscustomobject]@{
            schemaVersion = [int]$fields[1]
            historyCount = [int]$fields[2]
            interruptedCheckpoint = $fields[3] -eq "YES"
        }
    } elseif ($fields[0] -eq "MATCH" -and $fields.Count -ge 21) {
        $matches += [pscustomobject][ordered]@{
            index = [int]$fields[1]
            id = $fields[2]
            mapKey = $fields[3]
            mapName = $fields[4]
            result = $fields[5]
            startedAt = [long]($fields[6] -as [long])
            endedAt = [long]($fields[7] -as [long])
            durationSeconds = [int]($fields[8] -as [int])
            certificationStatus = $fields[9]
            commandHealth = $fields[10]
            replacements = [int]($fields[11] -as [int])
            reversals = [int]($fields[12] -as [int])
            preMovementInvalidations = [int]($fields[13] -as [int])
            successfulPlays = [int]($fields[14] -as [int])
            friendlyScore = [int]($fields[15] -as [int])
            enemyScore = [int]($fields[16] -as [int])
            friendlyPlayers = [int]($fields[17] -as [int])
            enemyPlayers = [int]($fields[18] -as [int])
            commands = [int]($fields[19] -as [int])
            events = [int]($fields[20] -as [int])
            addonVersion = if ($fields.Count -gt 21) { $fields[21] } else { "" }
            schemaVersion = if ($fields.Count -gt 22) { [int]($fields[22] -as [int]) } else { 0 }
            performance = [ordered]@{
                samples = if ($fields.Count -gt 23) { [int]($fields[23] -as [int]) } else { 0 }
                maxRefreshMs = if ($fields.Count -gt 24) { [double]($fields[24] -as [double]) } else { 0 }
                maxP95Ms = if ($fields.Count -gt 25) { [double]($fields[25] -as [double]) } else { 0 }
                firstMemoryKB = if ($fields.Count -gt 26) { [double]($fields[26] -as [double]) } else { 0 }
                lastMemoryKB = if ($fields.Count -gt 27) { [double]($fields[27] -as [double]) } else { 0 }
                maxMemoryKB = if ($fields.Count -gt 28) { [double]($fields[28] -as [double]) } else { 0 }
                maxTransitionMs = if ($fields.Count -gt 29) { [double]($fields[29] -as [double]) } else { 0 }
                errors = if ($fields.Count -gt 30) { [int]($fields[30] -as [int]) } else { 0 }
            }
            safety = [ordered]@{
                blocked = if ($fields.Count -gt 31) { [int]($fields[31] -as [int]) } else { 0 }
                forbidden = if ($fields.Count -gt 32) { [int]($fields[32] -as [int]) } else { 0 }
                total = if ($fields.Count -gt 33) { [int]($fields[33] -as [int]) } else { 0 }
            }
        }
    }
}
if (-not $meta) {
    throw "SavedVariables exporter did not emit a META record."
}

$certifiedAt = [DateTimeOffset]::Parse([string]$deployment.certifiedAt)
$schemaMatches = $meta.schemaVersion -eq $candidateSchema
$versionMatches = $deployment.candidateVersion -eq $candidateVersion
$postCertification = $savedItem.LastWriteTimeUtc -ge $certifiedAt.UtcDateTime
$bound = $schemaMatches -and $versionMatches -and $postCertification `
    -and $deployment.result -eq "PASS"
$certifiedEpoch = $certifiedAt.ToUnixTimeSeconds()
$candidateMatches = @($matches | Where-Object {
    $_.addonVersion -eq $candidateVersion -and
    $_.schemaVersion -eq $candidateSchema -and
    $_.endedAt -ge $certifiedEpoch
})
$completed = @($candidateMatches | Where-Object result -in @("VICTORY", "DEFEAT", "DRAW", "COMPLETE"))
$interrupted = @($candidateMatches | Where-Object result -eq "INTERRUPTED")
$ready = @($completed | Where-Object certificationStatus -eq "READY")
$failed = @($completed | Where-Object certificationStatus -eq "FAIL_REVIEW")
$observedCompleted = @($matches | Where-Object result -in @("VICTORY", "DEFEAT", "DRAW", "COMPLETE"))
$observedFailed = @($observedCompleted | Where-Object certificationStatus -eq "FAIL_REVIEW")
$maps = @($completed | ForEach-Object mapKey | Where-Object { $_ -and $_ -ne "UNKNOWN" } | Sort-Object -Unique)
$safeMatches = @($completed | Where-Object {
    $_.safety.total -eq 0 -and $_.performance.errors -eq 0
})
$performanceMatches = @($completed | Where-Object {
    $_.performance.samples -gt 0 -and
    $_.performance.maxRefreshMs -gt 0 -and
    $_.performance.maxP95Ms -gt 0 -and
    $_.performance.maxMemoryKB -gt 0 -and
    $_.performance.firstMemoryKB -gt 0 -and
    $_.performance.lastMemoryKB -gt 0 -and
    $_.performance.maxP95Ms -lt 2 -and
    $_.performance.maxRefreshMs -lt 10 -and
    $_.performance.maxMemoryKB -le (25 * 1024) -and
    [math]::Abs($_.performance.lastMemoryKB - $_.performance.firstMemoryKB) -le 2048
})

$proven = @()
$missing = @()
if ($bound -and $completed.Count -gt 0) {
    $proven += "complete-match lifecycle"
} else {
    $missing += "candidate-bound complete-match lifecycle"
}
if ($bound -and $ready.Count -gt 0 -and $failed.Count -eq 0) {
    $proven += "command stability"
} else {
    $missing += "candidate-bound command stability inside budget"
}
if ($bound -and $completed.Count -gt 0 -and $safeMatches.Count -eq $completed.Count) {
    $proven += "taint and blocked-action safety"
} else {
    $missing += "taint and blocked-action safety"
}
if ($bound -and $completed.Count -gt 0 -and $performanceMatches.Count -eq $completed.Count) {
    $proven += "field CPU and memory budgets"
} else {
    $missing += "field CPU and memory budgets"
}
foreach ($gate in @(
    "supported-resolution readability screenshots",
    "expanded Team truth screenshot",
    "canonical carrier-target capture",
    "full supported map-family coverage"
)) {
    $missing += $gate
}

$report = [ordered]@{
    schema = "kwr-retail-field-certification"
    schemaVersion = 1
    generatedAt = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
    candidateVersion = $candidateVersion
    candidateSchema = $candidateSchema
    source = [ordered]@{
        fileName = $savedItem.Name
        sha256 = $savedHash
        lastWriteTimeUtc = $savedItem.LastWriteTimeUtc.ToString("yyyy-MM-ddTHH:mm:ssZ")
        historyCount = $meta.historyCount
        candidateMatchCount = $candidateMatches.Count
        interruptedCheckpoint = $meta.interruptedCheckpoint
    }
    binding = [ordered]@{
        status = if ($bound) { "BOUND" } else { "UNBOUND" }
        schemaMatches = $schemaMatches
        deploymentVersionMatches = $versionMatches
        writtenAfterCertification = $postCertification
        deploymentCertifiedAt = $certifiedAt.UtcDateTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
    summary = [ordered]@{
        completedMatches = $completed.Count
        interruptedMatches = $interrupted.Count
        historicalOrUnboundMatches = $matches.Count - $candidateMatches.Count
        observedCompletedMatches = $observedCompleted.Count
        observedStabilityFailedMatches = $observedFailed.Count
        stabilityReadyMatches = $ready.Count
        stabilityFailedMatches = $failed.Count
        safetyPassingMatches = $safeMatches.Count
        performancePassingMatches = $performanceMatches.Count
        maps = $maps
    }
    matches = @($matches)
    provenGates = @($proven)
    missingGates = @($missing)
    result = if ($bound -and $missing.Count -eq 0) { "PASS" } else { "BLOCKED" }
}

$parent = Split-Path -Parent $outPath
if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}
[IO.File]::WriteAllText(
    $outPath,
    (($report | ConvertTo-Json -Depth 8) + "`n"),
    [Text.UTF8Encoding]::new($false))

Write-Output "KWR Retail SavedVariables certification"
Write-Output "Binding: $($report.binding.status)"
Write-Output "Completed matches: $($completed.Count)"
Write-Output "Interrupted matches: $($interrupted.Count)"
Write-Output "Stability ready/failed: $($ready.Count)/$($failed.Count)"
Write-Output "Result: $($report.result)"
Write-Output "Output: $outPath"
