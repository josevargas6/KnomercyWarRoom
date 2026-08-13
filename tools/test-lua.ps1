[CmdletBinding()]
param(
    [ValidateSet("All", "Smoke", "Soak", "Replay", "Sentinel")]
    [string]$Suite = "All",
    [string]$ReplayPath = "tests/replays/twin_peaks_recovery_sample.json",
    [string]$ReplayLabelPath,
    [string]$ReplayOutputPath
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$script:lastLuaOutput = @()

function New-LuaRuntime {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,
        [string[]]$Arguments = @(),
        [string]$NodePath,
        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    return @{
        Command = [IO.Path]::GetFullPath($Command)
        Arguments = @($Arguments)
        NodePath = $NodePath
        Description = $Description
    }
}

function Find-CommandPath {
    param([string[]]$Names)

    foreach ($name in $Names) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command -and $command.Source) {
            return $command.Source
        }
    }
    return $null
}

function Find-NodePath {
    $candidates = New-Object System.Collections.Generic.List[string]
    if ($env:KWR_NODE_EXE) {
        $candidates.Add($env:KWR_NODE_EXE)
    }

    $pathNode = Find-CommandPath @("node.exe", "node")
    if ($pathNode) {
        $candidates.Add($pathNode)
    }

    foreach ($candidate in @(
        (Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe"),
        (Join-Path $env:ProgramFiles "nodejs\node.exe"),
        (Join-Path $env:LOCALAPPDATA "Programs\nodejs\node.exe")
    )) {
        if ($candidate) {
            $candidates.Add($candidate)
        }
    }

    foreach ($candidate in $candidates | Select-Object -Unique) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return [IO.Path]::GetFullPath($candidate)
        }
    }
    return $null
}

function Find-CachedFengari {
    $candidates = New-Object System.Collections.Generic.List[string]
    if ($env:KWR_FENGARI_CLI) {
        $candidates.Add($env:KWR_FENGARI_CLI)
    }

    $globalCli = Join-Path $env:APPDATA "npm\node_modules\fengari-node-cli\src\lua-cli.js"
    $candidates.Add($globalCli)

    $luaToolsRoot = Join-Path $env:LOCALAPPDATA "Temp\kwr-lua-tools"
    $standardCli = Join-Path $luaToolsRoot "node_modules\fengari-node-cli\src\lua-cli.js"
    $candidates.Add($standardCli)
    $pnpmRoot = Join-Path $luaToolsRoot "node_modules\.pnpm"
    if (Test-Path -LiteralPath $pnpmRoot -PathType Container) {
        Get-ChildItem -LiteralPath $pnpmRoot -Recurse -Filter "lua-cli.js" -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -like "*fengari-node-cli*" } |
            Sort-Object FullName |
            ForEach-Object { $candidates.Add($_.FullName) }
    }

    foreach ($candidate in $candidates | Select-Object -Unique) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return [IO.Path]::GetFullPath($candidate)
        }
    }
    return $null
}

function Get-CachedNodePath {
    $luaToolsRoot = Join-Path $env:LOCALAPPDATA "Temp\kwr-lua-tools"
    $standardNodeModules = Join-Path $luaToolsRoot "node_modules"
    $pnpmRoot = Join-Path $luaToolsRoot "node_modules\.pnpm"
    $nodePaths = @($standardNodeModules)
    if (Test-Path -LiteralPath $pnpmRoot -PathType Container) {
        $nodePaths += @(
            (Join-Path $pnpmRoot "node_modules")
            Get-ChildItem -LiteralPath $pnpmRoot -Directory -ErrorAction SilentlyContinue |
                ForEach-Object { Join-Path $_.FullName "node_modules" }
        )
    }
    $nodePaths = $nodePaths | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Container) } |
        Select-Object -Unique

    return $nodePaths -join ";"
}

