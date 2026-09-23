[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'hash-utils.ps1')
$temp = Join-Path ([IO.Path]::GetTempPath()) ('kwr-source-install-ledger-' + [guid]::NewGuid().ToString('N'))
try {
    $reviews = Join-Path $temp 'reviews'; New-Item -ItemType Directory -Force -Path $reviews | Out-Null
    $packet = [pscustomobject]@{ schema='kwr-source-install-review-packet'; schemaVersion=1; entries=@(
        [pscustomobject]@{ addon='Commander'; path='Runtime\One.lua'; reviewPriority='P0'; sourceSha256='A'; installedSha256='B' },
        [pscustomobject]@{ addon='Commander'; path='UI\Two.lua'; reviewPriority='P1'; sourceSha256='C'; installedSha256='D' }
    ) }
    $packetPath = Join-Path $temp 'packet.json'; $packet | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $packetPath -Encoding UTF8
    $packetHash = Get-KwrFileSha256 -LiteralPath $packetPath
    [pscustomobject]@{ addon='Commander'; path='Runtime\One.lua'; sourceSha256='A'; installedSha256='B'; packetSha256=$packetHash; reviewedAt='2026-09-08T00:00:00Z'; reviewer=[pscustomobject]@{id='reviewer-one';role='engineer'}; disposition='PRESERVE_SOURCE'; evidence=@('tests/smoke.lua') } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $reviews 'one.source-install-review.json') -Encoding UTF8
    [pscustomobject]@{ addon='Commander'; path='UI\Two.lua'; sourceSha256='C'; installedSha256='D'; packetSha256=$packetHash; reviewedAt='2026-09-08T00:00:00Z'; reviewer=[pscustomobject]@{id='reviewer-two';role='engineer'}; disposition='DEFER'; evidence=@('needs client evidence') } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $reviews 'two.source-install-review.json') -Encoding UTF8
    $out = Join-Path $temp 'report.json'
    & (Join-Path $PSScriptRoot 'source-install-review-ledger.ps1') -ReviewPacket $packetPath -ReviewDirectory $reviews -OutputFile $out
    $result = Get-Content -LiteralPath $out -Raw | ConvertFrom-Json
    if ($result.summary.reviewed -ne 1 -or $result.summary.deferred -ne 1 -or $result.summary.complete) { throw 'Ledger did not preserve deferred review semantics.' }
    $threw = $false; try { & (Join-Path $PSScriptRoot 'source-install-review-ledger.ps1') -ReviewPacket $packetPath -ReviewDirectory $reviews -OutputFile $out -RequireComplete } catch { $threw = $true }
    if (-not $threw) { throw 'Incomplete ledger passed RequireComplete.' }
    (Get-Content -LiteralPath (Join-Path $reviews 'two.source-install-review.json') -Raw).Replace('"DEFER"', '"MERGE_INSTALLED"') | Set-Content -LiteralPath (Join-Path $reviews 'two.source-install-review.json') -Encoding UTF8
    & (Join-Path $PSScriptRoot 'source-install-review-ledger.ps1') -ReviewPacket $packetPath -ReviewDirectory $reviews -OutputFile $out -RequireComplete
    $result = Get-Content -LiteralPath $out -Raw | ConvertFrom-Json
    if (-not $result.summary.complete -or $result.summary.reviewed -ne 2) { throw 'Complete ledger was not accepted.' }
    Write-Output 'KWR source/install review ledger test passed'
} finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force } }
