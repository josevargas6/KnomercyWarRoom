[CmdletBinding()]
param(
    [string]$InputFile = "knowledge\season2-rbg-simulation-corpus.json",
    [string]$OutputFile = "Data\StrategistNexusCorpus.lua"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$inputPath = if ([IO.Path]::IsPathRooted($InputFile)) {
    [IO.Path]::GetFullPath($InputFile)
} else { Join-Path $root $InputFile }
$outputPath = if ([IO.Path]::IsPathRooted($OutputFile)) {
    [IO.Path]::GetFullPath($OutputFile)
} else { Join-Path $root $OutputFile }
$document = Get-Content -LiteralPath $inputPath -Raw | ConvertFrom-Json
$cases = if ($document.cases) { @($document.cases) } else { @() }
$completeMatrix = $document.coverageMode -eq "COMPLETE_CARTESIAN"

if ($document.schema -ne "kwr-season2-rbg-simulation-corpus") {
    throw "Unexpected Strategist Nexus corpus schema: $($document.schema)"
}
if ([int]$document.totalCases -ne 100000 -or
    ((-not $completeMatrix) -and $cases.Count -ne 100000)) {
    throw "Strategist Nexus requires exactly 100,000 source cases."
}
if (-not $completeMatrix -and @($cases.caseId | Sort-Object -Unique).Count -ne $cases.Count) {
    throw "Strategist Nexus source case IDs are not unique."
}
if (-not $completeMatrix -and @($cases.contentHash | Sort-Object -Unique).Count -ne $cases.Count) {
    throw "Strategist Nexus source content hashes are not unique."
}
if (-not $completeMatrix -and @($cases | Where-Object status -ne "SIMULATION_ONLY").Count -gt 0) {
    throw "The offline Nexus compiler only accepts SIMULATION_ONLY cases."
}

function ConvertTo-LuaString {
    param([AllowNull()][object]$Value)
    $text = [string]$Value
    $text = $text.Replace('\', '\\').Replace('"', '\"')
    $text = $text.Replace("`r", '\r').Replace("`n", '\n')
    return '"' + $text + '"'
}

function Add-Count {
    param(
        [Parameter(Mandatory = $true)][hashtable]$Table,
        [Parameter(Mandatory = $true)][string]$Key
    )
    $current = if ($Table.ContainsKey($Key)) { [int]$Table[$Key] } else { 0 }
    $Table[$Key] = $current + 1
}

function Write-CountTable {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [Parameter(Mandatory = $true)][string]$Indent,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][hashtable]$Values
    )
    $Lines.Add("$Indent$Name = {")
    foreach ($key in @($Values.Keys | Sort-Object)) {
        $Lines.Add("$Indent    [$(ConvertTo-LuaString $key)] = $($Values[$key]),")
    }
    $Lines.Add("$Indent},")
}

