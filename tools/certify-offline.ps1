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
Invoke-KwrTool 'validate.ps1'
# A new TOC version cannot have a candidate-bound package receipt until the
# exact archive exists.  Audit durable knowledge first, omitting only the
# version-bound generated receipts; the complete audit runs after packaging.
Invoke-KwrTool 'knowledge-audit.ps1' @('-AllowGeneratedEvidenceOmission')
Invoke-KwrTool 'season2-rbg-simulation-audit.ps1'
Invoke-KwrTool 'test-lua.ps1' @('-Suite', 'All')
Invoke-KwrTool 'performance-benchmark.ps1'
if (-not $SkipBuild) {
    Invoke-KwrTool 'build.ps1' @('-OutputDirectory', $OutputDirectory, '-IncludeSentinel')
    Invoke-KwrTool 'candidate-package-report.ps1' @('-BuildOutputDirectory', $OutputDirectory)
    Invoke-KwrTool 'field-readiness-report.ps1'
    Invoke-KwrTool 'field-blocker-report.ps1'
    Invoke-KwrTool 'offline-completion-audit.ps1'
    Invoke-KwrTool 'knowledge-audit.ps1'
}
if ($SkipBuild) {
    Write-Output 'KWR OFFLINE SOURCE CERTIFICATION PASS'
} else {
    Write-Output 'KWR OFFLINE CERTIFICATION PASS'
}
