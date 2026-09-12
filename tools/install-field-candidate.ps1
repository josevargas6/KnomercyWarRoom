[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$BuildDirectory,
    [Parameter(Mandatory=$true)][string]$WorkDirectory,
    [Parameter(Mandatory=$true)][string]$BackupDirectory,
    [string]$AddOnsDirectory = 'D:\Program Files\World of Warcraft\_retail_\Interface\AddOns',
    [switch]$Install
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
. (Join-Path $PSScriptRoot 'hash-utils.ps1')
$build = [IO.Path]::GetFullPath($BuildDirectory)
$work = [IO.Path]::GetFullPath($WorkDirectory)
$backup = [IO.Path]::GetFullPath($BackupDirectory)
$addons = [IO.Path]::GetFullPath($AddOnsDirectory).TrimEnd('\')
$names = @('KnomercyWarRoom','KWRSentinel','KWR_DevTools')
if (Get-Process WoW,WoWClassic -ErrorAction SilentlyContinue) { throw 'Exit World of Warcraft before preparation or installation.' }
foreach ($destination in @($work,$backup)) {
    if (Test-Path -LiteralPath $destination) { throw "Use a new evidence/backup directory: $destination" }
    if ($destination -eq $addons -or $destination -eq [IO.Path]::GetPathRoot($destination)) { throw 'Unsafe destination.' }
    foreach ($name in $names) {
        if ($destination.StartsWith((Join-Path $addons $name) + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Evidence must be outside active addon folders.' }
    }
}
function Write-Receipt($Path, $Value) {
    [IO.File]::WriteAllText($Path, (($Value | ConvertTo-Json -Depth 12) + "`n"), [Text.UTF8Encoding]::new($false))
}
function Get-Tree($Path) {
    $prefix = [IO.Path]::GetFullPath($Path).TrimEnd('\') + '\'
    $result = @{}
    foreach ($file in Get-ChildItem -LiteralPath $Path -Recurse -File) {
        $result[$file.FullName.Substring($prefix.Length)] = Get-KwrFileSha256 -LiteralPath $file.FullName
    }
    return $result
}
function Compare-Tree($Expected, $Actual) {
    $missing = @($Expected.Keys | Where-Object {-not $Actual.ContainsKey($_)})
    $extra = @($Actual.Keys | Where-Object {-not $Expected.ContainsKey($_)})
    $changed = @($Expected.Keys | Where-Object {$Actual.ContainsKey($_) -and $Expected[$_] -ne $Actual[$_]})
    return [ordered]@{ missing=$missing.Count; changed=$changed.Count; extra=$extra.Count; pass=($missing.Count+$extra.Count+$changed.Count -eq 0) }
}
function Copy-Verified($Source, $Destination) {
    if (Test-Path -LiteralPath $Destination) { throw "Copy destination already exists: $Destination" }
    Copy-Item -LiteralPath $Source -Destination $Destination -Recurse
    $comparison = Compare-Tree (Get-Tree $Source) (Get-Tree $Destination)
    if (-not $comparison.pass) { throw "Copy verification failed: $Destination" }
    return $comparison
}
$provenanceFiles = @(Get-ChildItem -LiteralPath $build -Filter '*_BUILD_PROVENANCE.json')
if ($provenanceFiles.Count -ne 1) { throw 'Expected one build provenance receipt.' }
$provenance = Get-Content -LiteralPath $provenanceFiles[0].FullName -Raw | ConvertFrom-Json
$version = [string]$provenance.candidate
$archives = @("KnomercyWarRoom-$version.zip", "KWR-Sentinel-$version.zip", "KWR_DevTools-$version.zip")
[IO.Directory]::CreateDirectory($work) | Out-Null
[IO.Directory]::CreateDirectory($backup) | Out-Null
$stage = Join-Path $work 'stage'
$rehearsal = Join-Path $work 'restore-rehearsal'
[IO.Directory]::CreateDirectory($stage) | Out-Null
[IO.Directory]::CreateDirectory($rehearsal) | Out-Null
$rows = @()
for ($i=0; $i -lt $names.Count; $i++) {
    $name=$names[$i]
    $archive=Join-Path $build $archives[$i]
    $hash=Get-KwrFileSha256 -LiteralPath $archive
    $record=@($provenance.outputArtifacts | Where-Object name -eq $archives[$i])
    if ($record.Count -ne 1 -or $record[0].sha256 -ne $hash) { throw "Archive provenance mismatch: $name" }
    $zip=[IO.Compression.ZipFile]::OpenRead($archive)
    try {
        $expected=@{}
        foreach($entry in $zip.Entries) {
            if (-not $entry.Name) { continue }
            $relative=$entry.FullName.Replace('/','\')
            $target=[IO.Path]::GetFullPath((Join-Path $stage $relative))
            $allowed=(Join-Path $stage $name) + '\'
            if (-not $target.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)) { throw 'Archive path escapes its addon root.' }
            $key=$target.Substring($allowed.Length)
            if ($expected.ContainsKey($key)) { throw 'Duplicate archive entry.' }
            $stream=$entry.Open(); $sha=[Security.Cryptography.SHA256]::Create()
            try { $expected[$key]=[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','') }
            finally { $sha.Dispose(); $stream.Dispose() }
        }
    } finally { $zip.Dispose() }
    [IO.Compression.ZipFile]::ExtractToDirectory($archive,$stage)
    if (-not (Compare-Tree $expected (Get-Tree (Join-Path $stage $name))).pass) { throw 'Extracted archive mismatch.' }
    $live=Join-Path $addons $name
    # Commander is the required player surface. Sentinel and DevTools are
    # optional companions and may be deliberately absent on a first field
    # install. Record that absence so rollback restores absence exactly.
    $baselinePresent=Test-Path -LiteralPath $live -PathType Container
    if ($name -eq 'KnomercyWarRoom' -and -not $baselinePresent) {
        throw 'Missing baseline addon: KnomercyWarRoom'
    }
    $baseline=if($baselinePresent){Get-Tree $live}else{@{}}
    $snapshot=Join-Path $backup $name
    $snapshotResult=if($baselinePresent){Copy-Verified $live $snapshot}else{[ordered]@{missing=0;changed=0;extra=0;pass=$true;absent=$true}}
    # Exercise candidate displacement and old-trio restoration only in staging.
    $trial=Join-Path $rehearsal $name
    $null=Copy-Verified (Join-Path $stage $name) $trial
    $displaced=Join-Path $rehearsal ($name + '-candidate')
    foreach($path in @($trial,$displaced)) {
        if (-not [IO.Path]::GetFullPath($path).StartsWith($rehearsal+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe rehearsal move.' }
    }
    Move-Item -LiteralPath $trial -Destination $displaced
    $restoreResult=if($baselinePresent){Copy-Verified $snapshot $trial}else{[ordered]@{missing=0;changed=0;extra=0;pass=(-not (Test-Path -LiteralPath $trial));absent=$true}}
    if(-not $restoreResult.pass){throw "Restore rehearsal failed: $name"}
    $rows+= [ordered]@{ name=$name; zip=$archive; sha256=$hash; files=$expected; baselinePresent=$baselinePresent; baselineFiles=$baseline; snapshot=$snapshotResult; restore=$restoreResult }
}
# Back up only KWR SavedVariables files; never read or modify unrelated data.
$savedRoot=Join-Path (Split-Path (Split-Path $addons -Parent) -Parent) 'WTF'
$savedCount=0
if (Test-Path -LiteralPath $savedRoot) {
    foreach($file in Get-ChildItem -LiteralPath $savedRoot -Recurse -File | Where-Object {$_.Name -in @('KnomercyWarRoom.lua','KnomercyWarRoom.lua.bak','KWRSentinel.lua','KWRSentinel.lua.bak')}) {
        $relative=$file.FullName.Substring($savedRoot.Length).TrimStart('\')
        $target=Join-Path (Join-Path $backup 'SavedVariables') $relative
        [IO.Directory]::CreateDirectory((Split-Path $target -Parent)) | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $target
        if ((Get-KwrFileSha256 -LiteralPath $target) -ne (Get-KwrFileSha256 -LiteralPath $file.FullName)) { throw 'SavedVariables copy mismatch.' }
        $savedCount++
    }
}
Write-Receipt (Join-Path $backup 'BACKUP_MANIFEST.json') @{version=$version; createdAt=[DateTime]::UtcNow.ToString('o'); addons=$rows; savedVariablesFiles=$savedCount}
$installed=@()
if ($Install) {
    if (Get-Process WoW,WoWClassic -ErrorAction SilentlyContinue) { throw 'Game started during preparation; installation cancelled.' }
    foreach($row in $rows) {
        $live=Join-Path $addons $row.name
        if($row.baselinePresent){
            if (-not (Compare-Tree $row.baselineFiles (Get-Tree $live)).pass) { throw 'Installed baseline changed after backup; installation cancelled.' }
        } elseif(Test-Path -LiteralPath $live) {
            throw "Previously absent companion appeared after backup: $($row.name); installation cancelled."
        }
    }
    foreach($row in $rows) {
        $live=Join-Path $addons $row.name
        foreach($relative in $row.files.Keys) {
            $destination=Join-Path $live $relative
            [IO.Directory]::CreateDirectory((Split-Path $destination -Parent)) | Out-Null
            Copy-Item -LiteralPath (Join-Path (Join-Path $stage $row.name) $relative) -Destination $destination -Force
        }
        foreach($relative in @($row.baselineFiles.Keys | Where-Object {-not $row.files.ContainsKey($_)})) {
            $from=[IO.Path]::GetFullPath((Join-Path $live $relative))
            $to=Join-Path (Join-Path $backup 'displaced-extras') ($row.name+'\'+$relative)
            if (-not $from.StartsWith($live+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe extra-file move.' }
            [IO.Directory]::CreateDirectory((Split-Path $to -Parent)) | Out-Null
            Move-Item -LiteralPath $from -Destination $to
        }
        $comparison=Compare-Tree $row.files (Get-Tree $live)
        if (-not $comparison.pass) { throw "Installed comparison failed: $($row.name). Restore from $backup" }
        $installed+=@{name=$row.name;sha256=$row.sha256;fileCount=$row.files.Count;comparison=$comparison}
    }
}
$buildInfo=Get-Content -LiteralPath (Join-Path $stage 'KnomercyWarRoom\Core\BuildInfo.lua') -Raw
$candidateID=[regex]::Match($buildInfo,'BuildInfo.candidateID = "([^"]+)"').Groups[1].Value
if (-not $candidateID) { throw 'Candidate capture ID missing.' }
Write-Receipt (Join-Path $work 'DEPLOYMENT.json') @{
    candidateID=$candidateID;version=$version;createdAt=[DateTime]::UtcNow.ToString('o');
    status=$(if($Install){'INSTALLED_VERIFIED'}else{'STAGED_VERIFIED'});
    scope='Owner-authorized diagnostic field candidate; no clean/public release or live certification';
    source=$provenance.git;backup=$backup;restoreRehearsal='PASS';savedVariablesFiles=$savedCount;
    installed=$installed;archives=@($rows|ForEach-Object {@{name=$_.name;path=$_.zip;sha256=$_.sha256}})
}
Write-Output "KWR field candidate: $candidateID; installed=$Install; restore rehearsal PASS; receipt=$work\DEPLOYMENT.json"