$maps = @{}
$jointSeparator = [string][char]31
if ($completeMatrix) {
    $familiesByPhase = $document.matrix.families
    $compWatches = @($document.matrix.compWatches)
    $scoreStates = @($document.matrix.scoreStates)
    $counterResponses = @($document.matrix.counterResponses)
    $evidenceStates = @($document.matrix.evidenceStates)
    $perPhase = [int]$document.casesPerPhasePerMap
    foreach ($sourceMap in @($document.matrix.maps)) {
        $map = @{ mapProfile = [string]$sourceMap.mapProfile; totalCases = 0; phases = @{} }
        foreach ($phase in @('OPENING', 'STABILIZE', 'PRESSURE', 'RECOVERY', 'ENDGAME')) {
            $families = @($familiesByPhase.$phase)
            $expected = $families.Count * $compWatches.Count * $scoreStates.Count *
                $counterResponses.Count * $evidenceStates.Count
            if ($expected -ne $perPhase) {
                throw "Complete matrix cardinality mismatch for $($sourceMap.mapKey) / $phase."
            }
            $bucket = @{
                totalCases = $perPhase
                completeMatrix = $true
                families = @{}; compWatches = @{}; scoreStates = @{}
                counterResponses = @{}; evidenceStates = @{}; jointCases = @{}
                outcomeBranches = @{}; sourceScenarios = @{}
            }
            foreach ($value in $families) { $bucket.families[[string]$value] = [int]($perPhase / $families.Count) }
            foreach ($value in $compWatches) { $bucket.compWatches[[string]$value] = [int]($perPhase / $compWatches.Count) }
            foreach ($value in $scoreStates) { $bucket.scoreStates[[string]$value] = [int]($perPhase / $scoreStates.Count) }
            foreach ($value in $counterResponses) { $bucket.counterResponses[[string]$value] = [int]($perPhase / $counterResponses.Count) }
            foreach ($value in $evidenceStates) { $bucket.evidenceStates[[string]$value] = [int]($perPhase / $evidenceStates.Count) }
            foreach ($value in @($sourceMap.phaseScenarioIds.$phase)) { $bucket.sourceScenarios[[string]$value] = 1 }
            $map.phases[$phase] = $bucket
            $map.totalCases += $perPhase
        }
        $maps[[string]$sourceMap.mapKey] = $map
    }
} else {
foreach ($case in $cases) {
    $mapKey = [string]$case.mapKey
    $phase = [string]$case.phase
    if (-not $maps.ContainsKey($mapKey)) {
        $maps[$mapKey] = @{
            mapProfile = [string]$case.mapProfile
            totalCases = 0
            phases = @{}
        }
    }
    $map = $maps[$mapKey]
    $map.totalCases++
    if (-not $map.phases.ContainsKey($phase)) {
        $map.phases[$phase] = @{
            totalCases = 0
            families = @{}
            compWatches = @{}
            scoreStates = @{}
            counterResponses = @{}
            evidenceStates = @{}
            jointCases = @{}
            outcomeBranches = @{}
            sourceScenarios = @{}
        }
    }
    $bucket = $map.phases[$phase]
    $bucket.totalCases++
    Add-Count $bucket.families ([string]$case.scenarioFamily)
    Add-Count $bucket.compWatches ([string]$case.compWatch)
    Add-Count $bucket.scoreStates ([string]$case.scoreState)
    Add-Count $bucket.counterResponses ([string]$case.counterResponse)
    Add-Count $bucket.evidenceStates ([string]$case.evidenceState)
    $jointKey = @(
        [string]$case.scenarioFamily,
        [string]$case.compWatch,
        [string]$case.scoreState,
        [string]$case.counterResponse,
        [string]$case.evidenceState
    ) -join $jointSeparator
    Add-Count $bucket.jointCases $jointKey
    Add-Count $bucket.outcomeBranches ([string]$case.outcomeBranch)
    Add-Count $bucket.sourceScenarios ([string]$case.sourceScenarioId)
}
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('local _, KWR = ...')
$lines.Add('')
$lines.Add('-- Generated by tools/build-strategist-nexus-corpus.ps1. Do not edit.')
$lines.Add('-- Counts describe deterministic branch coverage, not empirical win rates.')
$lines.Add('local StrategistNexusCorpus = {}')
$lines.Add('KWR.StrategistNexusCorpus = StrategistNexusCorpus')
$lines.Add('')
$lines.Add('local DATA = {')
$lines.Add('    schemaVersion = 1,')
$lines.Add("    sourceSchemaVersion = $([int]$document.schemaVersion),")
$lines.Add("    patch = $(ConvertTo-LuaString $document.patch),")
$lines.Add("    sourceStatus = $(ConvertTo-LuaString $document.status),")
$lines.Add("    activation = $(ConvertTo-LuaString $document.activation),")
$lines.Add("    totalCases = $([int]$document.totalCases),")
$lines.Add('    maps = {')
foreach ($mapKey in @($maps.Keys | Sort-Object)) {
    $map = $maps[$mapKey]
    $lines.Add("        [$((ConvertTo-LuaString $mapKey))] = {")
    $lines.Add("            mapProfile = $(ConvertTo-LuaString $map.mapProfile),")
    $lines.Add("            totalCases = $($map.totalCases),")
    $lines.Add('            phases = {')
    foreach ($phase in @($map.phases.Keys | Sort-Object)) {
        $bucket = $map.phases[$phase]
        $lines.Add("                [$((ConvertTo-LuaString $phase))] = {")
        $lines.Add("                    totalCases = $($bucket.totalCases),")
        if ($bucket.completeMatrix) { $lines.Add("                    completeMatrix = true,") }
        Write-CountTable $lines '                    ' 'families' $bucket.families
        Write-CountTable $lines '                    ' 'compWatches' $bucket.compWatches
        Write-CountTable $lines '                    ' 'scoreStates' $bucket.scoreStates
        Write-CountTable $lines '                    ' 'counterResponses' $bucket.counterResponses
        Write-CountTable $lines '                    ' 'evidenceStates' $bucket.evidenceStates
        Write-CountTable $lines '                    ' 'jointCases' $bucket.jointCases
        Write-CountTable $lines '                    ' 'outcomeBranches' $bucket.outcomeBranches
        Write-CountTable $lines '                    ' 'sourceScenarios' $bucket.sourceScenarios
        $lines.Add('                },')
    }
    $lines.Add('            },')
    $lines.Add('        },')
}
$lines.Add('    },')
$lines.Add('}')
$lines.Add('')
$lines.Add('local function jointKey(query)')
$lines.Add('    if not query.family or query.family == "" or not query.compWatch or query.compWatch == ""')
$lines.Add('        or not query.scoreState or query.scoreState == "" or not query.counterResponse or query.counterResponse == ""')
$lines.Add('        or not query.evidenceState or query.evidenceState == "" then return nil end')
$lines.Add('    local values = { query.family, query.compWatch, query.scoreState, query.counterResponse, query.evidenceState }')
$lines.Add('    return table.concat(values, "\31")')
$lines.Add('end')
$lines.Add('')
$lines.Add('function StrategistNexusCorpus:Count() return DATA.totalCases end')
$lines.Add('function StrategistNexusCorpus:Status() return DATA.sourceStatus end')
$lines.Add('function StrategistNexusCorpus:Activation() return DATA.activation end')
$lines.Add('function StrategistNexusCorpus:Patch() return DATA.patch end')
$lines.Add('function StrategistNexusCorpus:Map(mapKey) return DATA.maps[mapKey] end')
$lines.Add('')
$lines.Add('function StrategistNexusCorpus:Coverage(mapKey, phase, query)')
$lines.Add('    local map = DATA.maps[mapKey]')
$lines.Add('    local bucket = map and map.phases and map.phases[phase]')
$lines.Add('    if not bucket then')
$lines.Add('        return { available = false, marginalCases = 0, sourceStatus = DATA.sourceStatus }')
$lines.Add('    end')
$lines.Add('    query = type(query) == "table" and query or {}')
$lines.Add('    local key = jointKey(query)')
$lines.Add('    local hasQuery = next(query) ~= nil')
$lines.Add('    -- An incomplete filter cannot be treated as exact support. Empty')
$lines.Add('    -- queries intentionally report phase coverage; filtered queries')
$lines.Add('    -- require every indexed dimension and otherwise fail closed.')
$lines.Add('    local exactKnown = key and bucket.families[query.family] and bucket.compWatches[query.compWatch]')
$lines.Add('        and bucket.scoreStates[query.scoreState] and bucket.counterResponses[query.counterResponse]')
$lines.Add('        and bucket.evidenceStates[query.evidenceState]')
$lines.Add('    local count = not hasQuery and bucket.totalCases')
$lines.Add('        or (bucket.completeMatrix and exactKnown and 1)')
$lines.Add('        or (key and (bucket.jointCases and bucket.jointCases[key] or 0) or 0)')
$lines.Add('    return {')
$lines.Add('        available = count > 0,')
$lines.Add('        marginalCases = count,')
$lines.Add('        exactCases = count,')
$lines.Add('        phaseCases = bucket.totalCases,')
$lines.Add('        mapCases = map.totalCases,')
$lines.Add('        totalCases = DATA.totalCases,')
$lines.Add('        sourceStatus = DATA.sourceStatus,')
$lines.Add('        patch = DATA.patch,')
$lines.Add('        mapProfile = map.mapProfile,')
$lines.Add('    }')
$lines.Add('end')
$lines.Add('')
$lines.Add('function StrategistNexusCorpus:Shared() return DATA end')
$lines.Add('')
$lines.Add('KWR:RegisterModule("StrategistNexusCorpus", StrategistNexusCorpus)')

[IO.File]::WriteAllText($outputPath, (($lines -join "`n") + "`n"),
    [Text.UTF8Encoding]::new($false))
Write-Output "Strategist Nexus corpus: $([int]$document.totalCases) cases -> $OutputFile"
