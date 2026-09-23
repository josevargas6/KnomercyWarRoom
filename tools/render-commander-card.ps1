[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$OutputDirectory)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
. (Join-Path $PSScriptRoot 'hash-utils.ps1')
$output = [IO.Path]::GetFullPath($OutputDirectory)
if (Test-Path -LiteralPath $output) { throw 'Use a fresh render directory to preserve prior evidence.' }
New-Item -ItemType Directory -Path $output | Out-Null
$oldBridge = $env:KWR_CARD_GEOMETRY
$previous = Get-Location
try {
    Set-Location -LiteralPath $root
    $env:KWR_CARD_GEOMETRY = '1'
    $raw = @(& powershell -NoProfile -ExecutionPolicy Bypass -File tools/test-lua.ps1 -Suite Card `
        -ReceiptFile (Join-Path $output 'lua-receipt.json') 2>&1)
    $code = $LASTEXITCODE
    $raw | Set-Content -LiteralPath (Join-Path $output 'raw-test.log') -Encoding UTF8
    if ($code -ne 0) { throw "Card suite failed ($code); see raw-test.log." }
    $bridge = @($raw | ForEach-Object { $_.ToString() } | Where-Object { $_.StartsWith('KWR_CARD_GEOMETRY ') })
    if ($bridge.Count -ne 1) { throw 'Missing or duplicate production geometry output.' }
    $json = $bridge[0].Substring('KWR_CARD_GEOMETRY '.Length)
    $matrix = $json | ConvertFrom-Json
    if ($matrix.Count -ne 18 -or @($matrix | Where-Object { -not $_.fit }).Count -ne 0) {
        throw 'Incomplete or failed supported layout matrix.'
    }
    [IO.File]::WriteAllText((Join-Path $output 'geometry.json'), $json, [Text.UTF8Encoding]::new($false))
    foreach ($scenario in @('normal', 'ten-player-four-control')) {
        $case = $matrix | Where-Object { $_.scenario -eq $scenario -and $_.screenWidth -eq 1920 -and $_.scale -eq 1 } |
            Select-Object -First 1
        if (-not $case) { throw "Missing render case: $scenario" }
        $sections = foreach ($property in $case.bounds.PSObject.Properties) {
            $key, $box = $property.Name, $property.Value
            $heading = [Net.WebUtility]::HtmlEncode($case.labels.$key)
            $body = [Net.WebUtility]::HtmlEncode($box.text)
            $bodyY = 15 + $box.headingHeight
            $lineHeight = $box.fontSize * 1.2
            "<section class='$key' style='left:$($box.x)px;top:$($box.y)px;width:$($box.width)px;height:$($box.height)px'><div class='heading'>$heading</div><div class='body' style='top:$($bodyY)px;font-size:$($box.fontSize)px;line-height:$($lineHeight)px'>$body</div></section>"
        }
        $footer = [Net.WebUtility]::HtmlEncode($case.feedback)
        $context = [Net.WebUtility]::HtmlEncode($case.contextText)
        $clock = [Net.WebUtility]::HtmlEncode($case.clockText)
        $html = @"
<!doctype html><html lang="en"><meta charset="utf-8"><title>KWR commander card - $scenario</title>
<style>
*{box-sizing:border-box}body{margin:20px;background:#13171f;color:#d9e2ec;font-family:'Segoe UI',sans-serif}
.caption{font-size:13px;color:#a9b9ca;margin-bottom:14px}.card{position:relative;background:#060912;border:1px solid #c9a222}
.brand{position:absolute;left:10px;top:10px;font-size:17px;color:#fff}.context{position:absolute;left:10px;top:44px;font-size:13px;white-space:pre-wrap;line-height:15.6px;color:#c9a222}
.toolbar{position:absolute;right:10px;top:10px;display:flex;gap:8px}button{background:#172334;border:1px solid #344459;color:#d8e1ed;padding:5px 15px;font:12px 'Segoe UI'}
section{position:absolute;background:#121b26;border:1px solid #293643}.heading{position:absolute;left:10px;right:10px;top:10px;color:#c9a222;font-size:12px;line-height:14.4px}
.body{position:absolute;left:10px;right:10px;white-space:pre-wrap;overflow-wrap:anywhere;font-size:13px;line-height:15.6px;color:#f6f9fc}
.now{border-left:3px solid #d7b437}.localFight{border-left:3px solid #d18b49}.controls{border-left:3px solid #8675bb}.speech{border-left:3px solid #5f9db1}
.feedback{position:absolute;left:10px;right:10px;white-space:pre-wrap;font-size:13px;line-height:15.6px;color:#c1ccd8}.buttons{position:absolute;left:10px;display:flex;gap:6px}
</style>
<div class="caption">SOURCE DEVELOPMENT / $scenario / production Lua projection and bounds, conservative mock font metrics. Not a WoW-client screenshot.</div>
<main class="card" style="width:$($case.width)px;height:$($case.height)px">
<div class="brand">KWR / COMMANDER</div><div class="context">$context<br>$clock</div>
<div class="toolbar"><button>COPY CALL</button><button>WIDE</button><button>MENU</button></div>
$($sections -join "`n")
<div class="feedback" style="top:$($case.feedbackY)px">$footer</div>
<div class="buttons" style="top:$($case.buttonY)px"><button>NOT FOLLOWED</button><button>FOLLOWED</button><button>UNDO</button><button>LAST MARK</button></div>
</main></html>
"@
        [IO.File]::WriteAllText((Join-Path $output "$scenario.html"), $html, [Text.UTF8Encoding]::new($false))
    }
    $paths = @('KnomercyWarRoom.toc', 'tests/smoke.lua', 'tests/commander-card.lua', 'tools/test-lua.ps1', 'tools/render-commander-card.ps1')
    $paths += Get-Content -LiteralPath (Join-Path $root 'KnomercyWarRoom.toc') | Where-Object { $_ -match '\.lua$' }
    $paths += @('tests/fixtures/commander_card.lua', 'tests/fixtures/command_followthrough.lua',
        'tests/fixtures/commander_card_layout.lua', 'tests/fixtures/followthrough_learning.lua')
    $hashes = @($paths | Sort-Object -Unique | ForEach-Object {
        # Get-Content decorates strings with provider metadata. Serialize only
        # the plain relative path, not the PSDrive/provider object graph.
        $relative = $_.ToString()
        $path = Join-Path $root $relative
        [pscustomobject]@{ path = $relative; sha256 = Get-KwrFileSha256 -LiteralPath $path }
    })
    [pscustomobject]@{ schema = 'kwr-card-render-inputs'; schemaVersion = 1; generatedAt = [DateTime]::UtcNow.ToString('o');
        base = (& git rev-parse HEAD); dirty = @(& git status --porcelain); source = $root; inputHashes = $hashes;
        geometrySha256 = Get-KwrFileSha256 -LiteralPath (Join-Path $output 'geometry.json'); nativeClient = $false } |
        ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $output 'inputs.json') -Encoding UTF8
    Write-Output "KWR_CARD_RENDER_READY $output"
} finally {
    $env:KWR_CARD_GEOMETRY = $oldBridge
    Set-Location -LiteralPath $previous
}
