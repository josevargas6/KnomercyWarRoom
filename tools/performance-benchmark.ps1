[CmdletBinding()]
param(
    [string]$OutFile = "knowledge\offline-performance-benchmark.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$output = @(& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "tools\test-lua.ps1") -Suite Soak 2>&1)
$output | ForEach-Object { Write-Output $_ }
if ($LASTEXITCODE -ne 0) { throw "Offline soak benchmark failed." }
$line = @($output | Where-Object { $_ -match '^KWR_SOAK_PASS ' } | Select-Object -Last 1)
if (-not $line) { throw "Soak benchmark did not emit its result marker." }
$fields = @{}
foreach ($match in [regex]::Matches($line, '([A-Za-z0-9]+)=([0-9.]+)')) { $fields[$match.Groups[1].Value] = [double]$match.Groups[2].Value }
foreach ($required in @('refreshes', 'durationSamples', 'avgMs', 'p95Ms', 'maxMs', 'commanderHistory', 'evidence')) {
    if (-not $fields.ContainsKey($required)) { throw "Soak benchmark result is missing $required." }
}
$pass = $fields.avgMs -le 1.5 -and $fields.p95Ms -le 4 -and $fields.maxMs -le 10 -and
    $fields.durationSamples -le 120 -and $fields.commanderHistory -le 30 -and $fields.evidence -le 60
$report = [ordered]@{
    schema = 'kwr-offline-performance-benchmark'
    schemaVersion = 1
    generatedAt = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    result = if ($pass) { 'PASS' } else { 'FAIL' }
    budgets = [ordered]@{ averageMs = 1.5; p95Ms = 4.0; maxMs = 10.0; durationSamples = 120; commanderHistory = 30; evidenceLedger = 60 }
    observed = [ordered]@{ refreshes = [int]$fields.refreshes; durationSamples = [int]$fields.durationSamples; averageMs = $fields.avgMs; p95Ms = $fields.p95Ms; maxMs = $fields.maxMs; commanderHistory = [int]$fields.commanderHistory; evidenceLedger = [int]$fields.evidence }
    assertions = @('bounded refresh samples', 'bounded Commander history', 'bounded verification ledger', 'event-driven refresh soak')
}
$target = Join-Path $root $OutFile
[IO.File]::WriteAllText($target, (($report | ConvertTo-Json -Depth 6) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
if (-not $pass) { throw "Offline performance benchmark exceeded a budget." }
Write-Output "KWR OFFLINE PERFORMANCE BENCHMARK PASS"
