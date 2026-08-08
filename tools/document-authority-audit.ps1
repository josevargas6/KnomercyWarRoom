[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$registryPath = Join-Path $root 'docs\governance\document-authority-registry.yml'
$errors = [System.Collections.Generic.List[string]]::new()

function Add-AuditError {
    param([string]$Message)
    $script:errors.Add($Message)
}

if (-not (Test-Path -LiteralPath $registryPath)) {
    throw "Document authority registry is missing: $registryPath"
}

$lines = Get-Content -LiteralPath $registryPath
$authorities = New-Object System.Collections.Generic.List[object]
$approvedRoot = New-Object System.Collections.Generic.List[string]
$section = ''
$pendingConcern = $null
foreach ($line in $lines) {
    if ($line -match '^authorities:') { $section = 'authorities'; continue }
    if ($line -match '^approved_root_markdown:') { $section = 'root'; continue }
    if ($line -match '^historical_prefixes:') { $section = 'historical'; continue }
    if ($section -eq 'authorities' -and $line -match '^  - concern:\s*(.+)$') {
        $pendingConcern = $Matches[1].Trim()
        continue
    }
    if ($section -eq 'authorities' -and $pendingConcern -and $line -match '^    path:\s*(.+)$') {
        $authorities.Add([pscustomobject]@{ concern = $pendingConcern; path = $Matches[1].Trim() })
        $pendingConcern = $null
        continue
    }
    if ($section -eq 'root' -and $line -match '^  -\s+(.+)$') {
        $approvedRoot.Add($Matches[1].Trim())
    }
}

if ($authorities.Count -ne 12) {
    Add-AuditError "Document registry must declare exactly 12 authority concerns; found $($authorities.Count)."
}
foreach ($duplicate in @($authorities | Group-Object concern | Where-Object Count -gt 1)) {
    Add-AuditError "More than one authority owns concern: $($duplicate.Name)"
}
foreach ($authority in $authorities) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $authority.path))) {
        Add-AuditError "Authority document is missing for '$($authority.concern)': $($authority.path)"
    }
}

$supersededAuthorities = @(
    'RELEASE_VISION.md',
    'EXPERT_TIER_BATTLEFIELD_MASTER_PLAN.md',
    'ALPHA_S_TIER_MASTER_PLAN.md',
    'PILLAR_EXECUTION_SHEET.md',
    'WINNING_STATE_EXECUTION_MAP.md',
    'KWR_AUTOMATION_MASTER_DIRECTIVE.md'
)
foreach ($authority in $authorities | Where-Object { $_.path -notmatch '/$' }) {
    if ($authority.path -eq 'CHANGELOG.md') {
        continue
    }
    $text = Get-Content -LiteralPath (Join-Path $root $authority.path) -Raw
    foreach ($superseded in $supersededAuthorities) {
        if ($text -match [regex]::Escape($superseded)) {
            Add-AuditError "Authority document references a superseded authority: $($authority.path) -> $superseded"
        }
    }
}

$rootMarkdown = @(Get-ChildItem -LiteralPath $root -File -Filter '*.md')
foreach ($file in $rootMarkdown) {
    if ($file.Name -notin $approvedRoot) {
        Add-AuditError "Unapproved Markdown file at repository root: $($file.Name)"
    }
}

$tocVersion = ((Get-Content -LiteralPath (Join-Path $root 'KnomercyWarRoom.toc') |
    Where-Object { $_ -match '^## Version:' }) -replace '^## Version:\s*', '').Trim()
$readiness = Get-Content -LiteralPath (Join-Path $root 'RELEASE_READINESS.md') -Raw
if ($readiness -notmatch [regex]::Escape($tocVersion)) {
    Add-AuditError "RELEASE_READINESS.md does not name TOC version $tocVersion."
}

$taskFiles = @(Get-ChildItem -LiteralPath (Join-Path $root 'docs\tasks') -File -Filter 'KWR-*.md')
foreach ($task in $taskFiles) {
    $taskText = Get-Content -LiteralPath $task.FullName -Raw
    if ($taskText -notmatch '(?m)^status:\s*(in_progress|blocked|completed|planned)\s*$') {
        Add-AuditError "Active task lacks required status: $($task.Name)"
    }
    if ($taskText -notmatch '(?m)^authority_references:\s*\[') {
        Add-AuditError "Active task lacks authority references: $($task.Name)"
    }
    if ($taskText -match '(?m)^status:\s*completed\s*$' -and $task.FullName -notmatch '\\docs\\tasks\\completed\\') {
        Add-AuditError "Completed task remains in active work queue: $($task.Name)"
    }
}

$historicalPrefixes = @('docs\\evidence\\', 'docs\\audits\\')
$claimPattern = '(?i)\b(master plan|project handoff|execution map|current baseline|source of truth)\b'
$authorityPaths = @($authorities.path)
$markdownFiles = @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.md')
foreach ($file in $markdownFiles) {
    $relative = $file.FullName.Substring($root.Length + 1).Replace('/', '\\')
    if ($relative -match '^docs\\(evidence|audits)\\') {
        $historical = Get-Content -LiteralPath $file.FullName -Raw
        if ($historical -notmatch '(?m)^# Historical') {
            Add-AuditError "Historical document lacks an explicit historical label: $relative"
        }
        continue
    }
    $text = Get-Content -LiteralPath $file.FullName -Raw
    if ($text -match '(?m)^# Historical') {
        continue
    }
    if ($text -match $claimPattern -and $relative -notmatch '^docs\\tasks\\' -and $relative -notin $authorityPaths -and $relative -notin @('README.md', 'AGENTS.md')) {
        Add-AuditError "Competing active authority claim: $relative"
    }
}

Write-Output 'KWR document-authority audit'
Write-Output "Authorities: $($authorities.Count)"
Write-Output "Task contracts: $($taskFiles.Count)"
Write-Output "Errors: $($errors.Count)"
foreach ($errorText in $errors) {
    Write-Error $errorText -ErrorAction Continue
}
if ($errors.Count -gt 0) {
    exit 1
}
Write-Output 'DOCUMENT AUTHORITY AUDIT PASSED'
