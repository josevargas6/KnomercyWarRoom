[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'hash-utils.ps1')
$temp = Join-Path ([IO.Path]::GetTempPath()) ("kwr-review-packet-" + [guid]::NewGuid().ToString("N"))
try {
    $source = Join-Path $temp "source"; $installed = Join-Path $temp "installed"
    New-Item -ItemType Directory -Force -Path (Join-Path $source "Core"), (Join-Path $installed "Core"), (Join-Path $source "KWRSentinel"), (Join-Path $installed "KWRSentinel") | Out-Null
    "one`ntwo`nsource`nfour" | Set-Content -LiteralPath (Join-Path $source "Core\Changed.lua") -Encoding UTF8
    "one`ntwo`ninstalled`nfour" | Set-Content -LiteralPath (Join-Path $installed "Core\Changed.lua") -Encoding UTF8
    "source only" | Set-Content -LiteralPath (Join-Path $source "Core\SourceOnly.lua") -Encoding UTF8
    "installed only" | Set-Content -LiteralPath (Join-Path $installed "Core\InstalledOnly.lua") -Encoding UTF8
    $hash = { param($path) Get-KwrFileSha256 -LiteralPath $path }
    $changedSource = Join-Path $source "Core\Changed.lua"; $changedInstalled = Join-Path $installed "Core\Changed.lua"
    $report = [pscustomobject]@{
        schema = "kwr-source-install-reconciliation"; schemaVersion = 1; generatedAt = "2026-09-08T00:00:00Z"
        sourceRoot = $source; installedRoot = $installed; installedSentinelRoot = (Join-Path $installed "KWRSentinel")
        addons = @([pscustomobject]@{ addon = "Commander"; entries = @(
            [pscustomobject]@{ path = "Core\Changed.lua"; state = "CHANGED"; sourceSha256 = (& $hash $changedSource); installedSha256 = (& $hash $changedInstalled) },
            [pscustomobject]@{ path = "Core\SourceOnly.lua"; state = "SOURCE_ONLY"; sourceSha256 = (& $hash (Join-Path $source "Core\SourceOnly.lua")); installedSha256 = $null },
            [pscustomobject]@{ path = "Core\InstalledOnly.lua"; state = "INSTALLED_ONLY"; sourceSha256 = $null; installedSha256 = (& $hash (Join-Path $installed "Core\InstalledOnly.lua")) }
        ) })
    }
    $receipt = Join-Path $temp "receipt.json"; $out = Join-Path $temp "packet.json"
    $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $receipt -Encoding UTF8
    & (Join-Path $PSScriptRoot "source-install-review-packet.ps1") -ReconciliationReport $receipt -OutputFile $out
    $packet = Get-Content -LiteralPath $out -Raw | ConvertFrom-Json
    if ($packet.summary.reviewRequired -ne 3 -or $packet.summary.changed -ne 1 -or $packet.summary.p0 -ne 3 -or $packet.summary.reviewed -ne 0) { throw "Unexpected review packet summary." }
    $changed = @($packet.entries | Where-Object path -eq "Core\Changed.lua")[0]
    if ($changed.textRange.firstDifferingLine -ne 3 -or $changed.reviewPriority -ne "P0" -or $changed.reviewStatus -ne "review_required" -or $changed.disposition) { throw "Changed entry review state or line range is wrong." }
    if (-not $packet.reviewPacketToolSha256) { throw "Review packet does not bind its tool hash." }
    "drift" | Set-Content -LiteralPath $changedSource -Encoding UTF8
    $threw = $false; try { & (Join-Path $PSScriptRoot "source-install-review-packet.ps1") -ReconciliationReport $receipt -OutputFile (Join-Path $temp "drift.json") } catch { $threw = $true }
    if (-not $threw) { throw "Review packet accepted a file that drifted from its receipt hash." }
    Write-Output "KWR source/install review packet test passed"
} finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force } }
