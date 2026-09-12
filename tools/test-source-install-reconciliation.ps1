[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$temp = Join-Path ([IO.Path]::GetTempPath()) ("kwr-reconciliation-" + [guid]::NewGuid().ToString("N"))
try {
    $source = Join-Path $temp "source"; $installed = Join-Path $temp "installed"
    foreach ($base in @($source, $installed)) {
        New-Item -ItemType Directory -Force -Path (Join-Path $base "Core"), (Join-Path $base "KWRSentinel") | Out-Null
        @("Core\\Same.lua", "Core\\Changed.lua") | Set-Content -LiteralPath (Join-Path $base "KnomercyWarRoom.toc") -Encoding UTF8
        "Same" | Set-Content -LiteralPath (Join-Path $base "Core\\Same.lua") -Encoding UTF8
        "Sentinel" | Set-Content -LiteralPath (Join-Path $base "KWRSentinel\\Core.lua") -Encoding UTF8
        "Core.lua" | Set-Content -LiteralPath (Join-Path $base "KWRSentinel\\KWRSentinel.toc") -Encoding UTF8
    }
    "Source" | Set-Content -LiteralPath (Join-Path $source "Core\\Changed.lua") -Encoding UTF8
    "Installed" | Set-Content -LiteralPath (Join-Path $installed "Core\\Changed.lua") -Encoding UTF8
    Add-Content -LiteralPath (Join-Path $source "KnomercyWarRoom.toc") -Value "Core\\SourceOnly.lua"
    "SourceOnly" | Set-Content -LiteralPath (Join-Path $source "Core\\SourceOnly.lua") -Encoding UTF8
    Add-Content -LiteralPath (Join-Path $installed "KnomercyWarRoom.toc") -Value "Core\\InstalledOnly.lua"
    "InstalledOnly" | Set-Content -LiteralPath (Join-Path $installed "Core\\InstalledOnly.lua") -Encoding UTF8
    $out = Join-Path $temp "report.json"
    $global:LASTEXITCODE = 0
    & (Join-Path $PSScriptRoot "source-install-reconciliation.ps1") -SourceRoot $source -InstalledRoot $installed -InstalledSentinelRoot (Join-Path $installed "KWRSentinel") -OutputFile $out
    if ($LASTEXITCODE -ne 0) { throw "Reconciliation script failed." }
    $report = Get-Content -LiteralPath $out -Raw | ConvertFrom-Json
    if ($report.summary.match -ne 2 -or $report.summary.changed -ne 1 -or $report.summary.sourceOnly -ne 1 -or $report.summary.installedOnly -ne 1) { throw "Unexpected reconciliation counts." }
    if (@($report.addons[0].entries | Where-Object { $_.state -ne "MATCH" -and $_.disposition -ne "review_required" }).Count -ne 0) { throw "A divergent file was accepted automatically." }
    Write-Output "KWR source/install reconciliation test passed"
} finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
