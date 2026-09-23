[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$BackupDirectory,
    [string]$AddOnsDirectory='D:\Program Files\World of Warcraft\_retail_\Interface\AddOns'
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'hash-utils.ps1')
if(Get-Process WoW,WoWClassic -ErrorAction SilentlyContinue){throw 'Exit World of Warcraft before restoring.'}
$backup=[IO.Path]::GetFullPath($BackupDirectory).TrimEnd('\')
$addons=[IO.Path]::GetFullPath($AddOnsDirectory).TrimEnd('\')
if($backup -eq $addons){throw 'Backup and destination must differ.'}
$manifest=Get-Content -LiteralPath (Join-Path $backup 'BACKUP_MANIFEST.json') -Raw | ConvertFrom-Json
$names=@('KnomercyWarRoom','KWRSentinel','KWR_DevTools')
if(@($manifest.addons).Count -ne 3){throw 'Expected a complete three-addon backup.'}
function Resolve-Child($Root,$Relative){
    $path=[IO.Path]::GetFullPath((Join-Path $Root $Relative))
    if(-not $path.StartsWith($Root+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Unsafe backup entry.'}
    return $path
}
$rows=@{}
foreach($row in $manifest.addons){
    if($row.name -notin $names -or $rows.ContainsKey($row.name)){throw 'Invalid backup addon identity.'}
    $rows[$row.name]=$row
    $row.baselinePresent = if($null -eq $row.baselinePresent){$true}else{$row.baselinePresent -eq $true}
    if($row.baselinePresent){
        $folder=Join-Path $backup $row.name
        foreach($entry in $row.baselineFiles.PSObject.Properties){
            $path=Resolve-Child $folder $entry.Name
            if((Get-KwrFileSha256 -LiteralPath $path) -ne $entry.Value){throw "Backup hash mismatch: $($row.name)"}
        }
    }
}
$displaced=Join-Path $backup ('before-restore-'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($displaced)|Out-Null
foreach($name in $names){
    $live=Join-Path $addons $name
    if(Test-Path -LiteralPath $live){Copy-Item -LiteralPath $live -Destination (Join-Path $displaced $name) -Recurse}
}
foreach($name in $names){
    $live=Join-Path $addons $name
    if(-not $rows[$name].baselinePresent){
        if(Test-Path -LiteralPath $live){
            Move-Item -LiteralPath $live -Destination (Join-Path $displaced $name)
        }
        if(Test-Path -LiteralPath $live){throw 'Absent companion remained after restoration.'}
        continue
    }
    $expected=@{}
    foreach($entry in $rows[$name].baselineFiles.PSObject.Properties){
        $expected[$entry.Name]=$entry.Value
        $destination=Resolve-Child $live $entry.Name
        [IO.Directory]::CreateDirectory((Split-Path $destination -Parent))|Out-Null
        Copy-Item -LiteralPath (Resolve-Child (Join-Path $backup $name) $entry.Name) -Destination $destination -Force
    }
    foreach($file in Get-ChildItem -LiteralPath $live -Recurse -File){
        $relative=$file.FullName.Substring($live.Length+1)
        if(-not $expected.ContainsKey($relative)){
            $from=Resolve-Child $live $relative
            $extraRoot=Join-Path $displaced ('extras-'+$name)
            $to=Resolve-Child $extraRoot $relative
            [IO.Directory]::CreateDirectory((Split-Path $to -Parent))|Out-Null
            Move-Item -LiteralPath $from -Destination $to
        }
    }
    foreach($relative in $expected.Keys){
        if((Get-KwrFileSha256 -LiteralPath (Resolve-Child $live $relative)) -ne $expected[$relative]){throw 'Restored hash mismatch.'}
    }
    if(@(Get-ChildItem -LiteralPath $live -Recurse -File).Count -ne $expected.Count){throw 'Restored file count mismatch.'}
}
Write-Output "KWR RESTORE PASS: three addons verified. Previous files retained at $displaced. SavedVariables unchanged."
