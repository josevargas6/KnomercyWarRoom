[CmdletBinding()]
param(
    [string]$OutFile = "knowledge\runtime-preflight.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$outPath = Join-Path $root $OutFile
$toc = Get-Content -LiteralPath (Join-Path $root "KnomercyWarRoom.toc") -Raw
$version = [regex]::Match($toc, "## Version:\s*(.+)").Groups[1].Value.Trim()

function Test-ReadableFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $stream.Dispose()
        return $true
    } catch {
        return $false
    }
}

$nodeOnPath = Get-Command "node.exe" -ErrorAction SilentlyContinue
if (-not $nodeOnPath) {
    $nodeOnPath = Get-Command "node" -ErrorAction SilentlyContinue
}
$bundledNodePath = Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe"
$fengariCmdOnPath = Get-Command "fengari.cmd" -ErrorAction SilentlyContinue
$fengariPs1OnPath = Get-Command "fengari.ps1" -ErrorAction SilentlyContinue
$localLuaToolsRoot = Join-Path $env:LOCALAPPDATA "Temp\kwr-lua-tools"

$candidateCliPaths = @(
    (Join-Path $localLuaToolsRoot "node_modules\fengari-node-cli\src\lua-cli.js"),
    (Join-Path $localLuaToolsRoot "node_modules\.pnpm\fengari-node-cli@0.1.0\node_modules\fengari-node-cli\src\lua-cli.js"),
    (Join-Path $localLuaToolsRoot "node_modules\.bin\fengari.CMD"),
    (Join-Path $localLuaToolsRoot "node_modules\.bin\fengari.ps1"),
    (Join-Path $env:APPDATA "npm\fengari.cmd"),
    (Join-Path $env:APPDATA "npm\fengari.ps1")
) | Select-Object -Unique

$accessibleCliPaths = New-Object System.Collections.Generic.List[string]
$blockedCliPaths = New-Object System.Collections.Generic.List[string]
foreach ($path in $candidateCliPaths) {
    if (-not (Test-Path -LiteralPath $path)) {
        continue
    }
    if (Test-ReadableFile -Path $path) {
        $accessibleCliPaths.Add($path)
    } else {
        $blockedCliPaths.Add($path)
    }
}

$packagePaths = @(
    (Join-Path $localLuaToolsRoot "node_modules\fengari-node-cli\package.json"),
    (Join-Path $localLuaToolsRoot "node_modules\fengari\package.json"),
    (Join-Path $localLuaToolsRoot "node_modules\.pnpm\fengari-node-cli@0.1.0\node_modules\fengari-node-cli\package.json"),
    (Join-Path $localLuaToolsRoot "node_modules\.pnpm\fengari@0.1.4\node_modules\fengari\package.json")
)
$standardPackagesReadable = (Test-ReadableFile -Path $packagePaths[0]) -and
    (Test-ReadableFile -Path $packagePaths[1])
$pnpmPackagesReadable = (Test-ReadableFile -Path $packagePaths[2]) -and
    (Test-ReadableFile -Path $packagePaths[3])
$packageReadable = $standardPackagesReadable -or $pnpmPackagesReadable

$bundledNodeReadable = Test-ReadableFile -Path $bundledNodePath
$cliReadable = $accessibleCliPaths.Count -gt 0
$packageAuditReady = $bundledNodeReadable -and $cliReadable -and $packageReadable

$recommendedNextStep = if ($packageAuditReady) {
    "Run package-audit.ps1 against the current candidate artifacts."
} elseif ((Test-Path -LiteralPath $localLuaToolsRoot) -and -not $packageReadable) {
    "Replace or reinstall the local Fengari runtime into a readable location, then rerun runtime-preflight.ps1 and package-audit.ps1."
} elseif (-not $bundledNodeReadable -and -not $nodeOnPath) {
    "Install or expose a readable Node runtime, then rerun runtime-preflight.ps1."
} else {
    "Install a readable Fengari CLI/runtime and rerun runtime-preflight.ps1."
}

$report = [ordered]@{
    schema = "kwr-runtime-preflight"
    schemaVersion = 1
    generatedAt = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
    candidateVersion = $version
    node = [ordered]@{
        nodeOnPath = [bool]$nodeOnPath
        nodeOnPathSource = if ($nodeOnPath) { $nodeOnPath.Source } else { $null }
        bundledNodePath = $bundledNodePath
        bundledNodeReadable = $bundledNodeReadable
    }
    fengari = [ordered]@{
        fengariCmdOnPath = if ($fengariCmdOnPath) { $fengariCmdOnPath.Source } else { $null }
        fengariPs1OnPath = if ($fengariPs1OnPath) { $fengariPs1OnPath.Source } else { $null }
        accessibleCliPaths = @($accessibleCliPaths)
        blockedCliPaths = @($blockedCliPaths)
    }
    localLuaTools = [ordered]@{
        rootPath = $localLuaToolsRoot
        present = (Test-Path -LiteralPath $localLuaToolsRoot)
        cliReadable = $cliReadable
        packageReadable = $packageReadable
    }
    packageAuditReady = $packageAuditReady
    recommendedNextStep = $recommendedNextStep
}

$json = $report | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText($outPath, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))

Write-Output "KWR runtime preflight"
Write-Output "Candidate: $version"
Write-Output "Package audit ready: $packageAuditReady"
Write-Output "Output: $outPath"
