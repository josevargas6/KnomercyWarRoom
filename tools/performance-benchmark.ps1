[CmdletBinding()]
param(
    [string]$OutFile = "knowledge\offline-performance-benchmark.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$output = @(& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "tools\test-lua.ps1") -Suite Host 2>&1)
$output | ForEach-Object { Write-Output $_ }
if ($LASTEXITCODE -ne 0) { throw "Host measurement failed." }
$line = @($output | Where-Object { $_ -match '^KWR_HOST_BENCHMARK_PASS ' } | Select-Object -Last 1)
if (-not $line -or $line -notmatch 'timingSource=os.clock') { throw "Real host benchmark marker missing." }
$fields = @{}
foreach ($match in [regex]::Matches($line, '([A-Za-z0-9]+)=([0-9.]+)')) { $fields[$match.Groups[1].Value] = [double]$match.Groups[2].Value }
foreach ($required in @('samples', 'avgMs', 'p50Ms', 'p95Ms', 'p99Ms', 'maxMs')) {
    if (-not $fields.ContainsKey($required)) { throw "Soak benchmark result is missing $required." }
}
$gitRevision = @(& git -C $root rev-parse HEAD 2>$null | Select-Object -First 1)
if ($LASTEXITCODE -ne 0) { $gitRevision = @('unavailable') }
$runtimeLine = @($output | Where-Object { $_ -match '^KWR Lua runtime:' } | Select-Object -Last 1)
$commandLine = @($output | Where-Object { $_ -match '^Command:' } | Select-Object -Last 1)
$pass = $fields.samples -eq 30 -and $fields.avgMs -gt 0 -and $fields.p50Ms -gt 0 `
    -and $fields.p95Ms -gt 0 -and $fields.p99Ms -gt 0 -and $fields.maxMs -gt 0 `
    -and $fields.p50Ms -le $fields.p95Ms -and $fields.p95Ms -le $fields.p99Ms `
    -and $fields.p99Ms -le $fields.maxMs
$report = [ordered]@{
    schema = 'kwr-offline-performance-benchmark'
    schemaVersion = 2
    generatedAt = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    result = if ($pass) { 'PASS' } else { 'FAIL' }
    timingSource = 'os.clock'
    scope = 'actual host runtime with mocked WoW APIs and a preview workload'
    resultMeaning = 'Measurement completed; not a pass against Retail performance budgets.'
    clientBudgetStatus = 'REQUIRES_RETAIL_MEASUREMENT'
    provenance = [ordered]@{
        sourceRevision = [string]$gitRevision[0]
        sourceRoot = $root
        luaRuntime = if ($runtimeLine) { [string]$runtimeLine[0] } else { 'unavailable' }
        luaCommand = if ($commandLine) { [string]$commandLine[0] } else { 'unavailable' }
        host = [ordered]@{
            os = [Environment]::OSVersion.VersionString
            processor = [string]$env:PROCESSOR_IDENTIFIER
            processArchitecture = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture.ToString()
            powershell = $PSVersionTable.PSVersion.ToString()
        }
    }
    observed = [ordered]@{
        samples = [int]$fields.samples
        averageMs = $fields.avgMs
        p50Ms = $fields.p50Ms
        p95Ms = $fields.p95Ms
        p99Ms = $fields.p99Ms
        maxMs = $fields.maxMs
    }
    assertions = @('30 real host samples after five warm-up refreshes', 'nearest-rank P50/P95/P99/max ordering', 'no synthetic elapsed costs', 'refresh calls completed successfully')
}
$target = if ([IO.Path]::IsPathRooted($OutFile)) { [IO.Path]::GetFullPath($OutFile) } else { Join-Path $root $OutFile }
[IO.File]::WriteAllText($target, (($report | ConvertTo-Json -Depth 6) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
if (-not $pass) { throw "Host benchmark did not produce valid measurements." }
Write-Output "KWR OFFLINE PERFORMANCE BENCHMARK PASS"
