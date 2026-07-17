[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

$excludedDirectories = @(
    ".git",
    "artifacts",
    "builds",
    "coverage",
    "node_modules",
    "temp",
    "tmp"
)
$excludedPattern = "\\(" + (($excludedDirectories | ForEach-Object { [regex]::Escape($_) }) -join "|") + ")\\"

$files = @(
    Get-ChildItem -LiteralPath $root -Recurse -Force -File |
        Where-Object {
            $_.FullName -notmatch $excludedPattern -and
            $_.Length -lt 2MB
        }
)

$allowedEnvNames = @(".env.example", ".env.sample", ".env.template")
foreach ($file in $files) {
    if ($file.Name -match '^\.env(?:\.|$)' -and $allowedEnvNames -notcontains $file.Name) {
        $errors.Add("Local environment file must not enter the workspace: $($file.FullName.Substring($root.Length + 1))")
    }

    if ($file.Name -match '^(?:credentials\.json|service-account.*\.json|id_rsa|id_ed25519)$' -or
        $file.Extension -match '^\.(?:key|p12|pfx|pem)$') {
        $errors.Add("Sensitive credential file is present: $($file.FullName.Substring($root.Length + 1))")
    }
}

$secretPatterns = [ordered]@{
    "GitHub token" = '\bgh[pousr]_[A-Za-z0-9_]{20,}\b'
    "OpenAI API key" = '\bsk-(?:proj-)?[A-Za-z0-9_-]{20,}\b'
    "Discord bot token" = '\b(?:mfa\.[A-Za-z0-9_-]{20,}|[A-Za-z0-9_-]{23,28}\.[A-Za-z0-9_-]{6,7}\.[A-Za-z0-9_-]{27,})\b'
    "Discord webhook" = 'https://(?:canary\.|ptb\.)?discord(?:app)?\.com/api/webhooks/\d+/[A-Za-z0-9_-]+'
    "Private key" = '-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'
}

$textExtensions = @(
    ".cfg", ".conf", ".env", ".example", ".ini", ".js", ".json", ".lua",
    ".md", ".ps1", ".service", ".sh", ".toml", ".toc", ".txt", ".yaml", ".yml"
)

foreach ($file in $files) {
    if ($textExtensions -notcontains $file.Extension.ToLowerInvariant() -and $file.Name -notmatch '^\.env') {
        continue
    }

    foreach ($entry in $secretPatterns.GetEnumerator()) {
        $hits = @(Select-String -LiteralPath $file.FullName -Pattern $entry.Value -AllMatches -ErrorAction SilentlyContinue)
        foreach ($hit in $hits) {
            $relative = $file.FullName.Substring($root.Length + 1)
            $errors.Add("Possible $($entry.Key) at ${relative}:$($hit.LineNumber) (value redacted)")
        }
    }
}

if (-not (Test-Path -LiteralPath (Join-Path $root ".git"))) {
    $warnings.Add("This workspace has no .git metadata; branch, tracked-file, and pre-commit checks cannot be verified locally.")
}

Write-Output "KWR security audit"
Write-Output "Root: $root"
Write-Output "Files inspected: $($files.Count)"
Write-Output "Errors: $($errors.Count)"
Write-Output "Warnings: $($warnings.Count)"

foreach ($warning in $warnings) {
    Write-Warning $warning
}
foreach ($auditError in $errors) {
    Write-Error $auditError -ErrorAction Continue
}

if ($errors.Count -gt 0) {
    exit 1
}

Write-Output "SECURITY AUDIT PASSED"
exit 0
