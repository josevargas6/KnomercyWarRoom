[CmdletBinding()]
param(
    [string]$OutputDirectory = "C:\Users\josev\Desktop\KWR\Builds",
    [switch]$SkipBuild
)

# The one supported offline certification entrypoint. It is safe to run from a
# fresh checkout once the documented Node/Fengari runtime is available.
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
function Invoke-KwrTool([string]$Name, [string[]]$Arguments = @()) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "tools\$Name") @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Name failed." }
}

Invoke-KwrTool 'runtime-preflight.ps1'
Invoke-KwrTool 'compile-season2-rbg-lifecycle.ps1'
Invoke-KwrTool 'validate.ps1'
Invoke-KwrTool 'knowledge-audit.ps1'
Invoke-KwrTool 'season2-rbg-simulation-audit.ps1'
Invoke-KwrTool 'test-lua.ps1' @('-Suite', 'All')
Invoke-KwrTool 'performance-benchmark.ps1'
if (-not $SkipBuild) {
    Invoke-KwrTool 'build.ps1' @('-OutputDirectory', $OutputDirectory, '-IncludeSentinel')
}
Write-Output 'KWR OFFLINE CERTIFICATION PASS'
