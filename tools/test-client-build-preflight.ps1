[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("kwr-client-build-preflight-" + [guid]::NewGuid().ToString("N"))
$checks = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    $script:checks++
    if (-not $Condition) { throw $Message }
}

try {
    [IO.Directory]::CreateDirectory($testRoot) | Out-Null
    $buildInfoPath = Join-Path $testRoot ".build.info"
    @(
        "Active!DEC:1|Version!STRING:0|Product!STRING:0",
        "1|12.1.0.69587|wow"
    ) | Set-Content -LiteralPath $buildInfoPath -Encoding utf8
    $outputPath = Join-Path $testRoot "result.json"
    $tool = Join-Path $root "tools\\client-build-preflight.ps1"
    & $tool -BuildInfoPath $buildInfoPath -OutFile $outputPath
    $report = Get-Content -LiteralPath $outputPath -Raw | ConvertFrom-Json
    Assert-True ($report.status -eq "PASS_METADATA_ONLY") "Matching 12.1.0 metadata did not pass."
    Assert-True ($report.client.interface -eq 120100) "Retail version did not derive interface 120100."
    Assert-True ($report.client.version -eq "12.1.0.69587") "Active Retail product row was not selected."
    Assert-True (@($report.checks | Where-Object { -not $_.pass }).Count -eq 0) "A matching preflight contains a failed check."

    $badCommander = Join-Path $testRoot "bad-commander.toc"
    @("## Interface: 120007", "## Version: 6.1.1-alpha.12") | Set-Content -LiteralPath $badCommander -Encoding utf8
    $badOutput = Join-Path $testRoot "bad-result.json"
    & $tool -BuildInfoPath $buildInfoPath -CommanderTocPath $badCommander -OutFile $badOutput
    $badReport = Get-Content -LiteralPath $badOutput -Raw | ConvertFrom-Json
    Assert-True ($badReport.status -eq "UNSUPPORTED_CLIENT_INTERFACE") "Missing client interface was not rejected."
    Assert-True (-not (@($badReport.checks | Where-Object { $_.name -eq "commander-declares-client-interface" })[0].pass)) "Missing Commander interface did not fail its named check."
} finally {
    if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
}

Write-Output "KWR client-build preflight tests passed: $checks"
