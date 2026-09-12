[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
. (Join-Path $PSScriptRoot 'hash-utils.ps1')
$temp = Join-Path ([IO.Path]::GetTempPath()) ('kwr-field-evidence-' + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Force -Path $temp, (Join-Path $temp 'records') | Out-Null
    $archive = Join-Path $temp 'KnomercyWarRoom-6.1.1-alpha.12.zip'
    [IO.File]::WriteAllText($archive, 'fixture archive', [Text.UTF8Encoding]::new($false))
    $hash = Get-KwrFileSha256 -LiteralPath $archive
    $report = [ordered]@{ schema='kwr-candidate-package-report';schemaVersion=1;candidateVersion='6.1.1-alpha.12';candidateID='alpha12-kwr297-source-20260910-1';distributionArtifact=@{path=$archive};fieldEvidenceBinding=@{candidateID='alpha12-kwr297-source-20260910-1';candidateVersion='6.1.1-alpha.12';distributionSha256=$hash} }
    $reportPath=Join-Path $temp 'package.json'; [IO.File]::WriteAllText($reportPath, (($report|ConvertTo-Json -Depth 6)+"`n"), [Text.UTF8Encoding]::new($false))
    $capture = [ordered]@{candidateID='alpha12-kwr297-source-20260910-1';mapKey='WSG';bracket='STANDARD';sessionID='session-one';clientBuild='12.1.0';capturedAt='2026-09-11T00:00:00Z';roleContext='commander';observationCoverage='partial';capabilities=@('commander')}
    $capturePath=Join-Path $temp 'capture.json'; [IO.File]::WriteAllText($capturePath, (($capture|ConvertTo-Json -Depth 6)+"`n"), [Text.UTF8Encoding]::new($false))
    $out=Join-Path $temp 'records\one.field-evidence.json'
    & (Join-Path $PSScriptRoot 'field-evidence-import.ps1') -CaptureFile $capturePath -CandidatePackageReport $reportPath -OutputFile $out -ExistingRecordsDirectory (Join-Path $temp 'records')
    $bound=Get-Content -LiteralPath $out -Raw|ConvertFrom-Json
    if($bound.status -ne 'UNREVIEWED_FIELD_EVIDENCE' -or $bound.candidate.archiveSha256 -ne $hash){throw 'Valid capture was not bound to its exact archive.'}
    $duplicate=$false;try { & (Join-Path $PSScriptRoot 'field-evidence-import.ps1') -CaptureFile $capturePath -CandidatePackageReport $reportPath -OutputFile (Join-Path $temp 'records\two.field-evidence.json') -ExistingRecordsDirectory (Join-Path $temp 'records') } catch {$duplicate=$true}
    if(-not $duplicate){throw 'Duplicate capture was accepted.'}
    $capture.candidateID='wrong'; [IO.File]::WriteAllText($capturePath, (($capture|ConvertTo-Json -Depth 6)+"`n"), [Text.UTF8Encoding]::new($false))
    $wrong=$false;try { & (Join-Path $PSScriptRoot 'field-evidence-import.ps1') -CaptureFile $capturePath -CandidatePackageReport $reportPath -OutputFile (Join-Path $temp 'wrong.field-evidence.json') } catch {$wrong=$true}
    if(-not $wrong){throw 'Wrong candidate capture was accepted.'}
    Write-Output 'KWR field evidence import test passed'
} finally { if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp -Recurse -Force} }
