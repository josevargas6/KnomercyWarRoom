[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("kwr-retail-cert-test-" + [guid]::NewGuid().ToString("N"))
$checks = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    $script:checks++
    if (-not $Condition) { throw $Message }
}

try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    $savedPath = Join-Path $tempRoot "KnomercyWarRoom.lua"
    $deploymentPath = Join-Path $tempRoot "deployment.json"
    $outputPath = Join-Path $tempRoot "report.json"
    $addonSource = Get-Content -LiteralPath (Join-Path $root "Core\Addon.lua") -Raw
    $version = [regex]::Match($addonSource, 'KWR\.version\s*=\s*"([^"]+)"').Groups[1].Value
    $schema = [int][regex]::Match($addonSource, 'KWR\.schemaVersion\s*=\s*(\d+)').Groups[1].Value
    $matchStart = [DateTimeOffset]::UtcNow.AddMinutes(-8).ToUnixTimeSeconds()
    $matchEnd = [DateTimeOffset]::UtcNow.AddMinutes(-1).ToUnixTimeSeconds()
    $saved = @"
KWR_DB = {
    schemaVersion = $schema,
    journal = {
        history = {
            {
                id = "fixture:ARATHI",
                addonVersion = "$version",
                schemaVersion = $schema,
                mapKey = "ARATHI",
                mapName = "Arathi Basin",
                result = "VICTORY",
                startedAt = $matchStart,
                endedAt = $matchEnd,
                duration = 420,
                commandStability = {
                    certificationStatus = "READY",
                    commandHealth = "PASS",
                    replacements = 2,
                    reversals = 0,
                    preMovementInvalidations = 0,
                    successfulPlays = 1,
                },
                scoreEnd = { friendly = 1500, enemy = 1200 },
                performance = {
                    samples = 40,
                    maxRefreshMs = 3.5,
                    maxP95Ms = 1.2,
                    firstMemoryKB = 12000,
                    lastMemoryKB = 12500,
                    maxMemoryKB = 13000,
                    maxTransitionMs = 2.0,
                    errors = 0,
                },
                safety = { blocked = 0, forbidden = 0, total = 0 },
                friendlyTeam = { one = {}, two = {} },
                enemyTeam = { one = {}, two = {} },
                commands = { {}, {} },
                events = { {}, {}, {} },
            },
        },
    },
}
"@
    [IO.File]::WriteAllText($savedPath, $saved, [Text.UTF8Encoding]::new($false))
    $certifiedAt = [DateTime]::UtcNow.AddMinutes(-10)
    $deployment = [ordered]@{
        certifiedAt = $certifiedAt.ToString("yyyy-MM-ddTHH:mm:ssZ")
        candidateVersion = $version
        result = "PASS"
    }
    [IO.File]::WriteAllText(
        $deploymentPath,
        (($deployment | ConvertTo-Json) + "`n"),
        [Text.UTF8Encoding]::new($false))
    [IO.File]::SetLastWriteTimeUtc($savedPath, [DateTime]::UtcNow)

    & powershell -NoProfile -ExecutionPolicy Bypass -File `
        (Join-Path $PSScriptRoot "retail-savedvariables-audit.ps1") `
        -SavedVariablesPath $savedPath `
        -DeploymentCertificationPath $deploymentPath `
        -OutFile $outputPath | Out-Null
    Assert-True ($LASTEXITCODE -eq 0) "Bound SavedVariables audit failed to execute."
    $bound = Get-Content -LiteralPath $outputPath -Raw | ConvertFrom-Json
    Assert-True ($bound.binding.status -eq "BOUND") "Post-certification fixture was not bound."
    Assert-True ($bound.summary.completedMatches -eq 1) "Completed fixture match was not counted."
    Assert-True ($bound.summary.stabilityReadyMatches -eq 1) "Ready stability fixture was not counted."
    Assert-True ($bound.summary.safetyPassingMatches -eq 1) "Safe fixture was not counted."
    Assert-True ($bound.summary.performancePassingMatches -eq 1) "Performance fixture was not counted."
    Assert-True ($bound.provenGates -contains "complete-match lifecycle") `
        "Bound complete-match lifecycle was not proven."
    Assert-True ($bound.source.PSObject.Properties.Name -notcontains "path") `
        "Certification report leaked the local SavedVariables path."

    [IO.File]::SetLastWriteTimeUtc($savedPath, $certifiedAt.AddMinutes(-1))
    & powershell -NoProfile -ExecutionPolicy Bypass -File `
        (Join-Path $PSScriptRoot "retail-savedvariables-audit.ps1") `
        -SavedVariablesPath $savedPath `
        -DeploymentCertificationPath $deploymentPath `
        -OutFile $outputPath | Out-Null
    $unbound = Get-Content -LiteralPath $outputPath -Raw | ConvertFrom-Json
    Assert-True ($unbound.binding.status -eq "UNBOUND") `
        "Pre-certification fixture did not fail closed."
    Assert-True ($unbound.missingGates -contains "candidate-bound complete-match lifecycle") `
        "Unbound lifecycle proof was incorrectly accepted."

    Write-Output "KWR_RETAIL_SAVEDVARIABLES_AUDIT_TEST_PASS checks=$checks"
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
