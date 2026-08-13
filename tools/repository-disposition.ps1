[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$LiveRoot,
    [Parameter(Mandatory = $true)]
    [string]$RollbackSnapshot,
    [string]$PackageRoot = '',
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\repository-disposition.md')
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$liveRoot = [IO.Path]::GetFullPath($LiveRoot)
$snapshot = [IO.Path]::GetFullPath($RollbackSnapshot)
$excludedPattern = '\\(\.git|\.pnpm-store|artifacts|builds|node_modules|tmp|temp|coverage)\\'

function Get-FileMap {
    param([string]$BasePath)

    $map = @{}
    foreach ($file in Get-ChildItem -LiteralPath $BasePath -Recurse -File -Force) {
        $relative = $file.FullName.Substring($BasePath.Length + 1).Replace('\\', '/')
        $relativeForFilter = '\\' + $relative.Replace('/', '\\')
        if ($relativeForFilter -match $excludedPattern) {
            continue
        }
        $map[$relative] = [pscustomobject]@{
            size = [int64]$file.Length
            sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
        }
    }
    return $map
}

function Get-Disposition {
    param(
        [string]$Path,
        [bool]$Canonical,
        [bool]$Live,
        [bool]$SameHash,
        [bool]$Package,
        [bool]$SamePackageHash
    )

    if ($Path -match '^tmp_.*\.txt$') {
        return [pscustomobject]@{
            disposition = 'DELETE'
            reason = 'Root temporary extraction list; no callers or generator contract.'
            replacement = 'Ignored artifacts directory when a future generator needs output.'
            risk = 'low'
        }
    }
    if ($Path -match '^(\.pnpm-store|artifacts|builds|node_modules|tmp|temp|coverage)/' -or
        $Path -match '\.(zip|log)$' -or $Path -match '\.lua\.bak$') {
        return [pscustomobject]@{
            disposition = 'GENERATED'
            reason = 'Local, generated, cache, log, or backup material.'
            replacement = '.gitignore and explicit build artifacts.'
            risk = 'low'
        }
    }
    if ($Path -match '^Assets/') {
        return [pscustomobject]@{
            disposition = if ($Canonical) { 'KEEP' } else { 'MERGE' }
            reason = 'Production visual asset referenced by TOC or UI icon registry.'
            replacement = 'Canonical Assets/ tree.'
            risk = 'medium'
        }
    }
    if ($Path -match '(^|/)(ALPHA_S_TIER_MASTER_PLAN|EXPERT_TIER_BATTLEFIELD_MASTER_PLAN|PILLAR_EXECUTION_SHEET|POST_WINNING_BACKLOG|RELEASE_REWRITE_GUARDRAILS|RELEASE_VISION|S_TIER_EXECUTION_SCORECARD|WINNING_STATE_EXECUTION_MAP|WINNING_STATE_RELEASE_GATES)\.md$') {
        return [pscustomobject]@{
            disposition = 'HISTORICAL'
            reason = 'Superseded plan, directive, scorecard, or execution context.'
            replacement = 'Authority registry and dated rollback snapshot.'
            risk = 'medium'
        }
    }
    if ($Canonical -and $Live -and $SameHash) {
        return [pscustomobject]@{
            disposition = 'KEEP'
            reason = 'Matches canonical GitHub clone by SHA-256.'
            replacement = 'GitHub committed content.'
            risk = 'low'
        }
    }
    if ($Live -and $Package -and $SamePackageHash) {
        return [pscustomobject]@{
            disposition = 'DEPLOYMENT_ONLY'
            reason = 'Matches the verified production package by SHA-256; source form differs through an approved package transform or later canonical documentation.'
            replacement = 'Verified package manifest and GitHub committed source.'
            risk = 'low'
        }
    }
    if ($Canonical -and -not $Live) {
        return [pscustomobject]@{
            disposition = 'KEEP'
            reason = 'Canonical source not currently deployed.'
            replacement = 'GitHub committed content.'
            risk = 'medium'
        }
    }
    return [pscustomobject]@{
        disposition = 'REVIEW_REQUIRED'
        reason = 'Live and canonical content differ; ownership cannot be proven from path or hash.'
        replacement = 'Owner-reviewed GitHub change or preserved rollback snapshot.'
        risk = 'high'
    }
}

$canonical = Get-FileMap -BasePath $root
$live = Get-FileMap -BasePath $liveRoot
$package = if ($PackageRoot) {
    $resolvedPackageRoot = [IO.Path]::GetFullPath($PackageRoot)
    if (-not (Test-Path -LiteralPath $resolvedPackageRoot -PathType Container)) {
        throw "Package root is missing: $resolvedPackageRoot"
    }
    Get-FileMap -BasePath $resolvedPackageRoot
} else {
    @{}
}
$paths = @($canonical.Keys + $live.Keys | Sort-Object -Unique)
$rows = foreach ($path in $paths) {
    $isCanonical = $canonical.ContainsKey($path)
    $isLive = $live.ContainsKey($path)
    $sameHash = $isCanonical -and $isLive -and $canonical[$path].sha256 -eq $live[$path].sha256
    $isPackage = $package.ContainsKey($path)
    $samePackageHash = $isPackage -and $isLive -and $package[$path].sha256 -eq $live[$path].sha256
    $classification = Get-Disposition -Path $path -Canonical:$isCanonical -Live:$isLive -SameHash:$sameHash -Package:$isPackage -SamePackageHash:$samePackageHash
    [pscustomobject]@{
        path = $path
        disposition = $classification.disposition
        canonical = $isCanonical
        live = $isLive
        package = $isPackage
        reason = $classification.reason
        replacementAuthority = $classification.replacement
        risk = $classification.risk
        rollback = $snapshot
    }
}

$outputDirectory = Split-Path -Parent $OutputPath
[IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
$summary = @(
    '# KWR-047 repository disposition'
    ''
    "Generated: $((Get-Date).ToUniversalTime().ToString('o'))"
    ('Canonical clone: {0}' -f $root)
    ('Live deployment: {0}' -f $liveRoot)
    ('Read-only rollback snapshot: {0}' -f $snapshot)
    ''
    'Every non-cache file observed in the canonical clone or live deployment is'
    'listed below. `REVIEW_REQUIRED` entries are intentionally not removed or merged.'
    ''
    '| Disposition | Count |'
    '| --- | ---: |'
)
foreach ($group in $rows | Group-Object disposition | Sort-Object Name) {
    $summary += "| $($group.Name) | $($group.Count) |"
}
$summary += @('', '| Path | Disposition | Canonical | Live | Package | Reason | Replacement authority | Risk | Rollback |', '| --- | --- | --- | --- | --- | --- | --- | --- | --- |')
foreach ($row in $rows) {
    $summary += "| $($row.path) | $($row.disposition) | $($row.canonical) | $($row.live) | $($row.package) | $($row.reason) | $($row.replacementAuthority) | $($row.risk) | $($row.rollback) |"
}
$summary | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Output "Repository disposition: $OutputPath"
Write-Output "Files classified: $($rows.Count)"
foreach ($group in $rows | Group-Object disposition | Sort-Object Name) {
    Write-Output "$($group.Name): $($group.Count)"
}
