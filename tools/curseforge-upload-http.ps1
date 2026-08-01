function Assert-CurseForgeProjectId {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectId
    )

    if ($ProjectId -notmatch '^\d+$') {
        throw "CurseForge project id must be the numeric ID shown on the public project page; got '$ProjectId'."
    }
}

function Assert-CurseForgeUploadResponse {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HttpStatus,
        [AllowEmptyString()]
        [string]$ResponseBody = ""
    )

    $statusCode = 0
    if (-not [int]::TryParse($HttpStatus, [ref]$statusCode) -or
        $statusCode -lt 200 -or
        $statusCode -ge 300) {
        $detail = $ResponseBody.Trim()
        if ($detail.Length -gt 500) {
            $detail = $detail.Substring(0, 500)
        }
        throw "CurseForge upload returned HTTP $HttpStatus. $detail".Trim()
    }

    try {
        $response = $ResponseBody | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw "CurseForge upload returned HTTP $HttpStatus without a valid JSON response."
    }

    $fileId = 0L
    if ($null -eq $response.id -or
        -not [long]::TryParse([string]$response.id, [ref]$fileId) -or
        $fileId -le 0) {
        throw "CurseForge upload returned HTTP $HttpStatus without a positive file id."
    }

    return $fileId
}

function Invoke-CurseForgeMultipartUpload {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectId,
        [Parameter(Mandatory = $true)]
        [string]$ApiToken,
        [Parameter(Mandatory = $true)]
        [string]$MetadataPath,
        [Parameter(Mandatory = $true)]
        [string]$ArtifactPath
    )

    Assert-CurseForgeProjectId -ProjectId $ProjectId

    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if (-not $curl) {
        throw "curl.exe is required for the multipart CurseForge upload."
    }

    $endpoint = "https://www.curseforge.com/api/projects/$ProjectId/upload-file"
    $responsePath = Join-Path ([IO.Path]::GetTempPath()) (
        "kwr-curseforge-response-" + [guid]::NewGuid().ToString("N") + ".json"
    )
    $curlArguments = @(
        "--silent",
        "--show-error",
        "--output", $responsePath,
        "--write-out", "%{http_code}",
        "--request", "POST",
        "--header", "X-Api-Token: $ApiToken",
        "--form", "metadata=<$MetadataPath",
        "--form", "file=@$ArtifactPath",
        $endpoint
    )

    try {
        $httpStatus = (& $curl.Source @curlArguments | Out-String).Trim()
        $curlExitCode = $LASTEXITCODE
        $responseBody = if (Test-Path -LiteralPath $responsePath) {
            Get-Content -LiteralPath $responsePath -Raw
        } else {
            ""
        }

        if ($curlExitCode -ne 0) {
            throw "CurseForge upload transport failed with exit code $curlExitCode."
        }

        return Assert-CurseForgeUploadResponse `
            -HttpStatus $httpStatus `
            -ResponseBody $responseBody
    } finally {
        Remove-Item -LiteralPath $responsePath -Force -ErrorAction SilentlyContinue
    }
}