function Get-LuaRuntime {
    if ($env:KWR_LUA_EXE) {
        if (-not (Test-Path -LiteralPath $env:KWR_LUA_EXE -PathType Leaf)) {
            throw "KWR_LUA_EXE does not point to a file: $($env:KWR_LUA_EXE)"
        }
        return New-LuaRuntime -Command $env:KWR_LUA_EXE `
            -Description "explicit native Lua runtime"
    }

    if (($env:KWR_NODE_EXE -and -not $env:KWR_FENGARI_CLI) -or
        ($env:KWR_FENGARI_CLI -and -not $env:KWR_NODE_EXE)) {
        throw "Set both KWR_NODE_EXE and KWR_FENGARI_CLI when using explicit Fengari paths."
    }
    if ($env:KWR_NODE_EXE -and $env:KWR_FENGARI_CLI) {
        if (-not (Test-Path -LiteralPath $env:KWR_NODE_EXE -PathType Leaf)) {
            throw "KWR_NODE_EXE does not point to a file: $($env:KWR_NODE_EXE)"
        }
        if (-not (Test-Path -LiteralPath $env:KWR_FENGARI_CLI -PathType Leaf)) {
            throw "KWR_FENGARI_CLI does not point to a file: $($env:KWR_FENGARI_CLI)"
        }
        return New-LuaRuntime -Command $env:KWR_NODE_EXE `
            -Arguments @([IO.Path]::GetFullPath($env:KWR_FENGARI_CLI)) `
            -Description "explicit Node.js/Fengari runtime"
    }

    $fengari = Find-CommandPath @("fengari.cmd", "fengari")
    if ($fengari) {
        return New-LuaRuntime -Command $fengari -Description "Fengari on PATH"
    }

    $nativeLua = Find-CommandPath @("lua.exe", "lua", "luajit.exe", "luajit")
    if ($nativeLua) {
        return New-LuaRuntime -Command $nativeLua -Description "native Lua on PATH"
    }

    $node = Find-NodePath
    $fengariCli = Find-CachedFengari
    if ($node -and $fengariCli) {
        return New-LuaRuntime -Command $node -Arguments @($fengariCli) `
            -NodePath (Get-CachedNodePath) `
            -Description "cached Node.js/Fengari runtime"
    }

    throw @"
No usable Lua test runtime was found.
Install Node.js and run 'npm install --global fengari-node-cli', install Lua 5.1+,
or set KWR_LUA_EXE. For a portable Fengari runtime, set both KWR_NODE_EXE and
KWR_FENGARI_CLI.
"@
}

function Invoke-LuaCheck {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Runtime,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$ExpectedMarker,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    Write-Output "KWR Lua test: $Name"
    $previousNodePath = $env:NODE_PATH
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        if ($Runtime.NodePath) {
            $env:NODE_PATH = if ([string]::IsNullOrWhiteSpace($previousNodePath)) {
                $Runtime.NodePath
            } else {
                $Runtime.NodePath + ";" + $previousNodePath
            }
        }

        $ErrorActionPreference = "Continue"
        $output = @(& $Runtime.Command @($Runtime.Arguments + $Arguments) 2>&1)
        $exitCode = [int]$LASTEXITCODE
        $ErrorActionPreference = $previousErrorActionPreference
        $script:lastLuaOutput = @($output | ForEach-Object { [string]$_ })
        $script:lastLuaOutput |
            Where-Object { -not $_.StartsWith("KWR_REPLAY_JSON_OUT ") } |
            ForEach-Object { Write-Output $_ }

        if ($exitCode -ne 0) {
            throw "$Name failed with process exit code $exitCode."
        }
        if (-not ($script:lastLuaOutput -match
            [regex]::Escape($ExpectedMarker))) {
            throw "$Name completed without required pass marker '$ExpectedMarker'."
        }
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
        $env:NODE_PATH = $previousNodePath
    }
}

$runtime = Get-LuaRuntime
Write-Output "KWR Lua runtime: $($runtime.Description)"
Write-Output "Command: $($runtime.Command)"

$previousLocation = Get-Location
try {
    Set-Location -LiteralPath $root

    if ($Suite -eq "All" -or $Suite -eq "Smoke") {
        Invoke-LuaCheck -Runtime $runtime -Arguments @("tests/smoke.lua") `
            -ExpectedMarker "KWR_SMOKE_PASS" -Name "smoke"
    }

    if ($Suite -eq "All" -or $Suite -eq "Sentinel") {
        Invoke-LuaCheck -Runtime $runtime -Arguments @("tests/sentinel-transport.lua") `
            -ExpectedMarker "KWR_SENTINEL_TRANSPORT_PASS" -Name "Sentinel transport"
    }

    if ($Suite -eq "All" -or $Suite -eq "Soak") {
        Invoke-LuaCheck -Runtime $runtime -Arguments @("tests/soak.lua") `
            -ExpectedMarker "KWR_SOAK_PASS" -Name "soak"
    }

    if ($Suite -eq "All" -or $Suite -eq "Replay") {
        if (-not (Test-Path -LiteralPath $ReplayPath -PathType Leaf)) {
            throw "Replay fixture was not found: $ReplayPath"
        }
        if (-not $ReplayLabelPath) {
            $companionLabel = Join-Path "tests\golden" (
                [IO.Path]::GetFileNameWithoutExtension($ReplayPath) + ".label.json")
            if (Test-Path -LiteralPath $companionLabel -PathType Leaf) {
                $ReplayLabelPath = $companionLabel
            }
        }
        $replayArguments = @(
            "tools/replay-test-runner.lua"
            $ReplayPath
            "--check"
        )
        if ($ReplayLabelPath) {
            if (-not (Test-Path -LiteralPath $ReplayLabelPath -PathType Leaf)) {
                throw "Replay label was not found: $ReplayLabelPath"
            }
            $replayArguments += @("--label", $ReplayLabelPath)
        }
        if ($ReplayOutputPath) {
            $replayArguments += @("--json-out", $ReplayOutputPath)
        }

        $bridgeNames = @(
            "KWR_REPLAY_INPUT_PATH"
            "KWR_REPLAY_INPUT_JSON"
            "KWR_REPLAY_LABEL_PATH"
            "KWR_REPLAY_LABEL_JSON"
            "KWR_REPLAY_OUTPUT_PATH"
        )
        $previousBridge = @{}
        foreach ($name in $bridgeNames) {
            $previousBridge[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
        }
        try {
            $env:KWR_REPLAY_INPUT_PATH = $ReplayPath
            $env:KWR_REPLAY_INPUT_JSON =
                [IO.File]::ReadAllText([IO.Path]::GetFullPath($ReplayPath))
            if ($ReplayLabelPath) {
                $env:KWR_REPLAY_LABEL_PATH = $ReplayLabelPath
                $env:KWR_REPLAY_LABEL_JSON =
                    [IO.File]::ReadAllText([IO.Path]::GetFullPath($ReplayLabelPath))
            }
            if ($ReplayOutputPath) {
                $env:KWR_REPLAY_OUTPUT_PATH = $ReplayOutputPath
            }

            Invoke-LuaCheck -Runtime $runtime -Arguments $replayArguments `
                -ExpectedMarker "KWR_REPLAY_RUN_PASS" -Name "replay"

            if ($ReplayOutputPath) {
                $bridgePrefix = "KWR_REPLAY_JSON_OUT "
                $bridgedJson = $script:lastLuaOutput |
                    Where-Object { $_.StartsWith($bridgePrefix) } |
                    Select-Object -Last 1
                if ($bridgedJson) {
                    $outputFile = if ([IO.Path]::IsPathRooted($ReplayOutputPath)) {
                        [IO.Path]::GetFullPath($ReplayOutputPath)
                    } else {
                        [IO.Path]::GetFullPath((Join-Path $root $ReplayOutputPath))
                    }
                    [IO.File]::WriteAllText(
                        $outputFile,
                        $bridgedJson.Substring($bridgePrefix.Length) + [Environment]::NewLine,
                        [Text.UTF8Encoding]::new($false))
                }
            }
        } finally {
            foreach ($name in $bridgeNames) {
                [Environment]::SetEnvironmentVariable(
                    $name, $previousBridge[$name], "Process")
            }
        }
    }
} finally {
    Set-Location -LiteralPath $previousLocation
}

Write-Output "KWR_LUA_TESTS_PASS suite=$Suite"
