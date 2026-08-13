function Get-ReleaseExcludedEntries {
    return @(
        "Core\Diagnostics.lua"
    )
}

function Get-ProductionPackageDirectories {
    return @(
        'Adapters',
        'Assets',
        'Compliance',
        'Core',
        'Data',
        'Features',
        'Intelligence',
        'Rulesets',
        'Runtime',
        'State',
        'UI'
    )
}

function Get-ProductionPackageFiles {
    return @(
        'BATTLEGROUND_VERIFICATION.md',
        'CHANGELOG.md',
        'CURSEFORGE_DESCRIPTION.md',
        'DESIGN_CONTRACT.md',
        'KnomercyWarRoom.toc',
        'LICENSE',
        'META_SOURCES.md',
        'README.md',
        'RELEASE_READINESS.md',
        'THIRD_PARTY_NOTICES.md'
    )
}

function Get-SentinelProductionFiles {
    return @(
        'Bridge.lua',
        'Comm.lua',
        'Core.lua',
        'HUD.lua',
        'KWRSentinel.toc',
        'MinimapButton.lua',
        'NativeUI.lua',
        'Observer.lua',
        'Options.lua',
        'Panels.lua',
        'Relay.lua',
        'Theme.lua'
    )
}

function Get-NormalizedRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath,
        [Parameter(Mandatory = $true)]
        [string]$FullPath
    )

    $root = [IO.Path]::GetFullPath($RootPath).TrimEnd('\', '/')
    $full = [IO.Path]::GetFullPath($FullPath)
    if (-not $full.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path '$full' is outside root '$root'."
    }

    $relative = $full.Substring($root.Length).TrimStart('\', '/')
    return $relative.Replace("\", "/")
}

function Get-DirectoryManifestEntries {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    $entries = New-Object System.Collections.ArrayList
    foreach ($file in Get-ChildItem -LiteralPath $RootPath -Recurse -File | Sort-Object FullName) {
        $hash = Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256
        [void]$entries.Add([pscustomobject]@{
            path = Get-NormalizedRelativePath -RootPath $RootPath -FullPath $file.FullName
            size = [int64]$file.Length
            sha256 = $hash.Hash.ToUpperInvariant()
        })
    }
    return @($entries)
}

function Get-ManifestDigest {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Entries
    )

    $builder = New-Object System.Text.StringBuilder
    foreach ($entry in $Entries) {
        [void]$builder.Append($entry.path)
        [void]$builder.Append("|")
        [void]$builder.Append($entry.size)
        [void]$builder.Append("|")
        [void]$builder.Append($entry.sha256)
        [void]$builder.Append("`n")
    }

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($builder.ToString())
        $digest = $sha.ComputeHash($bytes)
        return ([BitConverter]::ToString($digest)).Replace("-", "")
    } finally {
        $sha.Dispose()
    }
}

function Get-ToolVersionInfo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName,
        [string[]]$Arguments = @("--version"),
        [string]$ExplicitPath,
        [string]$InvocationPath
    )

    $commandPath = $null
    if ($ExplicitPath -and (Test-Path -LiteralPath $ExplicitPath)) {
        $commandPath = [IO.Path]::GetFullPath($ExplicitPath)
    } else {
        $command = Get-Command $CommandName -ErrorAction SilentlyContinue
        if ($command) {
            $commandPath = $command.Source
        }
    }
    if (-not $commandPath) {
        return [pscustomobject]@{
            name = $CommandName
            available = $false
            path = $null
            version = $null
        }
    }

    $versionText = $null
    try {
        $versionCommandPath = if ($InvocationPath -and
            (Test-Path -LiteralPath $InvocationPath)) {
            [IO.Path]::GetFullPath($InvocationPath)
        } else {
            $commandPath
        }
        $versionText = (& $versionCommandPath @Arguments 2>$null | Select-Object -First 1)
        if ($versionText) {
            $versionText = $versionText.ToString().Trim()
        }
    } catch {
        $versionText = $null
    }

    return [pscustomobject]@{
        name = $CommandName
        available = $true
        path = $commandPath
        version = $versionText
    }
}

function Get-GitProvenance {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    $git = Get-Command "git.exe" -ErrorAction SilentlyContinue
    if (-not $git) {
        $git = Get-Command "git" -ErrorAction SilentlyContinue
    }
    if (-not $git) {
        return [pscustomobject]@{
            available = $false
            commit = $null
            branch = $null
            tag = $null
            dirty = $null
            reason = "git-unavailable"
        }
    }

    $resolvedRoot = [IO.Path]::GetFullPath($RootPath)
    $insideWorkTree = $null
    try {
        $insideWorkTree = (& $git.Source -C $resolvedRoot rev-parse --is-inside-work-tree 2>$null | Select-Object -First 1)
    } catch {
        $insideWorkTree = $null
    }
    if (($insideWorkTree | Out-String).Trim().ToLowerInvariant() -ne "true") {
        return [pscustomobject]@{
            available = $false
            commit = $null
            branch = $null
            tag = $null
            dirty = $null
            reason = "no-git-worktree"
        }
    }

    $commit = (& $git.Source -C $resolvedRoot rev-parse HEAD 2>$null | Select-Object -First 1)
    $branch = (& $git.Source -C $resolvedRoot rev-parse --abbrev-ref HEAD 2>$null | Select-Object -First 1)
    # Pull requests and local release candidates are valid git worktrees without
    # an exact tag. Git writes that expected miss to stderr; do not turn it into
    # a build failure while collecting provenance.
    try {
        $tag = (& $git.Source -C $resolvedRoot describe --tags --exact-match 2>$null | Select-Object -First 1)
    } catch {
        $tag = $null
    }
    $status = (& $git.Source -C $resolvedRoot status --porcelain 2>$null)

    return [pscustomobject]@{
        available = $true
        commit = (($commit | Out-String).Trim())
        branch = (($branch | Out-String).Trim())
        tag = (($tag | Out-String).Trim())
        dirty = [bool]($status -and $status.Count -gt 0)
        reason = $null
    }
}

function Get-ReleaseTocLines {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceTocPath
    )

    $skipLookup = @{}
    foreach ($entry in Get-ReleaseExcludedEntries) {
        $skipLookup[$entry.ToLowerInvariant()] = $true
    }

    $lines = Get-Content -LiteralPath $SourceTocPath
    $result = New-Object System.Collections.Generic.List[string]
    foreach ($line in $lines) {
        $normalized = $line.Trim().Replace("/", "\")
        if ($skipLookup.ContainsKey($normalized.ToLowerInvariant())) {
            continue
        }
        $result.Add($line)
    }
    return $result
}

function Remove-ReleaseExcludedFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    foreach ($entry in Get-ReleaseExcludedEntries) {
        $path = Join-Path $RootPath $entry
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Force
        }
    }
}

function Get-ReleaseExcludedArchiveEntries {
    param(
        [string]$ArchiveRoot = "KnomercyWarRoom"
    )

    $prefix = ($ArchiveRoot.TrimEnd("/", "\") + "/").Replace("\", "/")
    return @(Get-ReleaseExcludedEntries | ForEach-Object {
        $prefix + $_.Replace("\", "/")
    })
}
