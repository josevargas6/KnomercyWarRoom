[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$out = Join-Path ([IO.Path]::GetTempPath()) ("kwr-fresh-replay-" + [guid]::NewGuid().ToString("N"))
try {
    & (Join-Path $PSScriptRoot "fresh-replay-benchmark.ps1") -MaxReplays 1 -OutputDirectory $out
    if ($LASTEXITCODE -ne 0) { throw "One-replay fresh benchmark failed." }
    $report = Get-Content -LiteralPath (Join-Path $out "fresh-replay-benchmark.json") -Raw | ConvertFrom-Json
    if ($report.scope -notmatch "bounded" -or $report.runs.Count -ne 1 -or -not $report.runs[0].resultSha256) { throw "Fresh benchmark did not bind its one replay result to hashes." }
    if ($report.coverage.missingLabels.Count -ne 0) { throw "Reviewed replay fixtures are missing golden labels." }
    $result = Get-Content -LiteralPath (Join-Path $out $report.runs[0].resultFile.Replace('/', '\\')) -Raw | ConvertFrom-Json
    if (-not (@($result.final.tags) | Where-Object { $_ -like 'PLAN_TAG_*' })) { throw "Fresh replay output did not retain reviewed plan taxonomy tags." }
    $windowsOutput = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "tools\\fresh-replay-benchmark.ps1") -MaxReplays 1 -OutputDirectory $out
    if ($LASTEXITCODE -ne 0 -or -not ($windowsOutput -match "KWR fresh replay benchmark: True")) { throw "Windows PowerShell 5-compatible fresh benchmark failed." }
} finally {
    if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out -Recurse -Force }
}
Write-Output "KWR fresh replay benchmark test passed"
