[CmdletBinding()]
param()

function Get-KwrFileSha256 {
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LiteralPath
    )

    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) {
        throw "Cannot hash missing file: $LiteralPath"
    }

    # Get-FileHash is normally present, but a nested no-profile Windows
    # PowerShell process may not auto-load Microsoft.PowerShell.Utility. A
    # release checksum must be independent of that host-specific behavior.
    $getFileHash = Get-Command Get-FileHash -ErrorAction SilentlyContinue
    if ($getFileHash) {
        try {
            return (Get-FileHash -LiteralPath $LiteralPath -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()
        } catch {
            # Fall through to the platform SHA256 implementation.
        }
    }

    $stream = [IO.File]::OpenRead($LiteralPath)
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($algorithm.ComputeHash($stream))).Replace('-', '')
    } finally {
        $algorithm.Dispose()
        $stream.Dispose()
    }
}
