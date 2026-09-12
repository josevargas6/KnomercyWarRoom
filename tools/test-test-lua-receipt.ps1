[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$temp = Join-Path ([IO.Path]::GetTempPath()) ('kwr-lua-receipt-' + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Force -Path $temp | Out-Null
    $receipt = Join-Path $temp 'smoke-receipt.json'
    & (Join-Path $PSScriptRoot 'test-lua.ps1') -Suite Smoke -ReceiptFile $receipt
    if ($LASTEXITCODE -ne 0) { throw 'Smoke test did not exit successfully.' }
    $result = Get-Content -LiteralPath $receipt -Raw | ConvertFrom-Json
    if ($result.schema -ne 'kwr-lua-test-receipt' -or -not $result.passed -or @($result.completedStages) -notcontains 'smoke') {
        throw 'Lua test receipt does not prove the completed smoke stage.'
    }
    if (-not $result.toolSha256 -or $result.failure) { throw 'Successful Lua test receipt has missing provenance or failure.' }
    Write-Output 'KWR Lua test receipt regression passed'
} finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
